//
//  ErrorView.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//


import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                retryAction()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.rakioPrimary)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
