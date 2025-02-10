//
//  TradeService.swift
//  Storyworld
//
//  Created by peter on 2/8/25.
//

import Foundation
import FirebaseFirestore

class TradeService {
    static let shared = TradeService()
    private let db = Firestore.firestore()
    
    private init() { }
    
    // MARK: - 1) 마켓에 새로운 영상 등록
    func createMarketListing(from collectedVideo: CollectedVideo) async throws {
        let listing = MarketListing(
            video: collectedVideo.video,
            ownerId: collectedVideo.ownerId,
            tradeStatus: .available,
            createdDate: Date()
        )
        
        // 문서 ID를 자동 생성할 수도 있고, videoId로 할 수도 있음
        // 여기서는 "collectedVideo.id" (videoId)로 문서를 생성해보는 예시
        try await db.collection("market")
            .document(collectedVideo.id)
            .setData(from: listing)
        
        print("✅ MarketListing 등록 완료: \(collectedVideo.video.title)")
    }
    
    // MARK: - 2) 거래 가능한 목록 가져오기
    func fetchAvailableListings() async throws -> [MarketListing] {
        let snapshot = try await db.collection("market")
            .whereField("tradeStatus", isEqualTo: TradeStatus.available.rawValue)
            .getDocuments()
        
        let listings = try snapshot.documents.compactMap {
            try $0.data(as: MarketListing.self)
        }
        return listings
    }
    
    // MARK: - 3) 마켓 등록 해제(삭제 or 상태변경)
    func removeListing(withId listingId: String) async throws {
        // Firestore 문서를 삭제(완전히 제거)하거나,
        // tradeStatus = .notTradable 로 상태만 바꿀 수도 있음
        try await db.collection("market")
            .document(listingId)
            .delete()
        
        print("✅ MarketListing 문서(\(listingId)) 삭제 완료")
    }
    
    // 필요에 따라 거래 상세 조회, 거래 수락/거절 등 함수 추가
}
