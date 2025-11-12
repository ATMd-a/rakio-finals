import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct EditAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: { showImagePicker.toggle() }) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(Text("Add Photo").foregroundColor(.white))
                    }
                }
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .opacity(0.6)
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: saveChanges) {
                    if isSaving {
                        ProgressView()
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
                .disabled(isSaving) // Disable the button while saving
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Account")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Load the current user's information
                loadUserInfo()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }

        }
    }
    
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
    }

    
    private func saveChanges() {
        guard let user = firebaseManager.currentUser else {
            errorMessage = "User not found"
            return
        }

        isSaving = true
        errorMessage = nil

        let group = DispatchGroup()

        // Update username
        if !username.isEmpty {
            group.enter()
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges { error in
                if let error = error { errorMessage = error.localizedDescription }
                self.db.collection("users").document(user.uid).updateData([
                    "username": self.username
                ]) { err in
                    if let err = err { errorMessage = err.localizedDescription }
                    group.leave()
                }
            }
        }

        // Update password
        if !newPassword.isEmpty {
            group.enter()
            user.updatePassword(to: newPassword) { error in
                if let error = error { errorMessage = error.localizedDescription }
                group.leave()
            }
        }

        // Update profile image
        if let profileImage = profileImage {
            group.enter()
            saveProfileImage(profileImage, for: user.uid) { error in
                if let error = error { errorMessage = error.localizedDescription }
                group.leave()
            }
        }

        // Finish after all async calls
        group.notify(queue: .main) {
            self.isSaving = false
            if self.errorMessage == nil {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    
    private func saveProfileImage(_ image: UIImage, for userID: String, completion: @escaping (Error?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]))
            return
        }
        
        let storageRef = storage.reference().child("profile_images/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(error)
            } else {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.db.collection("users").document(userID).updateData([
                            "profileImageURL": url.absoluteString
                        ]) { error in
                            if let error = error {
                                completion(error)
                            } else {
                                completion(nil)
                            }
                        }
                    } else {
                        completion(error ?? NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                    }
                }
            }
        }
    }
}

