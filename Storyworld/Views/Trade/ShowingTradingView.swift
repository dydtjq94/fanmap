//
//  ShowingTradingView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI

struct ShowingTradingView: View {
    @StateObject private var viewModel = TradeOfferViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack {
                if $viewModel.offers.isEmpty {
                    Text("받은 트레이드 요청이 없습니다.")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.offers) { offer in
                                OfferItemView(offer: offer, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color(UIColor(hex: "#1D1D1D")))
            .onAppear {
                viewModel.loadReceivedOffers() // ✅ Firestore에서 받은 오퍼 불러오기
            }
            .navigationTitle("트레이드 요청") // ✅ 상단 제목 추가
            .navigationBarTitleDisplayMode(.inline) // ✅ 작은 제목 스타일
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.down") // 🔽 닫기 버튼
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
