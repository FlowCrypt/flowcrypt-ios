import AsyncDisplayKit

public class AlertNode: ASDisplayNode {

    enum Constants {
        static let antiBruteForceProtectionAttemptsMaxValue = 5
        static let blockingTimeInSeconds: Double = 5 * 60
    }

    private lazy var overlayNode = createOverlayNode()
    private lazy var contentView = createContentView()
    private lazy var separatorNode = createSeparatorNode()
    private lazy var titleLabel = createTextNode(text: title, isBold: true, fontSize: 17)
    private lazy var messageLabel = createTextNode(text: message ?? "", isBold: false, fontSize: 13)
    private lazy var introductionLabel = createTextNode(text: "", isBold: false, fontSize: 13)
    private lazy var secureTextFieldNode = createSecureTextField()
    private lazy var cancelButton = createButtonNode(title: "Cancel", color: .red, action: #selector(cancelButtonTapped))
    private lazy var okayButton = createButtonNode(title: "Ok", color: .blue, action: #selector(okayButtonTapped))
    private weak var alertTimer: Timer?

    private let title: String
    private let message: String?
    private var failedPassPhraseAttempts: Int?
    private let lastUnsuccessfulPassPhraseAttempt: Date?
    private var previousState: Bool?

    public var onOkay: ((String?) -> Void)?
    public var onCancel: (() -> Void)?
    public var resetFailedPassphraseAttempts: (() -> Void)?

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
        self.alertTimer?.invalidate()
        self.alertTimer = nil
    }

    func setupNodes() {
        contentView.addSubnode(titleLabel)
        if message != nil {
            contentView.addSubnode(messageLabel)
        }
        contentView.addSubnode(secureTextFieldNode)
        contentView.addSubnode(introductionLabel)
        contentView.addSubnode(separatorNode)
        contentView.addSubnode(cancelButton)
        contentView.addSubnode(okayButton)
        overlayNode.addSubnode(contentView)
        addSubnode(overlayNode)
        secureTextFieldNode.becomeFirstResponder()
        if failedPassPhraseAttempts ?? 0 > 0 {
            updateRemainingAttemptsLabel()
        }
    }

    func startTimer() {
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
            self.previousState = isPassphraseCheckDisabled
            if isPassphraseCheckDisabled {
                self.renderBruteForceProtectionAlert()
            } else {
                self.dismissBruteForceProtectionAlert()
            }
        }
    }

    func convertToMinuteSecondFormat(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func updateRemainingAttemptsLabel() {
        let remainingAttempts = Constants.antiBruteForceProtectionAttemptsMaxValue - (failedPassPhraseAttempts ?? 0)
        introductionLabel.isHidden = false
        let text = "passphrase_attempt_introduce".localizeWithArguments(remainingAttempts.pluralizeString(singularForm: "attempt", pluralForm: "attempts"))
        introductionLabel.attributedText = NSAttributedString(string: text)
    }

    func renderBruteForceProtectionAlert() {
        guard let lastUnsuccessfulPassPhraseAttempt else {
            return
        }
        let now = Date()
        let remainingTimeInSeconds = lastUnsuccessfulPassPhraseAttempt.addingTimeInterval(Constants.blockingTimeInSeconds).timeIntervalSince(now)

        introductionLabel.isHidden = false
        introductionLabel.attributedText = NSAttributedString(string: "passphrase_anti_brute_force_protection_hint".localized)

        okayButton.isEnabled = false
        okayButton.setTitle(convertToMinuteSecondFormat(seconds: Int(remainingTimeInSeconds)), with: UIFont.systemFont(ofSize: 15), with: .gray, for: .normal)
    }

    func dismissBruteForceProtectionAlert() {
        if failedPassPhraseAttempts == 0 {
            introductionLabel.isHidden = true
        }
        okayButton.setTitle("Ok", with: UIFont.systemFont(ofSize: 15), with: .blue, for: .normal)
        okayButton.isEnabled = true
    }

    func shouldDisablePassphraseCheck() -> Bool {
        let now = Date()
        // already passed anti-brute force 5 minute cooldown period
        // reset last unsuccessful count
        if let lastUnsuccessfulPassPhraseAttempt, now.timeIntervalSince(lastUnsuccessfulPassPhraseAttempt) >= Constants.blockingTimeInSeconds, failedPassPhraseAttempts != 0 {
            resetFailedPassphraseAttempts?()
            failedPassPhraseAttempts = 0
        }
        return (failedPassPhraseAttempts ?? 0) >= Constants.antiBruteForceProtectionAttemptsMaxValue
    }

    @objc private func cancelButtonTapped() {
        onCancel?()
    }

    @objc private func okayButtonTapped() {
        submitPassphrase(text: secureTextFieldNode.text)
    }

    private func submitPassphrase(text: String?) {
        let isPassphraseCheckDisabled = shouldDisablePassphraseCheck()
        if !isPassphraseCheckDisabled {
            onOkay?(text)
        }
    }

    private func createContentView() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor(hex: "F0F0F0")
        node.clipsToBounds = true
        node.cornerRadius = 13
        node.shadowColor = UIColor.black.cgColor
        node.shadowRadius = 15
        node.shadowOpacity = 0.1
        node.shadowOffset = CGSize(width: 0, height: 2)
        return node
    }

    private func createOverlayNode() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor(white: 0, alpha: 0.4) // semi-transparent black
        return node
    }

    private func createSeparatorNode() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor.lightGray
        node.style.height = ASDimension(unit: .points, value: 0.5)
        return node
    }

    private func createTextNode(text: String, isBold: Bool, fontSize: CGFloat) -> ASTextNode {
        let node = ASTextNode()
        let font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        node.attributedText = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.font: font]
        )
        return node
    }

    private func createButtonNode(title: String, color: UIColor, action: Selector) -> ASButtonNode {
        let node = ASButtonNode()
        node.setTitle(title, with: UIFont.systemFont(ofSize: 15), with: color, for: .normal)
        node.style.flexGrow = 1
        node.style.preferredSize.height = 35
        node.addTarget(self, action: action, forControlEvents: .touchUpInside)
        node.setBackgroundColor(.lightGray, forState: .highlighted)
        return node
    }

    private func createSecureTextField() -> TextFieldNode {
        let node = TextFieldNode(accessibilityIdentifier: "aid-message-passphrase-textfield") { [weak self] action in
            switch action {
            case let .didPaste(_, value):
                self?.submitPassphrase(text: value)
            default:
                break
            }
        }
        node.shouldReturn = { textField in
            self.submitPassphrase(text: textField.text)
            return true
        }
        node.borderColor = .init(gray: 0.2, alpha: 1.0)
        node.borderWidth = 0.1
        node.backgroundColor = .white
        node.cornerRadius = 6
        node.style.width = ASDimension(unit: .fraction, value: 1.0)
        node.style.preferredSize.height = 35
        node.textInsets = 5
        node.isSecureTextEntry = true
        return node
    }

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

        var contentChildren: [ASLayoutElement] = [secureTextFieldNode]
        if message != nil {
            contentChildren.insert(messageLabel, at: 1)
        }
        contentChildren.append(introductionLabel)

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
}
