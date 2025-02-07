//
//  CollectionAllItemView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct CollectionAllItemView: View {
    let collectedVideo: CollectedVideo
    @State private var showingDetail = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일 이미지 크기 조정
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(collectedVideo.video.videoId)/mqdefault.jpg")) { image in
                image
                    .resizable()
                    .frame(width: 72, height: 48)
                    .cornerRadius(8)
            } placeholder: {
                Color.gray
                    .frame(width: 72, height: 48)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(collectedVideo.video.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(2)
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))

                Text(VideoChannel.getChannelName(by: collectedVideo.video.channelId))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // 가로로 확장

            Spacer() // 남은 공간 채우기

            // 희귀도 UI 적용
            RarityBadgeView(rarity: collectedVideo.video.rarity)
        }
        .frame(maxWidth: .infinity)  // HStack을 가로로 확장
        .padding(.vertical, 8)
        .cornerRadius(10)
        .contentShape(Rectangle())  // 터치 영역 확장
        .onTapGesture {
            UIImpactFeedbackGenerator.trigger(.light)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: collectedVideo.video, rarity: collectedVideo.video.rarity)
        }
    }
    
}
