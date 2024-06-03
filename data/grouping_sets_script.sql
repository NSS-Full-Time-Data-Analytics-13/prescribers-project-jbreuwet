-- 1.
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR	specialty_description = 'Pain Management'
GROUP BY specialty_description;

--2. 
SELECT SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management';