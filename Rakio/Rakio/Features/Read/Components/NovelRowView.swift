import SwiftUI

struct NovelRowView: View {
    let novel: Novel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let imageName = novel.imageName {
                novelImage(imageName)
                    .frame(width: 116, height: 170)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 116, height: 170)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(novel.title)
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(.white)
                
                Text(novel.author)
                    .font(.custom("Poppins", size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.bottom, 10)
                
                Text(novel.description)
                    .font(.custom("Poppins", size: 12))
                    .foregroundColor(.white)
                    .frame(width: 196, height: 79, alignment: .topLeading)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
                
                if !novel.genre.isEmpty {
                    Text(novel.genre.joined(separator: ", "))
                        .font(.custom("Poppins", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal)
    }
    
    func novelImage(_ name: String) -> AnyView {
        if let uiImage = UIImage(named: name) {
            print("Found image \(name) in bundle.")
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
        } else {
            print("Image \(name) not found in bundle. Check that it is added to your target.")
            return AnyView(
                Rectangle()
                    .fill(Color.gray)
            )
        }
    }
}
