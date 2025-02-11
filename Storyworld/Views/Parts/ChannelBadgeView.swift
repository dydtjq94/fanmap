//
//  ChannelBadgeView.swift
//  Storyworld
//
//  Created by peter on 2/7/25.
//

import SwiftUI

struct ChannelBadgeView: View {
    let channel: VideoChannel

    var body: some View {
        HStack(spacing: 4) {
            Image(channel.imageName) // 🔥 채널 프로필 이미지 사용
                .resizable()
                .scaledToFill()
                .frame(width: 14, height: 14)
                .clipShape(Circle()) // 🔥 원형으로 변환
            
            Text(channel.localized()) // 🔥 채널명 표시
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 24)  // RarityBadgeView와 높이 통일
        .background(Color.gray) // 🔥 배경 추가 (원하면 변경 가능)
        .cornerRadius(6)
    }
}
