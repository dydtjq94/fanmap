//
//  CooldownBadgeView.swift
//  Storyworld
//
//  Created by peter on 1/30/25.
//

import SwiftUI

struct CooldownBadgeView: View {
    let circleData: CircleData

    var body: some View {
        HStack {
            Image(systemName: "lock.badge.clock.fill")
                .foregroundColor(Color(UIColor(hex: "#d1d1d1")))
                .font(.system(size: 12))
            
            Text(formattedCooldownTime(circleData.cooldownTime))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(UIColor(hex: "#d1d1d1")))
        }
        .padding(8)
        .frame(height: 24)  // RarityBadgeView와 높이 통일
        .background(Color(UIColor(hex: "#454545")))
        .cornerRadius(6)
    }
    
    /// ⏳ 쿨다운 시간을 "분" 또는 "시간"으로 변환하는 함수
    private func formattedCooldownTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let hours = minutes / 60

        if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}
