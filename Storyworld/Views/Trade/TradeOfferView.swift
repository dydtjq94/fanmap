//
//  TradeOfferView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

import SwiftUI
import FirebaseAuth

struct TradeOfferView: View {
    let trade: Trade  // 대상 트레이드 정보
    @Binding var tradeStatus: TradeStatus // ✅ 바인딩을 통해 상태 업데이트
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var myVideoViewModel = TradeMyVideoViewModel()
    
    @State private var selectedVideoIds: Set<String> = [] // 사용자가 선택한 영상 ID
    @State private var selectedVideos: [CollectedVideo] = [] // 실제 선택된 영상
    @State private var isSubmitting = false // ✅ 트레이드 요청 중 상태 표시
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) { // ✅ 버튼을 하단에 위치
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // 1️⃣ 트레이드 대상 영상 미리보기
                        VStack(alignment: .leading) {
                            Text("트레이드중인 영상")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                                .padding(.bottom, 4)
                            
                            TradeVideoPreviewView(video: trade.video)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                        
                        // 2️⃣ 트레이드에 사용될 영상들
                        VStack(alignment: .leading) {
                            Text("트레이드에 사용될 영상들")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                                .padding(.bottom, 4)
                            
                            if selectedVideos.isEmpty {
                                Text("선택된 영상 없음")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(selectedVideos, id: \.id) { myVid in
                                    TradeOfferVideoItemView(
                                        collectedVideo: myVid,
                                        isSelected: true,
                                        onSelect: {}, // 선택된 영상에서는 필요 없음
                                        onDeselect: { toggleSelection(myVid) }
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // 3️⃣ 내 영상들 (선택한 영상 제외)
                        VStack(alignment: .leading) {
                            Text("내 영상들")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                                .padding(.bottom, 4)
                            
                            LazyVStack {
                                ForEach(myVideoViewModel.myCollectedVideos.filter { !selectedVideoIds.contains($0.id) }, id: \.id) { myVid in
                                    TradeOfferVideoItemView(
                                        collectedVideo: myVid,
                                        isSelected: false,
                                        onSelect: { toggleSelection(myVid) },
                                        onDeselect: {} // 해제 버튼 없음
                                    )
                                }
                            }
                        }
                        
                        Spacer().frame(height: 80) // 🔥 버튼과 겹치지 않도록 아래 여백 추가
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // ✅ 버튼 애니메이션 추가
                if !selectedVideos.isEmpty {
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            submitTradeOffer()
                        }) {
                            Text("제안하기")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(width: 200) // ✅ 버튼 크기 고정
                                .padding()
                                .background(Color(AppColors.mainColor))
                                .cornerRadius(8)
                        }
                        .cornerRadius(8)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity)) // 🔥 아래에서 올라오는 애니메이션
                        .animation(.easeInOut(duration: 0.3), value: selectedVideos.count) // ✅ 부드러운 애니메이션 적용
                    }
                }
            }
            .onAppear {
                myVideoViewModel.loadMyVideos() // ✅ 사용자의 수집 영상 불러오기
            }
            .navigationTitle("트레이드 제안") // ✅ 상단 제목 추가
            .navigationBarTitleDisplayMode(.inline) // ✅ 작은 제목 스타일
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        presentationMode.wrappedValue.dismiss() // ✅ 시트 닫기
                    }) {
                        Image(systemName: "chevron.down") // 🔥 아래 화살표 아이콘 사용
                            .font(.title2) // 아이콘 크기 조정
                            .foregroundColor(.white) // 아이콘 색상
                    }
                }
            }
        }
    }
    
    /// ✅ 선택된 영상 추가/제거
    func toggleSelection(_ vid: CollectedVideo) {
        withAnimation { // 🔥 애니메이션 효과 추가
            if selectedVideoIds.contains(vid.id) {
                // ❌ 선택 해제
                selectedVideoIds.remove(vid.id)
                selectedVideos.removeAll { $0.id == vid.id }
            } else {
                // ✅ 선택 추가
                selectedVideoIds.insert(vid.id)
                selectedVideos.append(vid)
            }
        }
    }
    
    func submitTradeOffer() {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard !selectedVideos.isEmpty else { return } // ✅ 선택한 영상이 없으면 실행 안 함
        
        isSubmitting = true // ✅ 로딩 상태 활성화
        
        TradeService.shared.createOffer(for: trade, offeredVideos: selectedVideos.map { $0.video }, proposerId: currentUser.uid) { success in

            DispatchQueue.main.async {
                self.isSubmitting = false // ✅ 로딩 종료
                
                let generator = UINotificationFeedbackGenerator()
                
                if success {
                    generator.notificationOccurred(.success) // ✅ 성공 진동 피드백
                    tradeStatus = .pending // ✅ 상태 업데이트
                    presentationMode.wrappedValue.dismiss()
                } else {
                    generator.notificationOccurred(.error) // ✅ 실패 진동 피드백
                    print("❌ [submitTradeOffer] 트레이드 제안 실패")
                }
            }
        }
    }
}
