import SwiftUI
import MessageUI
import UIKit

let TWILIO_ACCOUNT_SID = "AC460da42b0b2ffe9c0fefa066076bcb52"
let TWILIO_AUTH_TOKEN = "e4be523787c806208e35991eff14251e"
let TWILIO_PHONE_NUMBER = "+447426962029"
let TWILIO_MESSAGING_SERVICE_SID = "MG6d5c5e9a85a5445ec1a64f4f35862a05"
let TWILIO_TEMPLATE_SID = "HX312492ffec3fefa5b2e9bc5efa8cda2c"


func sendSMSTwilio(to phoneNumber: String, message: String) {
    let accountSID = "AC460da42b0b2ffe9c0fefa066076bcb52"
    let authToken = "e4be523787c806208e35991eff14251e"
    let fromPhoneNumber = "+447426962029"  // Twilio phone number

    let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages.json")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let body = "To=\(phoneNumber)&From=\(fromPhoneNumber)&Body=\(message)"
    request.httpBody = body.data(using: .utf8)

    let authStr = "\(accountSID):\(authToken)"
    let authData = authStr.data(using: .utf8)!.base64EncodedString()
    request.setValue("Basic \(authData)", forHTTPHeaderField: "Authorization")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Error sending SMS: \(error.localizedDescription)")
            return
        }
        if let data = data, let responseStr = String(data: data, encoding: .utf8) {
            print("✅ Twilio Response: \(responseStr)")
        }
    }
    task.resume()
}

// MARK: - Modern Theme Button
struct ModernButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.gray.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.system(size: 18, weight: .bold))
            .padding(.horizontal)
    }
}
// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var isActive = false // Controls transition to login screen

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Background color
            
            VStack {
                Image("Image") // Your company logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .opacity(isActive ? 0 : 1) // Fades out when switching screens

                Text("Your Company Name") // Company Name (Optional)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(isActive ? 0 : 1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // Show splash for 2.5 seconds
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView() // Transition to the main login screen
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var dateOfBirth = Date()
    @State private var mobileNumber = ""
    @State private var loginError = ""
    @State private var isLoggedIn = false
    @State private var isSignUp = false
    @State private var loggedInUserId: Int64? = nil
    @State private var userRole: String? = nil
    @State private var showUnauthorizedAlert = false

    let dbManager = DatabaseManager()

    var body: some View {
        NavigationStack {
            ZStack {
                // Black Background
                Color.black
                    .ignoresSafeArea()
                
                if isLoggedIn, let userId = loggedInUserId, let role = userRole {
                    HomeScreen(
                        logoutAction: logoutUser,
                        dbManager: dbManager,
                        loggedInUserId: userId,
                        userRole: role
                    )
                    .navigationBarBackButtonHidden(true)
                } else {
                    VStack {
                        // App Logo
                        Image("Image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(.top, 40)

                        Text(isSignUp ? "Create an Account" : "Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding()

                        if isSignUp {
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    customTextField("Email", text: $email)
                                    customSecureField("Password", text: $password)
                                    customTextField("Full Name", text: $fullName)
                                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                        .padding()
                                    
                                    customTextField("Mobile Number", text: $mobileNumber)
                                        .keyboardType(.phonePad)

                                    if !loginError.isEmpty {
                                        Text(loginError)
                                            .foregroundColor(.red)
                                    }

                                    Button("Sign Up", action: signUpUser)
                                        .modifier(ModernButton())
                                }
                                .padding()
                            }
                        } else {
                            LazyVStack(spacing: 20) {
                                customTextField("Email", text: $email)
                                customSecureField("Password", text: $password)

                                if !loginError.isEmpty {
                                    Text(loginError)
                                        .foregroundColor(.red)
                                }

                                Button("Log In", action: loginUser)
                                    .modifier(ModernButton())
                            }
                            .padding()
                        }

                        Button(action: { isSignUp.toggle(); clearForm() }) {
                            Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 50) // Prevents bottom padding issue
                }
            }
        }
        .alert(isPresented: $showUnauthorizedAlert) {
            Alert(title: Text("Unauthorized"), message: Text("You do not have access to this area."), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Custom Styled TextField
    func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white) // Make text readable
            .padding(.horizontal)
            .autocorrectionDisabled()
            .autocapitalization(.none)
    }

    // MARK: - Custom SecureField
    func customSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white) // Make text readable
            .padding(.horizontal)
            .autocorrectionDisabled()
            .autocapitalization(.none)
    }

    private func clearForm() {
        email = ""
        password = ""
        fullName = ""
        mobileNumber = ""
        loginError = ""
    }

    private func initializeApp() {
        dbManager.createDefaultBusinessOwner()
        isLoggedIn = isUserLoggedIn()
    }

    private func isUserLoggedIn() -> Bool {
        if let savedEmail = UserDefaults.standard.string(forKey: "userEmail"),
           let user = dbManager.getUser(byEmail: savedEmail) {
            email = savedEmail
            loggedInUserId = user.1
            userRole = user.2
            return true
        }
        return false
    }

    private func signUpUser() {
        if email.isEmpty || password.isEmpty || fullName.isEmpty || mobileNumber.isEmpty {
            loginError = "Please fill in all fields."
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dateFormatter.string(from: dateOfBirth)

        let success = dbManager.insertUser(email: email, password: password, fullName: fullName, dob: dobString, mobileNumber: mobileNumber, role: "regularUser")
        
        DispatchQueue.main.async {
            if success, let user = dbManager.getUser(byEmail: email) {
                loggedInUserId = user.1
                userRole = user.2
                withAnimation {
                    isLoggedIn = true
                }
            } else {
                loginError = "Error creating account. Try again."
            }
        }
    }

    private func loginUser() {
        if email.isEmpty || password.isEmpty {
            loginError = "Please fill in all fields."
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let user = dbManager.getUser(byEmail: email), user.0 == password {
                DispatchQueue.main.async {
                    loggedInUserId = user.1
                    userRole = user.2
                    withAnimation {
                        isLoggedIn = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loginError = "Invalid email or password."
                }
            }
        }
    }

    private func logoutUser() {
        UserDefaults.standard.removeObject(forKey: "userEmail")
        DispatchQueue.main.async {
            loggedInUserId = nil
            userRole = nil
            isLoggedIn = false
        }
    }
}
struct HomeScreen: View {
    var logoutAction: () -> Void
    let dbManager: DatabaseManager
    let loggedInUserId: Int64
    let userRole: String

    var body: some View {
        NavigationView {
            VStack {
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.top, 10)

                Spacer()

                VStack(spacing: 20) {
                    // ✅ Navigate to Book Appointment Screen
                    NavigationLink(destination: BookAppointmentScreen(dbManager: dbManager, userId: loggedInUserId)) {
                        Text("Book Appointment")
                            .modifier(ModernButton())
                    }

                    // ✅ Navigate to Cancel Appointment Screen
                    NavigationLink(destination: CancelAppointmentScreen(dbManager: dbManager, userId: loggedInUserId)) {
                        Text("Cancel Appointment")
                            .modifier(ModernButton())
                    }

                    // ✅ Navigate to Business Owner Area (If User is a Business Owner)
                    if userRole == "businessOwner" {
                        NavigationLink(destination: BusinessOwnerView(dbManager: dbManager, userId: loggedInUserId)) {
                            Text("Business Owner Area")
                                .modifier(ModernButton())
                        }
                    }

                    // ✅ Logout Button
                    Button(action: logoutAction) {
                        Text("Logout")
                            .modifier(ModernButton())
                    }
                }
                .padding(.top, 30)

                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .navigationBarBackButtonHidden(true) // Hide back button
    }
}

// MARK: - Modern Navigation Button Modifier
func modernNavButton<Destination: View>(title: String, color: Color, destination: Destination) -> some View {
    NavigationLink(destination: destination) {
        Text(title)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 4)
    }
    .padding(.horizontal)
}

struct BusinessOwnerView: View {
    let dbManager: DatabaseManager
    let userId: Int64

    @State private var weeklyAppointments: [String: [(String, String, String)]] = [:] // [(Time, Client Name, Status)]
    @State private var daysOfWeek: [(String, String)] = [] // [(FormattedDay, DatabaseDay)]

    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    var body: some View {
        VStack {
            Text("Weekly Timetable")
                .font(.largeTitle)
                .padding()

            if weeklyAppointments.isEmpty {
                Text("No appointments scheduled for this week.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    ForEach(daysOfWeek, id: \.0) { formattedDay, databaseDay in
                        VStack(alignment: .leading) {
                            Text(formattedDay)
                                .font(.headline)
                                .padding(.top)

                            if let appointments = weeklyAppointments[databaseDay], !appointments.isEmpty {
                                ForEach(appointments.indices, id: \.self) { index in
                                    let appointment = appointments[index]
                                    HStack {
                                        Text("Time: \(appointment.0)") // Time
                                        Spacer()
                                        Text("Client: \(appointment.1)") // Client Name
                                        Spacer()
                                        Text("Status: \(appointment.2)") // Status (active/cancelled)
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                Text("No appointments")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
            }

            Spacer()

            // Home Button
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Navigate back to the home screen
            }) {
                Text("Home")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true) // Hides the back button
        .onAppear {
            setupWeekDays()
            fetchWeeklyAppointments()
        }
    }

    private func setupWeekDays() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM" // Display format (e.g., "Monday, 3 February")

        let dbFormatter = DateFormatter()
        dbFormatter.dateFormat = "yyyy-MM-dd" // Database format (e.g., "2025-02-03")

        let calendar = Calendar.current
        let today = Date()

        // Generate the next 5 days, including today
        daysOfWeek = (0..<5).compactMap { offset in
            let futureDate = calendar.date(byAdding: .day, value: offset, to: today)
            guard let unwrappedDate = futureDate else { return nil }
            return (formatter.string(from: unwrappedDate), dbFormatter.string(from: unwrappedDate))
        }

        print("Generated days for the next 5 days: \(daysOfWeek)")
    }

    private func fetchWeeklyAppointments() {
        var fetchedAppointments: [String: [(String, String, String)]] = [:]

        for (_, databaseDay) in daysOfWeek {
            // Fetch appointments for the specific day
            let appointments = dbManager.getAllAppointmentsForDate(forDate: databaseDay)
            fetchedAppointments[databaseDay] = appointments

            print("Appointments for \(databaseDay): \(appointments)")
        }

        DispatchQueue.main.async {
            self.weeklyAppointments = fetchedAppointments
            print("Updated weekly appointments: \(self.weeklyAppointments)")
        }
    }
}
import SwiftUI
import UIKit

struct BookAppointmentScreen: View {
    @State private var selectedDate = Date()          // Selected appointment date
    @State private var availableSlots: [String] = [] // Available time slots
    @State private var selectedSlot: String = ""     // Selected time slot
    @State private var bookingStatus: String? = ""   // Booking success or failure message
    @State private var clientName: String = ""       // Client's name

    let dbManager: DatabaseManager                   // Database manager instance
    let userId: Int64                                // User ID of the logged-in user
    
    func sendTwilioSMS(to phoneNumber: String, message: String) {
        let accountSid = "AC460da42b0b2ffe9c0fefa066076bcb52"
        let authToken = "e4be523787c806208e35991eff14251e"
        let fromNumber = "+447426962029"
        
        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSid)/Messages.json")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = "From=\(fromNumber)&To=\(phoneNumber)&Body=\(message)"
        request.httpBody = body.data(using: .utf8)
        
        let authString = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Twilio Error: \(error.localizedDescription)")
                return
            }
            print("✅ SMS Sent Successfully!")
        }
        task.resume()
    }

    var body: some View {
        ScrollView { // Enables scrolling
            VStack {
                Text("Book an Appointment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .onChange(of: selectedDate) { oldValue, newValue in
                        print("📅 Date changed: \(newValue)")
                        fetchAvailableSlots()
                    }
                    .padding()

                // Client Name Field
                TextField("Enter Your Name", text: $clientName)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // Available Slots Section
                Text("Available Time Slots")
                    .font(.headline)
                    .padding(.top)

                if availableSlots.isEmpty {
                    Text("No available slots for the selected date.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(availableSlots, id: \.self) { slot in
                        Button(action: {
                            selectedSlot = slot
                        }) {
                            HStack {
                                Text(slot)
                                Spacer()
                                if selectedSlot == slot {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .frame(height: 200) // Limit the height of the list
                }

                // Confirm Booking Button
                if !selectedSlot.isEmpty {
                    Button(action: {
                        bookAppointment()
                    }) {
                        Text("Confirm Booking for \(selectedSlot)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }

                // Booking Status Message
                if let status = bookingStatus {
                    Text(status)
                        .foregroundColor(status.contains("successfully") ? .green : .red)
                        .padding()
                }

                Spacer(minLength: 20) // Adds some space at the bottom
            }
            .padding()
        }
    }

    // MARK: - Fetch Available Slots
    private func fetchAvailableSlots() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        availableSlots = dbManager.getAvailableSlots(forDate: dateString)
    }

    // MARK: - Book Appointment (with SMS via Email)
    private func bookAppointment() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateValue = formatter.string(from: selectedDate)

        guard !selectedSlot.isEmpty else {
            bookingStatus = "Please select a time slot."
            return
        }

        guard !clientName.isEmpty else {
            bookingStatus = "Please enter your name."
            return
        }

        let success = dbManager.bookAppointment(forDate: dateValue, time: selectedSlot, userId: userId, clientName: clientName)

        if success {
            bookingStatus = "Appointment booked successfully for \(selectedSlot) on \(dateValue)."

            // ✅ Fetch User's Phone Number from Database
            if let phoneNumber = dbManager.getUserPhoneNumber(userId: userId) {
                let message = "Your appointment is confirmed for \(dateValue) at \(selectedSlot)."

                // ✅ Send SMS via Twilio
                sendSMSTwilio(to: phoneNumber, message: message)
            }

            fetchAvailableSlots() // Refresh available slots
            selectedSlot = ""     // Reset selected slot
        } else {
            bookingStatus = "Failed to book the appointment. Please try again."
        }
    }}

struct Appointment: Identifiable, Hashable {
    let id = UUID()           // Unique identifier for each appointment
    let date: String          // Date of the appointment
    let time: String          // Time of the appointment
    let clientName: String    // Client name for the appointment
}

struct CancelAppointmentScreen: View {
    let dbManager: DatabaseManager
    let userId: Int64

    @State private var userAppointments: [Appointment] = [] // Array of Appointment structs
    @State private var cancelStatus: String? // Status message after cancellation

    var body: some View {
        VStack {
            Text("Cancel an Appointment")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            if userAppointments.isEmpty {
                Text("You have no appointments.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(userAppointments) { appointment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Date: \(appointment.date)")
                            Text("Time: \(appointment.time)")
                            Text("Client: \(appointment.clientName)")
                        }
                        Spacer()
                        Button(action: {
                            cancelAppointment(forDate: appointment.date, time: appointment.time)
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // Cancelation Status Message
            if let status = cancelStatus {
                Text(status)
                    .foregroundColor(status.contains("successfully") ? .green : .red)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .onAppear {
            fetchUserAppointments()
        }
    }

    // Fetch all appointments for the user
    private func fetchUserAppointments() {
        print("Fetching all appointments for userId: \(userId)")
        let fetchedAppointments = dbManager.getAllAppointments(userId: userId) // [(String, String, String)]
        userAppointments = fetchedAppointments.map { Appointment(date: $0.0, time: $0.1, clientName: $0.2) }

        if userAppointments.isEmpty {
            print("No appointments found.")
        } else {
            for appointment in userAppointments {
                print("Fetched appointment: \(appointment)")
            }
        }
    }

    // Cancel the selected appointment
    private func cancelAppointment(forDate date: String, time: String) {
        let success = dbManager.cancelAppointment(forDate: date, time: time, userId: userId)
        
        if success {
            cancelStatus = "Appointment on \(date) at \(time) cancelled successfully."
            fetchUserAppointments() // Refresh the list of appointments
            
            // ✅ Fetch User's Phone Number from Database
            if let phoneNumber = dbManager.getUserPhoneNumber(userId: userId) {
                let message = "Your appointment on \(date) at \(time) has been successfully cancelled."

                // ✅ Send SMS via Twilio
                sendSMSTwilio(to: phoneNumber, message: message)
            }
        } else {
            cancelStatus = "Failed to cancel the appointment. Please try again."
        }
    }
}

struct AdminAreaView: View {
    let dbManager: DatabaseManager

    var body: some View {
        Text("Admin Area")
            .font(.largeTitle)
            .padding()
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
