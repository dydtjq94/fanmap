//
//  CollectionAllView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct CollectionAllView: View {
    @Environment(\.isPresented) private var isPresented
    @State private var tabBarVisible: Bool = false
    @StateObject private var viewModel = CollectionAllViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.collectedVideos.isEmpty {
                // ✅ 수집한 영상이 없을 때 표시되는 메시지
                VStack {
                    Spacer()
                    Text("아직 수집한 영상이 없어요!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 100)
                    Spacer()
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.collectedVideos, id: \.video.videoId) { collectedVideo in
                        CollectionAllItemView(collectedVideo: collectedVideo)
                            .onAppear {
                                if collectedVideo == viewModel.collectedVideos.last {
                                    viewModel.loadMoreVideos()
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    Spacer() // 빈 공간에서도 스크롤 가능하게 확장
                }
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor(hex:"#1D1D1D")))
        .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
        .onChange(of: isPresented) {
            if !isPresented {
                self.tabBarVisible = true
            }
        }
        .onAppear {
            viewModel.loadInitialVideos()
        }
    }
}
