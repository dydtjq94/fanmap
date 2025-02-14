//
//  TradeVideoView.swift
//  Storyworld
//
//  Created by peter on 2/11/25.
//

import SwiftUI
import FirebaseFirestore

struct TradeVideoView: View {
    let trade: Trade  // ⭐️ 이제 Trade 객체 하나만 받음
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.isPresented) private var isPresented
    @State private var tabBarVisible: Bool = false
    
    @State private var isGlowing = false
    // 시트 표시 상태
    @State private var tradeStatus: TradeStatus = .available // ✅ 실시간 트레이드 상태 추적
    @State private var showTradeOfferSheet = false
    
    var body: some View {
        ZStack {
            // 배경 (블러 썸네일)
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(trade.video.videoId)/mqdefault.jpg")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 10)
                    .overlay(Color.black.opacity(0.8))
            } placeholder: {
                Color.black.opacity(0.8)
            }
            
            VStack(spacing: 20) {
                Spacer()
                
                // 중앙 영상 카드
                VStack(spacing: 20) {
                    // 썸네일
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(trade.video.videoId)/mqdefault.jpg")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 330)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    } placeholder: {
                        Color.gray.frame(width: 330, height: 185)
                    }
                    
                    // 텍스트/버튼 등
                    VStack(alignment: .leading, spacing: 8) {
                        // 제목
                        Text(trade.video.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        // 채널
                        HStack(spacing: 4) {
                            Image(VideoChannel.getChannelImageName(by: trade.video.channelId))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            
                            Text(VideoChannel.getChannelName(by: trade.video.channelId))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 2)
                        }
                        .padding(.top, 4)
                        
                        // 희귀도 + 유튜브 버튼
                        HStack {
                            // 희귀도 표시
                            RarityBadgeView(rarity: trade.video.rarity)
                            
                            Spacer()
                            
                            // 유튜브 링크
                            Button(action: {
                                UIImpactFeedbackGenerator.trigger(.light)
                                if let url = URL(string: "https://www.youtube.com/watch?v=\(trade.video.videoId)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image("youtube-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 16)
                    }
                    .frame(width: 330, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                // rarity에 따라 카드 배경 + 그림자 애니메이션
                .background(RarityCardBackground(rarity: trade.video.rarity))
                .cornerRadius(10)
                .shadow(
                    color: getShadowColor(for: trade.video.rarity),
                    radius: getShadowRadius(for: trade.video.rarity),
                    x: 0,
                    y: 0
                )
                .onAppear {
                    withAnimation(
                        Animation
                            .easeInOut(duration: getAnimationDuration(for: trade.video.rarity))
                            .repeatForever(autoreverses: true)
                    ) {
                        isGlowing.toggle()
                    }
                }
                
                Spacer()
                
                // 하단 버튼
                VStack {
                    // ✅ 트레이드 상태가 "available"일 때만 버튼 표시
                    if tradeStatus == .available {
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            showTradeOfferSheet = true
                        }) {
                            Text("트레이드 신청하기")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                                .frame(width: 180, height: 48)
                                .background(Color(AppColors.mainColor))
                                .cornerRadius(32)
                                .shadow(radius: 4)
                                .shadow(color: Color(AppColors.mainColor).opacity(0.3), radius: 10, x: 0, y: 0)
                        }
                        .sheet(isPresented: $showTradeOfferSheet) {
                            TradeOfferView(trade: trade, tradeStatus: $tradeStatus) // ✅ 트레이드 상태 바인딩
                        }
                    } else {
                        Text("트레이드 진행 중...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            listenForTradeStatusUpdates()
        }
        // 이하 탭바 / 네비게이션바 숨김 로직은 그대로
        .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: isPresented) {
            if !isPresented {
                self.tabBarVisible = true
            }
        }
    }
    
    // ✅ Firestore에서 트레이드 상태 업데이트 감지
    private func listenForTradeStatusUpdates() {
        let tradeRef = Firestore.firestore().collection("trades").document(trade.id) // 변경된 부분
        
        tradeRef.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, let data = snapshot.data(),
                  let statusString = data["tradeStatus"] as? String,
                  let newStatus = TradeStatus(rawValue: statusString) else { return }
            
            DispatchQueue.main.async {
                tradeStatus = newStatus // 상태 변경에 맞게 UI를 업데이트
            }
        }
    }
    
    // MARK: - 애니메이션/그림자 로직 (rarity에 맞춤)
    func getShadowColor(for rarity: VideoRarity) -> Color {
        switch rarity {
        case .silver:
            return Color.gray.opacity(isGlowing ? 0.3 : 0.1)
        case .gold:
            return Color.yellow.opacity(isGlowing ? 0.5 : 0.3)
        case .diamond:
            return Color.blue.opacity(isGlowing ? 1.0 : 0.7)
        case .ruby:
            return Color.red.opacity(isGlowing ? 1.0 : 0.7)
        }
    }
    
    func getShadowRadius(for rarity: VideoRarity) -> CGFloat {
        switch rarity {
        case .silver:
            return isGlowing ? 10 : 5
        case .gold:
            return isGlowing ? 25 : 20
        case .diamond:
            return isGlowing ? 50 : 30
        case .ruby:
            return isGlowing ? 50 : 30
        }
    }
    
    func getAnimationDuration(for rarity: VideoRarity) -> Double {
        switch rarity {
        case .silver:
            return 2.0
        case .gold:
            return 3.0
        case .diamond:
            return 3.0
        case .ruby:
            return 3.0
        }
    }
}
