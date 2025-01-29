//
//  PlaylistView.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

struct PlaylistView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @StateObject private var sheetManager = SheetManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                HStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))
                    Text("재생 목록")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))
                }
                
                Spacer()
                
                NavigationLink(destination: PlaylistAllView()) {
                    Text("전체 보기")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))
                }.simultaneousGesture(TapGesture().onEnded {
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    feedbackGenerator.prepare()
                    feedbackGenerator.impactOccurred()
                })
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            if viewModel.playlists.isEmpty {
                Text("나만의 재생 목록을 만들어 보세요!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.playlists.prefix(10), id: \.id) { playlist in
                        Button(action: {
                            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            feedbackGenerator.prepare()
                            feedbackGenerator.impactOccurred()
                            sheetManager.presentPlaylistDetail(for: playlist)
                        }) {
                            PlaylistItemView(playlist: playlist)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(UIColor(hex:"#1D1D1D")))
        .cornerRadius(16)
        .onAppear {
            viewModel.loadPlaylists()
        }
        .sheet(isPresented: $sheetManager.showPlaylistDetail, onDismiss: {
            print("플레이리스트 상세 화면 닫힘, 데이터 새로고침")
            viewModel.loadPlaylists()
        }) {
            if let playlist = sheetManager.selectedPlaylist {
                PlaylistDetailedView(
                    playlist: playlist,
                    playlistViewModel: viewModel,
                    sheetManager: sheetManager  // 여기 추가
                )
            }
        }
    }
}
