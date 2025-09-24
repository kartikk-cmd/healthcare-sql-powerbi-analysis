-- ==============================
-- 1. Create & Use Database
-- ==============================
CREATE DATABASE IF NOT EXISTS hospitalanalysis;
USE hospitalanalysis;

-- ==============================
-- 2. Create Patients Table
-- ==============================
CREATE TABLE IF NOT EXISTS patients (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(10),
    Blood_Type VARCHAR(5),
    Medical_Condition VARCHAR(255),
    Date_of_Admission DATE,
    Doctor VARCHAR(100),
    Hospital VARCHAR(100),
    Insurance_Provider VARCHAR(100),
    Billing_Amount DECIMAL(10,2),
    Room_Number VARCHAR(10),
    Admission_Type VARCHAR(50),
    Discharge_Date DATE,
    Medication VARCHAR(255),
    Test_Results VARCHAR(255)
);

-- ==============================
-- 3. Load CSV Data
-- ==============================
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/healthcare_dataset.csv'
INTO TABLE patients
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results);

-- ==============================
-- 4. Data Cleaning
-- ==============================
UPDATE patients
SET Name = UPPER(Name);

-- ==============================
-- 5. Views (Instead of Loose Queries)
-- ==============================

-- Patients with Diabetes
CREATE OR REPLACE VIEW vw_patients_diabetes AS
SELECT Name, Age, Gender, Medical_Condition, Date_of_Admission
FROM patients
WHERE Medical_Condition = 'Diabetes';

-- Count patients with Diabetes
CREATE OR REPLACE VIEW vw_diabetes_count AS
SELECT COUNT(*) AS diabetes_count
FROM patients
WHERE Medical_Condition = 'Diabetes';

-- Top 15 billing amounts
CREATE OR REPLACE VIEW vw_top15_billing AS
SELECT Name, Billing_Amount, Hospital
FROM patients
ORDER BY Billing_Amount DESC
LIMIT 15;

-- Patients admitted in 2023
CREATE OR REPLACE VIEW vw_patients_2023 AS
SELECT Name, Date_of_Admission, Hospital
FROM patients
WHERE Date_of_Admission BETWEEN '2023-01-01' AND '2023-12-31';

-- Admission date range
CREATE OR REPLACE VIEW vw_admission_range AS
SELECT MIN(Date_of_Admission) AS first_admission, MAX(Date_of_Admission) AS last_admission
FROM patients;

-- Gender distribution
CREATE OR REPLACE VIEW vw_gender_distribution AS
SELECT Gender, COUNT(*) AS count
FROM patients
WHERE Gender IN ('Male', 'Female')
GROUP BY Gender;

-- Patients per hospital
CREATE OR REPLACE VIEW vw_patients_per_hospital AS
SELECT Hospital, COUNT(*) AS patient_count
FROM patients
GROUP BY Hospital;

-- Patients per doctor per hospital
CREATE OR REPLACE VIEW vw_patients_per_doctor_hospital AS
SELECT Doctor, Hospital, COUNT(*) AS patient_count
FROM patients
GROUP BY Doctor, Hospital;

-- Patients per doctor
CREATE OR REPLACE VIEW vw_patients_per_doctor AS
SELECT Doctor, COUNT(*) AS patient_count
FROM patients
GROUP BY Doctor;

-- Average billing per admission type
CREATE OR REPLACE VIEW vw_avg_billing_per_admission_type AS
SELECT Admission_Type, AVG(Billing_Amount) AS avg_bill
FROM patients
GROUP BY Admission_Type;

-- Monthly admissions trend
CREATE OR REPLACE VIEW vw_monthly_admissions AS
SELECT YEAR(Date_of_Admission) AS year,
       MONTH(Date_of_Admission) AS month,
       COUNT(*) AS admissions
FROM patients
GROUP BY YEAR(Date_of_Admission), MONTH(Date_of_Admission);

-- Monthly revenue trend
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT YEAR(Date_of_Admission) AS year,
       MONTH(Date_of_Admission) AS month,
       SUM(Billing_Amount) AS revenue
FROM patients
GROUP BY YEAR(Date_of_Admission), MONTH(Date_of_Admission);

-- Average patient stay time
CREATE OR REPLACE VIEW vw_avg_stay_time AS
SELECT AVG(DATEDIFF(Discharge_Date, Date_of_Admission)) AS avg_stay_days
FROM patients;

-- ==============================
-- 6. Lookup Tables
-- ==============================
CREATE TABLE IF NOT EXISTS doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_name VARCHAR(100) UNIQUE
);
INSERT INTO doctors (doctor_name)
SELECT DISTINCT Doctor FROM patients;

CREATE TABLE IF NOT EXISTS hospitals (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(100) UNIQUE
);
INSERT INTO hospitals (hospital_name)
SELECT DISTINCT Hospital FROM patients;

CREATE TABLE IF NOT EXISTS insurance_providers (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,
    provider_name VARCHAR(100) UNIQUE
);
INSERT INTO insurance_providers (provider_name)
SELECT DISTINCT Insurance_Provider FROM patients;

-- ==============================
-- 7. Views for Joins & Advanced Queries
-- ==============================

-- Patient with doctor
CREATE OR REPLACE VIEW vw_patient_doctor AS
SELECT p.Name, p.Medical_Condition, d.Doctor_Name
FROM patients p
JOIN doctors d ON p.Doctor = d.Doctor_Name;

-- Top 15 billing with doctor & hospital
CREATE OR REPLACE VIEW vw_top15_billing_doctor_hospital AS
SELECT p.Name, p.Medical_Condition, d.Doctor_Name, h.Hospital_Name, p.Billing_Amount
FROM patients p
JOIN doctors d ON p.Doctor = d.Doctor_Name
JOIN hospitals h ON p.Hospital = h.Hospital_Name
ORDER BY p.Billing_Amount DESC
LIMIT 15;

-- Average billing per hospital
CREATE OR REPLACE VIEW vw_avg_billing_per_hospital AS
SELECT h.Hospital_Name, AVG(p.Billing_Amount) AS avg_bill
FROM patients p
JOIN hospitals h ON p.Hospital = h.Hospital_Name
GROUP BY h.Hospital_Name;

-- Rank patients by billing
CREATE OR REPLACE VIEW vw_rank_patients_billing AS
SELECT Name, Billing_Amount,
       ROW_NUMBER() OVER (ORDER BY Billing_Amount DESC) AS bill_rank
FROM patients;

-- Running monthly revenue
CREATE OR REPLACE VIEW vw_running_monthly_revenue AS
SELECT YEAR(Date_of_Admission) AS year,
       MONTH(Date_of_Admission) AS month,
       SUM(Billing_Amount) AS monthly_revenue,
       SUM(SUM(Billing_Amount)) OVER (ORDER BY YEAR(Date_of_Admission), MONTH(Date_of_Admission)) AS running_total
FROM patients
GROUP BY YEAR(Date_of_Admission), MONTH(Date_of_Admission);

-- ==============================
-- 8. Views for Additional Analytics
-- ==============================

-- Total patients
CREATE OR REPLACE VIEW vw_total_patients AS
SELECT COUNT(*) AS total_patients FROM patients;

-- Average age
CREATE OR REPLACE VIEW vw_avg_age AS
SELECT AVG(Age) AS avg_age FROM patients;

-- Total billing & highest/lowest bills
CREATE OR REPLACE VIEW vw_billing_summary AS
SELECT SUM(Billing_Amount) AS total_revenue,
       MAX(Billing_Amount) AS highest_bill,
       MIN(Billing_Amount) AS lowest_bill
FROM patients;

-- Top medical conditions
CREATE OR REPLACE VIEW vw_top_medical_conditions AS
SELECT Medical_Condition, COUNT(*) AS patient_count
FROM patients
GROUP BY Medical_Condition
ORDER BY patient_count DESC
LIMIT 10;

-- Top medications
CREATE OR REPLACE VIEW vw_top_medications AS
SELECT Medication, COUNT(*) AS usage_count
FROM patients
GROUP BY Medication
ORDER BY usage_count DESC
LIMIT 10;

-- Average stay per medical condition
CREATE OR REPLACE VIEW vw_avg_stay_per_condition AS
SELECT Medical_Condition, AVG(DATEDIFF(Discharge_Date, Date_of_Admission)) AS avg_stay_days
FROM patients
GROUP BY Medical_Condition;

-- Top hospitals by revenue
CREATE OR REPLACE VIEW vw_top_hospitals_revenue AS
SELECT Hospital, SUM(Billing_Amount) AS total_revenue
FROM patients
GROUP BY Hospital
ORDER BY total_revenue DESC;

-- Top insurance providers by billing
CREATE OR REPLACE VIEW vw_top_insurance_providers AS
SELECT Insurance_Provider, SUM(Billing_Amount) AS total_billing
FROM patients
GROUP BY Insurance_Provider
ORDER BY total_billing DESC;

-- Insurance status analysis
CREATE OR REPLACE VIEW vw_insurance_status AS
SELECT CASE 
           WHEN Insurance_Provider IS NULL OR Insurance_Provider = '' THEN 'Uninsured'
           ELSE 'Insured'
       END AS insurance_status,
       AVG(Billing_Amount) AS avg_bill,
       COUNT(*) AS patient_count
FROM patients
GROUP BY insurance_status;

-- Patient segmentation by age group
CREATE OR REPLACE VIEW vw_patient_age_groups AS
SELECT CASE
           WHEN Age < 18 THEN 'Child'
           WHEN Age BETWEEN 18 AND 40 THEN 'Adult'
           WHEN Age BETWEEN 41 AND 60 THEN 'Middle-aged'
           ELSE 'Senior'
       END AS age_group,
       COUNT(*) AS patient_count
FROM patients
GROUP BY age_group;

-- Top doctors by patient count and billing
CREATE OR REPLACE VIEW vw_top_doctors AS
SELECT Doctor, COUNT(*) AS patient_count, SUM(Billing_Amount) AS total_billing
FROM patients
GROUP BY Doctor
ORDER BY patient_count DESC
LIMIT 5;
