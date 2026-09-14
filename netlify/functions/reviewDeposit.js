const { createClient } = require('@supabase/supabase-js');

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json'
};

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

    // Verify admin
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return {
        statusCode: 401,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Invalid token' })
      };
    }

    const adminId = userData.user.id;

    const { data: adminProfile } = await supabase
      .from('profiles')
      .select('is_admin')
      .eq('id', adminId)
      .single();

    if (!adminProfile?.is_admin) {
      return {
        statusCode: 403,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Admin access required' })
      };
    }

    const { transaction_id, action, admin_note } = JSON.parse(event.body);

    if (!transaction_id || !['approve', 'reject'].includes(action)) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Invalid request' })
      };
    }

    // Get the transaction
    const { data: txn, error: txnErr } = await supabase
      .from('transactions')
      .select('*')
      .eq('id', transaction_id)
      .single();

    if (txnErr || !txn) {
      return {
        statusCode: 404,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: 'Transaction not found' })
      };
    }

    if (txn.status !== 'Pending') {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: `Transaction already ${txn.status}` })
      };
    }

    if (action === 'approve') {
      // Credit user's balance
      const { data: profile } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', txn.user_id)
        .single();

      const newBalance = (parseFloat(profile.balance) + parseFloat(txn.amount)).toFixed(2);

      await supabase
        .from('profiles')
        .update({ balance: newBalance })
        .eq('id', txn.user_id);

      await supabase
        .from('transactions')
        .update({
          status: 'Completed',
          admin_note: admin_note || null,
          reviewed_by: adminId,
          reviewed_at: new Date().toISOString()
        })
        .eq('id', transaction_id);

      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({
          success: true,
          new_balance: newBalance,
          message: `Credited ₹${txn.amount}`
        })
      };
    } else {
      // Reject
      await supabase
        .from('transactions')
        .update({
          status: 'Rejected',
          admin_note: admin_note || null,
          reviewed_by: adminId,
          reviewed_at: new Date().toISOString()
        })
        .eq('id', transaction_id);

      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: JSON.stringify({ success: true, message: 'Deposit rejected' })
      };
    }
  } catch (err) {
    console.error('Review deposit error:', err);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: err.message })
    };
  }
};