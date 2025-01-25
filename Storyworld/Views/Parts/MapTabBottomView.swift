//
//  MapTabBottomView.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import SwiftUI

struct MapTabBottomView: View {
    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                NotificationCenter.default.post(name: .locationButtonTapped, object: nil)
            }) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                    .padding(16)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor(hex:"#1B1B1B")))
                    .clipShape(Circle())
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 0)
            }
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                NotificationCenter.default.post(name: .scanButtonTapped, object: nil)
            }) {
                Text("이 지역 스캔하기")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                    .background(Color(UIColor(hex:"#1B1B1B")))
                    .cornerRadius(16)
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 0)
            }
            Spacer()
            Color.clear
                .frame(width: 36, height: 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

extension Notification.Name {
    static let scanButtonTapped = Notification.Name("scanButtonTapped")
    static let locationButtonTapped = Notification.Name("locationButtonTapped")
}
