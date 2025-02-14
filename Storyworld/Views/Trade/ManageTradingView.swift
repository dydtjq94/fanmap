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
    @State private var tradeMemo: String = ""
    @State private var isEditingMemo = false

    @State private var selectedVideos: [CollectedVideo] = [] // ✅ 등록할 비디오 선택
    @State private var collectedVideos: [CollectedVideo] = [] // ✅ 내 컬렉션에서 가져올 데이터

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        VStack(alignment: .leading){
                                Text("내 메모")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                            
                            // 연필 아이콘 버튼
                            Button(action: {
                                UIImpactFeedbackGenerator.trigger(.light)
                                isEditingMemo = true
                            }) {
                                
                                HStack(alignment: .top){
                                    // 현재 메모 표시 (비어있으면 플레이스홀더)
                                    Text(tradeMemo.isEmpty ? "메모를 입력하세요" : tradeMemo)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(4)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .onTapGesture {
                                            isEditingMemo = true
                                        }
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.bottom, 20)
                        .alert("트레이드 메모 수정", isPresented: $isEditingMemo) {
                            TextField("메모를 입력하세요", text: $tradeMemo)
                            
                            Button("취소", role: .cancel) { isEditingMemo = false }
                            
                            Button("저장") {
                                UIImpactFeedbackGenerator.trigger(.light)
                                viewModel.updateTradeMemo(memo: tradeMemo)
                                isEditingMemo = false
                            }
                        }

                        // ✅ 2. 트레이드 등록 목록 (등록된 영상)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("새 트레이드 등록")
                                .font(.system(size:14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)

                            if selectedVideos.isEmpty {
                                // 🔥 점선 테두리로 빈 영역 표시 (기본 박스 유지)
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(height: 80)
                                    .overlay(
                                        Text("등록할 영상을 선택하세요")
                                            .foregroundColor(.gray)
                                    )
                            } else {
                                VStack{
                                    ForEach(selectedVideos) { video in
                                        TradeVideoPreviewView(video: video.video)
                                            .overlay(
                                                Button(action: {
                                                    UIImpactFeedbackGenerator.trigger(.light)
                                                    removeSelectedVideo(video: video) // ✅ 선택 해제 기능 추가
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .foregroundColor(Color(UIColor(hex:"#545454")))
                                                },
                                                alignment: .trailing
                                            )
                                    }
                                    .padding(.bottom, 4)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color(UIColor(hex: "#1D1D1D")))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.bottom, 20)

                        // ✅ 3. 내 컬렉션에서 트레이드 등록
                        VStack(alignment: .leading, spacing: 8) {
                            Text("내 컬렉션")
                                .font(.system(size:14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            if collectedVideos.isEmpty {
                                Text("등록 가능한 영상이 없습니다.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(collectedVideos) { collectedVideo in
                                    TradeOfferVideoItemView(
                                        collectedVideo: collectedVideo,
                                        isSelected: selectedVideos.contains(where: { $0.id == collectedVideo.id }),
                                        onSelect: { addSelectedVideo(video: collectedVideo) },
                                        onDeselect: { removeSelectedVideo(video: collectedVideo) }
                                    )
                                }
                            }
                        }
                        Spacer().frame(height: 80) // ✅ 버튼이 가려지지 않도록 여백 추가
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 16)

                // ✅ 4. 등록 버튼을 화면 하단에 고정
                if !selectedVideos.isEmpty {
                    VStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            registerSelectedTrades() // 선택된 영상 트레이드 등록
                        }
                        ) {
                            Text("선택한 영상 트레이드 등록 (\(selectedVideos.count)개)")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(AppColors.mainColor))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .background(
                            Color.black.opacity(0.8) // ✅ 버튼 배경을 추가하여 가독성 유지
                                .edgesIgnoringSafeArea(.bottom)
                        )
                    }
                }
            }
            .background(Color(UIColor(hex:"#121212")))
            .onAppear {
                loadUserTrades()
            }
            .navigationTitle("새 트레이드 등록")
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
    
    // 트레이드 로드 후 메모도 로드하여 UI에 반영
    private func loadUserTrades() {
        // 트레이드 데이터를 로드하는 로직
        viewModel.loadUserTrades()  // viewModel에서 트레이드 불러오기

        // 트레이드가 로드된 후에 내 컬렉션을 로드하고, 트레이드 메모도 가져옴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 약간의 지연을 주어 로드가 완료된 후 loadData 호출
            loadData()
            loadTradeMemo()  // 트레이드 메모 로드
        }
    }

    // 트레이드 메모 로드
    private func loadTradeMemo() {
        // viewModel에서 tradeMemo 값을 가져와서 업데이트
        tradeMemo = viewModel.fetchTradeMemo()
    }

    // 데이터 불러오는 메서드
    private func loadData() {
        // UserDefaults에서 내 컬렉션 불러오기
        var allCollectedVideos = UserDefaults.standard.loadCollectedVideos()
        
        // 이미 트레이드로 등록된 영상들의 videoId를 가져옴
        let registeredVideoIds = viewModel.trades.map { $0.video.videoId }
        print("등록된 영상 videoId: \(registeredVideoIds)")

        // 등록되지 않은 영상만 필터링 (videoId 기준)
        collectedVideos = allCollectedVideos.filter { !registeredVideoIds.contains($0.video.videoId) }
        
        print("✅ 내 컬렉션 영상 로드 완료, 등록되지 않은 영상 개수: \(collectedVideos.count)")
    }
    
    // ✅ 선택한 영상 추가
    private func addSelectedVideo(video: CollectedVideo) {
        withAnimation {
            selectedVideos.append(video)
            collectedVideos.removeAll { $0.id == video.id } // ✅ 등록하면 컬렉션에서 제거
        }
    }

    // ✅ 선택한 영상 제거
    private func removeSelectedVideo(video: CollectedVideo) {
        withAnimation {
            selectedVideos.removeAll { $0.id == video.id }
            collectedVideos.append(video) // ✅ 제거하면 다시 컬렉션으로 복귀
        }
    }

    // ✅ 트레이드 등록 버튼 클릭 후 호출
    private func registerSelectedTrades() {
        if selectedVideos.isEmpty {
            return // 영상이 선택되지 않으면 등록하지 않음
        }

        // 트레이드 메모와 선택된 영상들로 트레이드 등록
        viewModel.registerSelectedTrades(videos: selectedVideos, memo: tradeMemo)
        
        // 등록 후 선택된 영상 리스트를 비움
        selectedVideos.removeAll()
    }
}
