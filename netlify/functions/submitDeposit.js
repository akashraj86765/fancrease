const { createClient } = require('@supabase/supabase-js');

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json'
};

const MIN_DEPOSIT = 50;
const MAX_DEPOSIT = 2000;

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: CORS_HEADERS, body: '' };
  }
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers: CORS_HEADERS, body: 'Method Not Allowed' };
  }

  try {
    const authHeader = event.headers.authorization || event.headers.Authorization;
    if (!authHeader) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Missing authorization header' })
      };
    }

    const token = authHeader.replace('Bearer ', '');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );

    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Invalid token' })
      };
    }

    const userId = userData.user.id;
    const { amount, utr_number, proof_url } = JSON.parse(event.body);

    // Validate amount
    const amt = parseFloat(amount);
    if (!amt || amt < MIN_DEPOSIT) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: `Minimum deposit is ₹${MIN_DEPOSIT}` })
      };
    }
    if (amt > MAX_DEPOSIT) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: `Maximum deposit is ₹${MAX_DEPOSIT}` })
      };
    }

    // Validate UTR (must be 12 digits usually; accept 6-20 chars)
    const utr = (utr_number || '').toString().trim();
    if (utr.length < 6 || utr.length > 30) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Invalid UTR / Transaction ID' })
      };
    }

    // Prevent duplicate UTR submission
    const { data: existing } = await supabase
      .from('transactions')
      .select('id')
      .eq('utr_number', utr)
      .limit(1);

    if (existing && existing.length > 0) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'This UTR has already been submitted' })
      };
    }

    // Insert deposit request
    const { data: inserted, error: insertErr } = await supabase
      .from('transactions')
      .insert({
        user_id: userId,
        amount: amt.toFixed(2),
        type: 'Deposit',
        status: 'Pending',
        payment_method: 'UPI',
        utr_number: utr,
        proof_url: proof_url || null
      })
      .select()
      .single();

    if (insertErr) throw insertErr;

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({
        success: true,
        transaction_id: inserted.id,
        status: 'Pending'
      })
    };
  } catch (err) {
    console.error('Submit deposit error:', err);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: err.message })
    };
  }
};