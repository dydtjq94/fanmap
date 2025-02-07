//
//  PlaylistItemView.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

struct PlaylistItemView: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 16) {
            // 썸네일 이미지
            if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .cornerRadius(12)
                } placeholder: {
                    Image(playlist.defaultThumbnailName) // 기본 이미지 적용
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .cornerRadius(12)
                }
            } else {
                Image(playlist.defaultThumbnailName) // 기본 이미지 적용
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))
                    .padding(.bottom, 4)

                Text("\(playlist.videoIds.count)개의 영상")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
            }

            Spacer()
        }
    }
}
