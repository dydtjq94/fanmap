//
//  ProSubscriptionView.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//

import SwiftUI

struct ProSubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔒 PRO 기능 잠금 해제")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("PRO 구독을 통해 더 많은 기능을 이용하세요!")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
