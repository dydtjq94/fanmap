//
//  RarityBadgeView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct RarityBadgeView: View {
    let rarity: VideoRarity

    var body: some View {
        HStack(spacing: 4) {
            Image(rarity.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 14)
                .foregroundColor(Color(rarity.uiColor))
            
            Text(rarity.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(rarity.uiColor))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 24)  // RarityBadgeView와 높이 통일
        .background(Color(rarity.backgroundColor))
        .cornerRadius(6)
    }
}
