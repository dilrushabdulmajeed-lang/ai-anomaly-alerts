// Validates Claude's reply and turns it into one item per alert.
  const r = $input.first().json;
  const checkDate = $('Config').first().json.check_date;

  if (r.stop_reason === 'refusal') {
    throw new Error(`Claude declined (${r.stop_details?.category}): ${r.stop_details?.explanation}`);
  }
  if (r.stop_reason === 'max_tokens') throw new Error('Claude response was truncated (max_tokens)');

  const textBlock = (r.content || []).find(b => b.type === 'text');
  if (!textBlock) throw new Error('No text block in Claude response');
  const out = JSON.parse(textBlock.text);

  return out.alerts.map(a => ({ json: {
    check_date: checkDate,
    ...a,
    summary: out.summary,
    model: r.model,
    input_tokens: r.usage.input_tokens,
    output_tokens: r.usage.output_tokens,
  }}));
