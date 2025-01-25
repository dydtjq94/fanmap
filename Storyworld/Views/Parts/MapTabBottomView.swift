//
//  MapTabBottomView.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import SwiftUI

struct MapTabBottomView: View {
    @State private var isScanButtonDisabled = false  // 버튼 상태를 관리하는 상태 변수

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
                    .shadow(color: Color(UIColor(hex:"6aebaf")).opacity(0.3), radius: 10, x: 0, y: 0)
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
                    .shadow(color: Color(UIColor(hex:"6aebaf")).opacity(0.3), radius: 10, x: 0, y: 0)
            }
            .disabled(isScanButtonDisabled)  // 버튼 비활성화 처리
            Spacer()
            Color.clear
                .frame(width: 36, height: 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // 스캔 시작 전 버튼 비활성화
    func disableScanButton() {
        isScanButtonDisabled = true
    }

    // 스캔 완료 후 버튼 활성화
    func enableScanButton() {
        isScanButtonDisabled = false
    }
}

extension Notification.Name {
    static let scanButtonTapped = Notification.Name("scanButtonTapped")
    static let locationButtonTapped = Notification.Name("locationButtonTapped")
}
