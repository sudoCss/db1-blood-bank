-- SQL 1
SELECT 
  donor.name AS donor_name, 
  blood.type AS blood_type, 
  donation.date AS donation_date, 
  medical_check.allowed_quantity AS donation_quantity, 
  doctor.name AS doctor_name, 
  reception.name AS receptor_name
FROM 
  donor
JOIN blood ON donor.blood_id = blood.id
JOIN donor_reception ON donor.id = donor_reception.donor_id
JOIN medical_check ON donor_reception.id = medical_check.donor_reception_id
JOIN donation ON medical_check.id = donation.medical_check_id
JOIN employee doctor ON medical_check.doctor_id = doctor.id
JOIN employee reception ON donor_reception.receptor_id = reception.id;

-- SQL 2
SELECT 
  hospital.name, 
  blood_order.id AS blood_order_id, 
  blood_order.date AS blood_order_date, 
  blood.type AS blood_type
FROM 
  hospital
JOIN hospital_branch ON hospital.id = hospital_branch.hospital_id
JOIN blood_order ON hospital_branch.id = blood_order.hospital_branch_id
JOIN blood_order_response ON blood_order.id = blood_order_response.blood_order_id
JOIN blood ON blood_order.blood_id = blood.id
WHERE 
  blood_order_response.approved = FALSE;

-- SQL 3
SELECT donor.name
FROM donor
JOIN donor_reception ON donor.id = donor_reception.donor_id
LEFT JOIN medical_check ON donor_reception.id = medical_check.donor_reception_id
LEFT JOIN donation ON medical_check.id = donation.medical_check_id
GROUP BY donor.name
HAVING COUNT(DISTINCT donor_reception.id) = 5 AND COUNT(DISTINCT donation.id) = 4;

-- SQL 4
SELECT h_private.name
FROM hospital h_private
JOIN hospital_branch hb_private ON h_private.id = hb_private.hospital_id
JOIN blood_order bo_private ON hb_private.id = bo_private.hospital_branch_id
JOIN blood b_private ON bo_private.blood_id = b_private.id
WHERE h_private.type = 'private' AND b_private.type = 'O-'
GROUP BY h_private.name
HAVING SUM(bo_private.quantity) > ALL (
  SELECT SUM(bo_gov.quantity)
  FROM hospital h_gov
  JOIN hospital_branch hb_gov ON h_gov.id = hb_gov.hospital_id
  JOIN blood_order bo_gov ON hb_gov.id = bo_gov.hospital_branch_id
  JOIN blood b_gov ON bo_gov.blood_id = b_gov.id
  WHERE h_gov.type = 'governmental' AND b_gov.type = 'O-'
  GROUP BY h_gov.id
);

--- =====================
-- RA 1
-- SELECT name
-- FROM hospital
-- JOIN hospital_branch ON hospital_branch.hospital_id = hospital.id
-- WHERE 
--     type = 'private' AND 
--     address_id IN (
--         SELECT address_id
--         FROM hospital_branch
--         JOIN hospital ON hospital.id = hospital_branch.hospital_id
--         WHERE name = 'Al-Mowasat'
--     );

---
SELECT hospital.name
FROM hospital
JOIN hospital_branch ON hospital.id = hospital_branch.hospital_id
JOIN (
    SELECT hb.address_id
    FROM hospital_branch hb
    JOIN hospital h ON hb.hospital_id = h.id
    WHERE h.name = 'Al-Mowasat'
) AS mowasat_addresses ON hospital_branch.address_id = mowasat_addresses.address_id
WHERE hospital.type = 'private';

R1 := ρ h.id/hospital_id, h.name/hospital_name, h.type/hospital_type (hospital)
R2 := ρ hb.id/branch_id, hb.hospital_id/branch_hospital_id, hb.address_id/branch_address_id (hospital_branch)
R3 := R1 ⨝ R2
R4 := σ hospital_type='private' (R3)
R5 := ρ hb.id/sub_branch_id, hb.hospital_id/sub_hospital_id, hb.address_id/sub_address_id (hospital_branch)
R6 := ρ h.id/sub_hospital_id, h.name/sub_hospital_name, h.type/sub_hospital_type (hospital)
R7 := R5 ⨝ R6
R8 := σ sub_hospital_name='Al-Mowasat' (R7)
R9 := π sub_address_id (R8)
R10 := R4 ⨝ (branch_address_id=sub_address_id) R9
RESULT := π hospital_name (R10)


-- RA 2
-- SELECT DISTINCT address_one.neighborhood
-- FROM address address_one
-- JOIN hospital_branch ON hospital_branch.address_id = address_one.id
-- JOIN hospital ON hospital.id = hospital_branch.hospital_id
-- WHERE 
--     EXISTS (
--         SELECT DISTINCT address_two.neighborhood
--         FROM address address_two
--         JOIN hospital_branch ON hospital_branch.address_id = address_two.id
--         JOIN hospital ON hospital.id = hospital_branch.hospital_id
--         WHERE address_two.id = address_one.id AND  hospital.type = 'private'
-- ) 
-- AND 
--     EXISTS (
--         SELECT DISTINCT address_three.neighborhood
--         FROM address address_three
--         JOIN hospital_branch ON hospital_branch.address_id = address_three.id
--         JOIN hospital ON hospital.id = hospital_branch.hospital_id
--         WHERE address_three.id = address_one.id AND  hospital.type = 'governmental'
--     );

---
SELECT DISTINCT address_one.neighborhood 
FROM address address_one
JOIN hospital_branch ON hospital_branch.address_id = address_one.id
JOIN hospital ON hospital.id = hospital_branch.hospital_id
JOIN hospital_branch hb_private ON hb_private.address_id = address_one.id
JOIN hospital h_private ON h_private.id = hb_private.hospital_id AND h_private.type = 'private'
JOIN hospital_branch hb_governmental ON hb_governmental.address_id = address_one.id
JOIN hospital h_governmental ON h_governmental.id = hb_governmental.hospital_id AND h_governmental.type = 'governmental';

A1 := ρ id/address_one_id, neighborhood/address_one_neighborhood (address)
A2 := ρ id/address_two_id, neighborhood/address_two_neighborhood (address)
HB := ρ id/hb_id, hospital_id/hb_hospital_id, address_id/hb_address_id (hospital_branch)
H := ρ id/h_id, name/h_name, type/h_type (hospital)
R1 := A1 ⨝ (address_one_id=hb_address_id) HB ⨝ (hb_hospital_id=h_id) H
R2 := π address_one_neighborhood, hb_address_id (σ h_type='private' (R1))
R3 := A2 ⨝ (address_two_id=hb_address_id) HB ⨝ (hb_hospital_id=h_id) H
R4 := π address_two_neighborhood, hb_address_id (σ h_type='governmental' (R3))
R5 := R2 ⨝ (hb_address_id) R4
RESULT := δ (π address_one_neighborhood (R5))



-- RA 3
SELECT hospital.name, blood_order.id, blood_order.date, blood_order.quantity
FROM hospital
JOIN hospital_branch ON hospital.id = hospital_branch.hospital_id
JOIN blood_order ON blood_order.hospital_branch_id = hospital_branch.id
JOIN blood ON blood.id = blood_order.blood_id
WHERE blood.type = 'A+'
ORDER BY blood_order.quantity DESC
LIMIT 1;

H := ρ id/h_id, name/h_name, type/h_type (hospital)
HB := ρ id/hb_id, hospital_id/hb_hospital_id, address_id/hb_address_id (hospital_branch)
BO := ρ id/bo_id, hospital_branch_id/bo_hospital_branch_id, blood_id/bo_blood_id, date/bo_date, quantity/bo_quantity (blood_order)
B := ρ id/b_id, type/b_type (blood)
R1 := H ⨝ (h_id=hb_hospital_id) HB ⨝ (hb_id=bo_hospital_branch_id) BO ⨝ (bo_blood_id=b_id) B
R2 := σ b_type='A+' (R1)
R3 := τ -bo_quantity (R2)
RESULT := γ head(1) (R3)
RESULT := π h_name, bo_id, bo_date, bo_quantity (RESULT)

-- https://www.phind.com/search?cache=283f481b-981b-4854-9f67-78192f4bb3ad
