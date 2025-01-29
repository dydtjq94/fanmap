//
//  DropResultViewManager.swift
//  Storyworld
//
//  Created by peter on 1/20/25.
//

import UIKit

final class DropResultViewManager {
    static func createDropResultView(in parentView: UIView, video: Video, genre: VideoGenre, rarity: VideoRarity, closeAction: @escaping () -> Void) {
        // 기존 뷰 모두 제거
        parentView.subviews.forEach { $0.removeFromSuperview() }
        
        //Collect 버튼 추가
        let closeButton = UIButton(type: .system)
        
        // 썸네일 이미지 추가
        let thumbnailImageView = UIImageView()
        let titleLabel = UILabel()
        
        // 희귀도 StackView 생성
        let rarityContainerView = UIView()
        let rarityImageView = UIImageView()
        let rarityLabel = UILabel()
        let rarityStackView = UIStackView()
        
        // 장르 StackView 생성
        let genreContainerView = UIView()
        let genreImageView = UIImageView()
        let genreLabel = UILabel()
        let genreStackView = UIStackView()
        
        // 전체 StackView
        let infoStackView = UIStackView()
        
        let dropResultStackView = UIStackView()
        
        
        // dropResultStackView 설정 (세로 방향)
        dropResultStackView.axis = .vertical
        dropResultStackView.alignment = .leading  // 왼쪽 정렬
        dropResultStackView.spacing = 60
        dropResultStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 썸네일 이미지 추가
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 부모 뷰에 배경 썸네일 추가
        if let url = URL(string: video.thumbnailURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        thumbnailImageView.image = image
                        
                        // 배경 이미지 설정
                        let backgroundImageView = UIImageView(image: image)
                        backgroundImageView.contentMode = .scaleAspectFill
                        backgroundImageView.clipsToBounds = true
                        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
                        
                        // 블러 효과 추가
                        let blurEffect = UIBlurEffect(style: .dark) // .light, .dark, .extraLight 가능
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.alpha = 0.9  // 불투명도 조절 (0.0 ~ 1.0)
                        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                        
                        // 어두운 오버레이 추가 (반투명 검정색)
                        let darkOverlay = UIView()
                        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                        darkOverlay.translatesAutoresizingMaskIntoConstraints = false
                        
                        // 뷰 계층 추가
                        parentView.insertSubview(backgroundImageView, at: 0) // 최하단에 배경 추가
                        parentView.insertSubview(blurEffectView, aboveSubview: backgroundImageView)
                        parentView.insertSubview(darkOverlay, aboveSubview: blurEffectView)

                        // 오토레이아웃 설정
                        NSLayoutConstraint.activate([
                            backgroundImageView.topAnchor.constraint(equalTo: parentView.topAnchor),
                            backgroundImageView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                            backgroundImageView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                            backgroundImageView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),

                            blurEffectView.topAnchor.constraint(equalTo: parentView.topAnchor),
                            blurEffectView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                            blurEffectView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                            blurEffectView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),

                            darkOverlay.topAnchor.constraint(equalTo: parentView.topAnchor),
                            darkOverlay.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                            darkOverlay.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                            darkOverlay.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                        ])
                    }
                }
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2  // 줄 간격을 조정 (1.0이 기본, 높일수록 간격 증가)

        let attributedText = NSAttributedString(
            string: video.title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        // 영상 제목 추가
        titleLabel.text = video.title
        titleLabel.attributedText = attributedText
        titleLabel.numberOfLines = 2  // 최대 2줄
        titleLabel.lineBreakMode = .byTruncatingTail  // 말줄임표(...) 추가
        titleLabel.textAlignment = .natural
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 채널명 추가
        let channelLabel = UILabel()
        channelLabel.text = Channel.getChannelName(by: video.channelId)
        channelLabel.font = UIFont.systemFont(ofSize: 18)
        channelLabel.textColor = UIColor(hex:"#CECECE")
        channelLabel.textAlignment = .left
        channelLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        rarityContainerView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rarityContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        genreContainerView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        genreContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // 희귀도 및 장르 정보 스택뷰(infoStackView)
        infoStackView.axis = .horizontal
        infoStackView.alignment = .leading
        infoStackView.addArrangedSubview(rarityContainerView)
        infoStackView.addArrangedSubview(genreContainerView)
        infoStackView.spacing = 12
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Open Drop Button 설정
        closeButton.setTitle("Collect", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        closeButton.backgroundColor = AppColors.mainColor
        closeButton.layer.cornerRadius = 10
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(closeButton)
        
        // 버튼 액션 저장을 위한 클로저 래핑
        objc_setAssociatedObject(closeButton, AssociatedKeys.actionClosure, closeAction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // dropResultStackView에 요소 추가 (세로 정렬)
        dropResultStackView.addArrangedSubview(thumbnailImageView)
        dropResultStackView.addArrangedSubview(titleLabel)
        dropResultStackView.addArrangedSubview(channelLabel)
        dropResultStackView.addArrangedSubview(infoStackView)
        dropResultStackView.layer.cornerRadius = 20
        dropResultStackView.isLayoutMarginsRelativeArrangement = true
        dropResultStackView.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        dropResultStackView.backgroundColor = rarity.dropBackgroundColor
        
        // 부모 뷰에 추가
        parentView.addSubview(dropResultStackView)
        
        // Auto Layout 적용 후 애니메이션 실행
        parentView.layoutIfNeeded()

        animateDropResultView(dropResultStackView)
        
        // 원하는 가로/세로 비율 설정 (330:185)
        let widthRatio: CGFloat = 330
        let heightRatio: CGFloat = 185
        let aspectRatio = heightRatio / widthRatio  // 'let' 키워드 추가로 해결
        
        // Auto Layout Constraints 설정
        NSLayoutConstraint.activate([
            // 썸네일 이미지 크기 조정
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 330),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor, multiplier: aspectRatio),
            
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 16),
            channelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            
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
            
            // InfoStackView 크기 조정
            infoStackView.topAnchor.constraint(equalTo: channelLabel.bottomAnchor, constant: 24),
            
            // dropResultStackView 크기 조정
            dropResultStackView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            dropResultStackView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            dropResultStackView.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: 0.9),
            
            // Open Drop Button (화면 최하단)
            closeButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            closeButton.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: 0.6),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // 닫기 버튼 액션 처리
    @objc private static func closeTapped(sender: UIButton) {
        if let action = objc_getAssociatedObject(sender, AssociatedKeys.actionClosure) as? () -> Void {
            action()
        }
    }
    
    private struct AssociatedKeys {
        static let actionClosure = UnsafeRawPointer(bitPattern: "actionClosure".hashValue)!
    }
    
    // dropResultStackView 애니메이션 적용 함수
    private static func animateDropResultView(_ view: UIView) {
        // 초기 상태 설정 (투명도 0, 약간 아래로 이동)
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(
            withDuration: 2,
            delay: 0.1,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
                view.alpha = 1
                view.transform = .identity
            }
        )
    }
}
