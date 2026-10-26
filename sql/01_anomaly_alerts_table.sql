-- Project 3: log of AI-explained anomaly alerts (one row per flagged campaign per check date)
CREATE TABLE IF NOT EXISTS analytics.ads_anomaly_alerts
(
    check_date          Date,
    campaign_name       String,
    severity            LowCardinality(String),   -- low / medium / high
    likely_cause        String,
    evidence            String,
    excess_spend_aed    Float64,
    recommended_actions Array(String),
    summary             String,
    model               LowCardinality(String),
    input_tokens        UInt32,
    output_tokens       UInt32,
    created_at          DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(created_at)
ORDER BY (check_date, campaign_name);
