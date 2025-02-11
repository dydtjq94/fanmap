//
//  TradeItemView.swift
//  Storyworld
//
//  Created by peter on 2/11/25.
//


import SwiftUI

struct TradeItemView: View {
    let trade: Trade
    @State private var showingDetail = false
    
    var body: some View {
        HStack(alignment: .top) {
            // 썸네일 (유튜브 이미지 URL 예시)
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(trade.video.videoId)/mqdefault.jpg")) { image in
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
            
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(trade.video.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                // 채널 썸네일 + 채널명
                HStack(spacing: 4) {
                    Image(VideoChannel.getChannelImageName(by: trade.video.channelId))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .clipShape(Circle())
                    
                    Text(VideoChannel.getChannelName(by: trade.video.channelId))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                // 희귀도 배지
                RarityBadgeView(rarity: trade.video.rarity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 누를 때 동작 (예: 디테일 뷰)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: trade.video, rarity: trade.video.rarity)
        }
    }
}
