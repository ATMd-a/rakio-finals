//
//  LoadingView.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//


import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text(message)
                .foregroundColor(.white)
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}