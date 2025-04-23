INSERT INTO Concessions (category_name, discount_percentage) VALUES
	('Senior Citizen (Male)', 40.00),
	('Senior Citizen (Female)', 50.00),
	('Children (5-12 years)', 50.00),
	('Student', 50.00),
	('Disabled Person', 75.00),
	('Armed Forces', 75.00),
	('Railway Employee', 50.00);


	INSERT INTO Passengers (name, email, phone, age, gender, concession_id) VALUES
	('Aarav Gupta', 'aarav.g@example.com', '917788991122', 65, 'M', 
	  (SELECT concession_id FROM Concessions WHERE category_name = 'Senior Citizen (Male)')),
	('Ananya Singh', 'ananya.s@example.com', '916655443322', 22, 'F', 
	  (SELECT concession_id FROM Concessions WHERE category_name = 'Student')),
	('Vihaan Reddy', 'vihaan.r@example.com', '914433221100', 8, 'M', 
	  (SELECT concession_id FROM Concessions WHERE category_name = 'Children (5-12 years)')),
	('Ishaan Kumar', 'ishaan.k@example.com', '912233445566', 42, 'M', NULL);


	INSERT INTO Stations (station_name, city) VALUES
	('New Delhi', 'Delhi'),
	('Chandigarh Junction', 'Chandigarh'),
	('Amritsar Junction', 'Amritsar'),
	('Lucknow Junction', 'Lucknow'),
	('Kanpur Central', 'Kanpur'),
	('Mumbai Central', 'Mumbai'),
	('Ahmedabad Junction', 'Ahmedabad'),
	('Jaipur Junction', 'Jaipur'),
	('Pune Junction', 'Pune'),
	('Surat', 'Surat'),
	('Chennai Central', 'Chennai'),
	('Bengaluru City Junction', 'Bengaluru'),
	('Hyderabad Deccan', 'Hyderabad'),
	('Coimbatore Junction', 'Coimbatore'),
	('Kochi (Ernakulam)', 'Kochi'),
	('Howrah Junction', 'Kolkata'),
	('Patna Junction', 'Patna'),
	('Guwahati', 'Guwahati'),
	('Bhubaneswar', 'Bhubaneswar'),
	('Ranchi Junction', 'Ranchi'),
	('Bhopal Junction', 'Bhopal'),
	('Nagpur Junction', 'Nagpur'),
	('Jabalpur', 'Jabalpur'),
	('Raipur Junction', 'Raipur'),
	('Varanasi Junction', 'Varanasi');



	INSERT INTO Trains (train_name, train_number, source_station_id, destination_station_id, departure_time, arrival_time, travel_duration) VALUES

	('Mumbai Rajdhani', '12951', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Mumbai Central'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'New Delhi'),
	  '17:35:00', '08:15:00', '14:40:00'),
	('Howrah Rajdhani', '12301', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Howrah Junction'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'New Delhi'),
	  '16:55:00', '10:05:00', '17:10:00'),
	('Chennai Shatabdi', '12007', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Chennai Central'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'Bengaluru City Junction'),
	  '06:00:00', '11:00:00', '05:00:00'),
	('Bhopal Shatabdi', '12001', 
	  (SELECT station_id FROM Stations WHERE station_name = 'New Delhi'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'Bhopal Junction'),
	  '06:00:00', '12:35:00', '06:35:00'),
	('Pune Duronto', '12261', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Mumbai Central'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'Pune Junction'),
	  '22:30:00', '03:00:00', '04:30:00'),
	('Ahmedabad Duronto', '12267', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Mumbai Central'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'Ahmedabad Junction'),
	  '23:25:00', '06:40:00', '07:15:00'),
	('Jaipur Garib Rath', '12985', 
	  (SELECT station_id FROM Stations WHERE station_name = 'Mumbai Central'), 
	  (SELECT station_id FROM Stations WHERE station_name = 'Jaipur Junction'),
	  '21:05:00', '12:30:00', '15:25:00');
	  
	-- ADD train procedure to add trains 
	CALL AddTrain('Hyderabad Express', '12723', 'Hyderabad Deccan', 'Howrah Junction', '18:25:00', '08:10:00', @train_id);
	CALL AddTrain('Delhi Duronto', '12266', 'Kochi (Ernakulam)', 'New Delhi', '19:00:00', '10:45:00', @train_id);
	CALL AddTrain('Bangalore Rajdhani', '22691', 'Bengaluru City Junction', 'New Delhi', '20:20:00', '10:30:00', @train_id);
	CALL AddTrain('Kolkata Shatabdi', '12019', 'Howrah Junction', 'Patna Junction', '06:10:00', '12:30:00', @train_id);
	CALL AddTrain('Patna Jan Shatabdi', '12023', 'Patna Junction', 'Varanasi Junction', '14:15:00', '19:45:00', @train_id);
	CALL AddTrain('Lucknow Superfast', '12531', 'Lucknow Junction', 'Guwahati', '16:00:00', '08:00:00', @train_id);
	CALL AddTrain('Chandigarh Intercity', '12411', 'Chandigarh Junction', 'New Delhi', '07:15:00', '11:25:00', @train_id);
	CALL AddTrain('Coimbatore Express', '12683', 'Coimbatore Junction', 'Chennai Central', '22:45:00', '06:55:00', @train_id);
	CALL AddTrain('Ahmedabad Express', '19415', 'Ahmedabad Junction', 'Kanpur Central', '05:50:00', '14:10:00', @train_id);
	CALL AddTrain('Surat Intercity', '12935', 'Surat', 'Mumbai Central', '18:40:00', '21:00:00', @train_id);


	-- coaches added to trains and also the seats are added to seats table
	CALL AddCoachToTrain('12723', 'AC 3-Tier', 72, @p_coach_id);
	CALL AddCoachToTrain('12266', 'AC 2-Tier', 48, @p_coach_id);
	CALL AddCoachToTrain('22691', 'Sleeper', 72, @p_coach_id);
	CALL AddCoachToTrain('12019', 'AC 2-Tier', 48, @p_coach_id);
	CALL AddCoachToTrain('12023', 'AC 3-Tier', 72, @p_coach_id);
	CALL AddCoachToTrain('12531', 'Sleeper', 72, @p_coach_id);
	CALL AddCoachToTrain('12411', 'First Class', 24, @p_coach_id);
	CALL AddCoachToTrain('12683', 'AC 2-Tier', 48, @p_coach_id);
	CALL AddCoachToTrain('19415', 'AC 3-Tier', 72, @p_coach_id);
	CALL AddCoachToTrain('12935', 'AC 3-Tier', 72, @p_coach_id);


	-- add seats to coachs
	-- CALL AddSeatsToCoach(45, 'S45', 24, 'Upper', 300.00);
	-- CALL AddSeatsToCoach(45, 'S45', 24, 'Middle', 300.00);
	-- CALL AddSeatsToCoach(45, 'S45', 24, 'Lower', 300.00);
	CALL AddSeatsToCoach(1, 'A47', 24, 'Upper', 1000.00);
	CALL AddSeatsToCoach(2, 'A47', 24, 'Lower', 1000.00);
	CALL AddSeatsToCoach(3, 'B48', 24, 'Upper', 750.00);
	CALL AddSeatsToCoach(3, 'B48', 24, 'Middle', 750.00);
	CALL AddSeatsToCoach(3, 'B48', 24, 'Lower', 750.00);
	CALL AddSeatsToCoach(3, 'B49', 24, 'Upper', 750.00);
	CALL AddSeatsToCoach(3, 'B49', 24, 'Middle', 750.00);
	CALL AddSeatsToCoach(3, 'B49', 24, 'Lower', 750.00);


	-- adding schedule for trains
	CALL AddWeeklySchedules('12723', '2025-04-15', 4, '2,4,6');
	CALL AddWeeklySchedules('12266', '2025-04-15', 4, '1,3,5');
	CALL AddWeeklySchedules('22691', '2025-04-15', 4, '1,7');
	CALL AddWeeklySchedules('12019', '2025-04-15', 4, '2,3,5');
	CALL AddWeeklySchedules('12023', '2025-04-15', 4, '1,4');
	CALL AddWeeklySchedules('12531', '2025-04-15', 4, '6,7');
	CALL AddWeeklySchedules('12411', '2025-04-15', 4, '3,5');
	CALL AddWeeklySchedules('12683', '2025-04-15', 4, '2,4');
	CALL AddWeeklySchedules('19415', '2025-04-15', 4, '1,6');
	CALL AddWeeklySchedules('12935', '2025-04-15', 4, '3,5,7');

	SET SQL_SAFE_UPDATES = 0;

	-- to add seats in seat_availibility
	CALL GenerateTrainRuns('2025-04-15', '2025-06-30');