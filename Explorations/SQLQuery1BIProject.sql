
USE BI_Project
go

select * from BI_Project.dbo.hospital_er;


CREATE TABLE Dim_Department (
    department_sk INT PRIMARY KEY,
    department_name VARCHAR(100),
    department_type VARCHAR(50)
);

CREATE TABLE Dim_Date (
    date_sk INT PRIMARY KEY IDENTITY(1, 1),
    full_date DATE NOT NULL,     
    full_datetime DATETIME,     
    year INT NOT NULL,          
    month INT NOT NULL,         
    day INT NOT NULL,           
    day_of_week VARCHAR(15),    
    week_of_year INT,           
    hour INT,                   
    minute INT,                 
    time_of_day VARCHAR(20)     
);


CREATE TABLE Dim_Patient (
    patient_sk INT PRIMARY KEY,
    patient_id VARCHAR(20) UNIQUE,
    patient_gender CHAR(1),
    patient_age INT,
    patient_race VARCHAR(50),
    patient_fullName VARCHAR(100),
    patient_admin_flag BIT
);

CREATE TABLE Fact_PatientVisit (
    visit_sk INT PRIMARY KEY,
    patient_sk INT,
    date_sk INT,
    department_sk INT,
    patient_satisfaction_score INT,
    patient_wait_time INT,
    FOREIGN KEY (patient_sk) REFERENCES Dim_Patient(patient_sk),
    FOREIGN KEY (date_sk) REFERENCES Dim_Date(date_sk),
    FOREIGN KEY (department_sk) REFERENCES Dim_Department(department_sk)
);


--Populate the tables

-- Department Dimension

INSERT INTO Dim_Department (department_sk, department_name, department_type)
SELECT 
    ROW_NUMBER() OVER (ORDER BY department_name),
    department_name,
    CASE 
        WHEN department_name = 'General Practice' THEN 'Primary Care'
        WHEN department_name = 'Orthopedics' THEN 'Specialty'
        WHEN department_name = 'Unassigned' THEN 'Administrative'
        ELSE 'Other'
    END
FROM (
    SELECT DISTINCT 
        COALESCE(
            NULLIF(department_referral, 'None'), 
            'Unassigned'
        ) AS department_name
    FROM hospital_er
) AS UniqueReferrals;

INSERT INTO Dim_Date (full_date, full_datetime, year, month, day, day_of_week, week_of_year, hour, minute, time_of_day)
SELECT DISTINCT 
    CAST([date] AS DATE) AS full_date,                
    [date] AS full_datetime,                         
    YEAR([date]) AS year,                            
    MONTH([date]) AS month,                          
    DAY([date]) AS day,                              
    DATENAME(WEEKDAY, [date]) AS day_of_week,        
    DATEPART(WEEK, [date]) AS week_of_year,          
    DATEPART(HOUR, [date]) AS hour,                  
    DATEPART(MINUTE, [date]) AS minute,              
    CASE                                             
        WHEN DATEPART(HOUR, [date]) BETWEEN 0 AND 5 THEN 'Night'
        WHEN DATEPART(HOUR, [date]) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, [date]) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day
FROM hospital_er; 


-- select * from Dim_Date;

-- select MIN(date) AS MinDate, MAX(date) AS MaxDate FROM hospital_er;

-- Patient Dimension
INSERT INTO Dim_Patient (
    patient_sk, 
    patient_id, 
    patient_gender, 
    patient_age, 
    patient_race, 
    patient_fullName, 
    patient_admin_flag
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY patient_id),
    patient_id,
    patient_gender,
    patient_age,
    patient_race,
    patient_fullName,
    patient_admin_flag
	
FROM hospital_er;

 -- Fact Patient Visit Table
INSERT INTO Fact_PatientVisit (
    visit_sk,
    patient_sk,
    date_sk,
    department_sk,
    patient_satisfaction_score,
    patient_wait_time
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY h.patient_id),
    p.patient_sk,
    d.date_sk,
    dep.department_sk,
    h.patient_sat_score,
    h.patient_waittime
FROM 
    hospital_er h
    JOIN Dim_Patient p ON h.patient_id = p.patient_id
    JOIN Dim_Date d ON CAST(h.date AS DATE) = d.full_date
    LEFT JOIN Dim_Department dep ON h.department_referral = dep.department_name;

-- select * from Fact_PatientVisit;

-- Drop the existing table if it exists
--IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Fact_PatientVisit')
--    DROP TABLE Fact_PatientVisit;

