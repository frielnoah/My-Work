import SQLite
import Foundation
import UIKit

class DatabaseManager {
    private var db: Connection!
    private var usersTable: Table!
    private var appointmentsTable: Table!

    // Users table columns
    private var userId: SQLite.Expression<Int64>!
    private var email: SQLite.Expression<String>!
    private var password: SQLite.Expression<String>!
    private var role: SQLite.Expression<String>!
    private var fullName: SQLite.Expression<String>!
    private var dateOfBirth: SQLite.Expression<String>!
    private var mobileNumber: SQLite.Expression<String>!

    // Appointments table columns
    private var appointmentId: SQLite.Expression<Int64>!
    private var date: SQLite.Expression<String>!
    private var time: SQLite.Expression<String>!
    private var bookedBy: SQLite.Expression<Int64>!
    private var clientName: SQLite.Expression<String>!
    private var status: SQLite.Expression<String>!

    init() {
        do {
            // Set up database file path
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbPath = documentDirectory.appendingPathComponent("appointments.sqlite3").path
            db = try Connection(dbPath)

            // Initialize tables and columns
            usersTable = Table("users")
            userId = SQLite.Expression<Int64>("id")
            email = SQLite.Expression<String>("email")
            password = SQLite.Expression<String>("password")
            role = SQLite.Expression<String>("role")
            fullName = SQLite.Expression<String>("fullName")
            dateOfBirth = SQLite.Expression<String>("dob")
            mobileNumber = SQLite.Expression<String>("mobile_number")

            appointmentsTable = Table("appointments")
            appointmentId = SQLite.Expression<Int64>("id")
            date = SQLite.Expression<String>("date")
            time = SQLite.Expression<String>("time")
            bookedBy = SQLite.Expression<Int64>("booked_by")
            clientName = SQLite.Expression<String>("client_name")
            status = SQLite.Expression<String>("status")

            // Migrate users table if needed
            migrateUsersTable()

            // Ensure tables exist
            createUsersTable()
            createAppointmentsTable()

            // 🛑 DELETE OLD DATABASE (ONLY IF YOU WANT TO RESET)
            // try FileManager.default.removeItem(atPath: dbPath)

            // ✅ Ensure Business Owner Account Exists
            createDefaultBusinessOwner()

            print("Database initialized successfully.")
            
            printUsersTableContents()

        } catch {
            print("Database initialization error: \(error.localizedDescription)")
        }
    }
    
    func printUsersTableContents() {
        do {
            print("🔹 Checking Users Table Contents...")
            for user in try db.prepare(usersTable) {
                print("👤 User: ID=\(user[self.userId]), Email=\(user[self.email]), Role=\(user[self.role]), Password=\(user[self.password])")
            }
        } catch {
            print("❌ Error fetching users: \(error.localizedDescription)")
        }
    }
    
    func getAllAppointmentsForDate(forDate dateValue: String) -> [(String, String, String)] {
        var appointments: [(String, String, String)] = [] // (Time, Client Name, Status)
        do {
            let query = appointmentsTable.filter(self.date == dateValue)
            for appointment in try db.prepare(query) {
                let time = appointment[self.time]
                let clientName = appointment[self.clientName]
                let status = appointment[self.status]
                appointments.append((time, clientName, status))
            }
        } catch {
            print("Error fetching appointments for date \(dateValue): \(error.localizedDescription)")
        }
        return appointments
    }

    // MARK: - Table Creation and Migration
    
    private func createUsersTable() {
        do {
            print("🔹 Creating 'users' table if not exists...")

            try db.run(usersTable.create(ifNotExists: true) { table in
                table.column(userId, primaryKey: true)
                table.column(email, unique: true)
                table.column(password)
                table.column(role, defaultValue: "regularUser")
                table.column(fullName)
                table.column(dateOfBirth)
                table.column(mobileNumber)
            })

            print("✅ Users table created successfully.")
        } catch {
            print("❌ Error creating users table: \(error.localizedDescription)")
        }
    }
    
    private func createOrUpdateUsersTable() {
        do {
            if try db.scalar(usersTable.exists) {
                print("Users table already exists. Checking for missing columns...")
                migrateUsersTable()
            } else {
                print("Creating users table...")
                try db.run(usersTable.create { table in
                    table.column(userId, primaryKey: true)
                    table.column(email, unique: true)
                    table.column(password)
                    table.column(role, defaultValue: "regularUser")
                    table.column(fullName)
                    table.column(dateOfBirth)
                    table.column(mobileNumber)
                })
                print("Users table created successfully.")
            }
        } catch {
            print("Error creating or updating users table: \(error.localizedDescription)")
        }
    }

    private func createAppointmentsTable() {
        do {
            print("Creating appointments table if not exists...")
            try db.run(appointmentsTable.create(ifNotExists: true) { table in
                table.column(appointmentId, primaryKey: true)
                table.column(date)
                table.column(time)
                table.column(bookedBy)
                table.column(clientName)
                table.column(status, defaultValue: "active")
                table.unique(date, time)
            })
            print("Appointments table created successfully.")
        } catch {
            print("Error creating appointments table: \(error.localizedDescription)")
        }
    }

    // MARK: - User Management
    func insertUser(email: String, password: String, fullName: String, dob: String, mobileNumber: String, role: String) -> Bool {
        do {
            let insert = usersTable.insert(
                self.email <- email,
                self.password <- password,
                self.fullName <- fullName,
                self.dateOfBirth <- dob,
                self.mobileNumber <- mobileNumber,
                self.role <- role
            )
            try db.run(insert)
            print("User inserted successfully: \(email)")
            return true
        } catch let Result.error(message, code, statement) {
            print("SQLite Error \(code): \(message)")
            if let statement = statement {
                print("Failed SQL: \(statement)")
            }
            return false
        } catch {
            print("Unexpected error inserting user: \(error.localizedDescription)")
            return false
        }
    }

    func createDefaultBusinessOwner() {
        let email = "owner@example.com"
        let password = "password123"
        let fullName = "Business Owner"
        let dateOfBirth = "1980-01-01"
        let mobileNumber = "1234567890"
        let role = "businessOwner"

        // Check if the business owner already exists
        if getUser(byEmail: email) != nil {
            print("Business owner account already exists.")
            return
        }

        print("Inserting business owner account...")

        let success = insertUser(
            email: email,
            password: password,
            fullName: fullName,
            dob: dateOfBirth,
            mobileNumber: mobileNumber,
            role: role
        )

        if success {
            print("✅ Business owner account created: \(email)")
        } else {
            print("❌ Error inserting business owner.")
        }
    }
    
    func getUserPhoneNumber(userId: Int64) -> String? {
        do {
            let query = usersTable.filter(self.userId == userId)
            if let user = try db.pluck(query) {
                let phoneNumber = user[self.mobileNumber]
                print("📞 Retrieved Phone Number: \(phoneNumber) for User ID: \(userId)")
                return phoneNumber
            } else {
                print("❌ No phone number found for User ID: \(userId)")
            }
        } catch {
            print("❌ Error fetching phone number: \(error.localizedDescription)")
        }
        return nil
    }
    
    func getUser(byEmail emailValue: String) -> (password: String, userId: Int64, role: String)? {
        do {
            let query = usersTable.filter(self.email == emailValue)
            if let user = try db.pluck(query) {
                return (
                    password: user[self.password],
                    userId: user[self.userId],
                    role: user[self.role]
                )
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
        return nil
    }
    
    func sendSMSEmail(to phoneNumber: String, message: String) {
        let carriers = [
            "att": "@txt.att.net",
            "verizon": "@vtext.com",
            "tmobile": "@tmomail.net",
            "sprint": "@messaging.sprintpcs.com",
            "uscellular": "@email.uscc.net"
        ]

        // 📌 Manually update with user's carrier (or store carrier info in the database)
        let carrier = "verizon" // Change this based on the user's carrier
        guard let smsGateway = carriers[carrier] else {
            print("❌ Carrier not supported")
            return
        }

        let recipientEmail = phoneNumber + smsGateway

        let url = URL(string: "mailto:\(recipientEmail)?subject=Appointment Confirmation&body=\(message)")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func getAvailableSlots(forDate dateValue: String) -> [String] {
        let allSlots = generateTimeSlots()
        let bookedSlots = getBookedSlots(forDate: dateValue)
        return allSlots.filter { !bookedSlots.contains($0) }
    }

    func bookAppointment(forDate dateValue: String, time: String, userId: Int64, clientName: String) -> Bool {
        do {
            let insert = appointmentsTable.insert(
                self.date <- dateValue,
                self.time <- time,
                self.bookedBy <- userId,
                self.clientName <- clientName,
                self.status <- "active"
            )
            try db.run(insert)
            return true
        } catch {
            print("Error booking appointment: \(error.localizedDescription)")
            return false
        }
    }

    func cancelAppointment(forDate dateValue: String, time: String, userId: Int64) -> Bool {
        do {
            let appointmentToCancel = appointmentsTable.filter(
                self.date == dateValue && self.time == time && self.bookedBy == userId && self.status == "active"
            )
            let deleteCount = try db.run(appointmentToCancel.delete())
            return deleteCount > 0
        } catch {
            print("Error cancelling appointment: \(error.localizedDescription)")
            return false
        }
    }

    func getAppointments(forDate dateValue: String, userId: Int64) -> [(String, String)] {
        var appointments: [(String, String)] = []
        do {
            let query = appointmentsTable.filter(
                self.date == dateValue && self.bookedBy == userId && self.status == "active"
            )
            for appointment in try db.prepare(query) {
                appointments.append((appointment[self.time], appointment[self.clientName]))
            }
        } catch {
            print("Error fetching appointments: \(error.localizedDescription)")
        }
        return appointments
    }

    func getAllAppointments(userId: Int64) -> [(String, String, String)] {
        var appointments: [(String, String, String)] = []
        do {
            let query = appointmentsTable.filter(self.bookedBy == userId && self.status == "active")
            for appointment in try db.prepare(query) {
                appointments.append((appointment[self.date], appointment[self.time], appointment[self.clientName]))
            }
        } catch {
            print("Error fetching all appointments: \(error.localizedDescription)")
        }
        return appointments
    }

    private func getBookedSlots(forDate dateValue: String) -> [String] {
        var slots: [String] = []
        do {
            let query = appointmentsTable.filter(self.date == dateValue && self.status == "active")
            for appointment in try db.prepare(query) {
                slots.append(appointment[self.time])
            }
        } catch {
            print("Error fetching booked slots: \(error.localizedDescription)")
        }
        return slots
    }

    private func generateTimeSlots() -> [String] {
        var slots: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
        let endTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!

        while startTime < endTime {
            slots.append(formatter.string(from: startTime))
            startTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime)!
        }
        return slots
    }

    func printAppointmentsTableSchema() {
        do {
            for row in try db.prepare("PRAGMA table_info(appointments)") {
                print(row)
            }
        } catch {
            print("Error fetching table schema: \(error.localizedDescription)")
        }
    }
    
    private func migrateUsersTable() {
        do {
            // Fetch existing column names
            let existingColumns = try db.prepare("PRAGMA table_info(users)").map { $0[1] as? String }

            // Add `fullName` column if it doesn't exist
            if !existingColumns.contains("fullName") {
                print("Adding 'fullName' column to 'users' table...")
                try db.run(usersTable.addColumn(fullName, defaultValue: ""))
            }

            // Add `date` (or `dob`) column if it doesn't exist
            if !existingColumns.contains("dob") {
                print("Adding 'dob' column to 'users' table...")
                try db.run(usersTable.addColumn(dateOfBirth, defaultValue: ""))
            }

            // Add `mobile_number` column if it doesn't exist
            if !existingColumns.contains("mobile_number") {
                print("Adding 'mobile_number' column to 'users' table...")
                try db.run(usersTable.addColumn(mobileNumber, defaultValue: ""))
            }

            print("Users table migration completed.")
        } catch {
            print("Error migrating users table: \(error.localizedDescription)")
        }
    }

    func clearTable(tableName: String) {
        do {
            let query = "DELETE FROM \(tableName);"
            try db.run(query)
            print("All data cleared from \(tableName) table.")
        } catch {
            print("Error clearing table \(tableName): \(error.localizedDescription)")
        }
    }
}
