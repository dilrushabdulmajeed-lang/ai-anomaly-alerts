-- Metabase card: "AI anomaly alerts log" (cost uses Claude Opus 5.5 pricing: $4 / $20 per 1M input / output tokens)
SELECT
  check_date,
  campaign_name,
  severity,
  round(excess_spend_aed)                                     AS excess_spend_aed,
  likely_cause,
  arrayStringConcat(recommended_actions, ' | ')               AS actions,
  model,
  input_tokens + output_tokens                                AS tokens,
  round(input_tokens * 4 / 1e6 + output_tokens * 20 / 1e6, 3) AS cost_usd
FROM analytics.ads_anomaly_alerts FINAL
ORDER BY check_date DESC, excess_spend_aed DESC
