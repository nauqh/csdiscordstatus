-- Question answered by Month
SELECT
    strftime ('%Y-%m', created_at) AS month,
    COUNT(*) AS thread_count
FROM
    threads
GROUP BY
    strftime ('%Y-%m', created_at)
ORDER BY
    month;

-- Participation
SELECT
    r.name,
    COUNT(u.name)
FROM
    roles r
    JOIN user_role ur ON r.id = ur.role_id
    JOIN users u ON ur.user_id = u.id
WHERE
    r.name IN ('Learner', 'TA')
GROUP BY
    r.name;

-- Thread and message count by TA
SELECT
    u.name,
    COUNT(DISTINCT t.id) thread_count,
    COUNT(m.id) AS message_count
FROM
    messages m
    JOIN threads t ON m.thread_id = t.id
    JOIN user_role ur ON m.user_id = ur.user_id
    JOIN roles r ON ur.role_id = r.id
    JOIN users u ON m.user_id = u.id
WHERE
    r.name = 'TA'
GROUP BY
    u.name
ORDER BY
    thread_count DESC;

-- Response time per Thread
WITH
    ResponseMessage AS (
        SELECT
            id AS message_id,
            thread_id,
            created_at AS response_time
        FROM
            messages
    )
SELECT
    t.name AS thread_name,
    t.created_at AS thread_created_at,
    (
        strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
    ) / 60.0 AS response_time_mins
FROM
    threads t
    JOIN ResponseMessage rm ON t.response_msg_id = rm.message_id
WHERE
    (
        strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
    ) / 60.0 < 120
    OR (
        strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
    ) / 60.0 > 480
ORDER BY
    t.id;

-- Avg Response time by month
WITH
    ResponseMessage AS (
        SELECT
            id AS message_id,
            thread_id,
            created_at AS response_time
        FROM
            messages
    ),
    ResponseTimes AS (
        SELECT
            t.name AS thread_name,
            t.created_at AS thread_created_at,
            (
                strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
            ) / 60.0 AS response_time_mins,
            strftime ('%Y-%m', t.created_at) AS month
        FROM
            threads t
            JOIN ResponseMessage rm ON t.response_msg_id = rm.message_id
        WHERE
            (
                strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
            ) / 60.0 < 120
    )
SELECT
    month,
    AVG(response_time_mins) AS avg_response_time_mins
FROM
    ResponseTimes
GROUP BY
    month
ORDER BY
    month;

-- Avg Response time by month by guild
WITH
    ResponseMessage AS (
        SELECT
            id AS message_id,
            thread_id,
            created_at AS response_time
        FROM
            messages
    ),
    ResponseTimes AS (
        SELECT
            g.name AS guild_name,
            t.name AS thread_name,
            t.created_at AS thread_created_at,
            t.id AS thread_id,
            (
                strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
            ) / 60.0 AS response_time_mins,
            strftime ('%Y-%m', t.created_at) AS month
        FROM
            threads t
            JOIN ResponseMessage rm ON t.response_msg_id = rm.message_id
            JOIN guilds g ON t.guild_id = g.id
        WHERE
            (
                strftime ('%s', rm.response_time) - strftime ('%s', t.created_at)
            ) / 60.0 < 120
    )
SELECT
    guild_name,
    month,
    AVG(response_time_mins) AS avg_response_time_mins,
    COUNT(*) as threads,
    (
        SELECT
            COUNT(*)
        FROM
            messages m
        WHERE
            m.thread_id IN (
                SELECT
                    thread_id
                FROM
                    ResponseTimes rt2
                WHERE
                    rt2.guild_name = ResponseTimes.guild_name
                    AND rt2.month = ResponseTimes.month
            )
    ) as messages
FROM
    ResponseTimes
GROUP BY
    guild_name,
    month
ORDER BY
    guild_name,
    month;

-- Thread Resolution Time Analysis
SELECT
    t.name as thread_name,
    t.created_at as started_at,
    MAX(m.created_at) as last_message,
    (
        strftime ('%s', MAX(m.created_at)) - strftime ('%s', t.created_at)
    ) / 3600.0 as resolution_hours
FROM
    threads t
    JOIN messages m ON t.id = m.thread_id
GROUP BY
    t.id
ORDER BY
    resolution_hours DESC;

-- Activity by Hour of Day
SELECT
    strftime ('%H', m.created_at) as hour,
    COUNT(*) as message_count
FROM
    messages m
GROUP BY
    hour
ORDER BY
    hour;

-- Thread Complexity Analysis
SELECT
    t.name,
    COUNT(m.id) as message_count,
    COUNT(DISTINCT m.user_id) as participant_count,
    COUNT(m.id) * 1.0 / COUNT(DISTINCT m.user_id) as messages_per_participant
FROM
    threads t
    JOIN messages m ON t.id = m.thread_id
GROUP BY
    t.id
HAVING
    message_count > 5
ORDER BY
    messages_per_participant DESC;

-- User Engagement Patterns
SELECT
    u.name,
    COUNT(DISTINCT DATE (m.created_at)) as days_active,
    COUNT(m.id) as total_messages,
    COUNT(m.id) * 1.0 / COUNT(DISTINCT DATE (m.created_at)) as msgs_per_active_day,
    AVG(LENGTH (m.content)) as avg_message_length
FROM
    users u
    JOIN messages m ON u.id = m.user_id
GROUP BY
    u.id
HAVING
    total_messages > 10
ORDER BY
    msgs_per_active_day DESC;

-- Thread Categories by Response Pattern
SELECT
    t.name,
    CASE
        WHEN COUNT(m.id) <= 3 THEN 'Quick Resolution'
        WHEN COUNT(m.id) > 10 THEN 'Complex Discussion'
        ELSE 'Normal Thread'
    END as thread_type,
    COUNT(m.id) as message_count,
    COUNT(DISTINCT m.user_id) as participant_count
FROM
    threads t
    JOIN messages m ON t.id = m.thread_id
GROUP BY
    t.id
ORDER BY
    message_count DESC;