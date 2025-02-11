import Foundation
import FirebaseFirestore

class TradeService {
    static let shared = TradeService()
    private init() {}
    
    /// 특정 영상(videoId)에 해당하는 Trade 문서가 있는지 검사
    func checkIfTradeExists(ownerId: String, videoId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tradeDocRef = db
            .collection("users").document(ownerId)
            .collection("myTrades").document(videoId)
        
        tradeDocRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Trade 문서 조회 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            // 문서가 존재하면 true
            completion(snapshot?.exists == true)
        }
    }
    
    /// 새 트레이드 생성 (유저 하위 `myTrades` 서브컬렉션)
    func createTrade(for collectedVideo: CollectedVideo, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // 예: /users/{ownerId}/myTrades/{videoId}
        let userRef = db.collection("users").document(collectedVideo.ownerId)
        let myTradesRef = userRef.collection("myTrades")
        
        // 🔥 문서 ID를 video.videoId 로 사용 (중복등록 방지)
        let videoId = collectedVideo.video.videoId
        let newDoc = myTradesRef.document(videoId)
        
        let trade = Trade(
            id: newDoc.documentID,    // = videoId
            video: collectedVideo.video,
            ownerId: collectedVideo.ownerId,
            tradeStatus: .available,
            createdDate: Date()
        )
        
        do {
            try newDoc.setData(from: trade)
            print("✅ Trade 문서 생성 완료 (videoId=\(videoId))")
            completion(true)
        } catch {
            print("❌ Error creating trade: \(error)")
            completion(false)
        }
    }
    
    /// 특정 영상(videoId)에 해당하는 Trade 문서가 있다면 삭제
    func deleteTradeIfExists(ownerId: String, videoId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tradeDocRef = db
            .collection("users").document(ownerId)
            .collection("myTrades").document(videoId)
        
        tradeDocRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Trade 문서 조회 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // 문서가 존재하면 삭제
            if snapshot?.exists == true {
                tradeDocRef.delete { err in
                    if let err = err {
                        print("❌ Trade 문서 삭제 오류: \(err.localizedDescription)")
                        completion(false)
                    } else {
                        print("🔥 Trade 문서 삭제 완료 (videoId = \(videoId))")
                        completion(true)
                    }
                }
            } else {
                print("⚠️ 해당 Trade 문서가 없습니다. (이미 삭제되었거나 생성 안됨)")
                completion(true) // 문서 없으니 문제없이 true 처리
            }
        }
    }

    /// 모든 트레이드 가져오기: Collection Group 쿼리
    func fetchAllTrades(completion: @escaping ([Trade]) -> Void) {
        let db = Firestore.firestore()
        
        // ⚠️ 주의: "myTrades" 라는 이름이 맞아야 함
        db.collectionGroup("myTrades")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching trades: \(error.localizedDescription)")
                    completion([])
                    return
                }
                print("✅ Query succeeded. Document count: \(snapshot?.documents.count ?? 0)")
                     
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                // Snapshot → Trade 배열로 디코딩
                let trades: [Trade] = documents.compactMap { doc in
                    return try? doc.data(as: Trade.self)
                }
                completion(trades)
            }
    }
    
    // 필요에 따라 추가할 함수들 (updateTradeStatus, fetchTradesByUser 등)
    // ...
}
