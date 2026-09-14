const fetch = require('node-fetch');
const { createClient } = require('@supabase/supabase-js');

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json'
};

function response(statusCode, data) {
  return {
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify(data)
  };
}

exports.handler = async (event) => {

  // -----------------------------------------
  // OPTIONS / CORS
  // -----------------------------------------

  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: CORS_HEADERS,
      body: ''
    };
  }

  // -----------------------------------------
  // POST only
  // -----------------------------------------

  if (event.httpMethod !== 'POST') {
    return response(405, {
      error: 'Method Not Allowed'
    });
  }

  try {

    // -----------------------------------------
    // Authorization
    // -----------------------------------------

    const authHeader =
      event.headers.authorization ||
      event.headers.Authorization;

    if (!authHeader) {
      return response(401, {
        error: 'Missing authorization header'
      });
    }

    const token = authHeader.replace(
      'Bearer ',
      ''
    );

    // -----------------------------------------
    // Supabase
    // -----------------------------------------

    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );

    // -----------------------------------------
    // Verify user
    // -----------------------------------------

    const {
      data: userData,
      error: userError
    } = await supabase.auth.getUser(token);

    if (
      userError ||
      !userData ||
      !userData.user
    ) {
      return response(401, {
        error: 'Invalid token'
      });
    }

    const userId = userData.user.id;

    // -----------------------------------------
    // Parse request
    // -----------------------------------------

    let body;

    try {
      body = JSON.parse(event.body || '{}');
    } catch (error) {
      return response(400, {
        error: 'Invalid JSON request'
      });
    }

    const {
      action,
      ...data
    } = body;

    // =========================================
    // BALANCE
    // =========================================

    if (action === 'balance') {

      const {
        data: profile,
        error
      } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

      if (error) {
        throw error;
      }

      return response(200, {
        balance: profile.balance
      });
    }

    // =========================================
    // ADD ORDER
    // =========================================

    if (action === 'add') {

      // ---------------------------------------
      // Validate input
      // ---------------------------------------

      const serviceId = parseInt(data.service);
      const link = String(data.link || '').trim();
      const quantity = parseInt(data.quantity);

      if (!Number.isInteger(serviceId)) {
        return response(400, {
          error: 'Invalid service'
        });
      }

      if (!link) {
        return response(400, {
          error: 'Link is required'
        });
      }

      if (!Number.isInteger(quantity)) {
        return response(400, {
          error: 'Invalid quantity'
        });
      }

      // ---------------------------------------
      // Get service
      // ---------------------------------------

      const {
        data: service,
        error: serviceError
      } = await supabase
        .from('services')
        .select('*')
        .eq('id', serviceId)
        .single();

      if (
        serviceError ||
        !service
      ) {
        return response(400, {
          error: 'Service not found'
        });
      }

      // ---------------------------------------
      // IMPORTANT:
      // Check if service is active
      // ---------------------------------------

      if (service.is_active !== true) {
        return response(400, {
          error:
            'This service is currently unavailable. Please select another service.'
        });
      }

      // ---------------------------------------
      // Quantity validation
      // ---------------------------------------

      if (
        quantity < service.min_order ||
        quantity > service.max_order
      ) {
        return response(400, {
          error:
            `Quantity must be between ${service.min_order} and ${service.max_order}`
        });
      }

      // ---------------------------------------
      // Calculate cost
      // ---------------------------------------

      const cost =
        (parseFloat(service.rate) / 1000) *
        quantity;

      const charge =
        (parseFloat(service.selling_rate) / 1000) *
        quantity;

      // ---------------------------------------
      // Get user balance
      // ---------------------------------------

      const {
        data: profile,
        error: profileError
      } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

      if (profileError) {
        throw profileError;
      }

      const currentBalance =
        parseFloat(profile.balance);

      if (currentBalance < charge) {
        return response(400, {
          error: 'Insufficient balance'
        });
      }

      // ---------------------------------------
      // FINAL service status check
      // ---------------------------------------
      // Protect against the service being
      // disabled between the first check
      // and provider request.

      const {
        data: finalService,
        error: finalServiceError
      } = await supabase
        .from('services')
        .select(
          'id, is_active, min_order, max_order, rate, selling_rate'
        )
        .eq('id', serviceId)
        .single();

      if (
        finalServiceError ||
        !finalService
      ) {
        return response(400, {
          error: 'Service is no longer available'
        });
      }

      if (finalService.is_active !== true) {
        return response(400, {
          error:
            'This service is currently unavailable. Please select another service.'
        });
      }

      // ---------------------------------------
      // Provider request
      // ---------------------------------------

      const params = new URLSearchParams({
        key: process.env.SMM_API_KEY,
        action: 'add',
        service: String(serviceId),
        link: link,
        quantity: String(quantity)
      });

      const providerResponse = await fetch(
        'https://easysmmpanel.com/api/v2',
        {
          method: 'POST',
          headers: {
            'Content-Type':
              'application/x-www-form-urlencoded'
          },
          body: params
        }
      );

      const rawText =
        await providerResponse.text();

      let providerData;

      try {
        providerData =
          JSON.parse(rawText);
      } catch (error) {
        return response(500, {
          error:
            'Invalid response from provider',
          raw: rawText
        });
      }

      // ---------------------------------------
      // Provider error
      // ---------------------------------------

      if (providerData.error) {
        return response(400, {
          error: providerData.error
        });
      }

      // ---------------------------------------
      // Provider order ID required
      // ---------------------------------------

      if (!providerData.order) {
        return response(500, {
          error:
            'Provider did not return an order ID'
        });
      }

      // ---------------------------------------
      // Save order
      // ---------------------------------------

      const {
        error: insertError
      } = await supabase
        .from('orders')
        .insert({
          user_id: userId,
          service_id: serviceId,
          link: link,
          quantity: quantity,
          charge: charge.toFixed(2),
          cost: cost.toFixed(2),
          status: 'Pending',
          provider_order_id:
            providerData.order
        });

      if (insertError) {
        throw insertError;
      }

      // ---------------------------------------
      // Update balance
      // ---------------------------------------

      const newBalance =
        (
          currentBalance - charge
        ).toFixed(2);

      const {
        error: balanceError
      } = await supabase
        .from('profiles')
        .update({
          balance: newBalance
        })
        .eq('id', userId);

      if (balanceError) {
        throw balanceError;
      }

      // ---------------------------------------
      // Transaction
      // ---------------------------------------

      const {
        error: transactionError
      } = await supabase
        .from('transactions')
        .insert({
          user_id: userId,
          amount: (-charge).toFixed(2),
          type: 'Order',
          status: 'Completed',
          payment_method: 'Balance'
        });

      if (transactionError) {
        throw transactionError;
      }

      // ---------------------------------------
      // Success
      // ---------------------------------------

      return response(200, {
        success: true,
        order: providerData.order,
        charge: charge.toFixed(2),
        new_balance: newBalance
      });
    }

    // =========================================
    // UNKNOWN ACTION
    // =========================================

    return response(400, {
      error:
        'Unknown action: ' + action
    });

  } catch (error) {

    console.error(
      'SMM Proxy Error:',
      error
    );

    return response(500, {
      error: error.message
    });
  }
};