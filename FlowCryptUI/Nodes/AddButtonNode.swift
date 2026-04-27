//
//  AddButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class AddButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?
    private var identifier: String?

    override public init() {
        super.init()
        setViewBlock { UIButton(type: .system) }
    }

    public init(identifier: String, _ action: (() -> Void)?) {
        self.identifier = identifier
        super.init()

        setViewBlock { UIButton(type: .system) }
        onTap = action
        frame.size = CGSize(width: .addButtonSize, height: .addButtonSize)
    }

    override public func didLoad() {
        super.didLoad()

        guard let button = view as? UIButton else { return }
        button.accessibilityIdentifier = identifier
        button.isAccessibilityElement = true
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)

        if #available(iOS 26.0, *) {
            configureGlassButton(button)
        } else {
            configureLegacyButton(button)
        }
    }

    @objc private func onButtonTap() {
        onTap?()
    }

    @available(iOS 26.0, *)
    private func configureGlassButton(_ button: UIButton) {
        var configuration = UIButton.Configuration.glass()
        configuration.buttonSize = .medium
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: "plus")
        configuration.preferredSymbolConfigurationForImage = .init(
            pointSize: 24,
            weight: .semibold
        )

        button.configuration = configuration
    }

    private func configureLegacyButton(_ button: UIButton) {
        button.backgroundColor = .main
        button.layer.cornerRadius = .addButtonSize / 2
        button.setTitle("+", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
    }
}
