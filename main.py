import mysql.connector
import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime, timedelta

class RailwayReservationSystem:
    def __init__(self, root):
        self.root = root
        self.root.title("Railway Reservation System")
        self.root.geometry("1000x700")
        
        # Database connection
        self.conn = None
        self.cursor = None
        self.connect_db()
        
        # Current user data
        self.current_passenger_id = None
        self.current_reservation_data = None
        self.pnr=None
        
        # Create main container
        self.main_frame = tk.Frame(root)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Show login/registration screen initially
        self.show_passenger_screen()

    def connect_db(self):
        try:
            self.conn = mysql.connector.connect(
                host="localhost",
                port=3306,
                user="root",
                password="userrootPassword",
                database="railway12345"
            )
            self.cursor = self.conn.cursor()
        except Exception as e:
            messagebox.showerror("Database Error", f"Failed to connect to database: {e}")
            self.root.destroy()

    def clear_frame(self):
        for widget in self.main_frame.winfo_children():
            widget.destroy()

    def show_passenger_screen(self):
        self.clear_frame()
        
        # Passenger Login/Registration Frame
        passenger_frame = tk.LabelFrame(self.main_frame, text="Passenger Information", padx=10, pady=10)
        passenger_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)
        
        # Name
        tk.Label(passenger_frame, text="Full Name:").grid(row=0, column=0, sticky="e", padx=5, pady=5)
        self.name_entry = tk.Entry(passenger_frame, width=30)
        self.name_entry.grid(row=0, column=1, padx=5, pady=5)
        
        # Email
        tk.Label(passenger_frame, text="Email:").grid(row=1, column=0, sticky="e", padx=5, pady=5)
        self.email_entry = tk.Entry(passenger_frame, width=30)
        self.email_entry.grid(row=1, column=1, padx=5, pady=5)
        
        # Phone
        tk.Label(passenger_frame, text="Phone:").grid(row=2, column=0, sticky="e", padx=5, pady=5)
        self.phone_entry = tk.Entry(passenger_frame, width=30)
        self.phone_entry.grid(row=2, column=1, padx=5, pady=5)
        
        # Age
        tk.Label(passenger_frame, text="Age:").grid(row=3, column=0, sticky="e", padx=5, pady=5)
        self.age_entry = tk.Entry(passenger_frame, width=30)
        self.age_entry.grid(row=3, column=1, padx=5, pady=5)
        
        # Gender
        tk.Label(passenger_frame, text="Gender:").grid(row=4, column=0, sticky="e", padx=5, pady=5)
        self.gender_var = tk.StringVar(value="M")
        tk.Radiobutton(passenger_frame, text="Male", variable=self.gender_var, value="M").grid(row=4, column=1, sticky="w")
        tk.Radiobutton(passenger_frame, text="Female", variable=self.gender_var, value="F").grid(row=4, column=1, sticky="e")
        
        # Concession Category
        tk.Label(passenger_frame, text="Concession Category:").grid(row=5, column=0, sticky="e", padx=5, pady=5)
        self.concession_var = tk.StringVar()
        self.concession_combobox = ttk.Combobox(passenger_frame, textvariable=self.concession_var, 
                                              values=["None", "Senior Citizen", "Student", "Military"])
        self.concession_combobox.grid(row=5, column=1, padx=5, pady=5)
        self.concession_combobox.set("None")
        
        # Buttons
        button_frame = tk.Frame(passenger_frame)
        button_frame.grid(row=6, column=0, columnspan=2, pady=10)
        
        tk.Button(button_frame, text="Continue", command=self.process_passenger_info).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Exit", command=self.root.quit).pack(side=tk.LEFT, padx=5)

    def process_passenger_info(self):
        name = self.name_entry.get()
        email = self.email_entry.get()
        phone = self.phone_entry.get()
        age = self.age_entry.get()
        gender = self.gender_var.get()
        concession = self.concession_var.get() if self.concession_var.get() != "None" else None

        if not all([name, email, phone, age]):
            messagebox.showerror("Error", "Please fill all required fields")
            return

        try:
            age = int(age)
            if age <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Please enter a valid age")
            return

        try:
            # Step 1: Check if passenger already exists by email
            self.cursor.execute("SELECT passenger_id FROM Passengers WHERE email = %s", (email,))
            existing = self.cursor.fetchone()

            if existing:
                self.current_passenger_id = existing[0]
                print(f"Existing passenger found. ID: {self.current_passenger_id}")
            else:
                # Step 2: Create new passenger using stored procedure
                self.cursor.callproc('CreatePassenger', [
                    name, email, phone, age, gender, concession, 0
                ])
                print("Stored procedure called to create new passenger.")

                # Step 3: Fetch the new passenger_id after creation
                self.cursor.execute("SELECT passenger_id FROM Passengers WHERE email = %s", (email,))
                created = self.cursor.fetchone()

                if created:
                    self.current_passenger_id = created[0]
                    print(f"New passenger created. ID: {self.current_passenger_id}")
                else:
                    raise Exception("Passenger creation failed. No ID returned.")

            self.conn.commit()
            self.show_route_selection()

        except Exception as e:
            self.conn.rollback()
            print(f"Error processing passenger: {e}")
            messagebox.showerror("Error", f"Something went wrong: {e}")

    def show_route_selection(self):
        self.clear_frame()
        
        # Route Selection Frame
        route_frame = tk.LabelFrame(self.main_frame, text="Journey Details", padx=10, pady=10)
        route_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)
        
        # Source Station
        tk.Label(route_frame, text="From:").grid(row=0, column=0, sticky="e", padx=5, pady=5)
        self.source_var = tk.StringVar()
        self.source_combobox = ttk.Combobox(route_frame, textvariable=self.source_var, width=30)
        self.source_combobox.grid(row=0, column=1, padx=5, pady=5)
        
        # Destination Station
        tk.Label(route_frame, text="To:").grid(row=1, column=0, sticky="e", padx=5, pady=5)
        self.dest_var = tk.StringVar()
        self.dest_combobox = ttk.Combobox(route_frame, textvariable=self.dest_var, width=30)
        self.dest_combobox.grid(row=1, column=1, padx=5, pady=5)
        
        # Journey Date
        tk.Label(route_frame, text="Journey Date:").grid(row=2, column=0, sticky="e", padx=5, pady=5)
        self.date_entry = tk.Entry(route_frame, width=30)
        self.date_entry.grid(row=2, column=1, padx=5, pady=5)
        self.date_entry.insert(0, (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"))  # Default to tomorrow
        
        # Buttons
        button_frame = tk.Frame(route_frame)
        button_frame.grid(row=3, column=0, columnspan=2, pady=10)
        
        tk.Button(button_frame, text="Search Trains", command=self.search_trains).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Back", command=self.show_passenger_screen).pack(side=tk.LEFT, padx=5)

        # --- PNR Status Section ---
        pnr_frame = tk.LabelFrame(self.main_frame, text="Check PNR Status", padx=10, pady=10)
        pnr_frame.pack(padx=20, pady=10, fill=tk.X)

        tk.Label(pnr_frame, text="Enter PNR Number:").grid(row=0, column=0, padx=5, pady=5, sticky="e")
        self.pnr_var = tk.StringVar()
        pnr_entry = tk.Entry(pnr_frame, textvariable=self.pnr_var, width=30)
        pnr_entry.grid(row=0, column=1, padx=5, pady=5)

        tk.Button(pnr_frame, text="Show PNR Status", command=self.show_pnr_status).grid(row=0, column=2, padx=5, pady=5)
        # --- Available Seats Check Section ---
        available_seats_frame = tk.LabelFrame(self.main_frame, text="Check Available Seats", padx=10, pady=10)
        available_seats_frame.pack(padx=20, pady=10, fill=tk.X)

        tk.Label(available_seats_frame, text="Enter Train Number:").grid(row=0, column=0, padx=5, pady=5, sticky="e")
        self.train_number_var = tk.StringVar()
        train_number_entry = tk.Entry(available_seats_frame, textvariable=self.train_number_var, width=30)
        train_number_entry.grid(row=0, column=1, padx=5, pady=5)

        tk.Label(available_seats_frame, text="Journey Date:").grid(row=1, column=0, padx=5, pady=5, sticky="e")
        self.journey_date_var = tk.StringVar()
        journey_date_entry = tk.Entry(available_seats_frame, textvariable=self.journey_date_var, width=30)
        journey_date_entry.grid(row=1, column=1, padx=5, pady=5)

        tk.Label(available_seats_frame, text="Coach Type:").grid(row=2, column=0, padx=5, pady=5, sticky="e")
        self.coach_type_var = tk.StringVar()
        coach_type_combobox = ttk.Combobox(available_seats_frame, textvariable=self.coach_type_var, width=30)
        coach_type_combobox['values'] = ['Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'First Class']
        coach_type_combobox.grid(row=2, column=1, padx=5, pady=5)

        tk.Button(available_seats_frame, text="Check Available Seats", command=self.show_available_seats).grid(row=3, column=0, columnspan=2, pady=10)

        # Label to display available seats
        self.available_seats_label = tk.Label(available_seats_frame, text="", fg="green")
        self.available_seats_label.grid(row=4, column=0, columnspan=2, pady=10)


        # Populate stations
        try:
            self.cursor.callproc('ShowStations')
            for result in self.cursor.stored_results():
                stations = [row[0] for row in result.fetchall()]          
        except Exception as e:
            print("Error fetching stations:", e)
            stations = []

        self.source_combobox['values'] = stations
        self.dest_combobox['values'] = stations

    def show_available_seats(self):
        train_number = self.train_number_var.get().strip()
        journey_date = self.journey_date_var.get().strip()
        coach_type = self.coach_type_var.get().strip()

        if not train_number or not journey_date or not coach_type:
            messagebox.showerror("Error", "Please fill in all fields.")
            return

        try:
            # Query to get available seats
            query = """
            SELECT
                c.coach_type,
                COUNT(s.seat_id) AS available_seats
            FROM
                Train_Schedule ts
                JOIN Trains t ON ts.train_id = t.train_id
                JOIN Coaches c ON t.train_id = c.train_id
                JOIN Seats s ON c.coach_id = s.coach_id
                LEFT JOIN Seat_Availability sa ON s.seat_id = sa.seat_id AND sa.run_id = ts.schedule_id
            WHERE
                t.train_number = %s
                AND ts.journey_date = %s
                AND c.coach_type = %s
                AND (sa.is_booked = 0 OR sa.is_booked IS NULL)
            GROUP BY
                c.coach_type;
            """
            
            self.cursor.execute(query, (train_number, journey_date, coach_type))
            results = self.cursor.fetchall()

            if not results:
                self.available_seats_label.config(text="No available seats found for this route.")
            else:
                available_seats_text = "\n".join([f"{row[0]}: {row[1]} seats available" for row in results])
                self.available_seats_label.config(text=available_seats_text)
                
        except Exception as e:
            messagebox.showerror("Database Error", f"Something went wrong:\n{e}")


    def show_pnr_status(self):
        pnr = self.pnr_var.get().strip()
        if not pnr:
            messagebox.showerror("Error", "Please enter a PNR number.")
            return

        try:
            # Get the latest reservation for the PNR
            self.cursor.execute("""
                SELECT train_id, status, coach_id, journey_date, seat_id 
                FROM Reservations 
                WHERE pnr_number = %s 
                ORDER BY reservation_id DESC LIMIT 1
            """, (pnr,))
            reservation = self.cursor.fetchone()

            if not reservation:
                messagebox.showinfo("Not Found", f"No reservation found for PNR: {pnr}")
                return

            train_id, status, coach_id, journey_date, seat_id = reservation

            # Get coach type
            self.cursor.execute("SELECT coach_type FROM Coaches WHERE coach_id = %s", (coach_id,))
            coach_data = self.cursor.fetchone()
            coach_type = coach_data[0] if coach_data else "N/A"

            # Get seat number
            self.cursor.execute("SELECT seat_number FROM Seats WHERE seat_id = %s", (seat_id,))
            seat_data = self.cursor.fetchone()
            seat_number = seat_data[0] if seat_data else "N/A"

            # Create a new popup window
            pnr_window = tk.Toplevel(self.root)
            pnr_window.title(f"PNR Status: {pnr}")

            # Show booking details
            tk.Label(pnr_window, text=f"Train No: {train_id}").pack(anchor="w", padx=10, pady=5)
            tk.Label(pnr_window, text=f"Journey Date: {journey_date}").pack(anchor="w", padx=10)
            tk.Label(pnr_window, text=f"Class: {coach_type}").pack(anchor="w", padx=10)
            tk.Label(pnr_window, text=f"Seat No: {seat_number}").pack(anchor="w", padx=10)
            tk.Label(pnr_window, text=f"Booking Status: {status}").pack(anchor="w", padx=10, pady=5)

        except Exception as e:
            messagebox.showerror("Database Error", f"Something went wrong:\n{e}")




    def search_trains(self):
        source = self.source_var.get()
        dest = self.dest_var.get()
        journey_date = self.date_entry.get()
        
        if not all([source, dest, journey_date]):
            messagebox.showerror("Error", "Please fill all fields")
            return
        
        if source == dest:
            messagebox.showerror("Error", "Source and destination cannot be same")
            return
        
        try:
            # Call fetch_trains_by_route_date procedure
            self.cursor.callproc('fetch_trains_by_route_date', [journey_date, source, dest])
            
            # Get results
            trains = []
            for result in self.cursor.stored_results():
                trains = result.fetchall()
            
            if not trains:
                messagebox.showinfo("No Trains", "No trains found for this route and date")
                return
            
            self.show_train_selection(trains, journey_date, source, dest)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to search trains: {e}")

    def show_train_selection(self, trains, journey_date, source, dest):
        self.clear_frame()
        
        # Store journey info for later use
        self.current_journey_info = {
            'date': journey_date,
            'source': source,
            'dest': dest
        }
        
        # Train Selection Frame
        train_frame = tk.LabelFrame(self.main_frame, text="Available Trains", padx=10, pady=10)
        train_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)
        
        # Treeview for trains
        columns = ("Train No", "Train Name", "Departure", "Arrival", "Duration")
        self.train_tree = ttk.Treeview(train_frame, columns=columns, show="headings", selectmode="browse")
        
        for col in columns:
            self.train_tree.heading(col, text=col)
            self.train_tree.column(col, width=150, anchor="center")
        
        self.train_tree.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Add trains to treeview
        for train in trains:
            self.train_tree.insert("", "end", values=(
                train[2],  # train_number
                train[1],  # train_name
                str(train[5]),  # departure_time
                str(train[6]),  # arrival_time
                str(train[7])  # travel_duration
            ))
        
        # Buttons
        button_frame = tk.Frame(train_frame)
        button_frame.pack(pady=10)
        
        tk.Button(button_frame, text="Select Train", command=self.select_train).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Back", command=self.show_route_selection).pack(side=tk.LEFT, padx=5)

    def select_train(self):
        selected_item = self.train_tree.focus()
        if not selected_item:
            messagebox.showerror("Error", "Please select a train")
            return
        
        train_data = self.train_tree.item(selected_item)['values']
        train_number = train_data[0]
        
        # Store selected train info
        self.current_journey_info['train_number'] = train_number
        
        # Get coach availability for this train
        try:
            # First get train_id from train_number
            self.cursor.execute("SELECT train_id FROM Trains WHERE train_number = %s", (train_number,))
            train_id = self.cursor.fetchone()[0]
            
            # Call fetch_train_coach_seat_availability procedure
            self.cursor.callproc('fetch_train_coach_seat_availability', [
                train_id, 
                self.current_journey_info['date']
            ])
            
            # Get results (multiple result sets)
            coach_availability = []
            for result in self.cursor.stored_results():
                if result.description[0][0] == 'train_id':  # First result is train details
                    train_details = result.fetchone()
                else:  # Second result is coach availability
                    coach_availability = result.fetchall()
            
            if not coach_availability:
                messagebox.showinfo("No Coaches", "No coach data available for this train")
                return
            
            self.show_coach_selection(train_details, coach_availability)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to get coach availability: {e}")

    def show_coach_selection(self, train_details, coach_availability):
        self.clear_frame()
        
        # Coach Selection Frame
        coach_frame = tk.LabelFrame(self.main_frame, text="Select Coach Type", padx=10, pady=10)
        coach_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)
        
        # Train info
        tk.Label(coach_frame, text=f"Train: {train_details[1]} ({train_details[2]})").pack(anchor="w", pady=5)
        tk.Label(coach_frame, text=f"Date: {self.current_journey_info['date']}").pack(anchor="w", pady=5)
        tk.Label(coach_frame, 
                text=f"Route: {self.current_journey_info['source']} to {self.current_journey_info['dest']}").pack(anchor="w", pady=5)
        
        # Separator
        ttk.Separator(coach_frame, orient='horizontal').pack(fill='x', pady=10)
        
        # Treeview for coaches
        columns = ("Coach Type", "Total Seats", "Available", "Min Price", "Max Price")
        self.coach_tree = ttk.Treeview(coach_frame, columns=columns, show="headings", selectmode="browse")
        
        for col in columns:
            self.coach_tree.heading(col, text=col)
            self.coach_tree.column(col, width=120, anchor="center")
        
        self.coach_tree.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Add coaches to treeview
        for coach in coach_availability:
            self.coach_tree.insert("", "end", values=(
                coach[1],  # coach_type
                coach[2],  # total_seats
                coach[4],  # available_seats
                coach[5],  # min_price
                coach[6]   # max_price
            ))
        
        # Buttons
        button_frame = tk.Frame(coach_frame)
        button_frame.pack(pady=10)
        
        tk.Button(button_frame, text="Select Coach", command=self.select_coach).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Back", command=self.show_route_selection).pack(side=tk.LEFT, padx=5)

    def select_coach(self):
        selected_item = self.coach_tree.focus()
        if not selected_item:
            messagebox.showerror("Error", "Please select a coach type")
            return
        
        coach_data = self.coach_tree.item(selected_item)['values']
        coach_type = coach_data[0]
        available_seats = coach_data[2]
        
        if available_seats <= 0:
            messagebox.showinfo("No Seats", "No seats available in this coach type")
            return
        

        # Store selected coach info
        self.current_journey_info['coach_type'] = coach_type
        
        # Proceed to payment
        self.show_payment_screen(coach_data[3])  # Using min price as base fare

    def show_payment_screen(self, base_fare):
        self.clear_frame()
        # Payment Frame
        payment_frame = tk.LabelFrame(self.main_frame, text="Payment Details", padx=10, pady=10)
        payment_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)
        
        # Journey summary
        tk.Label(payment_frame, 
                text=f"Train: {self.current_journey_info['train_number']} | {self.current_journey_info['source']} to {self.current_journey_info['dest']}").pack(anchor="w", pady=5)
        tk.Label(payment_frame, text=f"Date: {self.current_journey_info['date']}").pack(anchor="w", pady=5)
        tk.Label(payment_frame, text=f"Coach: {self.current_journey_info['coach_type']}").pack(anchor="w", pady=5)
        
        # Fare
        tk.Label(payment_frame, text=f"Base Fare: ₹{base_fare}").pack(anchor="w", pady=5)
        
        # Payment method
        tk.Label(payment_frame, text="Payment Method:").pack(anchor="w", pady=5)
        self.payment_var = tk.StringVar(value="UPI")
        payment_methods = ["UPI", "Card", "Netbanking", "Cash"]
        for method in payment_methods:
            tk.Radiobutton(payment_frame, text=method, variable=self.payment_var, value=method).pack(anchor="w")
        
        # Buttons
        button_frame = tk.Frame(payment_frame)
        button_frame.pack(pady=10)
        
        tk.Button(button_frame, text="Confirm Booking", command=lambda: self.confirm_booking(base_fare)).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Back", command=lambda: self.select_train()).pack(side=tk.LEFT, padx=5)

    def confirm_booking(self, base_fare):
        payment_method = self.payment_var.get()
        
        try:
            # Call CreateReservation procedure
            self.cursor.callproc('CreateReservation', [
                self.current_passenger_id,
                self.current_journey_info['train_number'],
                self.current_journey_info['date'],
                self.current_journey_info['coach_type'],
                base_fare,
                payment_method,
                0, '', '', '', '', 0  # Dummy OUTs (they'll be populated in DB)
            ])

            for result in self.cursor.stored_results():
                result.fetchall()  # or just `pass` if you're not using it

            # Now safely query additional data
            self.cursor.execute("SELECT pnr_number FROM Reservations WHERE passenger_id = %s ORDER BY reservation_id DESC LIMIT 1", (self.current_passenger_id,))
            pnr_number = self.cursor.fetchone()[0]
            print(pnr_number)
            self.cursor.execute("SELECT status FROM Reservations WHERE passenger_id = %s ORDER BY reservation_id DESC LIMIT 1", (self.current_passenger_id,))
            status = self.cursor.fetchone()[0]

            self.cursor.execute("SELECT coach_id FROM Reservations WHERE passenger_id = %s ORDER BY reservation_id DESC LIMIT 1", (self.current_passenger_id,))
            coach_id = self.cursor.fetchone()[0]
            self.cursor.execute("SELECT seat_id FROM Reservations WHERE passenger_id = %s ORDER BY reservation_id DESC LIMIT 1", (self.current_passenger_id,))
            seat_id = self.cursor.fetchone()[0]
            self.cursor.execute("SELECT coach_type FROM Coaches WHERE coach_id = %s", (coach_id,))
            coach_number = self.cursor.fetchone()[0]
            self.cursor.execute("SELECT seat_number FROM Seats WHERE seat_id = %s", (seat_id,))
            seat_data = self.cursor.fetchone()
            seat_number = seat_data[0] if seat_data else "N/A"

            # self.cursor.execute("SELECT seat_number FROM Reservations WHERE passenger_id = %s ORDER BY reservation_id DESC LIMIT 1", (self.current_passenger_id,))
            # seat_number = self.cursor.fetchone()[0]

            self.conn.commit()
            
            # Store reservation data for ticket display
            self.current_reservation_data = {
                'pnr': pnr_number,
                'status': status,
                'coach': coach_number,
                'seat': seat_number,
                'fare': base_fare
            }
            
            self.show_ticket()

        except Exception as e:
            self.conn.rollback()
            messagebox.showerror("Booking Error", f"Failed to create reservation: {e}")


    def show_ticket(self):
        self.clear_frame()

        if not hasattr(self, 'main_frame') or not self.main_frame.winfo_exists():
            self.main_frame = tk.Frame(self.root)
            self.main_frame.pack(fill=tk.BOTH, expand=True)

        # Ticket Frame
        ticket_frame = tk.LabelFrame(self.main_frame, text="Booking Confirmation", padx=10, pady=10)
        ticket_frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)

        # PNR
        tk.Label(ticket_frame, text=f"PNR: {self.current_reservation_data['pnr']}", 
                font=('Helvetica', 12, 'bold')).pack(pady=10)

        # Status
        status_color = "green" if self.current_reservation_data['status'] == 'Confirmed' else "orange"
        tk.Label(ticket_frame, text=f"Status: {self.current_reservation_data['status']}", 
                fg=status_color, font=('Helvetica', 10, 'bold')).pack(pady=5)

        # Journey info
        tk.Label(ticket_frame, 
                text=f"Train: {self.current_journey_info['train_number']} | {self.current_journey_info['source']} to {self.current_journey_info['dest']}").pack(pady=5)
        tk.Label(ticket_frame, text=f"Date: {self.current_journey_info['date']}").pack(pady=5)
        tk.Label(ticket_frame, text=f"Coach: {self.current_reservation_data['coach']} | Seat: {self.current_reservation_data['seat']}").pack(pady=5)

        # Fare
        tk.Label(ticket_frame, text=f"Fare: ₹{self.current_reservation_data['fare']}", 
                font=('Helvetica', 10)).pack(pady=10)

        # Buttons
        button_frame = tk.Frame(ticket_frame)
        button_frame.pack(pady=10)
        if self.current_passenger_id!=None:
             tk.Button(button_frame, text="New Booking", command=self.show_route_selection).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="go to login", command=self.show_passenger_screen).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Exit", command=self.root.quit).pack(side=tk.LEFT, padx=5)

if __name__ == "__main__":
    root = tk.Tk()
    app = RailwayReservationSystem(root)
    root.mainloop()