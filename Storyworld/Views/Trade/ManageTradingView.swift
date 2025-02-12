//
//  ManageTradingView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

//
//  ManageTradingView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

import SwiftUI

struct ManageTradingView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel = ManageTradingViewModel()
    @State private var selectedFilter: TradeStatus = .available
    @State private var tradeMemo: String = ""
    @State private var isEditingMemo = false

    @State private var collectedVideos: [CollectedVideo] = [] // ✅ 내 컬렉션에서 가져올 데이터

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // 1️⃣ 트레이드 메모 관리
                VStack(alignment: .leading, spacing: 8) {
                    Text("트레이드 메모")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        TextField("트레이드 메모를 입력하세요", text: $tradeMemo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: tradeMemo) { _ in
                                isEditingMemo = true
                            }

                        if isEditingMemo {
                            Button("저장") {
                                viewModel.updateTradeMemo(memo: tradeMemo)
                                isEditingMemo = false
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // 2️⃣ 내가 등록한 트레이드 목록 (등록 취소 가능)
                VStack(alignment: .leading, spacing: 8) {
                    Text("내 등록된 트레이드")
                        .font(.headline)
                        .foregroundColor(.white)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if viewModel.trades.isEmpty {
                                Text("등록된 트레이드가 없습니다.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(viewModel.trades) { trade in
                                    TradeVideoPreviewView(video: trade.video)
                                        .overlay(
                                            Button(action: {
                                                cancelTrade(trade: trade) // ✅ 트레이드 취소 후 즉시 반영
                                            }) {
                                                Text("등록 취소")
                                                    .font(.caption)
                                                    .padding(6)
                                                    .background(Color.red)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                            .padding(6),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 3️⃣ 내 컬렉션에서 바로 트레이드 등록하기
                VStack(alignment: .leading, spacing: 8) {
                    Text("내 컬렉션에서 트레이드 등록")
                        .font(.headline)
                        .foregroundColor(.white)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if collectedVideos.isEmpty {
                                Text("등록 가능한 영상이 없습니다.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(collectedVideos) { collectedVideo in
                                    TradeOfferVideoItemView(
                                        collectedVideo: collectedVideo,
                                        isSelected: false,
                                        onSelect: { registerTrade(video: collectedVideo) },
                                        onDeselect: {} // 해제 버튼 없음
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .background(Color(UIColor(hex: "#1D1D1D")))
            .onAppear {
                loadData()
            }
            .navigationTitle("트레이드 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // ✅ 데이터 불러오기 (onAppear에서 실행)
    private func loadData() {
        viewModel.loadUserTrades(status: .available)
        tradeMemo = viewModel.fetchTradeMemo()

        // ✅ CollectionService에서 영상 불러오기 (등록된 트레이드와 비교해서 제외)
        let allVideos = CollectionService.shared.fetchAllVideos()
        let tradeVideoIds = Set(viewModel.trades.map { $0.video.videoId }) // ✅ 등록된 트레이드의 videoId 목록
        collectedVideos = allVideos.filter { !tradeVideoIds.contains($0.video.videoId) } // 🔥 거래 중이 아닌 영상만 남김
    }

    // ✅ 트레이드 등록 후, `collectedVideos`에서 즉시 숨김
    private func registerTrade(video: CollectedVideo) {
        viewModel.registerTrade(video: video)
        withAnimation {
            collectedVideos.removeAll { $0.video.videoId == video.video.videoId } // ✅ UI에서만 숨김 (삭제 X)
        }
    }

    // ✅ 트레이드 취소 후, `viewModel.trades`에서 즉시 제거하고 `collectedVideos`를 다시 표시
    private func cancelTrade(trade: Trade) {
        viewModel.cancelTrade(trade: trade)
        withAnimation {
            viewModel.trades.removeAll { $0.id == trade.id }
            
            let restoredVideo = CollectedVideo(
                id: trade.video.videoId, // ✅ trade.video.videoId 사용
                video: trade.video,
                collectedDate: Date(),
                tradeStatus: .available,
                isFavorite: false,
                ownerId: trade.ownerId
            )
            collectedVideos.append(restoredVideo) // ✅ 다시 UI에서 표시
        }
    }
}
