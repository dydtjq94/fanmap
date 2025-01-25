//
//  DropController.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit
import MapboxMaps

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
    private let genre: VideoGenre // 장르
    private let rarity: VideoRarity // 희귀도
    
    init(genre: VideoGenre, rarity: VideoRarity) {
        self.genre = genre
        self.rarity = rarity
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
        rarityImageView.image = UIImage(named: rarity.imageName)
        rarityImageView.contentMode = .scaleAspectFit
        rarityImageView.translatesAutoresizingMaskIntoConstraints = false
        
        rarityLabel.text = rarity.rawValue
        rarityLabel.textColor = rarity.uiColor
        rarityLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        // 희귀도 StackView 구성
        rarityStackView.axis = .horizontal
        rarityStackView.alignment = .center
        rarityStackView.spacing = 6
        rarityStackView.addArrangedSubview(rarityImageView)
        rarityStackView.addArrangedSubview(rarityLabel)
        rarityStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 희귀도 컨테이너 뷰 설정 (배경 색 추가)
        rarityContainerView.backgroundColor = rarity.backgroundColor
        rarityContainerView.layer.cornerRadius = 8
        rarityContainerView.translatesAutoresizingMaskIntoConstraints = false
        rarityContainerView.addSubview(rarityStackView)
        
        // 장르 SF Symbol 설정
        genreImageView.image = UIImage(systemName: "play.fill")?.withRenderingMode(.alwaysTemplate)
        //        genreImageView.image = UIImage(named: "chim")
        genreImageView.tintColor = genre.uiColor
        genreImageView.contentMode = .scaleAspectFit
        genreImageView.translatesAutoresizingMaskIntoConstraints = false
        
        genreLabel.text = genre.localized()
        genreLabel.textColor = genre.uiColor
        genreLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        // 장르 StackView 구성
        genreStackView.axis = .horizontal
        genreStackView.alignment = .center
        genreStackView.spacing = 6
        genreStackView.addArrangedSubview(genreImageView)
        genreStackView.addArrangedSubview(genreLabel)
        genreStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 장르 컨테이너 뷰 설정 (배경 색 추가)
        genreContainerView.backgroundColor = genre.backgroundColor
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
        openDropButton.setTitle("Open drop", for: .normal)
        openDropButton.setTitleColor(.white, for: .normal)
        openDropButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        openDropButton.backgroundColor = UIColor(hex:"F8483B")
        openDropButton.layer.cornerRadius = 10
        openDropButton.addTarget(self, action: #selector(handleDrop), for: .touchUpInside)
        openDropButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openDropButton)
        
        // DropView 추가
        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.backgroundColor = genre.backgroundColor
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
        dropView.dropSettingView(genre: genre.localized(), rarity: rarity.rawValue)
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
            // 애니메이션 완료 시 햅틱 피드백 실행
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()  // 미리 준비 (더 부드러운 피드백 제공)
            generator.impactOccurred()
        })
    }
    
    private func againDropViewAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            // blurView를 왼쪽 하단으로 3px 이동
            self.dropView.subviews.forEach { view in
                if view is UIVisualEffectView {
                    view.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
            // dropImageView를 오른쪽 상단으로 3px 이동
            self.dropView.dropImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { _ in
            // 애니메이션 완료 시 햅틱 피드백 실행
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()  // 미리 준비 (더 부드러운 피드백 제공)
            generator.impactOccurred()
        })
    }
    
    
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDrop() {
        // 중복 실행 방지
        guard dropView.playButton.isUserInteractionEnabled, openDropButton.isUserInteractionEnabled else { return }
        
        // 버튼 클릭 차단 (시각적으로 그대로 유지)
        dropView.playButton.isUserInteractionEnabled = false
        openDropButton.isUserInteractionEnabled = false

        // 비디오 가져오고 애니메이션 실행
        fetchVideosAndAnimate()
    }
    
    private func fetchVideosAndAnimate() {
        CollectionService.shared.fetchUncollectedVideos(for: genre, rarity: rarity) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let filteredVideos):
                    guard let video = filteredVideos.randomElement() else {
                        print("⚠️ No videos available")
                        return
                    }
                    self?.selectedVideo = video
                    CollectionService.shared.saveCollectedVideo(video)
                    self?.startImageAnimation()
                case .failure(let error):
                    print("❌ 비디오 가져오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var imageIndex = 0
    private var timer: Timer?
    
    private func startImageAnimation() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: largeConfig)
        
        self.dropView.playButton.setImage(pauseImage, for: .normal)
        againDropViewAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let video = self.selectedVideo else {
                print("⚠️ No video available to start animation.")
                return
            }
            self.animateImageSequence {
                self.showDropResult(with: video)
            }
        }
    }
    
    private func animateImageSequence(completion: @escaping () -> Void) {
        let imageCount = 11
        let images = (1...imageCount).map { "image\($0)" }
        let totalDuration: TimeInterval = 3
        let interval: TimeInterval = 0.1
        
        let randomImageNumber = Int.random(in: 1...10)
        
        imageIndex = randomImageNumber
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.dropView.dropImageView.image = UIImage(named: images[self.imageIndex])
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
            self.imageIndex += 1
            
            if self.imageIndex >= images.count {
                self.imageIndex = 0
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // 3초 후 타이머 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            timer.invalidate()  // 타이머 중지
            completion()
        }
    }
    
    private func showDropResult(with video: Video) {
        DropResultViewManager.createDropResultView(
            in: self.view,
            video: video,
            genre: genre,
            rarity: rarity
        ) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
