export async function onRequestGet(context) {
  const ip = context.request.headers.get('CF-Connecting-IP') || 
             context.request.headers.get('X-Forwarded-For') ||
             'Unknown';
  
  return new Response(JSON.stringify({ ip }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}