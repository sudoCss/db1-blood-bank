DROP DATABASE blood_bank;

CREATE DATABASE blood_bank;

\c blood_bank

CREATE TYPE BLOOD_TYPE AS ENUM ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-');

CREATE TABLE blood (
  id SERIAL PRIMARY KEY,
  type BLOOD_TYPE NOT NULL,
  quantity DECIMAL NOT NULL,
  UNIQUE (type)
);

CREATE TYPE GENDER AS ENUM ('male', 'female');
CREATE TYPE JOB AS ENUM ('doctor', 'reception', 'nurse');

CREATE TABLE employee (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  gender GENDER NOT NULL,
  job JOB NOT NULL,
  phone VARCHAR(255) NOT NULL
);

CREATE TABLE donor (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  gender GENDER NOT NULL,
  phone VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  birth_date TIMESTAMP NOT NULL,
  blood_id INTEGER NOT NULL,
  FOREIGN KEY (blood_id) REFERENCES blood (id)
);

CREATE TABLE donor_reception (
  id SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
  receptor_id INTEGER NOT NULL,
  donor_id INTEGER NOT NULL,
  FOREIGN KEY (receptor_id) REFERENCES employee (id),
  FOREIGN KEY (donor_id) REFERENCES donor (id)
);

CREATE TABLE medical_check (
  id SERIAL PRIMARY KEY,
  approved BOOLEAN NOT NULL,
  allowed_quantity DECIMAL NOT NULL,
  donor_reception_id INTEGER NOT NULL,
  doctor_id INTEGER NOT NULL,
  FOREIGN KEY (donor_reception_id) REFERENCES donor_reception (id),
  FOREIGN KEY (doctor_id) REFERENCES employee (id)
);

CREATE TABLE donation (
  id SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
  medical_check_id INTEGER NOT NULL,
  FOREIGN KEY (medical_check_id) REFERENCES medical_check (id)
);

CREATE TYPE HOSPITAL_TYPE AS ENUM ('private', 'governmental');

CREATE TABLE hospital (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type HOSPITAL_TYPE NOT NULL
);

CREATE TABLE address (
    id SERIAL PRIMARY KEY,
    state VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    area VARCHAR(255) NOT NULL,
    neighborhood VARCHAR(255) NOT NULL
);

CREATE TABLE hospital_branch (
    id SERIAL PRIMARY KEY,
    street VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    hospital_id INTEGER NOT NULL,
    address_id INTEGER NOT NULL,
    FOREIGN KEY (hospital_id) REFERENCES hospital (id),
    FOREIGN KEY (address_id) REFERENCES address (id)
);

CREATE TABLE blood_order (
  id SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
  quantity DECIMAL NOT NULL,
  blood_id INTEGER NOT NULL,
  hospital_branch_id INTEGER NOT NULL,
  FOREIGN KEY (blood_id) REFERENCES blood (id),
  FOREIGN KEY (hospital_branch_id) REFERENCES hospital_branch (id)
);

CREATE TABLE blood_order_response (
  id SERIAL PRIMARY KEY,
  approved BOOLEAN NOT NULL,
  quantity DECIMAL NOT NULL,
  date TIMESTAMP NOT NULL,
  blood_order_id INTEGER NOT NULL,
  FOREIGN KEY (blood_order_id) REFERENCES blood_order (id)
);

---
-- TRIGGERS FOR VALIDATION(NOT REQUIRED)
CREATE OR REPLACE FUNCTION check_receptor_job() RETURNS TRIGGER AS $$
DECLARE
  job_type JOB;
BEGIN
  SELECT job INTO job_type FROM employee WHERE id = NEW.receptor_id;
  
  IF job_type = 'reception' THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Receptor must have a job type of reception';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_receptor_job_trigger
  BEFORE INSERT OR UPDATE ON donor_reception
  FOR EACH ROW
  EXECUTE FUNCTION check_receptor_job();

CREATE OR REPLACE FUNCTION check_doctor_job() RETURNS TRIGGER AS $$
DECLARE
  job_type JOB;
BEGIN
  SELECT job INTO job_type FROM employee WHERE id = NEW.doctor_id;
  
  IF job_type = 'doctor' THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Doctor must have a job type of doctor';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_doctor_job_trigger
  BEFORE INSERT OR UPDATE ON medical_check
  FOR EACH ROW
  EXECUTE FUNCTION check_doctor_job();


---
-- INSERT DUMMY DATA
INSERT INTO blood (type, quantity) VALUES
('A+', 100),
('A-', 200),
('B+', 150),
('B-', 250),
('O+', 300),
('O-', 350),
('AB+', 400),
('AB-', 450);

INSERT INTO employee (name, gender, job, phone) VALUES
('John Doe', 'male', 'doctor', '555-1234'),
('Jane Smith', 'female', 'reception', '555-5678'),
('Alice Johnson', 'female', 'nurse', '555-9012'),
('Bob Brown', 'male', 'doctor', '555-3456');

INSERT INTO donor (name, gender, phone, email, birth_date, blood_id) VALUES
('Michael Jackson', 'male', '555-7890', 'michael@example.com', '1958-08-29', 1),
('Madonna', 'female', '555-2345', 'madonna@example.com', '1958-08-16', 2),
('Prince', 'male', '555-6789', 'prince@example.com', '1958-06-07', 3),
('Freddie Mercury', 'male', '555-1239', 'freddie@example.com', '1946-09-05', 4);

INSERT INTO donor_reception (date, receptor_id, donor_id) VALUES
('2023-06-01', 2, 1),
('2023-06-02', 2, 1),
('2023-06-03', 2, 1),
('2023-06-04', 2, 1),
('2023-06-05', 2, 1),
('2023-06-02', 2, 2),
('2023-06-03', 2, 3),
('2023-06-04', 2, 4);

INSERT INTO medical_check (approved, allowed_quantity, donor_reception_id, doctor_id) VALUES
(true, 500, 1, 1),
(true, 500, 2, 1),
(true, 500, 3, 1),
(true, 500, 4, 1),
(false, 0, 7, 4),
(true, 100, 7, 4),
(true, 450, 8, 4);

INSERT INTO donation (date, medical_check_id) VALUES
('2023-06-01', 1),
('2023-06-02', 2),
('2023-06-02', 3),
('2023-06-02', 4),
('2023-06-03', 6),
('2023-06-04', 7);

INSERT INTO hospital (name, type) VALUES
('City Hospital', 'governmental'),
('Al-Mowasat', 'governmental'),
('Green Valley Hospital', 'private'),
('River Side Hospital', 'governmental'),
('Sunrise Hospital', 'private'),
('Moonlight Hospital', 'private');

INSERT INTO address (state, city, area, neighborhood) VALUES
('California', 'Los Angeles', 'Downtown', 'Main St'),
('New York', 'New York City', 'Manhattan', 'Broadway'),
('Texas', 'Houston', 'Midtown', 'Washington Ave'),
('Florida', 'Miami', 'South Beach', 'Ocean Drive');

INSERT INTO hospital_branch (street, location, hospital_id, address_id) VALUES
('123 Main St', 'Building A', 1, 1),
('456 Broadway', 'Floor 2', 2, 2),
('789 Washington Ave', 'Suite 300', 3, 3),
('101112 Ocean Drive', 'Unit 4', 4, 4),
('101112 Ocean Drive', 'Unit 4', 5, 3),
('101112 Ocean Drive', 'Unit 4', 6, 2);

INSERT INTO blood_order (date, quantity, blood_id, hospital_branch_id) VALUES
('2023-06-01', 10, 1, 1),
('2023-06-02', 15, 1, 2),
('2023-06-03', 20, 3, 3),
('2023-06-04', 25, 4, 4),
('2023-06-04', 34, 6, 3),
('2023-06-04', 25, 6, 4),
('2023-06-04', 26, 6, 5),
('2023-06-04', 27, 6, 6);

INSERT INTO blood_order_response (approved, quantity, date, blood_order_id) VALUES
(true, 10, '2023-06-01', 1),
(false, 0, '2023-06-02', 2),
(true, 20, '2023-06-03', 3),
(false, 0, '2023-06-04', 4);
