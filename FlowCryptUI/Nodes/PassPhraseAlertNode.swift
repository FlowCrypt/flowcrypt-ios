//
//  PassPhraseAlertNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 17/07/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class PassPhraseAlertNode: CoreAlertNode {

    private var overlayNode: ASDisplayNode!
    private var contentView: ASDisplayNode!
    private var separatorNode: ASDisplayNode!
    private var titleLabel: ASTextNode!
    private var messageLabel: ASTextNode!
    private var introductionLabel: ASTextNode!
    private var passPhraseTextField: TextFieldNode!
    private var cancelButton: ASButtonNode!
    private var okayButton: ASButtonNode!
    private weak var alertTimer: Timer?

    private var introduction: String? { didSet { updateIntroduction() } }

    private let title: String
    private let message: String?
    private var failedPassPhraseAttempts: Int?
    private let lastUnsuccessfulPassPhraseAttempt: Date?
    private var previousState: Bool?

    public var onOkay: ((String?) -> Void)?
    public var onCancel: (() -> Void)?
    public var resetFailedPassphraseAttempts: (() -> Void)?

    // MARK: - Initialization

    public init(
        failedPassPhraseAttempts: Int?,
        lastUnsuccessfulPassPhraseAttempt: Date?,
        title: String,
        message: String? = nil
    ) {
        self.failedPassPhraseAttempts = failedPassPhraseAttempts
        self.lastUnsuccessfulPassPhraseAttempt = lastUnsuccessfulPassPhraseAttempt
        self.title = title
        self.message = message
        super.init()
        setupNodes()
        startTimer()
    }

    deinit {
        alertTimer?.invalidate()
        alertTimer = nil
    }

    private func createNodes() {
        overlayNode = createOverlayNode()
        contentView = createContentView()
        separatorNode = createSeparatorNode()
        titleLabel = createTextNode(text: title, isBold: true, fontSize: 17, identifier: "aid-enter-passphrase-title-label")
        messageLabel = createTextNode(text: message ?? "", isBold: false, fontSize: 13)
        introductionLabel = createTextNode(text: "", isBold: false, fontSize: 13, identifier: "aid-anti-brute-force-introduce-label")
        passPhraseTextField = createPassPhraseTextField()
        cancelButton = createButtonNode(
            title: Constants.cancelButtonText,
            color: .systemRed,
            identifier: "aid-cancel-button",
            action: #selector(cancelButtonTapped)
        )
        okayButton = createButtonNode(
            title: Constants.submitButtonText,
            color: .systemBlue,
            identifier: "aid-ok-button",
            action: #selector(okayButtonTapped)
        )
    }

    private func setupNodes() {
        createNodes()
        contentView.addSubnode(titleLabel)
        if message != nil {
            contentView.addSubnode(messageLabel)
        }
        contentView.addSubnode(passPhraseTextField)
        contentView.addSubnode(introductionLabel)
        contentView.addSubnode(separatorNode)
        contentView.addSubnode(cancelButton)
        contentView.addSubnode(okayButton)
        overlayNode.addSubnode(contentView)
        addSubnode(overlayNode)
        passPhraseTextField.becomeFirstResponder()
        if failedPassPhraseAttempts ?? 0 > 0 {
            updateRemainingAttemptsLabel()
        }
    }

    private func startTimer() {
        guard alertTimer == nil else { return }
        alertTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.monitorBruteForceProtection()
        }
        alertTimer?.fire()
    }

    // Monitor the status of anti-brute-force protection and manage the display of alerts.
    func monitorBruteForceProtection() {
        let isPassphraseCheckDisabled = shouldDisablePassphraseCheck()

        // Check if the state has changed or if we need to update the timer.
        // This condition ensures the brute force protection alert is only rendered or dismissed
        // when the state actually changes or when an update to the timer value is required.
        if isPassphraseCheckDisabled != previousState || (previousState ?? false && isPassphraseCheckDisabled) {
            previousState = isPassphraseCheckDisabled
            if isPassphraseCheckDisabled {
                renderBruteForceProtectionAlert()
            } else {
                dismissBruteForceProtectionAlert()
            }
        }
    }

    private func convertToMinuteSecondFormat(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func updateRemainingAttemptsLabel() {
        let remainingAttempts = Constants.antiBruteForceProtectionAttemptsMaxValue - (failedPassPhraseAttempts ?? 0)
        introduction = "passphrase_attempt_introduce".localizeWithArguments("%@ attempt(s)".localizePluralsWithArguments(remainingAttempts))
    }

    private func renderBruteForceProtectionAlert() {
        guard let lastUnsuccessfulPassPhraseAttempt else { return }
        let now = Date()

        let remainingTimeInSeconds = lastUnsuccessfulPassPhraseAttempt
            .addingTimeInterval(Constants.blockingTimeInSeconds)
            .timeIntervalSince(now)

        introduction = "passphrase_anti_brute_force_protection_hint".localized

        okayButton.isEnabled = false
        let minuteSecondStr = convertToMinuteSecondFormat(seconds: Int(remainingTimeInSeconds))
        okayButton.setTitle(minuteSecondStr, with: Constants.buttonFont, with: .gray, for: .normal)
    }

    private func dismissBruteForceProtectionAlert() {
        if failedPassPhraseAttempts == 0 {
            introduction = nil
        }
        okayButton.setTitle(Constants.submitButtonText, with: Constants.buttonFont, with: .systemBlue, for: .normal)
        okayButton.isEnabled = true
    }

    private func shouldDisablePassphraseCheck() -> Bool {
        let now = Date()
        // already passed anti-brute force 5 minute cooldown period
        // reset last unsuccessful count
        if let lastUnsuccessfulPassPhraseAttempt,
           now.timeIntervalSince(lastUnsuccessfulPassPhraseAttempt) >= Constants.blockingTimeInSeconds,
           failedPassPhraseAttempts != 0 {
            resetFailedPassphraseAttempts?()
            failedPassPhraseAttempts = 0
        }
        return (failedPassPhraseAttempts ?? 0) >= Constants.antiBruteForceProtectionAttemptsMaxValue
    }

    private func submitPassphrase(text: String?) {
        let isPassphraseCheckDisabled = shouldDisablePassphraseCheck()
        if !isPassphraseCheckDisabled {
            onOkay?(text)
        }
    }

    private func updateIntroduction() {
        if let introduction, !introduction.isEmpty {
            introductionLabel.attributedText = NSAttributedString(
                string: introduction,
                attributes: [.foregroundColor: UIColor.mainTextColor]
            )
            introductionLabel.isHidden = false
        } else {
            introductionLabel.isHidden = true
        }
        setNeedsLayout()
        contentView.setNeedsLayout()
    }

    private func createPassPhraseTextField() -> TextFieldNode {
        let node = TextFieldNode(accessibilityIdentifier: "aid-message-passphrase-textfield") { [weak self] action in
            if case let .didPaste(_, value) = action {
                self?.submitPassphrase(text: value)
            }
        }
        node.shouldReturn = { textField in
            self.submitPassphrase(text: textField.text)
            return true
        }
        node.borderColor = UIColor.colorFor(
            darkStyle: .init(white: 0.8, alpha: 1.0),
            lightStyle: .init(white: 0.2, alpha: 1.0)
        ).cgColor
        node.borderWidth = 0.1
        node.backgroundColor = UIColor.colorFor(
            darkStyle: UIColor(hex: "1D1D1E") ?? .black,
            lightStyle: .white
        )
        node.cornerRadius = 6
        node.style.width = ASDimension(unit: .fraction, value: 1.0)
        node.style.preferredSize.height = 35
        node.textInsets = 5
        node.isSecureTextEntry = true
        return node
    }

    // MARK: - Layout
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let separatorInsetSpec = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0),
            child: separatorNode
        )

        let buttonStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [cancelButton, okayButton]
        )
        buttonStack.style.flexGrow = 1.0

        var contentChildren: [ASLayoutElement] = [passPhraseTextField]
        if message != nil {
            contentChildren.append(messageLabel)
        }
        if introduction != nil {
            contentChildren.append(introductionLabel)
        }
        let verticalStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .center,
            alignItems: .stretch,
            children: [titleLabel] + contentChildren + [separatorInsetSpec, buttonStack]
        )

        let contentLayout = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20),
            child: verticalStack
        )

        contentView.layoutSpecBlock = { _, _ in
            return contentLayout
        }

        let contentViewInset = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10), child: contentView)

        let centerSpec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: contentViewInset)

        overlayNode.layoutSpecBlock = { _, _ in
            return centerSpec
        }
        return ASWrapperLayoutSpec(layoutElement: overlayNode)
    }

    // MARK: - Action Handlers
    @objc private func cancelButtonTapped() {
        onCancel?()
    }

    @objc private func okayButtonTapped() {
        submitPassphrase(text: passPhraseTextField.text)
    }
}
