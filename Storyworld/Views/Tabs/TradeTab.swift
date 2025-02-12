//
//  TradeTab.swift
//  Storyworld
//
//  Created by peter on 2/10/25.
//


import SwiftUI

struct TradeTab: View {
    @State private var showingTrading = false // 설정 시트 표시 여부를 관리하는 상태 변수
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TradeView()
            }
            .padding(.horizontal, 16) // 좌우 패딩 적용
            .padding(.bottom, 32) // 하단 패딩 적용
            .padding(.top, 16)
        }
        .background(Color(UIColor(hex:"#121212")))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator.trigger(.light)
                    showingTrading.toggle()
                }) {
                    Image(systemName: "bell") // 설정 아이콘
                }
            }
        }
        .sheet(isPresented: $showingTrading) {
            ShowingTradingView()
        }
    }
}
