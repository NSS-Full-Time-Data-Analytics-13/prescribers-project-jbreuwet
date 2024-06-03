-- 1. a.
SELECT DISTINCT npi
	, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;
-- npi 1881634483 had the highest number of claims with 99707

-- 1. b. 
SELECT nppes_provider_first_name
	, nppes_provider_last_org_name
	, specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
GROUP BY prescriber.nppes_provider_first_name
		, prescriber.nppes_provider_last_org_name
		, prescriber.specialty_description
ORDER BY total_claims DESC
LIMIT 1;
-- Bruce Pendley, Family Practice with 99707 total claims

-- 2. a. 
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;
-- Family Practice has the highest total claims with 9752347

-- 2. b. 
SELECT specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;
-- Nurse Practitioner had the most claims for opioids at 900845

-- 2. c. 
SELECT specialty_description
	, COUNT(drug_name) AS total_prescriptions
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
GROUP BY specialty_description
ORDER BY total_prescriptions ASC;
-- Yes, there are 14 specialties that have no associated prescriptions

-- 2. d. 
SELECT specialty_description
	, COALESCE(ROUND(SUM(opioid_claims) / SUM(total_claims)*100, 2), '0') AS percent_opioid
FROM prescriber
	LEFT JOIN (SELECT npi
					, SUM(total_claim_count) AS opioid_claims
				FROM prescription
					INNER JOIN drug
					USING(drug_name)
				WHERE opioid_drug_flag = 'Y'
				GROUP BY npi) AS opioids
	ON prescriber.npi = opioids.npi
-- subquery finding opioid claims
	LEFT JOIN (SELECT npi
					, SUM(total_claim_count) AS total_claims
				FROM prescription
					INNER JOIN prescriber
					USING(npi)
				GROUP BY npi) AS total
	ON prescriber.npi = total.npi
-- subquery finding total claims
GROUP BY specialty_description
ORDER BY percent_opioid DESC;
-- Not working yet

-- 3. a. 
SELECT generic_name
	, SUM(total_drug_cost) AS drug_cost
FROM drug
	LEFT JOIN prescription
	USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY drug_cost DESC;
-- Insulin had the highest total drug cost with $104,264,066.35

-- 3. b. 
SELECT generic_name
	, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_day
FROM drug
	LEFT JOIN prescription
	USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY cost_per_day DESC;
-- C1 Esterase Inhibitor has the highest cost per day at $3495.22

-- 4. a. 
SELECT drug_name
	, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug
GROUP BY drug_name
	, drug_type;

-- 4. b. 
SELECT CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
	, (SUM(total_drug_cost)::money) AS total_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;
-- More money was spent on opioids than antibiotics

-- 5. a. 
SELECT COUNT(cbsa)
FROM cbsa
	INNER JOIN fips_county
	USING(fipscounty)
WHERE state = 'TN';
-- 42 CBSAs in TN

-- 5. b. 
SELECT cbsaname
	, SUM(population) AS total_pop
FROM cbsa
	INNER JOIN population
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;
-- Nashville-Davidson-Murfreesboro-Franklin, TN has the highest combined population with 1,830,410, Morristown, TN has the lowest with 116,352

-- 5. c. 
SELECT county
	, SUM(population) AS total_pop
FROM population
	INNER JOIN fips_county
	USING(fipscounty)
WHERE population.fipscounty NOT IN (SELECT fipscounty
						FROM cbsa)
GROUP BY county
ORDER BY total_pop DESC;
-- Sevier county is the county with the highest pop that does not appear in the cbsa table with a pop of 95,523

-- 6. a. 
SELECT drug_name
	, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;
-- 9 rows found for drugs with total claims at least 3000

-- 6. b. and c.
SELECT drug_name
	, total_claim_count
	, opioid_drug_flag
	, nppes_provider_first_name
	, nppes_provider_last_org_name
FROM prescription
	INNER JOIN drug
	USING(drug_name)
	INNER JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000;
-- Execute for results

-- 7. 
SELECT prescriber.npi
	, opioids.drug_name
	, COALESCE(SUM(opioids.total_claim_count), '0') AS total_claims
FROM prescriber
	CROSS JOIN (SELECT drug_name
					, total_claim_count
				FROM drug
				FULL JOIN prescription
				USING(drug_name)
				WHERE opioid_drug_flag = 'Y') AS opioids
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi
		, opioids.drug_name
ORDER BY npi;