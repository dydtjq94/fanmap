//
//  CollectionView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct CollectionView: View {
    @ObservedObject var viewModel = CollectionViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))

                    Text("수집한 영상")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))
                }

                Spacer()

                NavigationLink(destination: CollectionAllView()) {
                    Text("전체 보기")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor(hex: "#8F8E94")))
                }.simultaneousGesture(TapGesture().onEnded {
                    UIImpactFeedbackGenerator.trigger(.light)
                })
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            if viewModel.collectedVideos.isEmpty {
                Text("아직 수집한 영상이 없어요!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.collectedVideos.prefix(10), id: \.video.videoId) { collectedVideo in
                        CollectionItemView(collectedVideo: collectedVideo)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor(hex:"#1D1D1D")))
        .cornerRadius(16)
        .onAppear {
            viewModel.loadVideos()
        }
    }
}
