USE `railway12345`;


DELIMITER //
CREATE PROCEDURE `CreatePassenger`(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_age INT,
    IN p_gender ENUM('M', 'F', 'O'),
    IN p_concession_category VARCHAR(50),
    OUT p_passenger_id INT
)
BEGIN
    DECLARE concession_id INT DEFAULT NULL;
    
    
    IF p_concession_category IS NOT NULL THEN
        SELECT c.concession_id INTO concession_id
        FROM Concessions c
        WHERE c.category_name = p_concession_category;
    END IF;
    
    INSERT INTO Passengers (name, email, phone, age, gender, concession_id)
    VALUES (p_name, p_email, p_phone, p_age, p_gender, concession_id);
    
    SET p_passenger_id = LAST_INSERT_ID();
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE `AddTrain`(
    IN p_train_name VARCHAR(100),
    IN p_train_number VARCHAR(20),
    IN p_source_station VARCHAR(100),
    IN p_destination_station VARCHAR(100),
    IN p_departure_time TIME,
    IN p_arrival_time TIME,
    OUT p_train_id INT
)
BEGIN
    DECLARE source_id INT;
    DECLARE dest_id INT;
    
    -- Get station IDs
    SELECT station_id INTO source_id FROM Stations WHERE station_name = p_source_station;
    SELECT station_id INTO dest_id FROM Stations WHERE station_name = p_destination_station;
    
    -- Insert train record
    INSERT INTO Trains (train_name, train_number, source_station_id, destination_station_id, 
                       departure_time, arrival_time, travel_duration)
    VALUES (p_train_name, p_train_number, source_id, dest_id, 
            p_departure_time, p_arrival_time, 
            TIMEDIFF(p_arrival_time, p_departure_time));
    
    SET p_train_id = LAST_INSERT_ID();
END //
DELIMITER ;

DELIMITER //

CREATE PROCEDURE `AddStation`(
    IN p_station_name VARCHAR(100),
    IN p_city VARCHAR(100),
    OUT p_station_id INT
)
BEGIN
    -- Check if station already exists
    DECLARE station_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO station_exists
    FROM Stations
    WHERE station_name = p_station_name AND city = p_city;
    
    IF station_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Station already exists in this city';
    ELSE
        -- Insert new station
        INSERT INTO Stations (station_name, city)
        VALUES (p_station_name, p_city);
        
        -- Return the new station ID
        SET p_station_id = LAST_INSERT_ID();
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE `AddWeeklySchedules`(
    IN p_train_number VARCHAR(20),
    IN p_start_date DATE,
    IN p_weeks INT,
    IN p_days_of_week VARCHAR(20) -- Comma separated (e.g., '1,3,5' for Mon,Wed,Fri)
)
BEGIN
    DECLARE v_train_id INT;
    DECLARE v_current_date DATE;
    DECLARE v_day_of_week INT;
    DECLARE v_week_counter INT DEFAULT 0;
    
    -- Get train_id
    SELECT train_id INTO v_train_id 
    FROM Trains 
    WHERE train_number = p_train_number;
    
    IF v_train_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found';
    ELSE
        -- Loop through weeks
        WHILE v_week_counter < p_weeks DO
            -- Loop through days 0-6 (Sunday-Saturday)
            SET v_day_of_week = 0;
            WHILE v_day_of_week < 7 DO
                SET v_current_date = DATE_ADD(p_start_date, INTERVAL (v_week_counter*7 + v_day_of_week) DAY);
                
                -- Check if this day is in our schedule
                IF FIND_IN_SET(v_day_of_week+1, p_days_of_week) > 0 THEN
                    -- Add schedule for this day
                    INSERT INTO Train_runs (train_id, journey_date, status)
                    VALUES (v_train_id, v_current_date, 'Scheduled')
                    ON DUPLICATE KEY UPDATE status = 'Scheduled';
                END IF;
                
                SET v_day_of_week = v_day_of_week + 1;
            END WHILE;
            
            SET v_week_counter = v_week_counter + 1;
        END WHILE;
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE `GenerateTrainRuns`(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Ensure all train runs in the date range are set to 'Scheduled' if not already existing
    -- We'll assume that runs should already exist (via AddWeeklySchedules or similar)
    -- This block ensures any run with no status or needing reset will be scheduled

    UPDATE Train_Runs
    SET status = 'Scheduled'
    WHERE journey_date BETWEEN p_start_date AND p_end_date
      AND status IS NULL;

    -- Initialize seat availability for runs in the date range
    INSERT INTO Seat_Availability (seat_id, run_id, is_booked)
    SELECT s.seat_id, r.run_id, 0
    FROM Train_Runs r
    JOIN Coaches c ON r.train_id = c.train_id
    JOIN Seats s ON c.coach_id = s.coach_id
    WHERE r.journey_date BETWEEN p_start_date AND p_end_date
    AND NOT EXISTS (
        SELECT 1 FROM Seat_Availability sa 
        WHERE sa.seat_id = s.seat_id 
        AND sa.run_id = r.run_id
    );
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE `AddCoachToTrain`(
    IN p_train_number VARCHAR(20),
    IN p_coach_type ENUM('Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'First Class', 'AC Chair Car', 'Executive Class'),
    IN p_seat_count INT,
    OUT p_coach_id INT
)
BEGIN
    DECLARE v_train_id INT;

    -- Get train_id from train_number
    SELECT train_id INTO v_train_id 
    FROM Trains 
    WHERE train_number = p_train_number;

    -- Check if train exists
    IF v_train_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found';
    ELSE
        -- Insert the coach record
        INSERT INTO Coaches (train_id, coach_type, total_seats)
        VALUES (v_train_id, p_coach_type, p_seat_count);
        
        -- Get the last inserted coach ID
        SET p_coach_id = LAST_INSERT_ID();
    END IF;
END //
DELIMITER ;


DELIMITER //

CREATE PROCEDURE `AddSeatsToCoach`(
    IN p_coach_id INT,
    IN p_seat_prefix VARCHAR(3),
    IN p_seat_count INT,
    IN p_seat_type ENUM('Upper', 'Middle', 'Lower', 'Side Upper', 'Side Lower'),
    IN p_price DECIMAL(10,2)
)
BEGIN
    DECLARE i INT DEFAULT 1;
    
    -- Add specified number of seats
    WHILE i <= p_seat_count DO
        INSERT INTO Seats (coach_id, seat_number, seat_type, price)
        VALUES (p_coach_id, CONCAT(p_seat_prefix, i), p_seat_type, p_price);
        
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

DELIMITER //

CREATE PROCEDURE `UpdateSeatAvailability`(
    IN p_run_id INT,
    IN p_seat_id INT,
    IN p_booking_status TINYINT,  -- 1 for booked, 0 for available
    IN p_booking_id INT           -- NULL if making available
)
BEGIN
    DECLARE seat_exists INT DEFAULT 0;
    
    -- Check if seat availability record already exists
    SELECT COUNT(*) INTO seat_exists
    FROM Seat_Availability
    WHERE run_id = p_run_id AND seat_id = p_seat_id;
    
    IF seat_exists > 0 THEN
        -- Update existing record
        UPDATE Seat_Availability
        SET is_booked = p_booking_status,
            booking_id = p_booking_id
        WHERE run_id = p_run_id AND seat_id = p_seat_id;
    ELSE
        -- Insert new record
        INSERT INTO Seat_Availability (seat_id, run_id, is_booked, booking_id)
        VALUES (p_seat_id, p_run_id, p_booking_status, p_booking_id);
    END IF;
END //

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE `CreateReservation`(
    IN p_passenger_id INT,
    IN p_train_number VARCHAR(20),
    IN p_journey_date DATE,
    IN p_coach_type ENUM('Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'First Class'),
    IN p_payment_amount DECIMAL(10,2),
    IN p_payment_method ENUM('Card', 'UPI', 'Cash', 'Netbanking'),
    OUT p_reservation_id INT,
    OUT p_pnr_number VARCHAR(10),
    OUT p_status ENUM('Confirmed', 'RAC', 'Waitlist'),
    OUT p_coach_number VARCHAR(5),
    OUT p_seat_number VARCHAR(10),
    OUT p_payment_id INT
)
BEGIN
    DECLARE v_train_id INT;
    DECLARE v_run_id INT;
    DECLARE v_available_seat_id INT;
    DECLARE v_coach_id INT;
    DECLARE v_seat_count INT;
    DECLARE v_waitlist_number INT;
    DECLARE v_pnr VARCHAR(10);
    DECLARE v_concession_discount DECIMAL(5,2) DEFAULT 0;
    DECLARE v_final_amount DECIMAL(10,2);
    DECLARE v_max_rac_per_coach INT DEFAULT 10;
    DECLARE v_existing_reservations INT;

    -- Validate passenger exists
    IF NOT EXISTS (SELECT 1 FROM Passengers WHERE passenger_id = p_passenger_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger not found';
    END IF;

    -- Get concession discount if applicable
    SELECT IFNULL(c.discount_percentage, 0) INTO v_concession_discount
    FROM Passengers p
    LEFT JOIN Concessions c ON p.concession_id = c.concession_id
    WHERE p.passenger_id = p_passenger_id;

    -- Apply concession discount
    SET v_final_amount = p_payment_amount * (100 - v_concession_discount) / 100;

    -- Generate more unique PNR (8 alphanumeric characters)
    SET v_pnr = UPPER(
        CONCAT(
            CHAR(FLOOR(65 + RAND() * 26)),
            CHAR(FLOOR(65 + RAND() * 26)),
            FLOOR(RAND() * 10),
            FLOOR(RAND() * 10),
            FLOOR(RAND() * 10),
            CHAR(FLOOR(65 + RAND() * 26)),
            CHAR(FLOOR(65 + RAND() * 26))
        )
    );

    -- Get train_id from train_number with lock
    SELECT train_id INTO v_train_id
    FROM Trains 
    WHERE train_number = p_train_number
    LOCK IN SHARE MODE;

    IF v_train_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid train number';
    END IF;

    -- Get run_id with lock to prevent concurrent modifications
    SELECT run_id INTO v_run_id 
    FROM Train_Runs 
    WHERE train_id = v_train_id 
    AND journey_date = p_journey_date
    FOR UPDATE;

    IF v_run_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No scheduled run for this date';
    END IF;

    -- Check train status with lock
    IF EXISTS (
        SELECT 1 FROM Train_Runs 
        WHERE run_id = v_run_id AND status = 'Cancelled'
        FOR UPDATE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This train run has been cancelled';
    END IF;

    -- Start transaction
    START TRANSACTION;

    -- Check for existing reservations by this passenger on same train/date
    SELECT COUNT(*) INTO v_existing_reservations
    FROM Reservations
    WHERE passenger_id = p_passenger_id
    AND train_id = v_train_id
    AND journey_date = p_journey_date;

    IF v_existing_reservations > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger already has a reservation on this train/date';
    END IF;

    -- Find available seat with lock to prevent race conditions
    SELECT s.seat_id, s.coach_id INTO v_available_seat_id, v_coach_id
    FROM Seats s
    JOIN Coaches c ON s.coach_id = c.coach_id
    LEFT JOIN Seat_Availability sa ON s.seat_id = sa.seat_id AND sa.run_id = v_run_id
    WHERE c.train_id = v_train_id
    AND c.coach_type = p_coach_type
    AND (sa.is_booked = 0 OR sa.is_booked IS NULL)
    AND s.status = 'Available'
    LIMIT 1
    FOR UPDATE;

    IF v_available_seat_id IS NOT NULL THEN
        -- Found available seat - confirm reservation
        INSERT INTO Reservations (
            passenger_id, 
            train_id, 
            journey_date, 
            coach_id, 
            seat_id, 
            status, 
            pnr_number
        ) VALUES (
            p_passenger_id,
            v_train_id,
            p_journey_date,
            v_coach_id,
            v_available_seat_id,
            'Confirmed',
            v_pnr
        );

        SET p_reservation_id = LAST_INSERT_ID();

        -- Update seat availability directly (more efficient than calling another procedure)
        INSERT INTO Seat_Availability (seat_id, run_id, is_booked, booking_id)
        VALUES (v_available_seat_id, v_run_id, 1, p_reservation_id)
        ON DUPLICATE KEY UPDATE is_booked = 1, booking_id = p_reservation_id;

        -- Update seat status
        UPDATE Seats SET status = 'Booked' WHERE seat_id = v_available_seat_id;

        -- Get coach and seat numbers
        SELECT 
            c.coach_id AS coach_number,
            s.seat_number INTO p_coach_number, p_seat_number
        FROM Seats s
        JOIN Coaches c ON s.coach_id = c.coach_id
        WHERE s.seat_id = v_available_seat_id;

        SET p_status = 'Confirmed';
    ELSE
        -- No available seats - check for RAC/Waitlist
        SELECT COUNT(*) INTO v_seat_count
        FROM Coaches
        WHERE train_id = v_train_id
        AND coach_type = p_coach_type
        LOCK IN SHARE MODE;

        IF v_seat_count = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No coaches of this type available';
        END IF;

        -- Check RAC availability with lock
        SELECT COUNT(*) INTO v_existing_reservations
        FROM Reservations 
        WHERE train_id = v_train_id 
        AND journey_date = p_journey_date
        AND status = 'RAC'
        FOR UPDATE;

        IF v_existing_reservations < (v_seat_count * v_max_rac_per_coach) THEN
            -- Create RAC reservation
            INSERT INTO Reservations (
                passenger_id, 
                train_id, 
                journey_date, 
                status, 
                pnr_number
            ) VALUES (
                p_passenger_id,
                v_train_id,
                p_journey_date,
                'RAC',
                v_pnr
            );

            SET p_reservation_id = LAST_INSERT_ID();
            SET p_status = 'RAC';
            SET p_coach_number = 'RAC';
            SET p_seat_number = CONCAT('RAC-', p_reservation_id);
        ELSE
            -- Create Waitlist reservation with proper numbering
            SELECT IFNULL(MAX(CAST(SUBSTRING_INDEX(seat_number, '-', -1) AS UNSIGNED)), 0) + 1 
            INTO v_waitlist_number
            FROM Reservations
            WHERE train_id = v_train_id
            AND journey_date = p_journey_date
            AND status = 'Waitlist'
            FOR UPDATE;

            INSERT INTO Reservations (
                passenger_id, 
                train_id, 
                journey_date, 
                status, 
                pnr_number,
                seat_number
            ) VALUES (
                p_passenger_id,
                v_train_id,
                p_journey_date,
                'Waitlist',
                v_pnr,
                CONCAT('WL-', v_waitlist_number)
            );

            SET p_reservation_id = LAST_INSERT_ID();
            SET p_status = 'Waitlist';
            SET p_coach_number = 'WL';
            SET p_seat_number = CONCAT('WL-', v_waitlist_number);
        END IF;
    END IF;

    -- Create payment record (using discounted amount)
    INSERT INTO Payments (
        reservation_id,
        amount,
        payment_method,
        payment_date
    ) VALUES (
        p_reservation_id,
        v_final_amount,
        p_payment_method,
        NOW()
    );

    SET p_payment_id = LAST_INSERT_ID();
    SET p_pnr_number = v_pnr;

    COMMIT;
END$$

DELIMITER ;



DELIMITER //
CREATE PROCEDURE fetch_trains_by_route_date(
    IN journey_date DATE,
    IN source_station VARCHAR(100),
    IN destination_station VARCHAR(100)
)
BEGIN
    SELECT 
        t.train_id,
        t.train_name,
        t.train_number,
        src.station_name AS source_station,
        dest.station_name AS destination_station,
        t.departure_time,
        t.arrival_time,
        t.travel_duration,
        ts.status AS train_status
    FROM 
        Trains t
    JOIN 
        Stations src ON t.source_station_id = src.station_id
    JOIN 
        Stations dest ON t.destination_station_id = dest.station_id
    JOIN 
        Train_runs ts ON t.train_id = ts.train_id
    WHERE 
        ts.journey_date = journey_date
        AND src.station_name = source_station
        AND dest.station_name = destination_station;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_train_coach_seat_availability(
    IN train_id_param INT,
    IN journey_date_param DATE
)
BEGIN
    -- Get train details
    SELECT 
        t.train_id,
        t.train_name,
        t.train_number,
        src.station_name AS source_station,
        dest.station_name AS destination_station,
        t.departure_time,
        t.arrival_time
    FROM 
        Trains t
    JOIN 
        Stations src ON t.source_station_id = src.station_id
    JOIN 
        Stations dest ON t.destination_station_id = dest.station_id
    WHERE 
        t.train_id = train_id_param;
    
    -- Get coach-wise availability with calculated available seats
    SELECT 
        c.coach_id,
        c.coach_type,
        c.total_seats,
        SUM(CASE WHEN sa.is_booked = 1 THEN 1 ELSE 0 END) AS booked_seats,
        (c.total_seats - SUM(CASE WHEN sa.is_booked = 1 THEN 1 ELSE 0 END)) AS available_seats,
        MIN(s.price) AS min_price,
        MAX(s.price) AS max_price
    FROM 
        Coaches c
    JOIN 
        Seats s ON c.coach_id = s.coach_id
    LEFT JOIN 
        Train_Runs tr ON tr.train_id = c.train_id AND tr.journey_date = journey_date_param
    LEFT JOIN 
        Seat_Availability sa ON sa.seat_id = s.seat_id AND sa.run_id = tr.run_id
    WHERE 
        c.train_id = train_id_param
    GROUP BY 
        c.coach_id, c.coach_type, c.total_seats;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_coach_prices(IN train_id_param INT)
BEGIN
    SELECT 
        c.coach_type,
        ROUND(AVG(s.price), 2) AS avg_fare,
        COUNT(s.seat_id) AS total_seats
    FROM 
        Coaches c
    JOIN 
        Seats s ON c.coach_id = s.coach_id
    WHERE 
        c.train_id = train_id_param
    GROUP BY 
        c.coach_type
    ORDER BY
        CASE c.coach_type
            WHEN 'First Class' THEN 1
            WHEN 'AC 2-Tier' THEN 2
            WHEN 'AC 3-Tier' THEN 3
            WHEN 'Sleeper' THEN 4
            ELSE 5
        END;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_pnr_status(IN pnr_number_param VARCHAR(20))
BEGIN
    SELECT 
        r.reservation_id,
        r.pnr_number,
        t.train_name,
        t.train_number,
        src.station_name AS source_station,
        dest.station_name AS destination_station,
        r.journey_date,
        p.name AS passenger_name,
        p.age,
        p.gender,
        c.coach_type,
        s.seat_number,
        s.seat_type,
        r.status AS reservation_status,
        s.price AS fare,
        IFNULL(con.category_name, 'No Concession') AS concession_applied,
        IFNULL(con.discount_percentage, 0) AS discount_percentage,
        (s.price * (100 - IFNULL(con.discount_percentage, 0)) / 100) AS final_fare
    FROM 
        Reservations r
    JOIN 
        Passengers p ON r.passenger_id = p.passenger_id
    JOIN 
        Trains t ON r.train_id = t.train_id
    JOIN 
        Stations src ON t.source_station_id = src.station_id
    JOIN 
        Stations dest ON t.destination_station_id = dest.station_id
    LEFT JOIN 
        Coaches c ON r.coach_id = c.coach_id
    LEFT JOIN 
        Seats s ON r.seat_id = s.seat_id
    LEFT JOIN 
        Concessions con ON p.concession_id = con.concession_id
    WHERE 
        r.pnr_number = pnr_number_param;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_passengers_by_train(
    IN train_id_param INT,
    IN journey_date_param DATE
)
BEGIN
    SELECT 
        p.passenger_id,
        p.name,
        p.age,
        p.gender,
        p.phone,
        c.coach_type,
        s.seat_number,
        s.seat_type,
        r.status AS reservation_status,
        r.pnr_number
    FROM 
        Reservations r
    JOIN 
        Passengers p ON r.passenger_id = p.passenger_id
    JOIN 
        Coaches c ON r.coach_id = c.coach_id
    JOIN 
        Seats s ON r.seat_id = s.seat_id
    WHERE 
        r.train_id = train_id_param
        AND r.journey_date = journey_date_param
    ORDER BY 
        c.coach_type, s.seat_number;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_waitlisted_passengers_by_train(
    IN train_id_param INT,
    IN journey_date_param DATE
)
BEGIN
    SELECT 
        p.passenger_id,
        p.name,
        p.age,
        p.gender,
        p.phone,
        r.status AS reservation_status,
        r.pnr_number,
        r.reservation_id
    FROM 
        Reservations r
    JOIN 
        Passengers p ON r.passenger_id = p.passenger_id
    WHERE 
        r.train_id = train_id_param
        AND r.journey_date = journey_date_param
        AND r.status = 'Waitlist'
    ORDER BY 
        r.reservation_id; -- Earlier reservations get priority
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE fetch_cancellation_refunds(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT 
        SUM(c.refund_amount) AS total_refunds,
        COUNT(c.cancellation_id) AS total_cancellations
    FROM 
        cancellations c
    JOIN 
        Reservations r ON c.reservation_id = r.reservation_id
    WHERE 
        c.cancellation_date BETWEEN start_date AND end_date;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE calculate_revenue(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    DECLARE total_payments DECIMAL(12,2);
    DECLARE total_refunds DECIMAL(12,2);
    DECLARE net_revenue DECIMAL(12,2);
    
    -- Calculate total payments
    SELECT IFNULL(SUM(amount), 0) INTO total_payments
    FROM Payments
    WHERE payment_date BETWEEN start_date AND end_date;
    
    -- Calculate total refunds from cancellations
    SELECT IFNULL(SUM(refund_amount), 0) INTO total_refunds
    FROM cancellations
    WHERE cancellation_date BETWEEN start_date AND end_date;
    
    -- Calculate net revenue
    SET net_revenue = total_payments - total_refunds;
    
    -- Return results
    SELECT 
        total_payments AS total_payments,
        total_refunds AS total_refunds,
        net_revenue AS net_revenue;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE process_cancellation(IN reservation_id_param INT)
BEGIN
    DECLARE train_id_val INT;
    DECLARE journey_date_val DATE;
    DECLARE coach_id_val INT;
    DECLARE seat_id_val INT;
    DECLARE pnr_val VARCHAR(20);
    DECLARE passenger_id_val INT;
    DECLARE seat_price_val DECIMAL(10,2);
    DECLARE current_status VARCHAR(20);
    
    -- Start transaction
    START TRANSACTION;
    
    -- Get reservation details with validation
    SELECT 
        r.train_id, r.journey_date, r.coach_id, r.seat_id, 
        r.pnr_number, r.passenger_id, s.price, r.status
    INTO 
        train_id_val, journey_date_val, coach_id_val, 
        seat_id_val, pnr_val, passenger_id_val, seat_price_val, current_status
    FROM 
        Reservations r
    JOIN 
        Seats s ON r.seat_id = s.seat_id
    WHERE 
        r.reservation_id = reservation_id_param;
    
    -- Validate reservation exists
    IF train_id_val IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Reservation not found';
    END IF;
    
    -- Validate status is cancellable
    IF current_status NOT IN ('Confirmed', 'RAC') THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Only Confirmed or RAC tickets can be cancelled';
    END IF;
    
    -- Validate seat price exists
    IF seat_price_val IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot determine refund amount - seat price not found';
    END IF;
    
    -- 1. Mark seat as available in Seat_Availability
    UPDATE Seat_Availability sa
    JOIN Train_Runs tr ON sa.run_id = tr.run_id
    SET sa.is_booked = 0, sa.booking_id = NULL
    WHERE sa.seat_id = seat_id_val
    AND tr.train_id = train_id_val
    AND tr.journey_date = journey_date_val;
    
    -- 2. Update the reservation status to Cancelled (matching ENUM)
    UPDATE Reservations
    SET status = 'Cancelled'
    WHERE reservation_id = reservation_id_param;
    
    -- 3. Add to cancellations table with proper ENUM value
    INSERT INTO cancellations (reservation_id, status, refund_amount, cancellation_date)
    VALUES (reservation_id_param, 'completed', seat_price_val, CURDATE());
    
    -- 4. Process RAC upgrades only if this was a confirmed seat
    IF current_status = 'Confirmed' THEN
        -- Upgrade oldest RAC to Confirmed
        UPDATE Reservations r
        JOIN (
            SELECT r1.reservation_id
            FROM Reservations r1
            WHERE r1.train_id = train_id_val
            AND r1.journey_date = journey_date_val
            AND r1.status = 'RAC'
            ORDER BY r1.reservation_id ASC
            LIMIT 1
        ) rac_to_upgrade ON r.reservation_id = rac_to_upgrade.reservation_id
        SET 
            r.status = 'Confirmed',
            r.coach_id = coach_id_val,
            r.seat_id = seat_id_val;
        
        -- If RAC was upgraded, promote oldest Waitlist to RAC
        IF ROW_COUNT() > 0 THEN
            UPDATE Reservations r
            JOIN (
                SELECT r1.reservation_id
                FROM Reservations r1
                WHERE r1.train_id = train_id_val
                AND r1.journey_date = journey_date_val
                AND r1.status = 'Waitlist'
                ORDER BY r1.reservation_id ASC
                LIMIT 1
            ) wl_to_upgrade ON r.reservation_id = wl_to_upgrade.reservation_id
            SET r.status = 'RAC';
            
            -- Update Seat_Availability for newly confirmed passenger
            UPDATE Seat_Availability sa
            JOIN Train_Runs tr ON sa.run_id = tr.run_id
            JOIN Reservations r ON sa.seat_id = r.seat_id
            SET sa.is_booked = 1, sa.booking_id = r.reservation_id
            WHERE tr.train_id = train_id_val
            AND tr.journey_date = journey_date_val
            AND r.reservation_id IN (
                SELECT reservation_id 
                FROM Reservations 
                WHERE train_id = train_id_val
                AND journey_date = journey_date_val
                AND status = 'Confirmed'
                AND reservation_id > reservation_id_param
            );
        END IF;
    END IF;
    
    -- Commit transaction
    COMMIT;
    
    -- Return success message
    SELECT CONCAT('Cancellation processed for PNR: ', pnr_val, 
                  '. Refund amount: ₹', seat_price_val) AS message;
END //
DELIMITER ;


DELIMITER //

CREATE PROCEDURE CancelReservation(
    IN p_reservation_id INT
)
BEGIN
    DECLARE v_train_id INT;
    DECLARE v_run_id INT;
    DECLARE v_status ENUM('Confirmed', 'RAC', 'Waitlist');
    DECLARE v_seat_id INT;
    DECLARE v_coach_id INT;
    DECLARE v_journey_date DATE;
    DECLARE v_refund_amount INT DEFAULT 0;
    DECLARE v_seat_number VARCHAR(10);

    -- Check if reservation exists and is not already cancelled
    SELECT r.train_id, r.status, r.seat_id, r.coach_id, r.journey_date
    INTO v_train_id, v_status, v_seat_id, v_coach_id, v_journey_date
    FROM Reservations r
    WHERE r.reservation_id = p_reservation_id
      AND r.status != 'Cancel'
    FOR UPDATE;

    IF v_train_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation not found or already cancelled';
    END IF;

    -- Get run_id for the journey
    SELECT run_id INTO v_run_id
    FROM Train_Runs
    WHERE train_id = v_train_id AND journey_date = v_journey_date
    FOR UPDATE;

    -- Update reservation status to Cancel
    UPDATE Reservations
    SET status = 'Cancel'
    WHERE reservation_id = p_reservation_id;

    -- Release seat if was confirmed
    IF v_status = 'Confirmed' THEN
        UPDATE Seat_Availability
        SET is_booked = 0, booking_id = NULL
        WHERE seat_id = v_seat_id AND run_id = v_run_id;

        UPDATE Seats
        SET status = 'Available'
        WHERE seat_id = v_seat_id;

        -- Promote RAC to Confirmed
        UPDATE Reservations r
        JOIN (
            SELECT reservation_id
            FROM Reservations
            WHERE train_id = v_train_id AND journey_date = v_journey_date AND status = 'RAC'
            ORDER BY reservation_id ASC
            LIMIT 1
        ) rac ON r.reservation_id = rac.reservation_id
        SET r.status = 'Confirmed', r.seat_id = v_seat_id, r.coach_id = v_coach_id;

        -- Update seat availability for RAC promoted
        UPDATE Seat_Availability
        SET is_booked = 1, booking_id = rac.reservation_id
        WHERE seat_id = v_seat_id AND run_id = v_run_id;

        UPDATE Seats
        SET status = 'Booked'
        WHERE seat_id = v_seat_id;

        -- Shift RAC up from Waitlist
        UPDATE Reservations r
        JOIN (
            SELECT reservation_id
            FROM Reservations
            WHERE train_id = v_train_id AND journey_date = v_journey_date AND status = 'Waitlist'
            
            LIMIT 1
        ) wl ON r.reservation_id = wl.reservation_id
        SET r.status = 'RAC', r.coach_id = NULL, r.seat_id = NULL;
    ELSEIF v_status = 'RAC' THEN
        -- Shift RAC up from Waitlist
        UPDATE Reservations r
        JOIN (
            SELECT reservation_id
            FROM Reservations
            WHERE train_id = v_train_id AND journey_date = v_journey_date AND status = 'Waitlist'
            
            LIMIT 1
        ) wl ON r.reservation_id = wl.reservation_id
        SET r.status = 'RAC';
    END IF;

    -- Refund logic
    IF v_status = 'Confirmed' THEN
        SET v_refund_amount = 2500;
    ELSEIF v_status = 'RAC' THEN
        SET v_refund_amount = 2600;
    ELSE
        SET v_refund_amount = 2700;
    END IF;

    -- Insert into cancellations table
    INSERT INTO cancellations (
        reservation_id,
        status,
        refund_amount,
        cancellation_date
    ) VALUES (
        p_reservation_id,
        'completed',
        v_refund_amount,
        CURDATE()
    );
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE VerifyPassengerByEmail(
    IN p_email VARCHAR(100),
    OUT p_passenger_id INT,
    OUT p_name VARCHAR(100),
    OUT p_exists BOOLEAN
)
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count
    FROM Passengers
    WHERE email = p_email;
    
    IF v_count > 0 THEN
        -- Passenger exists, return details
        SELECT passenger_id, name INTO p_passenger_id, p_name
        FROM Passengers
        WHERE email = p_email
        LIMIT 1;
        
        SET p_exists = TRUE;
    ELSE
        -- Passenger doesn't exist
        SET p_passenger_id = NULL;
        SET p_name = NULL;
        SET p_exists = FALSE;
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE ShowStations()
BEGIN
    SELECT station_name FROM stations ORDER BY station_name;
END //

DELIMITER ;
