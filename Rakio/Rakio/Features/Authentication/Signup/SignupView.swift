import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var navigateToSetPassword = false
    @State private var isCheckingEmail = false
    @State private var showEmailExistsOverlay = false
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 10) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .padding(16)
                        }
                        Spacer()
                    }
                    
                    Spacer().frame(height: 300)

                    // Logo
                    if let logo = UIImage(named: "MewerLogo_White.png") {
                        Image(uiImage: logo)
                            .resizable()
                            .frame(width: 150, height: 84)
                            .scaledToFit()
                            .clipped()
                            .padding(.bottom, -15)
                    } else {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 200, height: 113)
                    }
                    
                    // Header Text
                    Text("Sign up now and enjoy free stories")
                        .font(.custom("Poppins", size: 25))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(width: 255, height: 60)
                        .foregroundColor(.white)

                    // Subheader Text
                    Text("Start reading and watching hundreds of free gl with other fans and creators!")
                        .font(.custom("Poppins-Regular", size: 14))
                        .multilineTextAlignment(.center)
                        .frame(width: 255, height: 33)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    
                    // Email Input Field with error as placeholder style
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text(errorMessage ?? "Enter your email")
                                .foregroundColor(errorMessage != nil ? .red : .white.opacity(0.5))
                                .font(.custom("Poppins-Regular", size: 14))
                                .padding(.horizontal, 16)
                        }
                        
                        TextField("", text: $email)
                            .onChange(of: email) { oldValue, newValue in
                                errorMessage = nil
                            }

                            .padding()
                            .frame(width: 321, height: 47)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .font(.custom("Poppins-Regular", size: 14))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Continue Button
                    Button(action: {
                        errorMessage = nil

                        guard !email.isEmpty else {
                            errorMessage = "Please enter your email."
                            return
                        }

                        guard isValidEmail(email) else {
                            errorMessage = "Please enter a valid email."
                            return
                        }

                        isCheckingEmail = true
                        FirebaseManager.shared.checkIfEmailExists(email) { exists, error in
                            DispatchQueue.main.async {
                                isCheckingEmail = false
                                if let error = error {
                                    errorMessage = "Failed to check email: \(error.localizedDescription)"
                                } else if exists {
                                    showEmailExistsOverlay = true
                                } else {
                                    navigateToSetPassword = true
                                }
                            }
                        }
                    }) {
                        if isCheckingEmail {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 321, height: 47)
                                .background(Color.rakioPrimary)
                                .cornerRadius(8)
                        } else {
                            Text("Continue")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 321, height: 47)
                    .background(Color.rakioPrimary)
                    .cornerRadius(8)
                    
                    
                    
                    // Already have account prompt
                    NavigationLink(destination: LoginView(selectedTab: .constant(.account)).navigationBarBackButtonHidden(true)) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                                .font(.custom("Poppins-Regular", size: 14))
                            
                            Text("Log in")
                                .foregroundColor(.white)
                                .font(.custom("Poppins-Bold", size: 14))
                        }
                    }
                    .padding(.top, 4)

                    Spacer()
                    
                    
                    // Terms and Conditions Text
                    Text(buildTermsText())
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(width: 340, height: 47)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(showEmailExistsOverlay)
                
                // MARK: - Overlay View
                if showEmailExistsOverlay {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            showEmailExistsOverlay = false
                        }

                    VStack(spacing: 20) {
                        Text("Email Already Exists")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.white)

                        Text("The email you entered is already registered. Please log in or use a different email.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(width: 280)

                        Button(action: {
                            showEmailExistsOverlay = false
                        }) {
                            Text("OK")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 44)
                                .background(Color.rakioPrimary)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.rakioBackground)
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .frame(maxWidth: 320)
                    .transition(.scale)
                }
            }
            .animation(.easeInOut, value: showEmailExistsOverlay)
            .background(Color.rakioBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToSetPassword) {
                SetPasswordView(email: email, selectedTab: .constant(.account))
            }
        }
    }
    
    
    private func buildTermsText() -> AttributedString {
        var string = AttributedString("By logging in you agree to the Terms & Condition and Privacy Policy of Rakio")
        
        if let termsRange = string.range(of: "Terms & Condition") {
            string[termsRange].font = .custom("Poppins-Bold", size: 14)
            string[termsRange].foregroundColor = .white
        }
        
        if let privacyRange = string.range(of: "Privacy Policy") {
            string[privacyRange].font = .custom("Poppins-Bold", size: 14)
            string[privacyRange].foregroundColor = .white
        }
        
        return string
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}
