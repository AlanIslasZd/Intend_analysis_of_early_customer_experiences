WITH Table_1 AS (
    SELECT
        crm_account_id,
        MAX(crm_win_dt) AS crm_win_dt,
        AVG(crm_total_arr) AS crm_total_arr,
        CASE
            WHEN AVG(crm_total_arr) < 1000 THEN 'Sub $1K'
            WHEN AVG(crm_total_arr) BETWEEN 1000 AND 5000 THEN '$1K-$5K'
            WHEN AVG(crm_total_arr) BETWEEN 5001 AND 10000 THEN '$5K-$10K'
            WHEN AVG(crm_total_arr) BETWEEN 10001 AND 20000 THEN '$10K-$20K'
            WHEN AVG(crm_total_arr) BETWEEN 20001 AND 50000 THEN '$20K-$50K'
            WHEN AVG(crm_total_arr) BETWEEN 50001 AND 100000 THEN '$50K-$100K'
            WHEN AVG(crm_total_arr) BETWEEN 100001 AND 250000 THEN '$100K-$250K'
            WHEN AVG(crm_total_arr) >= 250001 THEN '$250K+'
            ELSE 'Not Found'
        END AS crm_total_arr_category
    FROM `edw-prod-153420.adv_data_domain__prototype.customers`
    WHERE run_at = '2024-03-31'
      AND crm_win_dt < '2024-04-01'
      AND is_employee_owned = 0
      AND is_zendesk_internal = 0
      AND is_abusive = 0
      AND is_fraud = 0
      AND is_junk_trial = 0
      AND (crm_churn_dt IS NULL OR crm_churn_dt > '2024-03-31')
    GROUP BY crm_account_id
)

, Ticket_Differences AS (
    SELECT
        a.crm_account_id,
        a.crm_win_dt,
        a.crm_total_arr,
        a.crm_total_arr_category,
        b.ticket_id,
        DATE_DIFF(b.created_at_date, a.crm_win_dt, DAY) AS days_since_win
    FROM Table_1 a
    LEFT JOIN `edw-prod-153420.adv_data_domain__prototype.tickets` b
    ON a.crm_account_id = b.crm_account_id
    WHERE b.adv_ticket_filter_performance = 1
      AND b.created_at_date BETWEEN '2024-01-01' AND '2024-03-31'
      AND DATE_DIFF(b.created_at_date, a.crm_win_dt, DAY) < 90 -- Ensuring tickets are within 90 days
)

SELECT
    crm_account_id,
    crm_win_dt,
    crm_total_arr,
    crm_total_arr_category,
    COUNT(ticket_id) AS total_tickets
FROM Ticket_Differences
GROUP BY
    crm_account_id,
    crm_win_dt,
    crm_total_arr,
    crm_total_arr_category
ORDER BY
    crm_account_id;
