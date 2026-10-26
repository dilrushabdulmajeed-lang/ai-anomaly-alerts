// Builds the Anthropic Messages API request: flagged campaigns in, structured diagnosis out.
  const flagged = $('Detect anomalies').first().json.data;
  const checkDate = $('Config').first().json.check_date;

  const system = `You are a senior paid-search analyst for a GCC e-commerce advertiser (currency AED).
  A rules engine has flagged campaigns whose spend, CPC or CPA rose more than 40% above their trailing 7-day average.
  For each flagged campaign: explain the most likely cause using only the data provided, cite the numbers that support it,
  estimate excess spend versus baseline (spend minus spend_base, minimum 0), rate severity, and give 1-3 concrete actions
  a PPC manager could take today.
  The breakdown field lists CPC by ad group/device versus baseline: a rise across every segment points to auction-level
  pressure (competitor bidding, bid strategy change); a rise in one segment points to a localized issue.
  If the data cannot distinguish between causes, say what additional data would.
  Keep the summary to 2-3 sentences suitable for a team chat message.`;

  const schema = {
    type: 'object',
    additionalProperties: false,
    required: ['summary', 'alerts'],
    properties: {
      summary: { type: 'string' },
      alerts: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['campaign_name', 'severity', 'likely_cause', 'evidence', 'excess_spend_aed', 'recommended_actions'],
          properties: {
            campaign_name: { type: 'string' },
            severity: { type: 'string', enum: ['low', 'medium', 'high'] },
            likely_cause: { type: 'string' },
            evidence: { type: 'string' },
            excess_spend_aed: { type: 'number' },
            recommended_actions: { type: 'array', items: { type: 'string' } },
          },
        },
      },
    },
  };

  const body = {
    model: 'claude-opus-5-5',
    max_tokens: 16000,
    fallbacks: 'default',   // if Claude declines, the API retries on another model automatically
    output_config: { effort: 'medium', format: { type: 'json_schema', schema } },
    system,
    messages: [{
      role: 'user',
      content: `Check date: ${checkDate}\nFlagged campaigns:\n${JSON.stringify(flagged, null, 2)}`,
    }],
  };

  return [{ json: { body } }];
