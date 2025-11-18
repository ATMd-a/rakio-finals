import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var navigateToEnterPassword = false
    @Binding var selectedTab: ContentView.Tab
    @State private var isCheckingEmail = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                
                // X Button in top-left
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
                            .padding(.bottom, 10)
                    }
                    Spacer()
                }

                Spacer()
                    .frame(height: 300)
                
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
                Text("Log in now and enjoy free stories")
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
                
                // Email Input Field
                // Email Input Field with error inside placeholder
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text(errorMessage ?? "Enter your email")
                            .foregroundColor(errorMessage != nil ? .red : .white.opacity(0.5))
                            .font(.custom("Poppins-Regular", size: 14))
                            .padding(.horizontal, 16)
                    }
                    
                    TextField("", text: $email)
                        .onChange(of: email) {
                            errorMessage = nil
                        }
                        .padding()
                        .frame(width: 321, height: 47)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(errorMessage != nil ? Color.red : Color.white, lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .font(.custom("Poppins-Regular", size: 14))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                
                // Continue Button with validation
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
                                errorMessage = "Error checking email: \(error.localizedDescription)"
                                return
                            }
                            if !exists {
                                errorMessage = "Email not found. Please sign up."
                                return
                            }
                            // Email exists, proceed to next screen
                            navigateToEnterPassword = true
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
                .disabled(isCheckingEmail)

                // Sign Up Prompt
                NavigationLink(destination: SignupView(selectedTab: .constant(.account)).navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                            .font(.custom("Poppins-Regular", size: 14))
                        
                        Text("Sign up")
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
            .background(Color.rakioBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToEnterPassword) {
                EnterPasswordView(email: email, selectedTab: $selectedTab)
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

//#Preview {
//    LoginView(selectedTab: .constant(.account))
//}
