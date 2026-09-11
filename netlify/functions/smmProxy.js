// netlify/functions/smmProxy.js
const fetch = require('node-fetch');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  const { action, ...data } = JSON.parse(event.body);

  const params = new URLSearchParams({
    key: process.env.SMM_API_KEY,
    action: action,
    ...data
  });

  try {
    const response = await fetch('https://easysmmpanel.com/api/v2', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params
    });

    const result = await response.json();
    return {
      statusCode: 200,
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to connect to the SMM provider.' })
    };
  }
};