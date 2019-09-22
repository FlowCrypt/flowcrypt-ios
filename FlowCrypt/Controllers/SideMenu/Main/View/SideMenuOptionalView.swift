//
//  SideMenuOptionalView.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/20/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class SideMenuOptionalView: UIView {
    private let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    typealias Action = () -> Void
    private var onAction: Action?

    enum State {
        case oppened, closed
    }

    init(_ action: Action?) {
        super.init(frame: .zero)
        self.onAction = action
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        addSubview(visualView)
        constrainToEdges(visualView)
        visualView.alpha = 0
    }

    @objc private func handleTap() {
        onAction?()
    }

    func animate(to state: State, with duration: TimeInterval) {
        let alpha: CGFloat = {
            switch state {
                case .oppened: return 0.8
                case .closed: return 0.0
            }
        }()

        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: [.beginFromCurrentState],
            animations: {
                self.visualView.alpha = alpha
            },
            completion: nil
        )
    }
}
