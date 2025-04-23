-- --	PNR status tracking for a given ticket.
-- --	Train schedule lookup for a given train.
-- --	Available seats query for a specific train, date and class.
-- --	List all passengers traveling on a specific train on a given date.
-- --	Retrieve all waitlisted passengers for a particular train.
-- --	Find total amount that needs to be refunded for cancelling a train.
-- --	Total revenue generated from ticket bookings over a specified period.
-- --	Cancellation records with refund status.
-- --	Find the busiest route based on passenger count.
-- --	Generate an itemized bill for a ticket including all charges.





-- 1. PNR Status Tracking for a Given Ticket


DELIMITER //
CREATE PROCEDURE GetPNRStatus(IN pnr VARCHAR(20)) BEGIN
SELECT r.pnr_number, r.status, p.name AS passenger_name, t.train_name, r.journey_date
FROM reservations r
JOIN passengers p ON r.passenger_id = p.passenger_id JOIN trains t ON r.train_id = t.train_id
WHERE r.pnr_number = pnr; END //
DELIMITER ;
-- 2. Train Schedule Lookup for a Given Train
 
DELIMITER //
CREATE PROCEDURE GetTrainSchedule(IN trainNo VARCHAR(20)) BEGIN
SELECT ts.journey_date, ts.status FROM trains t
JOIN train_schedule ts ON t.train_id = ts.train_id WHERE t.train_number = trainNo;
END //
DELIMITER ;
-- 3. Available Seats Query


DELIMITER //
CREATE PROCEDURE GetAvailableSeats(IN trainId INT, IN journeyDate DATE, IN coachType VARCHAR(50))
BEGIN
SELECT s.seat_number, c.coach_id, s.seat_type, s.price FROM seats s
JOIN coaches c ON s.coach_id = c.coach_id
JOIN train_runs tr ON tr.train_id = trainId AND tr.journey_date = journeyDate JOIN seat_availability sa ON sa.seat_id = s.seat_id AND sa.run_id = tr.run_id
WHERE c.train_id = trainId AND c.coach_type = coachType AND sa.is_booked
= 0;
END //
DELIMITER ;
-- 4. List All Passengers on a Train for a Specific Date
 
DELIMITER //
CREATE PROCEDURE GetPassengersOnTrain(IN trainId INT, IN journeyDate DATE)
BEGIN
SELECT p.name, p.age, p.gender, r.coach_id, r.seat_id FROM reservations r
JOIN passengers p ON r.passenger_id = p.passenger_id
WHERE r.train_id = trainId AND r.journey_date = journeyDate AND r.status = 'Confirmed';
END //
DELIMITER ;
-- 5. Retrieve Waitlisted Passengers


DELIMITER //
CREATE PROCEDURE GetWaitlistedPassengers(IN trainId INT, IN journeyDate DATE)
BEGIN
SELECT p.name, w.pnr_number, w.status FROM waitlist w
JOIN passengers p ON w.passenger_id = p.passenger_id
WHERE w.train_id = trainId AND w.journey_date = journeyDate AND w.status
= 'Waitlist';
END //
DELIMITER ;
-- 6. Total Refund Amount for Cancelling a Train


DELIMITER //
 
CREATE PROCEDURE GetTotalRefundForCancelledTrain(IN trainId INT) BEGIN
SELECT SUM(c.refund_amount) AS total_refund FROM cancellations c
JOIN reservations r ON c.reservation_id = r.reservation_id WHERE r.train_id = trainId;
END //
DELIMITER ;
-- 7. Total Revenue Generated Over a Period


DELIMITER //
CREATE PROCEDURE GetRevenue(IN startDate DATE, IN endDate DATE) BEGIN
SELECT SUM(amount) AS total_revenue FROM payments
WHERE payment_date BETWEEN startDate AND endDate; END //
DELIMITER ;
-- 8. Cancellation Records with Refund Status


DELIMITER //
CREATE PROCEDURE GetCancellationRecords() BEGIN
SELECT c.cancellation_id, c.cancellation_date, c.refund_amount, c.status, r.pnr_number
FROM cancellations c
JOIN reservations r ON c.reservation_id = r.reservation_id;
 
END //
DELIMITER ;
-- 9. Find the Busiest Route Based on Passenger Count


DELIMITER //
CREATE PROCEDURE GetBusiestRoute() BEGIN
SELECT s1.station_name AS source, s2.station_name AS destination, COUNT(r.reservation_id) AS passenger_count
FROM reservations r
JOIN trains t ON r.train_id = t.train_id
JOIN stations s1 ON t.source_station_id = s1.station_id JOIN stations s2 ON t.destination_station_id = s2.station_id GROUP BY t.source_station_id, t.destination_station_id ORDER BY passenger_count DESC
LIMIT 1;
END //
DELIMITER ;


-- 10. Generate an Itemized Bill for a Ticket


DELIMITER //
CREATE PROCEDURE GenerateItemizedBill(IN reservationId INT) BEGIN
SELECT r.pnr_number, p.name AS passenger_name, s.price, pay.amount, pay.payment_method, pay.payment_date
FROM reservations r
 
JOIN passengers p ON r.passenger_id = p.passenger_id JOIN seats s ON r.seat_id = s.seat_id
JOIN payments pay ON r.reservation_id = pay.reservation_id WHERE r.reservation_id = reservationId;
END //
DELIMITER ;
