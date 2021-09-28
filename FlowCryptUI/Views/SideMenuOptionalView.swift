//
//  SideMenuOptionalView.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 19/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public final class SideMenuOptionalView: UIView {
    private let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    public typealias Action = () -> Void
    private var onAction: Action?

    public enum State {
        case opened, closed
    }

    public init(_ action: Action?) {
        super.init(frame: .zero)
        onAction = action
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

    public func animate(to state: State, with duration: TimeInterval) {
        let alpha: CGFloat = {
            switch state {
            case .opened: return 0.8
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
