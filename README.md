ER Diagram And UI

https://drive.google.com/drive/folders/1PQJPzJa6TFCasgqor3p2BXKrjpbr8ZU1?usp=drive_link
From Above link You can access the EER Diagram > IR Project EER2.mwb
How to Run This Project
Method 1: Using SQL File Loading
Step 1: Load SQL Files into MySQL Workbench

-	Download the required SQL files from the following Google Drive link:

https://drive.google.com/drive/folders/1PQJPzJa6TFCasgqor3p2BXKrjpbr8ZU1? usp=drive_link

-	Load the following files in MySQL Workbench:
-	Create_table.sql
-	Create_procedure.sql
-	Data.sql

Step 2: Execute SQL Files

-	After loading, run the files in the following order:
1.	Create_table.sql
2.	Create_procedure.sql
3.	Data.sql

Step 3: Run the Dashboard Application

-	If you want to use the dashboard, proceed with this step:
-	Download main.py from the same Google Drive link above.
-	Open the file in Visual Studio Code (VS Code).
-	Open a terminal in VS Code and install the required Python packages by running:
pip install tk
pip install mysql-connector-python
-	Important: Update the MySQL password in main.py to your MySQL root password.
-	Run the application using: python main.py
 
-	Do not use python3 main.py.

Step 4: View Procedures and Queries

-	To explore stored procedures and SQL queries manually, run them directly in MySQL Workbench.

Method 2: Using PDF Files
Step 1: Copy and Execute SQL from PDFs

-	Download the PDF files from the following link:

https://drive.google.com/drive/folders/1cFGGwHLpxu6NrPK4yJNdn1tl1PQdVXj S?usp=drive_link

-	Open each of the following PDFs:
-	Create_table.pdf
-	Create_procedure.pdf
-	Data.pdf
-	Copy the SQL code from each file and paste it into the MySQL terminal.
-	Execute the queries in the following order:
1.	Table creation queries
2.	Stored procedures
3.	Data insertion queries



Railway Management Procedures
Note : Use this data for testing the UI Example : Source – Hyderabad deccan Destination – Howrah junction
Date – 2025-04-30
 
Passenger Procedures
1.	CreatePassenger – Creates a new passenger; returns passenger_id.
Inputs: name, email, phone, age, gender, concession category (optional)
2.	VerifyPassengerByEmail – Checks passenger existence by email.
Inputs: email → Outputs: passenger_id, name, exists (true/false)

Station & Train Procedures
3.	AddStation – Adds a station; returns station_id.
Inputs: station name, city
4.	AddTrain – Adds a train; returns train_id.
Inputs: train name, number, source & destination stations, schedule
5.	AddWeeklySchedules – Schedules a train across weeks.
Inputs: train number, start date, number of weeks, days of week
6.	GenerateTrainRuns – Initializes runs with "Scheduled" status.
Inputs: start date, end date

Coach & Seat Management
7.	AddCoachToTrain – Adds a coach to train; returns coach_id.
Inputs: train number, coach type, seat count
8.	AddSeatsToCoach – Adds sequential seats to coach.
Inputs: coach ID, seat prefix, count, type, price
9.	UpdateSeatAvailability – Books or releases seat.
Inputs: run ID, seat ID, status (booked/available), booking ID

Reservation & Booking
10.	CreateReservation – Books a journey; returns full details.
Inputs: passenger/train/journey/payment info
→ Outputs: reservation_id, PNR, status, seats, payment_id
11.	fetch_trains_by_route_date – Finds trains on route/date.
Inputs: journey date, source, destination
 
12.	fetch_train_coach_seat_availability – Shows seat stats per coach.
Inputs: train ID, journey date
13.	fetch_coach_prices – Shows fare info per coach type.
Inputs: train ID
14.	fetch_pnr_status – Gets reservation details by PNR.
Inputs: PNR

Passenger Info
15.	fetch_passengers_by_train – Lists passengers on a run.
Inputs: train ID, journey date
16.	fetch_waitlisted_passengers_by_train – Lists waitlisted passengers.
Inputs: train ID, journey date

Cancellation & Refunds
17.	process_cancellation / 18. CancelReservation – Cancels tickets and handles refunds.
Inputs: reservation ID
19.	fetch_cancellation_refunds – Shows cancellation/refund stats.
Inputs: date range

Financial & Utility
20.	calculate_revenue – Computes total revenue and refunds.
Inputs: start and end dates
21.	ShowStations – Lists all stations alphabetically.
Inputs: None







Potential Queries
 
--	PNR status tracking for a given ticket.
--	Train schedule lookup for a given train.
--	Available seats query for a specific train, date and class.
--	List all passengers traveling on a specific train on a given date.
--	Retrieve all waitlisted passengers for a particular train.
--	Find total amount that needs to be refunded for cancelling a train.
--	Total revenue generated from ticket bookings over a specified period.
--	Cancellation records with refund status.
--	Find the busiest route based on passenger count.
--	Generate an itemized bill for a ticket including all charges.




The Above Query are in testQuery.sql file in Project link
https://drive.google.com/file/d/127C3RymjYA0w9NmDlM677ZsgzNagIh-W/view?usp=drive_link
