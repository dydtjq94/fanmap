//
//  TradeMyVideoViewModel.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI

class TradeMyVideoViewModel: ObservableObject {
    @Published var myCollectedVideos: [CollectedVideo] = []
    
    private let collectionService = CollectionService.shared
    
    /// Firestore & UserDefaults에서 내 영상 목록 로드
    func loadMyVideos() {
        let videos = collectionService.fetchAllVideos()
        let uniqueVideos = Array(Set(videos)).sorted { $0.collectedDate > $1.collectedDate }
        myCollectedVideos = uniqueVideos
        
        print("✅ 내 수집 영상 로드 완료: \(myCollectedVideos.count)개")
    }
}
