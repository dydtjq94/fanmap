import Foundation
import FirebaseFirestore

class TradeService {
    static let shared = TradeService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    func fetchUserTrades(userId: String, status: TradeStatus, completion: @escaping ([Trade]) -> Void) {
        let db = Firestore.firestore()
        let tradesRef = db.collection("users").document(userId).collection("myTrades")

        tradesRef.whereField("tradeStatus", isEqualTo: status.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [fetchUserTrades] 트레이드 가져오기 실패: \(error.localizedDescription)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let trades: [Trade] = documents.compactMap { try? $0.data(as: Trade.self) }
                print("✅ [fetchUserTrades] \(status.rawValue) 상태 트레이드 불러오기 완료: \(trades.count)개")
                completion(trades)
            }
    }

    
    /// 최신 20명의 유저를 가져온 후, 각 유저별 "available" 상태 트레이드 가져오기
    func fetchAvailableTradesForUsers(users: [User], completion: @escaping ([Trade]) -> Void) {
        var allTrades: [Trade] = []
        let group = DispatchGroup()
        
        for user in users {
            group.enter()
            let tradesRef = db.collection("users").document(user.id).collection("myTrades")
            
            tradesRef.whereField("tradeStatus", isEqualTo: "available") // ✅ "available" 상태 필터링
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ [fetchAvailableTradesForUsers] \(user.nickname)의 트레이드 가져오기 오류: \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        group.leave()
                        return
                    }
                    
                    let trades: [Trade] = documents.compactMap { doc in
                        return try? doc.data(as: Trade.self)
                    }
                    print("✅ \(user.nickname)의 'available' 상태 트레이드 가져오기 완료: \(trades.count)개")
                    
                    allTrades.append(contentsOf: trades)
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            print("✅ 전체 'available' 상태의 트레이드 목록 가져오기 완료: \(allTrades.count)개")
            completion(allTrades)
        }
    }
    
    // MARK: - 📌 트레이드 문서 관련 (생성, 삭제, 상태 업데이트)
    
    /// 새 트레이드 생성 (유저 하위 `myTrades` 서브컬렉션)
    func createTrade(for collectedVideo: CollectedVideo, completion: @escaping (Bool) -> Void) {
        let userRef = db.collection("users").document(collectedVideo.ownerId)
        let tradeDocRef = userRef.collection("myTrades").document() // ✅ Firestore 자동 문서 ID 사용
        let tradeId = tradeDocRef.documentID // ✅ 문서 ID 가져오기
        
        let trade = Trade(
            id: tradeId, // ✅ UUID 기반 트레이드 ID
            video: collectedVideo.video,
            ownerId: collectedVideo.ownerId,
            tradeStatus: .available,
            createdDate: Date()
        )
        
        let now = Date() // ✅ 현재 시간 저장

        db.runTransaction { transaction, errorPointer in
            do {
                // ✅ 1. 새로운 트레이드 문서 저장
                try transaction.setData(from: trade, forDocument: tradeDocRef)

                // ✅ 2. 유저 문서의 `tradeUpdated` 필드 갱신 (현재 시간으로 업데이트)
                transaction.updateData(["tradeUpdated": FieldValue.serverTimestamp()], forDocument: userRef)

                print("✅ [createTrade] Trade 생성 완료 (tradeId=\(tradeId), videoId=\(trade.video.videoId))")
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                print("❌ [createTrade] Trade 생성 오류: \(error.localizedDescription)")
                return nil
            }
        } completion: { success, error in
            if let error = error {
                print("❌ [createTrade] Firestore 트랜잭션 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [createTrade] Trade 생성 및 tradeUpdated 필드 갱신 완료!")

                // ✅ 3. tradeUpdated를 UserDefaults에도 즉시 반영
                if var user = UserService.shared.user {
                    user.tradeUpdated = now
                    UserService.shared.saveUser(user)
                    print("✅ [createTrade] tradeUpdated UserDefaults 저장 완료! \(now)")
                }
                completion(true)
            }
        }
    }

    /// 특정 트레이드(tradeId)에 해당하는 Trade 문서가 있다면 삭제
    func deleteTradeIfExists(ownerId: String, tradeId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(ownerId)
        let tradeDocRef = userRef.collection("myTrades").document(tradeId)
        
        let now = Date() // ✅ 현재 시간 저장
        
        db.runTransaction { transaction, errorPointer in
            do {
                let tradeDoc = try transaction.getDocument(tradeDocRef)

                if tradeDoc.exists {
                    // ✅ 1. 트레이드 문서 삭제
                    transaction.deleteDocument(tradeDocRef)

                    // ✅ 2. 유저 문서의 `tradeUpdated` 필드 갱신 (현재 시간으로 업데이트)
                    transaction.updateData(["tradeUpdated": FieldValue.serverTimestamp()], forDocument: userRef)

                    print("🔥 [deleteTradeIfExists] Trade 문서 삭제 완료 (tradeId=\(tradeId))")
                    return nil
                } else {
                    print("⚠️ [deleteTradeIfExists] 해당 Trade 문서 없음 (이미 삭제됨)")
                    return nil
                }
            } catch {
                errorPointer?.pointee = error as NSError
                print("❌ [deleteTradeIfExists] Trade 삭제 오류: \(error.localizedDescription)")
                return nil
            }
        } completion: { success, error in
            if let error = error {
                print("❌ [deleteTradeIfExists] Firestore 트랜잭션 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [deleteTradeIfExists] Trade 삭제 및 tradeUpdated 필드 갱신 완료!")

                // ✅ 3. tradeUpdated를 UserDefaults에도 즉시 반영
                if var user = UserService.shared.user {
                    user.tradeUpdated = now
                    UserService.shared.saveUser(user)
                    print("✅ [deleteTradeIfExists] tradeUpdated UserDefaults 저장 완료! \(now)")
                }
                completion(true)
            }
        }
    }

    
    /// Trade 상태 업데이트 (예: "available" → "pending" → "done")
    func updateTradeStatus(ownerId: String, videoId: String, newStatus: String, completion: @escaping (Bool) -> Void) {
        let tradeDocRef = db.collection("users").document(ownerId).collection("myTrades").document(videoId)
        
        tradeDocRef.updateData(["tradeStatus": newStatus]) { error in
            if let error = error {
                print("❌ [updateTradeStatus] 상태 업데이트 오류: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [updateTradeStatus] Trade 상태 업데이트 완료: \(newStatus) (videoId=\(videoId))")
                completion(true)
            }
        }
    }
    
    // MARK: - 📌 Offer 관리 (신청, 승인, 거절)
    func createOffer(for trade: Trade, offeredVideos: [Video], proposerId: String, completion: @escaping (Bool) -> Void) {
        let tradeRef = db.collection("users").document(trade.ownerId).collection("myTrades").document(trade.id)
        let offerRef = tradeRef.collection("offer").document() // 항상 하나만 유지
        let offerId = offerRef.documentID // ✅ 문서 ID 가져오기
        
        db.runTransaction { transaction, errorPointer in
            do {
                let tradeDoc = try transaction.getDocument(tradeRef)
                if let existingTrade = tradeDoc.data(), let status = existingTrade["tradeStatus"] as? String, status == "pending" {
                    print("⚠️ [createOffer] 이미 진행 중인 거래가 있음")
                    return nil
                }
                
                let offerData: [String: Any] = [
                    "id": offerId, // ✅ Firestore 문서 ID 추가
                    "tradeOwnerId": trade.ownerId, // ✅ 트레이드 소유자 ID
                    "proposerId": proposerId, // ✅ 제안을 보낸 유저 ID
                    "trade": (try? Firestore.Encoder().encode(trade)) ?? [:],
                    "offeredVideos": offeredVideos.compactMap { try? Firestore.Encoder().encode($0) }, // ✅ Video 데이터 저장 (try? 추가)
                    "status": "pending", // ✅ 초기 상태
                    "createdDate": Timestamp(date: Date()) // ✅ 생성 시각 추가
                ]
                
                transaction.setData(offerData, forDocument: offerRef)
                transaction.updateData(["tradeStatus": "pending"], forDocument: tradeRef)
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                print("❌ [createOffer] Offer 데이터 인코딩 실패: \(error.localizedDescription)")
                return nil
            }
        } completion: { success, error in
            if let error = error {
                print("❌ [createOffer] Offer 생성 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [createOffer] Offer 생성 완료!")
                completion(true)
            }
        }
    }
    
    /// ✅ Offer 승인 시 영상 교환 로직 포함 (UserDefaults에서도 반영)
    func acceptOffer(for trade: Trade, offerId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tradeRef = db.collection("users").document(trade.ownerId).collection("myTrades").document(trade.id)
        let offerRef = tradeRef.collection("offer").document(offerId)

        db.runTransaction { transaction, errorPointer in
            do {
                // 1️⃣ Offer 문서 확인
                let offerDoc = try transaction.getDocument(offerRef)
                guard let offerData = offerDoc.data(),
                      let proposerId = offerData["proposerId"] as? String,
                      let offeredVideos = offerData["offeredVideos"] as? [[String: Any]] else {
                    print("⚠️ [acceptOffer] Offer 문서가 올바르지 않음")
                    return nil
                }

                // 2️⃣ 트레이드 상태 변경 (pending → done)
                transaction.updateData(["tradeStatus": "done"], forDocument: tradeRef)

                // 3️⃣ 서로의 `collectedVideos` 교환 로직
                let ownerRef = db.collection("users").document(trade.ownerId).collection("collectedVideos")
                let proposerRef = db.collection("users").document(proposerId).collection("collectedVideos")

                // ✅ UserDefaults에서 기존 영상 제거
                var localVideos = UserDefaults.standard.loadCollectedVideos()
                localVideos.removeAll { $0.video.videoId == trade.video.videoId }
                UserDefaults.standard.saveCollectedVideos(localVideos)
                print("🔥 [acceptOffer] UserDefaults에서 내 영상 제거 완료")

                // 🔥 3-1) 내 영상 → 상대방의 `collectedVideos` 에 추가
                let myTradeVideo = trade.video
                let newOwnerCollectedVideo = CollectedVideo(
                    id: myTradeVideo.videoId,
                    video: myTradeVideo,
                    collectedDate: Date(),
                    tradeStatus: .available,
                    isFavorite: false,
                    ownerId: proposerId
                )
                let newOwnerVideoRef = proposerRef.document(myTradeVideo.videoId)
                try transaction.setData(from: newOwnerCollectedVideo, forDocument: newOwnerVideoRef)

                // 🔥 3-2) 상대방이 제안한 영상들 → 내 `collectedVideos` 에 추가
                for videoData in offeredVideos {
                    guard let videoId = videoData["videoId"] as? String,
                          let title = videoData["title"] as? String,
                          let description = videoData["description"] as? String,
                          let channelId = videoData["channelId"] as? String,
                          let publishDateTimestamp = videoData["publishDate"] as? Timestamp,
                          let rarityRaw = videoData["rarity"] as? String,
                          let rarity = VideoRarity(rawValue: rarityRaw) else { continue }

                    let publishDate = publishDateTimestamp.dateValue() // Firestore Timestamp → Date 변환

                    let newVideo = CollectedVideo(
                        id: videoId,
                        video: Video(
                            videoId: videoId,
                            title: title,
                            description: description,
                            channelId: channelId,
                            publishDate: publishDate,
                            rarity: rarity
                        ),
                        collectedDate: Date(),
                        tradeStatus: .available,
                        isFavorite: false,
                        ownerId: trade.ownerId
                    )

                    let newVideoRef = ownerRef.document(videoId)
                    try transaction.setData(from: newVideo, forDocument: newVideoRef)

                    // ✅ UserDefaults에도 추가
                    localVideos.append(newVideo)
                }

                // 🔥 4) 서로의 기존 영상 삭제 (거래 완료된 영상들)
                let myVideoRef = ownerRef.document(myTradeVideo.videoId)
                transaction.deleteDocument(myVideoRef)

                for videoData in offeredVideos {
                    if let videoId = videoData["videoId"] as? String {
                        let proposerVideoRef = proposerRef.document(videoId)
                        transaction.deleteDocument(proposerVideoRef)

                        // ✅ UserDefaults에서도 삭제
                        localVideos.removeAll { $0.video.videoId == videoId }
                    }
                }

                // ✅ UserDefaults에 최종 저장
                UserDefaults.standard.saveCollectedVideos(localVideos)
                print("🔥 [acceptOffer] UserDefaults에 최종 반영 완료")

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        } completion: { success, error in
            if let error = error {
                print("❌ [acceptOffer] Offer 승인 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [acceptOffer] Offer 승인 완료, Trade 상태 업데이트 및 영상 교환 완료!")
                completion(true)
            }
        }
    }

    
    /// Offer 거절 (트레이드 다시 available 상태로 복구)
    func rejectOffer(for trade: Trade, offerId: String, completion: @escaping (Bool) -> Void) {
        let tradeRef = db.collection("users").document(trade.ownerId).collection("myTrades").document(trade.id)
        let offerRef = tradeRef.collection("offer").document(offerId)
        
        db.runTransaction { transaction, errorPointer in
            do {
                let offerDoc = try transaction.getDocument(offerRef)
                if offerDoc.exists {
                    transaction.updateData(["status": "rejected"], forDocument: offerRef)
                    transaction.updateData(["tradeStatus": "available"], forDocument: tradeRef)
                    transaction.deleteDocument(offerRef) // Offer 삭제
                } else {
                    print("⚠️ [rejectOffer] Offer가 존재하지 않음")
                    return nil
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        } completion: { success, error in
            if let error = error {
                print("❌ [rejectOffer] Offer 거절 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ [rejectOffer] Offer 거절 완료, Trade 상태 복원됨!")
                completion(true)
            }
        }
    }
}
