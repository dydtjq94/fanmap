//
//  TradeVideoPreviewView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI

struct TradeVideoPreviewView: View {
    let video: Video
    
    @State private var showingDetail = false
    
    var body: some View {
        HStack(alignment: .top) {
            // 썸네일 이미지 (유튜브 기본 썸네일)
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(video.videoId)/mqdefault.jpg")) { image in
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
                // 비디오 제목
                Text(video.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))
                    .padding(.bottom, 1)
                
                // 채널 정보 (썸네일 + 채널명)
                HStack(spacing: 4) {
                    Image(VideoChannel.getChannelImageName(by: video.channelId)) // 🔥 채널 프로필 이미지 사용
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .clipShape(Circle()) // 🔥 원형
                    
                    Text(VideoChannel.getChannelName(by: video.channelId))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                }
                .padding(.bottom, 2)
                
                // 희귀도 UI 적용
                RarityBadgeView(rarity: video.rarity)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())  // 터치 영역 확장
        .onTapGesture {
            UIImpactFeedbackGenerator.trigger(.light)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: video, rarity: video.rarity)
        }
    }
}
