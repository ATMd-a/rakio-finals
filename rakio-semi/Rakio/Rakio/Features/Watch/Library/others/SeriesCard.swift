//
//  SeriesCard.swift
//  Test3
//
//  Created by STUDENT on 9/19/25.
//

import SwiftUI

struct SeriesCardView: View {
    let series: Series
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            seriesImage(series.imageName)
                .frame(width: 163, height: 95)
                .cornerRadius(8)
                .clipped()
            
            Text(series.title)
                .font(.custom("Poppins-Bold", size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
            
           
            
            Spacer().frame(height: 4)
            
            Text(series.genre.map { "#\($0)" }.joined(separator: " "))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(width: 163, height: 169)
        .background(Color.clear)
    }
    
    func seriesImage(_ name: String) -> some View {
        if let uiImage = UIImage(named: name) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
        } else {
            return AnyView(
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("No Image")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
                    )
            )
        }
    }
}
