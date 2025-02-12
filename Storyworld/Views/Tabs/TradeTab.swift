//
//  TradeTab.swift
//  Storyworld
//
//  Created by peter on 2/10/25.
//

import SwiftUI

struct TradeTab: View {
    @State private var showingManageTrading = false // ✅ 트레이드 관리 시트
    @State private var showingTradingOffers = false // ✅ 받은 트레이드(알림) 시트
    
    var body: some View {
        ZStack(alignment: .bottom) { // ✅ 버튼을 하단에 고정
            ScrollView {
                VStack(spacing: 16) {
                    TradeView()
                }
                .padding(.horizontal, 16) // 좌우 패딩 적용
                .padding(.bottom, 80) // ✅ 버튼과 겹치지 않도록 하단 여백 추가
                .padding(.top, 16)
            }
            .background(Color(UIColor(hex:"#121212")))
            .toolbar {
                // 🔔 알림 버튼 (받은 트레이드 보기)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        showingTradingOffers.toggle() // ✅ 받은 트레이드 보기
                    }) {
                        Image(systemName: "bell") // 🔔 알림 아이콘
                    }
                }
            }
            
            // ✅ 트레이드 관리 버튼 (하단 고정)
            Button(action: {
                UIImpactFeedbackGenerator.trigger(.light)
                showingManageTrading.toggle() // ✅ 트레이드 등록/관리로 이동
            }) {
                Text("트레이드 등록")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 180, height: 50)
                    .background(Color(AppColors.mainColor))
                    .cornerRadius(32)
                    .shadow(radius: 4)
            }
            .padding(.bottom, 24) // 하단 여백 추가
        }
        // ✅ "트레이드 등록" 버튼 → `ManageTradingView()`
        .sheet(isPresented: $showingManageTrading) {
            ManageTradingView()
        }
        // ✅ "알림(🔔)" 버튼 → `ShowingTradingView()`
        .sheet(isPresented: $showingTradingOffers) {
            ShowingTradingView()
        }
    }
}
