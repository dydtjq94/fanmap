//
//  OfferItemView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

import SwiftUI

struct OfferItemView: View {
    let offer: TradeOffer
    @ObservedObject var viewModel: TradeOfferViewModel
    
    var proposerNickname: String {
        viewModel.userMap[offer.proposerId]?.nickname ?? "알 수 없음"
    }
    
    var proposerProfileImageURL: String? {
        viewModel.userMap[offer.proposerId]?.profileImageURL
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1️⃣ 🔥 제안 받은 비디오 (Trade 대상)
            VStack(alignment: .leading, spacing: 8) {
                Text("트레이딩 영상")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                
                if let trade = viewModel.tradeMap[offer.tradeId] {
                    TradeVideoPreviewView(video: trade.video)
                } else {
                    Text("트레이드 정보를 불러오는 중...")
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 4)
                
                // 2️⃣ 🔥 제안한 유저 정보 + 프로필
                HStack(spacing: 6) {
                    if let profileURL = proposerProfileImageURL, let url = URL(string: profileURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(proposerNickname) 님의 제안")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                // 3️⃣ 🔥 제안된 비디오 리스트
                VStack(alignment: .leading, spacing: 8) {
                    Text("제안한 영상 수: \(offer.offeredVideos.count)개")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                    
                    ForEach(offer.offeredVideos, id: \.videoId) { video in
                        TradeVideoPreviewView(video: video)
                            .padding(.bottom, 4)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 4)
                
                //                 4️⃣ 🔥 수락 / 거절 버튼 (우측 정렬)
                HStack {
                    Spacer()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        viewModel.rejectOffer(offer: offer)
                    }) {
                        Text("거절")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        viewModel.acceptOffer(offer: offer)
                    }) {
                        Text("수락")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
