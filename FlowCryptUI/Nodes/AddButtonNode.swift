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
    private let buttonSize = CGSize(width: .addButtonSize, height: .addButtonSize)

    override public init() {
        super.init()
        setupNode()
    }

    public init(identifier: String, _ action: (() -> Void)?) {
        self.identifier = identifier
        super.init()

        setupNode()
        onTap = action
    }

    override public var frame: CGRect {
        didSet {
            guard oldValue.size != frame.size else { return }
            updateButtonFrame()
        }
    }

    override public func didLoad() {
        super.didLoad()

        guard let button = view as? UIButton else { return }
        updateButtonFrame()
        button.accessibilityIdentifier = identifier
        button.isAccessibilityElement = true
        button.accessibilityLabel = "Add"
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)

        if #available(iOS 26.0, *) {
            configureGlassButton(button)
        } else {
            configureLegacyButton(button)
        }
    }

    override public func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        buttonSize
    }

    private func setupNode() {
        setViewBlock { UIButton(type: .system) }
        style.preferredSize = buttonSize
        frame.size = buttonSize
        isUserInteractionEnabled = true
    }

    private func updateButtonFrame() {
        guard isNodeLoaded else { return }
        view.frame = CGRect(origin: view.frame.origin, size: buttonSize)
        view.bounds = CGRect(origin: .zero, size: buttonSize)
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
