SET NOCOUNT ON;

WITH can_pause
AS (
	SELECT (
			SELECT @@version
			) version_number
		,(
			SELECT count(*)
			FROM sys.dm_pdw_exec_requests
			WHERE STATUS IN (
					'Running'
					,'Pending'
					,'CancelSubmitted'
					)
				AND session_id != SESSION_ID()
			) active_query_count
		,(
			SELECT count(*)
			FROM sys.dm_pdw_exec_sessions
			WHERE is_transactional = 1
			) AS session_transactional_count
		,(
			SELECT count(*)
			FROM sys.dm_pdw_waits
			WHERE type = 'Exclusive'
			) AS pdw_waits
	)
SELECT CASE 
		WHEN version_number LIKE 'Microsoft Azure SQL Data Warehouse%'
			AND active_query_count = 0
			AND session_transactional_count = 0
			AND pdw_waits = 0
			THEN 1
		ELSE 0
		END AS CanPause
FROM can_pause