const fetch = require('node-fetch');
const { createClient } = require('@supabase/supabase-js');

exports.config = {
  schedule: '*/10 * * * *'
};

exports.handler = async () => {
  const startedAt = Date.now();

  try {
    // -----------------------------------------
    // 1. Check environment variables
    // -----------------------------------------

    const requiredEnv = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_KEY',
      'SMM_API_KEY'
    ];

    for (const key of requiredEnv) {
      if (!process.env[key]) {
        throw new Error(`Missing environment variable: ${key}`);
      }
    }

    // -----------------------------------------
    // 2. Supabase client
    // -----------------------------------------

    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );

    // -----------------------------------------
    // 3. Get current services from provider
    // -----------------------------------------

    const params = new URLSearchParams({
      key: process.env.SMM_API_KEY,
      action: 'services'
    });

    const response = await fetch(
      'https://easysmmpanel.com/api/v2',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: params
      }
    );

    if (!response.ok) {
      throw new Error(
        `Provider API returned HTTP ${response.status}`
      );
    }

    const rawText = await response.text();

    let services;

    try {
      services = JSON.parse(rawText);
    } catch (error) {
      throw new Error(
        `Invalid JSON response from provider: ${rawText.substring(0, 500)}`
      );
    }

    // -----------------------------------------
    // 4. Validate provider response
    // -----------------------------------------

    if (!Array.isArray(services)) {
      throw new Error(
        'Provider returned an invalid services response'
      );
    }

    // Safety protection:
    // Never disable all services because of
    // an unexpected empty provider response.
    if (services.length === 0) {
      throw new Error(
        'Provider returned zero services. Sync aborted to protect existing services.'
      );
    }

    // -----------------------------------------
    // 5. Get existing services BEFORE upsert
    // -----------------------------------------

    const {
      data: existingServices,
      error: existingError
    } = await supabase
      .from('services')
      .select('id, is_active');

    if (existingError) {
      throw existingError;
    }

    const previousState = new Map();

    for (const service of existingServices || []) {
      previousState.set(
        Number(service.id),
        service.is_active === true
      );
    }

    // -----------------------------------------
    // 6. Convert provider services
    // -----------------------------------------

    const rows = [];
    const providerServiceIds = new Set();

    for (const s of services) {
      const serviceId = parseInt(s.service, 10);
      const baseRate = parseFloat(s.rate);

      // Ignore invalid provider records
      if (
        !Number.isInteger(serviceId) ||
        !Number.isFinite(baseRate)
      ) {
        continue;
      }

      providerServiceIds.add(serviceId);

      // Your selling price
      const sellingRate = baseRate * 1.30;

      rows.push({
        id: serviceId,

        name: s.name || `Service ${serviceId}`,

        category: s.category || 'Other',

        rate: baseRate,

        selling_rate: parseFloat(
          sellingRate.toFixed(4)
        ),

        min_order: parseInt(s.min, 10) || 1,

        max_order: parseInt(s.max, 10) || 100000,

        // IMPORTANT:
        // Correct database column is "description"
        description: s.desc || null,

        avg_time: s.avg_time || null,

        service_type: s.type || 'Default',

        refill:
          s.refill === true ||
          s.refill === 'true' ||
          s.refill === 1 ||
          s.refill === '1',

        cancel:
          s.cancel === true ||
          s.cancel === 'true' ||
          s.cancel === 1 ||
          s.cancel === '1',

        // Provider currently has this service
        is_active: true,

        last_updated: new Date().toISOString()
      });
    }

    // -----------------------------------------
    // 7. Safety check
    // -----------------------------------------

    if (rows.length === 0) {
      throw new Error(
        'No valid services were received. Sync aborted.'
      );
    }

    // -----------------------------------------
    // 8. Detect reactivated services
    // -----------------------------------------

    let reactivatedCount = 0;

    for (const row of rows) {
      const oldState = previousState.get(row.id);

      if (oldState === false) {
        reactivatedCount++;
      }
    }

    // -----------------------------------------
    // 9. Upsert active provider services
    // -----------------------------------------

    const {
      error: upsertError
    } = await supabase
      .from('services')
      .upsert(rows, {
        onConflict: 'id'
      });

    if (upsertError) {
      throw upsertError;
    }

    // -----------------------------------------
    // 10. Find services removed by provider
    // -----------------------------------------

    const disabledServiceIds = [];

    for (const service of existingServices || []) {
      const serviceId = Number(service.id);

      if (!providerServiceIds.has(serviceId)) {
        disabledServiceIds.push(serviceId);
      }
    }

    // -----------------------------------------
    // 11. Disable provider-removed services
    // -----------------------------------------

    if (disabledServiceIds.length > 0) {
      const {
        error: disableError
      } = await supabase
        .from('services')
        .update({
          is_active: false,
          last_updated: new Date().toISOString()
        })
        .in('id', disabledServiceIds);

      if (disableError) {
        throw disableError;
      }
    }

    // -----------------------------------------
    // 12. Return sync result
    // -----------------------------------------

    const duration = Date.now() - startedAt;

    return {
      statusCode: 200,

      body: JSON.stringify({
        success: true,

        provider_services: services.length,

        synced_services: rows.length,

        disabled_services: disabledServiceIds.length,

        disabled_service_ids: disabledServiceIds,

        reactivated_services: reactivatedCount,

        duration_ms: duration
      })
    };

  } catch (error) {
    console.error(
      'Service sync failed:',
      error
    );

    return {
      statusCode: 500,

      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};