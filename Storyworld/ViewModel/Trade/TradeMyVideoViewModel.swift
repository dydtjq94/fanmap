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
    
    /// Firestore & UserDefaults에서 내 영상 목록 로드 (available 상태의 영상만)
    func loadMyVideos() {
        // 내 모든 영상 목록 가져오기
        let videos = collectionService.fetchAllVideos()
        
        // tradeStatus가 'available'인 영상만 필터링
        let availableVideos = videos.filter { $0.tradeStatus.rawValue == "available" }
        
        // 중복 제거 및 날짜 순으로 정렬
        let uniqueVideos = Array(Set(availableVideos)).sorted { $0.collectedDate > $1.collectedDate }
        
        // 필터링된 영상 목록 업데이트
        myCollectedVideos = uniqueVideos
        
        print("✅ 내 수집 영상 중 available 상태 로드 완료: \(myCollectedVideos.count)개")
    }
}
