CREATE DATABASE  IF NOT EXISTS `railway12345` /*!40100 DEFAULT CHARACTER SET utf8mb3 */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `railway12345`;

-- Table: admin
CREATE TABLE admin (
  admin_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('Station Master', 'Ticket Officer') NOT NULL,
  PRIMARY KEY (admin_id)
);

-- Table: stations
CREATE TABLE stations (
  station_id INT NOT NULL AUTO_INCREMENT,
  station_name VARCHAR(100) NOT NULL UNIQUE,
  city VARCHAR(100) NOT NULL,
  PRIMARY KEY (station_id)
);

-- Table: trains
CREATE TABLE trains (
  train_id INT NOT NULL AUTO_INCREMENT,
  train_name VARCHAR(100) NOT NULL,
  train_number VARCHAR(20) NOT NULL UNIQUE,
  source_station_id INT,
  destination_station_id INT,
  departure_time TIME NOT NULL,
  arrival_time TIME NOT NULL,
  travel_duration TIME NOT NULL,
  PRIMARY KEY (train_id),
  FOREIGN KEY (source_station_id) REFERENCES stations(station_id),
  FOREIGN KEY (destination_station_id) REFERENCES stations(station_id)
);

-- Table: coaches
CREATE TABLE coaches (
  coach_id INT NOT NULL AUTO_INCREMENT,
  train_id INT,
  coach_type ENUM('Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'First Class'),
  total_seats INT NOT NULL,
  PRIMARY KEY (coach_id),
  FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

-- Table: seats
CREATE TABLE seats (
  seat_id INT NOT NULL AUTO_INCREMENT,
  coach_id INT,
  seat_number VARCHAR(10) NOT NULL,
  status ENUM('Available', 'Booked', 'RAC', 'Waitlist') DEFAULT 'Available',
  seat_type ENUM('Upper', 'Middle', 'Lower', 'Side Upper', 'Side Lower') NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (seat_id),
  FOREIGN KEY (coach_id) REFERENCES coaches(coach_id)
);

-- Table: concessions
CREATE TABLE concessions (
  concession_id INT NOT NULL AUTO_INCREMENT,
  category_name ENUM('Senior Citizen (Male)', 'Senior Citizen (Female)', 'Children (5-12 years)', 'Student', 'Disabled Person', 'Armed Forces', 'Railway Employee') NOT NULL,
  discount_percentage DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (concession_id)
);

-- Table: passengers
CREATE TABLE passengers (
  passenger_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(15) NOT NULL UNIQUE,
  age INT NOT NULL,
  gender ENUM('M', 'F', 'O') NOT NULL,
  concession_id INT,
  PRIMARY KEY (passenger_id),
  FOREIGN KEY (concession_id) REFERENCES concessions(concession_id)
);

-- Table: reservations
CREATE TABLE reservations (
  reservation_id INT NOT NULL AUTO_INCREMENT,
  passenger_id INT,
  train_id INT,
  journey_date DATE NOT NULL,
  coach_id INT,
  seat_id INT,
  status VARCHAR(20) DEFAULT 'Confirmed',
  pnr_number VARCHAR(20) NOT NULL UNIQUE,
  PRIMARY KEY (reservation_id),
  FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
  FOREIGN KEY (train_id) REFERENCES trains(train_id),
  FOREIGN KEY (coach_id) REFERENCES coaches(coach_id),
  FOREIGN KEY (seat_id) REFERENCES seats(seat_id)
);

-- Table: payments
CREATE TABLE payments (
  payment_id INT NOT NULL AUTO_INCREMENT,
  reservation_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('Card', 'UPI', 'Netbanking', 'Cash') NOT NULL,
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id),
  FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE
);

-- Table: cancellations
CREATE TABLE cancellations (
  cancellation_id INT NOT NULL AUTO_INCREMENT,
  reservation_id INT NOT NULL,
  status ENUM('pending', 'completed') NOT NULL DEFAULT 'pending',
  refund_amount INT NOT NULL,
  cancellation_date DATE NOT NULL,
  PRIMARY KEY (cancellation_id),
  FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE
);

-- Table: train_runs
CREATE TABLE train_runs (
  run_id INT NOT NULL AUTO_INCREMENT,
  train_id INT,
  journey_date DATE,
  status ENUM('Scheduled', 'Cancelled', 'Completed'),
  PRIMARY KEY (run_id),
  FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

-- Table: seat_availability
CREATE TABLE seat_availability (
  seat_avail_id INT NOT NULL AUTO_INCREMENT,
  seat_id INT,
  run_id INT,
  is_booked TINYINT DEFAULT 0,
  booking_id INT,
  PRIMARY KEY (seat_avail_id),
  FOREIGN KEY (seat_id) REFERENCES seats(seat_id),
  FOREIGN KEY (run_id) REFERENCES train_runs(run_id)
);

-- Table: train_schedule
CREATE TABLE train_schedule (
  schedule_id INT NOT NULL AUTO_INCREMENT,
  train_id INT,
  journey_date DATE NOT NULL,
  status ENUM('On Time', 'Delayed', 'Cancelled') DEFAULT 'On Time',
  PRIMARY KEY (schedule_id),
  FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

-- Table: waitlist
CREATE TABLE waitlist (
  waitlist_id INT NOT NULL AUTO_INCREMENT,
  passenger_id INT,
  train_id INT,
  journey_date DATE,
  coach_id INT,
  status VARCHAR(20) DEFAULT 'Waitlist',
  pnr_number VARCHAR(20),
  PRIMARY KEY (waitlist_id),
  FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
  FOREIGN KEY (train_id) REFERENCES trains(train_id),
  FOREIGN KEY (coach_id) REFERENCES coaches(coach_id)
);
