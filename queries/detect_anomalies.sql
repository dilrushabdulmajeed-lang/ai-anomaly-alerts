-- Flags campaigns whose check-day spend, CPC or CPA rose >40% above their trailing 7-day baseline.
-- Includes ad-group and device breakdowns so the LLM can reason about where the change happened.
-- Standalone: clickhouse-client --param_check_date=2026-10-09 < queries/detect_anomalies.sql
-- In n8n the date is injected as toDate('{{ $json.check_date }}').
WITH
  toDate({check_date:String}) AS d,
  base AS (
    SELECT
      campaign_id, ad_group, device,
      sumIf(cost, date = d)                                   AS cost_d,
      sumIf(clicks, date = d)                                 AS clicks_d,
      sumIf(impressions, date = d)                            AS impr_d,
      sumIf(conversions, date = d)                            AS conv_d,
      sumIf(cost, date BETWEEN d - 7 AND d - 1) / 7           AS cost_b,
      sumIf(clicks, date BETWEEN d - 7 AND d - 1) / 7         AS clicks_b,
      sumIf(impressions, date BETWEEN d - 7 AND d - 1) / 7    AS impr_b,
      sumIf(conversions, date BETWEEN d - 7 AND d - 1) / 7    AS conv_b
    FROM analytics.ads_daily FINAL
    WHERE date BETWEEN d - 7 AND d
    GROUP BY campaign_id, ad_group, device
  ),
  camp AS (
    SELECT
      campaign_id,
      sum(cost_d) AS spend, sum(cost_b) AS spend_base,
      sum(cost_d) / nullIf(sum(clicks_d), 0) AS cpc, sum(cost_b) / nullIf(sum(clicks_b), 0) AS cpc_base,
      sum(clicks_d) / nullIf(sum(impr_d), 0) AS ctr, sum(clicks_b) / nullIf(sum(impr_b), 0) AS ctr_base,
      sum(conv_d) AS conv, sum(conv_b) AS conv_base,
      sum(cost_d) / nullIf(sum(conv_d), 0) AS cpa, sum(cost_b) / nullIf(sum(conv_b), 0) AS cpa_base,
      arrayStringConcat(groupArray(concat(ad_group, '/', device, ': CPC ',
        toString(round(cost_d / nullIf(clicks_d, 0), 2)), ' vs ', toString(round(cost_b / nullIf(clicks_b, 0), 2)))), '; ') AS breakdown
    FROM base
    GROUP BY campaign_id
  )
SELECT
  toString(d)                         AS check_date,
  c.campaign_name, c.campaign_type, c.objective, c.market,
  round(spend, 0) AS spend, round(spend_base, 0) AS spend_base, round((spend / spend_base - 1) * 100) AS spend_chg_pct,
  round(cpc, 2) AS cpc, round(cpc_base, 2) AS cpc_base, round((cpc / cpc_base - 1) * 100) AS cpc_chg_pct,
  round(ctr * 100, 2) AS ctr_pct, round(ctr_base * 100, 2) AS ctr_base_pct,
  round(conv, 1) AS conv, round(conv_base, 1) AS conv_base,
  round(cpa, 1) AS cpa, round(cpa_base, 1) AS cpa_base, round((cpa / cpa_base - 1) * 100) AS cpa_chg_pct,
  breakdown
FROM camp
INNER JOIN analytics.campaigns AS c FINAL USING (campaign_id)
WHERE spend_base > 20
  AND (spend / spend_base - 1 > 0.4 OR cpc / cpc_base - 1 > 0.4 OR cpa / cpa_base - 1 > 0.4)
  AND (SELECT count() FROM analytics.marketing_calendar FINAL WHERE d BETWEEN start_date AND end_date) = 0   -- skip planned events
ORDER BY greatest(toFloat64(spend_chg_pct), toFloat64(cpc_chg_pct), toFloat64(ifNull(cpa_chg_pct, 0))) DESC
SETTINGS output_format_json_quote_64bit_integers = 0
