// netlify/functions/smmProxy.js
const fetch = require('node-fetch');
const { createClient } = require('@supabase/supabase-js');

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: CORS_HEADERS, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers: CORS_HEADERS, body: 'Method Not Allowed' };
  }

  try {
    // 1. Verify user's JWT
    const authHeader = event.headers.authorization || event.headers.Authorization;
    if (!authHeader) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Missing authorization header' })
      };
    }

    const token = authHeader.replace('Bearer ', '');

    // 2. Create Supabase admin client
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );

    // 3. Verify the token and get the user
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Invalid token' })
      };
    }

    const userId = userData.user.id;

    // 4. Parse the request
    const { action, ...data } = JSON.parse(event.body);

    // ---- HANDLE: balance ----
    if (action === 'balance') {
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

      if (error) throw error;
      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({ balance: profile.balance })
      };
    }

    // ---- HANDLE: add order ----
    if (action === 'add') {
      const serviceId = parseInt(data.service);
      const link = data.link;
      const quantity = parseInt(data.quantity);

      // Get service details
      const { data: service, error: svcErr } = await supabase
        .from('services')
        .select('*')
        .eq('id', serviceId)
        .single();

      if (svcErr || !service) {
        return {
          statusCode: 400,
          headers: CORS_HEADERS,
          body: JSON.stringify({ error: 'Service not found' })
        };
      }

      if (quantity < service.min_order || quantity > service.max_order) {
        return {
          statusCode: 400,
          headers: CORS_HEADERS,
          body: JSON.stringify({
            error: `Quantity must be between ${service.min_order} and ${service.max_order}`
          })
        };
      }

      // Calculate cost and charge
      const cost = (service.rate / 1000) * quantity;
      const charge = (service.selling_rate / 1000) * quantity;

      // Check user's balance
      const { data: profile, error: profErr } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();

      if (profErr) throw profErr;

      if (parseFloat(profile.balance) < charge) {
        return {
          statusCode: 400,
          headers: CORS_HEADERS,
          body: JSON.stringify({ error: 'Insufficient balance' })
        };
      }

      // Place order with easysmmpanel
      const params = new URLSearchParams({
        key: process.env.SMM_API_KEY,
        action: 'add',
        service: serviceId,
        link: link,
        quantity: quantity
      });

      const providerRes = await fetch('https://easysmmpanel.com/api/v2', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
      });

      const providerData = await providerRes.json();

      if (providerData.error) {
        return {
          statusCode: 400,
          headers: CORS_HEADERS,
          body: JSON.stringify({ error: providerData.error })
        };
      }

      // Save order to database
      const { error: insertErr } = await supabase.from('orders').insert({
        user_id: userId,
        service_id: serviceId,
        link: link,
        quantity: quantity,
        charge: charge.toFixed(2),
        cost: cost.toFixed(2),
        status: 'Pending',
        provider_order_id: providerData.order
      });

      if (insertErr) throw insertErr;

      // Deduct balance
      const newBalance = (parseFloat(profile.balance) - charge).toFixed(2);
      await supabase
        .from('profiles')
        .update({ balance: newBalance })
        .eq('id', userId);

      // Log transaction
      await supabase.from('transactions').insert({
        user_id: userId,
        amount: -charge.toFixed(2),
        type: 'Order',
        status: 'Completed',
        payment_method: 'Balance'
      });

      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({
          success: true,
          order: providerData.order,
          charge: charge.toFixed(2),
          new_balance: newBalance
        })
      };
    }

    // ---- Unknown action ----
    return {
      statusCode: 400,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Unknown action: ' + action })
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: err.message })
    };
  }
};