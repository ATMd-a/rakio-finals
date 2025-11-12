import SwiftUI
import FirebaseStorage

struct ProfileImageView: View {
    let userID: String
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false
    private let storage = Storage.storage()
    
    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("Add Photo")
                            .foregroundColor(.white)
                            .font(.caption2)
                    )
            }
        }
        .frame(width: 65, height: 65)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        .onAppear(perform: loadImage)
        .onTapGesture {
            showImagePicker = true
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    private func loadImage() {
        let ref = storage.reference().child("profile_images/\(userID).jpg")
        ref.getData(maxSize: 2 * 1024 * 1024) { data, error in
            if let data, let uiImage = UIImage(data: data) {
                self.image = uiImage
            }
        }
    }
}
