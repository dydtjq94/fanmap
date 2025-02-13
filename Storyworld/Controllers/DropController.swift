//
//  DropController.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit
import MapboxMaps
import SwiftUI

final class DropController: UIViewController {
    private let dismissButton = UIButton(type: .system) // 화살표 버튼
    private let openDropButton = UIButton(type: .system) // Open drop 버튼
    
    // 희귀도 StackView 생성
    private let rarityContainerView = UIView()
    private let rarityImageView = UIImageView()
    private let rarityLabel = UILabel()
    private let rarityStackView = UIStackView()
    
    // 장르 StackView 생성
    private let genreContainerView = UIView()
    private let genreImageView = UIImageView()
    private let genreLabel = UILabel()
    private let genreStackView = UIStackView()
    
    // 전체 StackView
    private let infoStackView = UIStackView()
    
    private let dropView = DropView()
    private var selectedVideo: Video?
    private let circleData: CircleData // 🔥 CircleData를 저장
    private let mapView: MapView
    private var isFetchCompleted = false // 🔥 Fetch 완료 여부 추적 변수 추가
    
    init(circleData: CircleData, mapView: MapView) {
        self.circleData = circleData
        self.mapView = mapView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configureInitialView()
        
        // DropView의 클릭 이벤트 처리
        dropView.onPlayButtonTapped = { [weak self] in
            self?.handleDrop()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startDropViewAnimation()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(hex: "#171717")
        
        // Dismiss Button 설정
        dismissButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        dismissButton.tintColor = .white
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        
        // 희귀도 이미지 설정
        rarityImageView.image = UIImage(named: circleData.rarity.imageName)
        rarityImageView.contentMode = .scaleAspectFit
        rarityImageView.translatesAutoresizingMaskIntoConstraints = false
        
        rarityLabel.text = circleData.rarity.rawValue
        rarityLabel.textColor = circleData.rarity.uiColor
        rarityLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        // 희귀도 StackView 구성
        rarityStackView.axis = .horizontal
        rarityStackView.alignment = .center
        rarityStackView.spacing = 6
        rarityStackView.addArrangedSubview(rarityImageView)
        rarityStackView.addArrangedSubview(rarityLabel)
        rarityStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 희귀도 컨테이너 뷰 설정 (배경 색 추가)
        rarityContainerView.backgroundColor = circleData.rarity.backgroundColor
        rarityContainerView.layer.cornerRadius = 8
        rarityContainerView.translatesAutoresizingMaskIntoConstraints = false
        rarityContainerView.addSubview(rarityStackView)
        
        // 장르 SF Symbol 설정
        genreImageView.image = UIImage(named: circleData.channel.imageName)
        genreImageView.tintColor = .gray
        genreImageView.contentMode = .scaleAspectFit
        genreImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // ✅ 이미지 원형으로 만들기
        genreImageView.layer.cornerRadius = 12  // 🔥 반지름을 절반으로 설정 (24x24 가정)
        genreImageView.clipsToBounds = true  // ✅ 원형 적용 유지
        
        genreLabel.text = circleData.channel.localized()
        genreLabel.textColor = .white  // 🔥 흰색으로 변경
        genreLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        // 장르 StackView 구성
        genreStackView.axis = .horizontal
        genreStackView.alignment = .center
        genreStackView.spacing = 6
        genreStackView.addArrangedSubview(genreImageView)
        genreStackView.addArrangedSubview(genreLabel)
        genreStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 장르 컨테이너 뷰 설정 (배경 색 추가)
        genreContainerView.backgroundColor = circleData.rarity.backgroundColor
        genreContainerView.layer.cornerRadius = 8
        genreContainerView.translatesAutoresizingMaskIntoConstraints = false
        genreContainerView.addSubview(genreStackView)
        
        // 메인 스택뷰 설정
        infoStackView.axis = .horizontal
        infoStackView.alignment = .center
        infoStackView.spacing = 12
        infoStackView.addArrangedSubview(rarityContainerView)
        infoStackView.addArrangedSubview(genreContainerView)
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStackView)
        
        // Open Drop Button 설정
        openDropButton.setTitle("영상 열기", for: .normal)
        openDropButton.setTitleColor(.black, for: .normal)
        openDropButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        openDropButton.backgroundColor = AppColors.mainColor
        openDropButton.layer.cornerRadius = 10
        openDropButton.addTarget(self, action: #selector(handleDrop), for: .touchUpInside)
        openDropButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openDropButton)
        
        // DropView 추가
        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.backgroundColor = circleData.rarity.dropBackgroundColor
        view.addSubview(dropView)
        
        // Constraints 설정
        NSLayoutConstraint.activate([
            // Dismiss Button (왼쪽 상단)
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Rarity StackView 크기 조정
            rarityStackView.leadingAnchor.constraint(equalTo: rarityContainerView.leadingAnchor, constant: 8),
            rarityStackView.trailingAnchor.constraint(equalTo: rarityContainerView.trailingAnchor, constant: -8),
            rarityStackView.topAnchor.constraint(equalTo: rarityContainerView.topAnchor, constant: 3),
            rarityStackView.bottomAnchor.constraint(equalTo: rarityContainerView.bottomAnchor, constant: -3),
            rarityStackView.heightAnchor.constraint(equalToConstant: 24),
                    
            // Genre StackView 크기 조정
            genreStackView.leadingAnchor.constraint(equalTo: genreContainerView.leadingAnchor, constant: 8),
            genreStackView.trailingAnchor.constraint(equalTo: genreContainerView.trailingAnchor, constant: -8),
            genreStackView.topAnchor.constraint(equalTo: genreContainerView.topAnchor, constant: 3),
            genreStackView.bottomAnchor.constraint(equalTo: genreContainerView.bottomAnchor, constant: -3),
            genreStackView.heightAnchor.constraint(equalToConstant: 24),
            
            // 희귀도 및 장르 이미지 크기 조정
            rarityImageView.widthAnchor.constraint(equalToConstant: 18),
            rarityImageView.heightAnchor.constraint(equalToConstant: 18),
            genreImageView.widthAnchor.constraint(equalToConstant: 18),
            genreImageView.heightAnchor.constraint(equalToConstant: 18),
            
            // Main StackView 위치 조정
            infoStackView.bottomAnchor.constraint(equalTo: openDropButton.topAnchor, constant: -24),
            infoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Open Drop Button (화면 최하단)
            openDropButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            openDropButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openDropButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            openDropButton.heightAnchor.constraint(equalToConstant: 50),
            
            // DropView 중앙 배치
            dropView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dropView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dropView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
        ])
    }
    
    private func configureInitialView() {
        //         DropView에 기본 정보 업데이트
        dropView.dropSettingView(channel: circleData.channel.localized(), rarity: circleData.rarity.rawValue)
    }
    
    private func startDropViewAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // blurView를 왼쪽 하단으로 3px 이동
            self.dropView.subviews.forEach { view in
                if view is UIVisualEffectView {
                    view.transform = CGAffineTransform(translationX: -5, y: 3)
                }
            }
            // dropImageView를 오른쪽 상단으로 3px 이동
            self.dropView.dropImageView.transform = CGAffineTransform(translationX: 5, y: -3)
        }, completion: { _ in

            UIImpactFeedbackGenerator.trigger(.heavy)
        })
    }
    
    private func againDropViewAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.dropView.subviews.forEach { view in
                if view is UIVisualEffectView {
                    view.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
            
            self.dropView.dropImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { _ in
            UIImpactFeedbackGenerator.trigger(.heavy)
        })
    }
    
    
    @objc private func dismissView() {
        UIImpactFeedbackGenerator.trigger(.light)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDrop() {
        // 중복 실행 방지
        guard dropView.playButton.isUserInteractionEnabled, openDropButton.isUserInteractionEnabled else { return }

        // 버튼 클릭 차단 (시각적으로 그대로 유지)
        dropView.playButton.isUserInteractionEnabled = false
        openDropButton.isUserInteractionEnabled = false

        startImageAnimation()
        
        // 애니메이션과 비디오 fetch 동시에 시작
        let animationStartTime = Date()
        
        fetchVideosAndAnimate { video in
            let elapsedTime = Date().timeIntervalSince(animationStartTime)
            let remainingTime = max(3.0 - elapsedTime, 0) // 3초를 보장하기 위한 대기 시간

            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                if let video = video {
                    self.showDropResult(with: video)
                } else {
                    print("⚠️ No video available.")
                    self.resetDropView()
                }
            }
        }
    }
    
    private func fetchVideosAndAnimate(completion: @escaping (Video?) -> Void) {
        // 🔥 타일 데이터 업데이트
        TileService().updateLastDropTime(for: circleData)

        // ✅ mapView를 이용해서 VideoLayerMapManager 생성 후 업데이트 실행
        VideoLayerMapManager(mapView: mapView).updateVideoCircleLayer(for: circleData)

        CollectionService.shared.fetchRandomVideoByChannel(channel: circleData.channel, rarity: circleData.rarity) { result in
            DispatchQueue.main.async {
                self.isFetchCompleted = true // 🔥 Fetch 완료 시 플래그 변경
                
                switch result {
                case .success(let video):
                    self.selectedVideo = video
                    Task {
                        await CollectionService.shared.saveCollectedVideo(video) // ✅ `Task` 내부에서 `await` 사용
                    }
                    completion(video)
                case .failure(let error):
                    print("Error fetching video: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }

    private func startImageAnimation() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: largeConfig)
        
        self.dropView.playButton.setImage(pauseImage, for: .normal)
        againDropViewAnimation()
        
        // 애니메이션 시퀀스 실행
        self.animateImageSequence { [weak self] in
            guard self != nil else { return }
            print("🎥 Image animation completed, waiting for video fetch...")
        }
    }

    private var imageIndex = 0
    private var timer: Timer?

    private func animateImageSequence(completion: @escaping () -> Void) {
        let imageCount = 11
        let images = (1...imageCount).map { "image\($0)" }
        let interval: TimeInterval = 0.1
        let animationStartTime = Date()

        imageIndex = Int.random(in: 1...10)
        
        // 타이머 시작
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            // 이미지 변경
            self.dropView.dropImageView.image = UIImage(named: images[self.imageIndex])

            // 햅틱 피드백
            UIImpactFeedbackGenerator.trigger(.light)

            self.imageIndex += 1
            if self.imageIndex >= images.count {
                self.imageIndex = 0
            }
        }
        
        // **fetch & 3초 조건을 모두 만족하면 타이머 종료**
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            // 🔥 fetch 완료될 때까지 기다림
            while !self.isFetchCompleted { usleep(100_000) } // 0.1초 대기

            // **최소 3초는 보장 후 종료**
            let remainingTime = max(3.0 - Date().timeIntervalSince(animationStartTime), 0)
            usleep(useconds_t(remainingTime * 1_000_000)) // 남은 시간만큼 대기

            // 타이머 중지 & 애니메이션 종료
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = nil
                completion() // 애니메이션 종료 후 callback 실행 (영상 표시)
            }
        }
    }
    
    private func showDropResult(with video: Video) {
        // 기존에 있는 모든 서브뷰 제거 (메인 스레드에서 실행)
        DispatchQueue.main.async {
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            // SwiftUI 뷰를 HostingController로 감싸기
            let hostingController = UIHostingController(
                rootView: DropResultView(
                    video: video
                ) {
                    DispatchQueue.main.async { // ✅ 메인 스레드에서 실행하도록 변경
                        self.dismiss(animated: true, completion: nil) // 닫기 액션
                    }
                }
            )

            // 배경 투명하게 설정
            hostingController.view.backgroundColor = UIColor.clear

            // 새로운 SwiftUI 뷰 추가
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)

            // Auto Layout 설정
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            // 등장 애니메이션 적용
            hostingController.view.alpha = 0
            hostingController.view.transform = CGAffineTransform(translationX: 0, y: 30)
            
            UIView.animate(
                withDuration: 0.4,
                delay: 0.1,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    hostingController.view.alpha = 1
                    hostingController.view.transform = .identity
                }
            )
        }
    }
    
    private func resetDropView() {
        print("⚠️ Resetting Drop View due to error.")
        dropView.playButton.isUserInteractionEnabled = true
        openDropButton.isUserInteractionEnabled = true
        let playImage = UIImage(systemName: "play.fill")
        dropView.playButton.setImage(playImage, for: .normal)
    }
    
}
