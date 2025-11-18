//
//  ExpandableDescriptionView.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//


import SwiftUI

struct ExpandableDescriptionView: View {
    let description: String
    @Binding var isExpanded: Bool
    
    private let lineLimit = 2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(description)
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : lineLimit)
                .font(.body)
            
            if shouldShowSeeMoreButton {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Show Less" : "See More")
                        .foregroundColor(Color.blue)
                        .font(.subheadline)
                        .bold()
                }
            }
        }
    }
    
    private var shouldShowSeeMoreButton: Bool {
        description.count > 100
    }
}