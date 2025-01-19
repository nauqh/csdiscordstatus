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