const test = require('node:test');
const assert = require('node:assert/strict');
const { validateYarnMix, sameYarnMix } = require('../src/domain/job_validation');

const validMix = [
  { yarn_id: 'cotton', required_kg: 600, requirement_percent: 60 },
  { yarn_id: 'poly', required_kg: 400, requirement_percent: 40 },
];

test('accepts a complete 100 percent yarn mix', () => {
  assert.equal(validateYarnMix(validMix), null);
});

test('rejects missing yarn percentages', () => {
  assert.match(validateYarnMix([{ yarn_id: 'cotton', required_kg: 100 }]), /percentage/);
});

test('rejects a yarn mix that does not total 100 percent', () => {
  assert.match(validateYarnMix([{ yarn_id: 'cotton', required_kg: 100, requirement_percent: 75 }]), /total 100/);
});

test('rejects duplicate yarn rows', () => {
  assert.match(validateYarnMix([
    { yarn_id: 'cotton', required_kg: 50, requirement_percent: 50 },
    { yarn_id: 'cotton', required_kg: 50, requirement_percent: 50 },
  ]), /once/);
});

test('rejects zero or invalid required quantities', () => {
  assert.match(validateYarnMix([{ yarn_id: 'cotton', required_kg: 0, requirement_percent: 100 }]), /positive/);
});

test('recognizes an unchanged yarn mix when legacy percentages are absent', () => {
  const legacy = [
    { yarn_id: 'cotton', required_kg: 600, requirement_percent: null },
    { yarn_id: 'poly', required_kg: 400, requirement_percent: null },
  ];
  assert.equal(sameYarnMix(legacy, validMix, 1000), true);
});

test('detects changes to a yarn mix', () => {
  assert.equal(sameYarnMix(validMix, [
    { yarn_id: 'cotton', required_kg: 500, requirement_percent: 50 },
    { yarn_id: 'poly', required_kg: 500, requirement_percent: 50 },
  ], 1000), false);
});