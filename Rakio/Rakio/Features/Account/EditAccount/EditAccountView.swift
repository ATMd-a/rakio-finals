import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AccountViewModel
    @StateObject private var firebaseManager = FirebaseManager.shared

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false // ✅ success popup

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Edit Account")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)

            // Profile Image
            Button(action: { showImagePicker.toggle() }) {
                Image(uiImage: profileImage ?? UIImage(named: "MewerLogo_Black")!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            }

            // Input Fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1))
                        .autocapitalization(.none)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.gray)
                        .disabled(true)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("New Password")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    SecureField("New Password", text: $newPassword)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1))
                }
            }
            .padding(.horizontal)

            // Save Button
            Button(action: saveChanges) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                } else {
                    Text("Save Changes")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .disabled(isSaving)

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }

            Spacer()
        }
        .background(Color(hex: "14110F").ignoresSafeArea())
        .onAppear(perform: loadUserInfo)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .alert(isPresented: $showSuccessAlert) { // ✅ success alert
            Alert(
                title: Text("✅ Success"),
                message: Text("Your profile has been updated successfully."),
                dismissButton: .default(Text("OK")) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    // MARK: - Load user info
    private func loadUserInfo() {
        guard let user = firebaseManager.currentUser else { return }

        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.username = data["username"] as? String ?? ""
                    self.email = data["email"] as? String ?? user.email ?? ""
                }
            }
        }

        if let localImage = loadImageLocally(named: user.uid) {
            self.profileImage = localImage
        }
    }

    // MARK: - Save changes
    private func saveChanges() {
        guard let user = firebaseManager.currentUser else {
            errorMessage = "User not found"
            return
        }

        isSaving = true
        errorMessage = nil

        let group = DispatchGroup()

        // 🧑‍💻 Update username
        if !username.isEmpty {
            group.enter()
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges { error in
                if let error = error { self.errorMessage = error.localizedDescription }
                self.db.collection("users").document(user.uid).updateData([
                    "username": self.username
                ]) { err in
                    if let err = err { self.errorMessage = err.localizedDescription }
                    group.leave()
                }
            }
        }

        // 🔒 Update password
        if !newPassword.isEmpty {
            group.enter()
            user.updatePassword(to: newPassword) { error in
                if let error = error { self.errorMessage = error.localizedDescription }
                group.leave()
            }
        }

        // 🖼️ Save profile image locally
        if let profileImage = profileImage {
            group.enter()
            saveImageLocally(profileImage, named: user.uid)
            viewModel.profileImage = profileImage
            group.leave()
        }

        // 🔁 When all done
        group.notify(queue: .main) {
            self.isSaving = false
            if self.errorMessage == nil {
                self.viewModel.currentUsername = self.username
                self.showSuccessAlert = true // ✅ success popup
            }
        }
    }

    // MARK: - Local Storage Helpers
    private func saveImageLocally(_ image: UIImage, named: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let fileManager = FileManager.default
        let resourcesDir = getDocumentsDirectory().appendingPathComponent("Resources")

        if !fileManager.fileExists(atPath: resourcesDir.path) {
            try? fileManager.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        }

        let fileURL = resourcesDir.appendingPathComponent("\(named)_profile.jpg")
        try? data.write(to: fileURL)
    }

    private func loadImageLocally(named: String) -> UIImage? {
        let fileURL = getDocumentsDirectory()
            .appendingPathComponent("Resources/\(named)_profile.jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
