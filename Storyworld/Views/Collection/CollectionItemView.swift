//
//  CollectionItemView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct CollectionItemView: View {
    let collectedVideo: CollectedVideo
    @State private var showingDetail = false
    
    var body: some View {
        HStack(alignment: .top) {
            // 썸네일 이미지 크기 2/3로 조정
            AsyncImage(url: URL(string: collectedVideo.video.thumbnailURL)) { image in
                image
                    .resizable()
                    .frame(width: 114, height:76)
                    .cornerRadius(8)
            } placeholder: {
                Color.gray
                    .frame(width: 114, height:76)
                    .cornerRadius(8)
            }
            .padding(.trailing, 4)
            
            VStack(alignment: .leading) {
                Text(collectedVideo.video.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))
                    .padding(.bottom, 1)
                
                Text(Channel.getChannelName(by: collectedVideo.video.channelId))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
                    .lineLimit(1)
                    .padding(.bottom, 2)
                
                // 희귀도 UI 적용
                RarityBadgeView(rarity: collectedVideo.video.rarity)
            }
        }
        .contentShape(Rectangle())  // 터치 영역 확장
        .onTapGesture {
            UIImpactFeedbackGenerator.trigger(.light)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: collectedVideo.video, genre: collectedVideo.video.genre, rarity: collectedVideo.video.rarity)
        }
    }
}
