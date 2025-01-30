//
//  PlaylistVideoItemView.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

struct PlaylistVideoItemView: View {
    let collectedVideo: CollectedVideo
    @State private var showingDetail = false
    let isInPlaylist: Bool
    var onAdd: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // 썸네일 이미지 크기 2/3로 조정
            AsyncImage(url: URL(string: collectedVideo.video.thumbnailURL)) { image in
                image
                    .resizable()
                    .frame(width: 60, height:40)
                    .cornerRadius(4)
            } placeholder: {
                Color.gray
                    .frame(width: 60, height:40)
                    .cornerRadius(4)
            }
            .padding(.trailing, 1 )
            
            VStack(alignment: .leading) {
                Text(collectedVideo.video.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))
                    .padding(.bottom, 1)
                
                Text(Channel.getChannelName(by: collectedVideo.video.channelId))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
                    .lineLimit(1)
                    .padding(.bottom, 2)

            }
            Spacer()
            
            // 희귀도 UI 적용
            RarityBadgeView(rarity: collectedVideo.video.rarity)

            // + 버튼 (추가) 또는 - 버튼 (제거) 조건에 따라 표시
            Button(action: {
                isInPlaylist ? onRemove() : onAdd()
            }) {
                Image(systemName: isInPlaylist ? "xmark" : "plus")
                    .foregroundColor(isInPlaylist ? Color(UIColor(hex:"#545454")) : Color(UIColor(hex:"#545454")))
                    .font(.title2)
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator.trigger(.light)
            
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VideoDetailedView(video: collectedVideo.video, genre: collectedVideo.video.genre, rarity: collectedVideo.video.rarity)
        }
    }
}

