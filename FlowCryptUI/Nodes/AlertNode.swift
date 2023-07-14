import AsyncDisplayKit

public class AlertNode: ASDisplayNode {

    private lazy var overlayNode = createOverlayNode()
    private lazy var contentView = createContentView()
    private lazy var separatorNode = createSeparatorNode()
    private lazy var titleLabel = createTextNode(text: title, isBold: true, fontSize: 17)
    private lazy var messageLabel = createTextNode(text: message ?? "", isBold: false, fontSize: 13)
    private lazy var introductionLabel = createTextNode(text: introduction ?? "", isBold: false, fontSize: 13)
    private lazy var secureTextFieldNode = createSecureTextField()
    private lazy var cancelButton = createButtonNode(title: "Cancel", color: .red, action: #selector(cancelButtonTapped))
    private lazy var okayButton = createButtonNode(title: "Ok", color: .blue, action: #selector(okayButtonTapped))

    private let title: String
    private let message: String?
    private let introduction: String?

    public var onOkay: ((String?) -> Void)?
    public var onCancel: (() -> Void)?

    public init(title: String, message: String? = nil, introduction: String? = nil) {
        self.title = title
        self.message = message
        self.introduction = introduction
        super.init()
        setupNodes()
    }

    func setupNodes() {
        contentView.addSubnode(titleLabel)
        if message != nil {
            contentView.addSubnode(messageLabel)
        }
        contentView.addSubnode(secureTextFieldNode)
        if introduction != nil {
            contentView.addSubnode(introductionLabel)
        }
        contentView.addSubnode(separatorNode)
        contentView.addSubnode(cancelButton)
        contentView.addSubnode(okayButton)
        overlayNode.addSubnode(contentView)
        addSubnode(overlayNode)
        secureTextFieldNode.becomeFirstResponder()
    }

    @objc private func cancelButtonTapped() {
        onCancel?()
    }

    @objc private func okayButtonTapped() {
        onOkay?(secureTextFieldNode.text)
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
            case let .didEndEditing(value), let .didPaste(_, value):
                self?.onOkay?(value)
            default:
                break
            }
        }
        node.shouldReturn = { textField in
            self.onOkay?(textField.text)
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
}
