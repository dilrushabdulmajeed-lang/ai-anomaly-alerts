-- Planned marketing events: the detector suppresses alerts on these days,
-- because budget and CPC increases during a planned sale are expected, not anomalies.
CREATE TABLE IF NOT EXISTS analytics.marketing_calendar
(
    event_name String,
    start_date Date,
    end_date   Date,
    note       String
)
ENGINE = ReplacingMergeTree
ORDER BY (start_date, event_name);

INSERT INTO analytics.marketing_calendar VALUES
    ('White Friday 2025', '2025-11-20', '2025-11-30', 'Planned budget uplift across all campaigns'),
    ('White Friday 2026', '2026-11-19', '2026-11-29', 'Planned budget uplift across all campaigns');
