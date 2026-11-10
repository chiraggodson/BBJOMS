function yarnId(yarn) {
  return String(yarn?.yarn_id ?? yarn?.yarnId ?? '');
}

function yarnQuantity(yarn) {
  return Number(yarn?.required_kg ?? yarn?.requiredKg ?? yarn?.quantity);
}

function yarnPercent(yarn) {
  const value = yarn?.requirement_percent ?? yarn?.requirementPercent;
  return value === '' || value == null ? NaN : Number(value);
}

function validateYarnMix(yarns) {
  if (!Array.isArray(yarns)) return 'Yarn requirements must be a list.';
  if (!yarns.length) return null;
  const seen = new Set();
  let totalPercent = 0;
  for (const yarn of yarns) {
    const id = yarnId(yarn);
    const quantity = yarnQuantity(yarn);
    const percent = yarnPercent(yarn);
    if (!id || !Number.isFinite(quantity) || quantity <= 0) {
      return 'Each yarn requirement needs a yarn and a positive required quantity.';
    }
    if (seen.has(id)) return 'A yarn can only appear once in the job yarn mix.';
    if (!Number.isFinite(percent) || percent <= 0 || percent > 100) {
      return 'Each yarn percentage must be greater than 0 and no more than 100.';
    }
    seen.add(id);
    totalPercent += percent;
  }
  if (Math.abs(totalPercent - 100) > 0.01) {
    return `Yarn percentages must total 100%. Current total: ${totalPercent.toFixed(2)}%.`;
  }
  return null;
}

function sameYarnMix(existing, incoming, orderQuantity) {
  if (existing.length !== incoming.length) return false;
  const requested = new Map(incoming.map(yarn => [yarnId(yarn), yarn]));
  for (const row of existing) {
    const item = requested.get(String(row.yarn_id));
    if (!item) return false;
    const oldQuantity = Number(row.required_kg);
    const newQuantity = yarnQuantity(item);
    const oldPercent = row.requirement_percent == null
      ? (Number(orderQuantity) > 0 ? oldQuantity / Number(orderQuantity) * 100 : 0)
      : Number(row.requirement_percent);
    const newPercent = yarnPercent(item);
    if (Math.abs(oldQuantity - newQuantity) > 0.001 || Math.abs(oldPercent - newPercent) > 0.01) {
      return false;
    }
  }
  return true;
}

module.exports = { validateYarnMix, sameYarnMix };