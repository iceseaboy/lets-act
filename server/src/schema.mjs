const string = { type: 'string' };
const object = properties => ({ type: 'object', properties, required: Object.keys(properties), additionalProperties: false });
const list = items => ({ type: 'array', items });
export const scriptSchema = object({
  scenes: list(object({ id: string, title: string })),
  characters: list(object({ id: string, name: string })),
  units: list(object({
    id: string,
    type: { type: 'string', enum: ['scene_heading', 'dialogue', 'stage_direction', 'song', 'lyrics'] },
    sceneId: string,
    characterId: { type: ['string', 'null'] },
    text: string,
    order: { type: 'integer' }
  })),
  aliases: list(object({ sourceId: string, targetId: string, reason: string }))
});

function validateShape(value, schema) {
  if (Array.isArray(schema.type)) return schema.type.some(type => validateShape(value, { ...schema, type }));
  if (schema.type === 'null') return value === null;
  if (schema.type === 'string') return typeof value === 'string' && value.trim().length > 0 && value.length <= 30_000 && (!schema.enum || schema.enum.includes(value));
  if (schema.type === 'integer') return Number.isSafeInteger(value) && value >= 0;
  if (schema.type === 'array') return Array.isArray(value) && value.length <= 3000 && value.every(item => validateShape(item, schema.items));
  if (schema.type === 'object') return value !== null && typeof value === 'object' && !Array.isArray(value)
    && Object.keys(value).length === schema.required.length
    && schema.required.every(key => Object.hasOwn(value, key) && validateShape(value[key], schema.properties[key]));
  return false;
}
export function validateScript(script) {
  if (!validateShape(script, scriptSchema)) throw new Error('Invalid script shape');
  const unique = values => new Set(values).size === values.length;
  for (const collection of [script.scenes, script.characters, script.units]) {
    if (!unique(collection.map(item => item.id))) throw new Error('Duplicate IDs');
  }
  if (!script.scenes.length || !script.characters.length || !script.units.some(u => ['dialogue', 'lyrics'].includes(u.type))) throw new Error('Empty script');
  if (!unique(script.units.map(u => u.order))) throw new Error('Duplicate order');
  const scenes = new Set(script.scenes.map(s => s.id));
  const cast = new Set(script.characters.map(c => c.id));
  for (const unit of script.units) {
    if (!scenes.has(unit.sceneId) || (unit.characterId !== null && !cast.has(unit.characterId))
      || (['dialogue', 'lyrics'].includes(unit.type) && !cast.has(unit.characterId))) throw new Error('Invalid reference');
  }
  for (const alias of script.aliases) {
    if (!cast.has(alias.sourceId) || !cast.has(alias.targetId) || alias.sourceId === alias.targetId) throw new Error('Invalid alias');
  }
  return script;
}
