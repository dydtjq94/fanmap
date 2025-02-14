//
//  TradeService.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//  (또는 원하는 생성일/파일명)
//
//  Firestore에 trades 컬렉션을 CRUD 하는 Service 레이어입니다.
//

import Foundation
import FirebaseFirestore

class TradeService {
    // 싱글톤 인스턴스
    static let shared = TradeService()
    private let db = Firestore.firestore()
    private let collectionService = CollectionService.shared
    
    // 생성자 private 처리 (직접 생성 방지)
    private init() {}
    
    // MARK: ✅ 트레이드 생성 (trades 컬렉션에 저장)
    func createTrade(video: Video, completion: @escaping (Result<String, Error>) -> Void) {
        // 현재 로그인한 유저 정보 가져오기
        guard let currentUser = UserService.shared.user else {
            print("❌ 현재 유저 정보가 없습니다. (로그인 여부 확인 필요)")
            completion(.failure(NSError(domain: "TradeService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let tradeRef = db.collection("trades").document()
        
        let newTrade = Trade(
            id: tradeRef.documentID,
            video: video,
            ownerId: currentUser.id,
            tradeStatus: .available,
            createdDate: Date()
        )
        
        do {
            try tradeRef.setData(from: newTrade) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(tradeRef.documentID))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // ✅ 트레이드 취소 메서드 (Firestore에서 트레이드 삭제 및 tradeOffers 삭제)
    func cancelTrade(ownerId: String, tradeId: String, completion: @escaping (Bool) -> Void) {
        let tradeRef = db.collection("trades").document(tradeId)
        
        // 트레이드 문서 삭제
        tradeRef.delete { error in
            if let error = error {
                print("❌ 트레이드 삭제 실패: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // tradeOffers 서브 컬렉션에서 제안된 트레이드 삭제
            let tradeOffersRef = tradeRef.collection("tradeOffers")
            
            // tradeOffers 서브 컬렉션의 모든 문서를 가져와서 삭제
            tradeOffersRef.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ tradeOffers 삭제 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // tradeOffers의 모든 제안 삭제
                for document in snapshot?.documents ?? [] {
                    document.reference.delete { error in
                        if let error = error {
                            print("❌ tradeOffer 삭제 실패: \(error.localizedDescription)")
                        } else {
                            print("✅ tradeOffer 삭제 완료")
                        }
                    }
                }

                // UserDefaults에서 로컬 데이터 삭제
                var collectedVideos = UserDefaults.standard.loadCollectedVideos()
                collectedVideos.removeAll { $0.id == tradeId }
                UserDefaults.standard.saveCollectedVideos(collectedVideos)
                
                print("✅ 트레이드 취소 및 삭제 완료: \(tradeId)")
                completion(true)
            }
        }
    }
    
    // MARK: - 20개의 최신 트레이드 로드 (OwnerId별로 그룹화)
    func loadTrades(completion: @escaping (Result<[Trade], Error>) -> Void) {
        // 현재 로그인한 유저 정보 가져오기
        guard let currentUser = UserService.shared.user else {
            completion(.failure(NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        // 'trades' 컬렉션에서 최근 날짜 순으로 20개 가져오기
        db.collection("trades")
            .whereField("tradeStatus", isEqualTo: "available")
            .order(by: "createdDate", descending: true) // 최근 날짜 기준으로 정렬
            .limit(to: 20) // 20개만 가져오기
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError(domain: "TradeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data found."])))
                    return
                }

                // Firestore에서 가져온 데이터를 Trade 구조체로 디코딩
                let trades: [Trade] = snapshot.documents.compactMap { document in
                    do {
                        let trade = try document.data(as: Trade.self)
                        return trade
                    } catch {
                        print("❌ Trade 디코딩 오류: \(error.localizedDescription)")
                        return nil
                    }
                }

                // 본인 트레이드를 제외한 트레이드만 필터링
                let filteredTrades = trades.filter { $0.ownerId != currentUser.id }

                // 결과 반환
                completion(.success(filteredTrades))
            }
    }

    
    func createTradeOffer(trade: Trade, offeredVideos: [Video], proposerId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 트레이드의 videoId에 해당하는 트레이드 상태 확인
        let videoTradeRef = db.collection("trades")
            .whereField("video.videoId", isEqualTo: trade.video.videoId)
        
        videoTradeRef.getDocuments { snapshot, error in
            // 에러 처리
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 이미 진행 중인 트레이드가 있을 경우 제안 불가
            if let snapshot = snapshot, !snapshot.isEmpty {
                for document in snapshot.documents {
                    let tradeData = document.data()
                    
                    // 안전하게 tradeStatus 값을 추출하고 조건 비교
                    if let status = tradeData["tradeStatus"] as? String, status == "pending" {
                        let error = NSError(domain: "TradeService", code: 409, userInfo: [NSLocalizedDescriptionKey: "이미 진행 중인 영상입니다."])
                        completion(.failure(error))
                        return
                    }
                }
            }
            
            
            // 트레이드 상태가 available일 때 제안 생성
            let tradeRef = self.db.collection("trades").document(trade.id)
            let tradeOffersRef = tradeRef.collection("tradeOffers").document()
            
            // 새로운 트레이드 제안 객체 생성
            let newTradeOffer = TradeOffer(
                id: tradeOffersRef.documentID,
                tradeOwnerId: trade.ownerId,
                proposerId: proposerId,
                tradeId: trade.id,
                offeredVideos: offeredVideos,
                status: "pending",
                createdDate: Timestamp(date: Date())
            )
            
            // 트레이드 제안 Firestore에 저장
            do {
                try tradeOffersRef.setData(from: newTradeOffer) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    // 트레이드 상태를 pending으로 변경
                    tradeRef.updateData([
                        "tradeStatus": "pending"
                    ]) { error in
                        if let error = error {
                            print("❌ 트레이드 상태 업데이트 실패: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ 트레이드 상태가 pending으로 변경됨")
                        }
                    }
                    
                    // 제안한 영상들의 상태를 'pending'으로 업데이트
                    self.updateVideosStatusToPending(for: offeredVideos, proposerId: proposerId) { updateError in
                        if let updateError = updateError {
                            completion(.failure(updateError))
                        } else {
                            // 모든 처리가 성공적으로 완료되었으면 제안 ID 반환
                            completion(.success(tradeOffersRef.documentID))
                        }
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateVideosStatusToPending(for offeredVideos: [Video], proposerId: String, completion: @escaping (Error?) -> Void) {
        guard let user = UserService.shared.user else {
            completion(NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 정보가 없습니다."]))
            return
        }
        
        let collectedVideosRef = db.collection("users").document(user.id).collection("collectedVideos")
        
        // 비동기적으로 모든 영상 상태를 업데이트
        let group = DispatchGroup()
        var updateError: Error?
        
        for video in offeredVideos {
            group.enter()  // 비동기 작업 시작
            
            collectedVideosRef.whereField("video.videoId", isEqualTo: video.videoId).getDocuments { snapshot, error in
                if let error = error {
                    updateError = error
                    group.leave()  // 작업 종료
                    return
                }
                
                if let snapshot = snapshot, let document = snapshot.documents.first {
                    document.reference.updateData([
                        "tradeStatus": "pending"
                    ]) { error in
                        if let error = error {
                            updateError = error
                        }
                        group.leave()  // 작업 종료
                    }
                } else {
                    group.leave()  // 영상이 없으면 작업 종료
                }
            }
        }
        
        group.notify(queue: .main) {
            // 모든 작업이 끝난 후 UserDefaults 상태 업데이트
            if updateError == nil {
                var collectedVideos = UserDefaults.standard.loadCollectedVideos()
                
                // offeredVideos에 해당하는 영상들의 상태를 "pending"으로 업데이트
                for (index, video) in collectedVideos.enumerated() {
                    if offeredVideos.contains(where: { $0.videoId == video.video.videoId }) {
                        collectedVideos[index].tradeStatus = .pending
                    }
                }
                
                // UserDefaults 덮어쓰기
                UserDefaults.standard.saveCollectedVideos(collectedVideos)
                print("✅ UserDefaults에서 영상 상태를 'pending'으로 업데이트 완료!")
            }
            
            // 완료 핸들러 호출
            completion(updateError)
        }
    }
    
    // MARK: ✅ 트레이드 수락 (Accept)
    func acceptTradeOffer(offer: TradeOffer, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        // 1. 제안한 영상 삭제 (자신의 영상에서)
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        
        // 내가 제안한 영상 삭제
        collectedVideos.removeAll { video in
            offer.offeredVideos.contains { offeredVideo in
                offeredVideo == video.video  // 'video' 객체 자체를 비교
            }
        }
        
        // UserDefaults에 업데이트된 상태 덮어쓰기
        UserDefaults.standard.saveCollectedVideos(collectedVideos)
        print("✅ 제안한 영상들을 UserDefaults에서 삭제 완료!")
        
        // 2. 상대방의 영상 추가 (Firestore에)
        let group = DispatchGroup()  // 여러 비동기 작업을 동시에 처리하기 위한 그룹
        var updateError: Error?
        
        for video in offer.offeredVideos {
            group.enter()  // 비동기 작업 시작
            
            let videoRef = db.collection("users")
                .document(offer.proposerId)  // 제안한 유저의 ID
                .collection("collectedVideos")
                .document(video.videoId)  // 영상 ID로 해당 영상 문서 찾기
            
            // 상대방의 영상을 내 컬렉션에 추가
            let newCollectedVideo = CollectedVideo(
                id: video.videoId,
                video: video,
                collectedDate: Date(),
                tradeStatus: .available,
                isFavorite: false,
                ownerId: UserService.shared.user?.id ?? "unknown"
            )
            
            // Firestore에 저장
            do {
                try videoRef.setData(from: newCollectedVideo) { error in
                    if let error = error {
                        updateError = error
                    }
                    group.leave()  // 비동기 작업 종료
                }
            } catch {
                updateError = error
                group.leave()  // 비동기 작업 종료
            }
        }
        
        // 3. 상대방의 제안한 영상 삭제 (Firestore)
        for video in offer.offeredVideos {
            group.enter()  // 비동기 작업 시작
            
            let proposerVideoRef = db.collection("users")
                .document(offer.proposerId)
                .collection("collectedVideos")
                .document(video.videoId)
            
            proposerVideoRef.delete() { error in
                if let error = error {
                    updateError = error
                }
                group.leave()  // 비동기 작업 종료
            }
        }
        
        // 4. 트레이드 상태를 'done'으로 변경 (Firestore)
        group.notify(queue: .main) {
            if let error = updateError {
                completion(.failure(error))
                return
            }
            
            let tradeRef = db.collection("trades").document(offer.tradeId)
            
            tradeRef.updateData([
                "tradeStatus": "done"
            ]) { error in
                if let error = error {
                    print("❌ 트레이드 상태 업데이트 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("✅ 트레이드 상태를 'done'으로 업데이트 완료!")
                
                // 5. 성공 콜백 호출
                completion(.success(()))
            }
        }
    }
    
    // MARK: ✅ 트레이드 거절 (Reject)
    func rejectTradeOffer(offer: TradeOffer, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. 상대방의 제안된 영상들의 상태를 'available'로 변경 (Firestore)
        let db = Firestore.firestore()
        
        let group = DispatchGroup()  // 여러 비동기 작업을 동시에 처리하기 위한 그룹
        var updateError: Error?
        
        for video in offer.offeredVideos {
            group.enter()  // 비동기 작업 시작
            
            // Firestore에서 해당 영상의 tradeStatus를 'available'로 변경
            let videoRef = db.collection("users")
                .document(offer.proposerId)  // 제안한 유저의 ID
                .collection("collectedVideos")
                .document(video.videoId)  // 영상 ID로 해당 영상 문서 찾기
            
            videoRef.updateData([
                "tradeStatus": "available"
            ]) { error in
                if let error = error {
                    updateError = error
                }
                group.leave()  // 비동기 작업 종료
            }
        }
        
        // 2. Firestore에서 트레이드 상태를 'available'로 변경
        group.notify(queue: .main) {
            if let error = updateError {
                completion(.failure(error))
                return
            }
            
            let tradeRef = db.collection("trades").document(offer.tradeId)
            
            tradeRef.updateData([
                "tradeStatus": "available"
            ]) { error in
                if let error = error {
                    print("❌ 트레이드 상태 업데이트 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("✅ 트레이드 상태를 'available'로 업데이트 완료!")
                
                // 3. 성공 콜백 호출
                completion(.success(()))
            }
        }
    }
}
