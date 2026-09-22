import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/server.mjs';
import { parseScript } from '../src/parser.mjs';
import { validateScript } from '../src/schema.mjs';

const token = 'test-token-with-at-least-32-characters';
const fixture = () => ({ scenes: [{ id: 's1', title: 'Garden' }], characters: [{ id: 'c1', name: 'Luna' }], units: [{ id: 'u1', type: 'dialogue', sceneId: 's1', characterId: 'c1', text: 'Hello!', order: 0 }], aliases: [] });

test('schema rejects unknown fields, dangling references and false aliases', () => {
  assert.deepEqual(validateScript(fixture()), fixture());
  for (const mutate of [s => s.extra = true, s => s.units[0].characterId = 'unknown', s => s.units[0].type = 'chat', s => s.units.push(s.units[0]), s => s.aliases.push({ sourceId: 'c1', targetId: 'c1', reason: 'same' })]) {
    const script = fixture(); mutate(script); assert.throws(() => validateScript(script));
  }
});

test('provider request uses strict outputs, no storage and retries malformed structure once', async () => {
  let calls = 0;
  const result = await parseScript('LUNA: Hello!', { apiKey: 'test', model: 'configured-model', fetchImpl: async (url, options) => {
    calls++;
    assert.equal(url, 'https://api.openai.com/v1/responses');
    const body = JSON.parse(options.body);
    assert.equal(body.store, false);
    assert.equal(body.text.format.strict, true);
    assert.equal(body.model, 'configured-model');
    return { ok: true, json: async () => ({ status: 'completed', output: [{ content: [{ type: 'output_text', text: calls === 1 ? '{}' : JSON.stringify(fixture()) }] }] }) };
  } });
  assert.equal(calls, 2); assert.deepEqual(result, fixture());
});

test('provider refusal and incomplete response are never treated as a script', async () => {
  for (const result of [{ status: 'incomplete' }, { status: 'completed', output: [{ content: [{ type: 'refusal' }] }] }]) {
    await assert.rejects(parseScript('text', { apiKey: 'test', model: 'test', fetchImpl: async () => ({ ok: true, json: async () => result }) }));
  }
});

test('HTTP service enforces auth, consent, size, input shape and routes', async t => {
  let calls = 0;
  const server = createApp({ apiKey: 'test', model: 'test', accessToken: token, parse: async () => { calls++; return fixture(); } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => { server.closeAllConnections(); server.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (body, auth = token, path = '/v1/parse') => fetch(base + path, { method: 'POST', headers: { Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  assert.equal((await post({ text: 'hello', consent: true }, 'wrong')).status, 401);
  assert.equal((await post({ text: 'hello' })).status, 400);
  assert.equal((await post({ text: 'hello', consent: true, audio: 'no' })).status, 400);
  assert.equal((await post({ text: 'x'.repeat(30001), consent: true })).status, 400);
  assert.equal((await post({ text: 'hello', consent: true }, token, '/audio')).status, 404);
  const response = await post({ text: 'LUNA: Hello!', consent: true });
  assert.equal(response.status, 200); assert.deepEqual(await response.json(), fixture()); assert.equal(calls, 1);
  assert.equal(response.headers.get('cache-control'), 'no-store');
});

test('service has a finite global pilot quota', async t => {
  const server = createApp({ apiKey: 'test', model: 'test', accessToken: token, parse: async () => fixture(), now: () => 1000 });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => { server.closeAllConnections(); server.close(); });
  for (let i = 0; i < 11; i++) {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/v1/parse`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ text: 'Hello', consent: true }) });
    assert.equal(response.status, i < 10 ? 200 : 429);
    await response.text();
  }
});

test('service refuses incomplete secrets configuration', () => { assert.throws(() => createApp({ apiKey: '', model: '', accessToken: '' })); });
