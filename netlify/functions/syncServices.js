// netlify/functions/syncServices.js
const fetch = require('node-fetch');
const { createClient } = require('@supabase/supabase-js');

exports.handler = async (event) => {
  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );

    // 1. Fetch services from easysmmpanel
    const params = new URLSearchParams({
      key: process.env.SMM_API_KEY,
      action: 'services'
    });

    const response = await fetch('https://easysmmpanel.com/api/v2', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params
    });

    const services = await response.json();

    if (!Array.isArray(services)) {
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Invalid response from provider', raw: services })
      };
    }

    // 2. Transform and add a 30% profit margin
    const PROFIT_MULTIPLIER = 1.30; // 30% markup

    const rows = services.map((s) => ({
      id: parseInt(s.service),
      name: s.name,
      category: s.category || 'Other',
      rate: parseFloat(s.rate),
      selling_rate: parseFloat((parseFloat(s.rate) * PROFIT_MULTIPLIER).toFixed(4)),
      min_order: parseInt(s.min) || 1,
      max_order: parseInt(s.max) || 100000,
      last_updated: new Date().toISOString()
    }));

    // 3. Upsert into Supabase
    const { error } = await supabase
      .from('services')
      .upsert(rows, { onConflict: 'id' });

    if (error) throw error;

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, count: rows.length })
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  }
};