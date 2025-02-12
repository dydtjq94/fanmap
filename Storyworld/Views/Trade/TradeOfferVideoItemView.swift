//
//  TradeOfferVideoItemView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI

struct TradeOfferVideoItemView: View {
    let collectedVideo: CollectedVideo
    let isSelected: Bool
    var onSelect: () -> Void
    var onDeselect: () -> Void
    
    @State private var showingDetail = false
    
    var body: some View {
        HStack(alignment: .top) {
            // 썸네일 이미지
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(collectedVideo.video.videoId)/mqdefault.jpg")) { image in
                image
                    .resizable()
                    .frame(width: 60, height: 40)
                    .cornerRadius(4)
            } placeholder: {
                Color.gray
                    .frame(width: 60, height: 40)
                    .cornerRadius(4)
            }
            .padding(.trailing, 8)
            
            // 제목 + 채널명
            VStack(alignment: .leading) {
                Text(collectedVideo.video.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(Color.white)
                    .padding(.bottom, 1)
                
                Text(VideoChannel.getChannelName(by: collectedVideo.video.channelId))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
                    .lineLimit(1)
            }
            Spacer()
            
            // 희귀도 UI
            RarityBadgeView(rarity: collectedVideo.video.rarity)
            
            // 선택 추가(+) 또는 제거(✖) 버튼
            Button(action: {
                UIImpactFeedbackGenerator.trigger(.light)
                isSelected ? onDeselect() : onSelect()
            }) {
                Image(systemName: isSelected ? "xmark" : "plus")
                    .foregroundColor(isSelected ? Color(UIColor(hex:"#545454")) : Color(UIColor(hex:"#545454")))
                    .font(.title2)
            }
        }
        .cornerRadius(8)
        .onTapGesture {
            UIImpactFeedbackGenerator.trigger(.light)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: collectedVideo.video, rarity: collectedVideo.video.rarity)
        }
    }
}
