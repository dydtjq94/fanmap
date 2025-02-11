//
//  TradeView.swift
//  Storyworld
//
//  Created by peter on 2/11/25.
//


//
//  TradeView.swift
//  Storyworld
//
//  Created by peter on 2/25/25.
//

import SwiftUI

struct TradeView: View {
    @StateObject private var viewModel = TradeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let grouped = Dictionary(grouping: viewModel.trades, by: { $0.ownerId })
                
                // 각 ownerId별로 섹션 구성
                ForEach(grouped.keys.sorted(), id: \.self) { ownerId in
                    VStack(alignment: .leading, spacing: 8) {
                        ownerHeaderView(ownerId: ownerId) // 🔥 유저 정보 헤더
                        
                        // 🔥 각 사용자의 TradeItemView 렌더링
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(grouped[ownerId] ?? []) { trade in
                                TradeItemView(trade: trade)
                            }
                        }
                    }
                    .padding(.bottom, 20) // 섹션 간격
                }
            }
        }
        .onAppear {
            viewModel.loadTrades()
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor(hex:"#121212")))
    }
    
    @ViewBuilder
    private func ownerHeaderView(ownerId: String) -> some View {
        if let user = viewModel.userMap[ownerId] {
            HStack(spacing: 8) {
                // 프로필 (예: AsyncImage)
                if let urlStr = user.profileImageURL,
                   let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure(_):
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                                .frame(width: 32, height: 32)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                }
                
                // 닉네임 + memo
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.nickname)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let memo = user.tradeMemo, !memo.isEmpty {
                        Text(memo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } else {
            // 아직 로딩 안 됨
            Text("Owner: \(ownerId)")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
