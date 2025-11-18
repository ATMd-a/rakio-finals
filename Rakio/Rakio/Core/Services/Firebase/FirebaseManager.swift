import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    
    @Published var currentUser: User? = nil
    @Published var currentUsername: String? = nil

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        // Listen for authentication state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] auth, user in
            self?.currentUser = user
        }
    }

    // MARK: - Signup
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                self.createUserDocument(user: user, email: email)
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during signup."])))
            }
        }
    }

    // MARK: - Login
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login succeeded but user not found."])))
            }
        }
    }

    // MARK: - Logout
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
    }

    // MARK: - Create User Document
    
    func createUserDocument(user: User, email: String) {
        let username = email.components(separatedBy: "@").first ?? "user"

        let userData: [String: Any] = [
            "uid": user.uid,
            "email": email,
            "username": username,
            "createdAt": FieldValue.serverTimestamp(),
            "watchHistory": [:],
            "favorites": [],
            "reminders": [],
            "settings": [
                "darkModeEnabled": false,
                "notificationsEnabled": true
            ]
        ]

        firestore.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("❌ Error creating user document: \(error.localizedDescription)")
            } else {
                print("✅ User document successfully created for \(username).")

                // ✅ Also update FirebaseAuth displayName
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                changeRequest.commitChanges(completion: nil)
            }
        }
    }



    func fetchCurrentUsername() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            if let username = snapshot?.data()?["username"] as? String {
                DispatchQueue.main.async {
                    self.currentUsername = username
                }
            }
        }
    }

}

extension FirebaseManager {
    /// Checks if an email exists by querying the 'users' collection in Firestore.
    /// - Parameters:
    ///   - email: The email to check.
    ///   - completion: Returns true if user exists, false otherwise. Also returns an error if any.
    func checkIfEmailExists(_ email: String, completion: @escaping (Bool, Error?) -> Void) {
        firestore.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                let exists = (snapshot?.documents.count ?? 0) > 0
                completion(exists, nil)
            }
    }
}
