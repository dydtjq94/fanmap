//
//  GenreBadgeView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct GenreBadgeView: View {
    let genre: VideoGenre

    var body: some View {
        HStack {
            Image(systemName: "play.fill")
                .foregroundColor(Color(genre.uiColor))
                .font(.system(size: 12))
            
            Text(genre.localized())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(genre.uiColor))
        }
        .padding(8)
        .frame(height: 24)  // RarityBadgeView와 높이 통일
        .background(Color(genre.backgroundColor))
        .cornerRadius(6)
    }
}
