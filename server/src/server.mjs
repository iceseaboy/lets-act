import http from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { parseScript } from './parser.mjs';

export function createApp({ apiKey, model, accessToken, parse = parseScript, now = Date.now }) {
  if (!apiKey || !model || !accessToken || accessToken.length < 32) throw new Error('Set OPENAI_API_KEY, OPENAI_MODEL and a PARSER_ACCESS_TOKEN of at least 32 characters.');
  let requests = [], inFlight = 0;
  const expected = Buffer.from(`Bearer ${accessToken}`);
  const server = http.createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    const send = (code, value) => { if (!res.destroyed) { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(value)); } };
    if (req.method === 'GET' && req.url === '/health') return send(200, { ok: true });
    if (req.method !== 'POST' || req.url !== '/v1/parse') return send(404, { error: 'Not found' });
    const supplied = Buffer.from(req.headers.authorization ?? '');
    if (supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) return send(401, { error: 'Unauthorized' });
    if (req.headers['content-type']?.split(';')[0].trim() !== 'application/json') return send(415, { error: 'JSON required' });
    requests = requests.filter(time => now() - time < 60_000);
    if (requests.length >= 10 || inFlight >= 2) return send(429, { error: 'Please try again shortly' });
    requests.push(now());
    inFlight++;
    try {
      let size = 0;
      const chunks = [];
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 150_000) { send(413, { error: 'Script is too large' }); req.resume(); return; }
        chunks.push(chunk);
      }
      let body;
      try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
      catch { return send(400, { error: 'Invalid JSON' }); }
      if (!body || typeof body !== 'object' || Array.isArray(body)
        || Object.keys(body).some(key => !['text', 'consent'].includes(key))
        || typeof body.text !== 'string' || !body.text.trim() || body.text.length > 30_000 || body.consent !== true) return send(400, { error: 'Provide script text (1–30,000 characters) and explicit consent' });
      const script = await parse(body.text, { apiKey, model });
      send(200, script);
    } catch {
      // No raw script, provider errors, credentials, or child data in logs/responses.
      send(502, { error: 'Script understanding is unavailable. Use local parsing or try again.' });
    } finally { inFlight--; }
  });
  server.requestTimeout = 100_000;
  server.headersTimeout = 15_000;
  server.timeout = 100_000;
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const server = createApp({ apiKey: process.env.OPENAI_API_KEY, model: process.env.OPENAI_MODEL, accessToken: process.env.PARSER_ACCESS_TOKEN });
  server.listen(Number(process.env.PORT ?? 8787), process.env.HOST ?? '127.0.0.1', () => console.log('Let’s Act script service ready'));
}
