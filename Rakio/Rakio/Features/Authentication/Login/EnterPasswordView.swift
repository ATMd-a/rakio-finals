import SwiftUI

struct EnterPasswordView: View {
    @Environment(\.dismiss) var dismiss
    let email: String
    
    @State private var password: String = ""
    @State private var showMismatchWarning: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var navigateToHome = false
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                
                Spacer()
                    .frame(height: 250)
                
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
                
                Text("Enter your password")
                    .font(.custom("Poppins", size: 25))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(width: 255, height: 30)
                    .foregroundColor(.white)
                
                Text("Log in to your account securely")
                    .font(.custom("Poppins-Regular", size: 14))
                    .multilineTextAlignment(.center)
                    .frame(width: 255, height: 33)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Text("Password")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .frame(width: 321)
                
                SecureField("", text: $password)
                    .padding()
                    .frame(width: 321, height: 47)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errorMessage != nil ? Color.red : Color.white, lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    .font(.custom("Poppins-Regular", size: 14))
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("Poppins-Regular", size: 12))
                        .frame(width: 321, alignment: .leading)
                }
                
                Button(action: {
                    errorMessage = nil
                    
                    guard !password.isEmpty else {
                        errorMessage = "Please enter your password."
                        return
                    }
                    
                    if password.count < 6 {
                        errorMessage = "Password must be at least 6 characters."
                        return
                    }
                    
                    isLoading = true
                    
                    FirebaseManager.shared.login(email: email, password: password) { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            switch result {
                            case .success(_):
                                selectedTab = .home  // switch tab to home
                                dismiss()         
                                
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }) {
                    if isLoading {
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
                .padding(.top, 20)

                
                Spacer()
                
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
            .navigationBarBackButtonHidden(false)


            
        }
    }
    
    private func buildTermsText() -> AttributedString {
        var string = AttributedString("By continuing you agree to the Terms & Condition and Privacy Policy of Rakio")
        
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
}

