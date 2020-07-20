//
//  EnterPassPhraseViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class EnterPassPhraseViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, enterPhrase, chooseAnother

        var indexPath: IndexPath {
            IndexPath(row: rawValue, section: 0)
        }
    }

    private let decorator: EnterPassPhraseViewDecoratorType
    private let email: String
    private let fetchedKeys: [KeyDetails]
    private let keyMethods: KeyMethodsType
    private let keysService: KeyDataServiceType
    private let router: GlobalRouterType

    private var passPhrase: String?

    init(
        decorator: EnterPassPhraseViewDecoratorType = EnterPassPhraseViewDecorator(),
        keyMethods: KeyMethodsType = KeyMethods(core: .shared),
        keysService: KeyDataServiceType = DataService.shared,
        router: GlobalRouterType = GlobalRouter(),
        email: String,
        fetchedKeys: [KeyDetails]
    ) {
        self.fetchedKeys = fetchedKeys
        self.email = email
        self.decorator = decorator
        self.keyMethods = keyMethods
        self.keysService = keysService
        self.router = router
        super.init(node: TableNode())
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeKeyboardNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.barStyle = .black
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        node.reloadData()
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
        node.view.contentInsetAdjustmentBehavior = .never
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        node.contentInset.top = view.safeAreaInsets.top
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Keyboard

extension EnterPassPhraseViewController {
    // swiftlint:disable discarded_notification_center_observer
    /// Observation should be removed in a place where subscription is
    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.adjustForKeyboard(height: self.keyboardHeight(from: notification))
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustForKeyboard(height: 0)
        }
    }

    private func adjustForKeyboard(height: CGFloat) {
        node.contentInset = UIEdgeInsets(top: node.contentInset.top, left: 0, bottom: height + 10, right: 0)
        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension EnterPassPhraseViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    title: self.decorator.passPhraseTitle,
                    insets: self.decorator.titleInsets
                )
            case .description:
                return SetupTitleNode(
                    title: self.decorator.subtitleStyle(self.email),
                    insets: self.decorator.subTitleInset
                )
            case .passPhrase:
                return TextFieldCellNode(input: self.decorator.passPhraseTextFieldStyle) { [weak self] action in
                    guard case let .didEndEditing(text) = action else { return }
                    self?.passPhrase = text
                }
                .onShouldReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    return true
                }
            case .enterPhrase:
                return ButtonCellNode(
                    title: self.decorator.passPhraseContine,
                    insets: self.decorator.passPhraseInsets
                ) { [weak self] in
                    self?.handleContinueAction()
                }
            case .chooseAnother:
                return ButtonCellNode(
                    title: self.decorator.passPhraseChooseAnother,
                    insets: self.decorator.buttonInsets,
                    color: .lightGray
                ) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            case .divider:
                return DividerCellNode(inset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
            }
        }
    }
}

// MARK: - Actions

extension EnterPassPhraseViewController {
    private func handleContinueAction() {
        view.endEditing(true)
        guard let passPhrase = passPhrase else { return }

        guard passPhrase.isNotEmpty else {
            showAlert(message: "setup_enter_pass_phrase".localized)
            return
        }
        showSpinner()

        let matchingKeys = keyMethods.filterByPassPhraseMatch(keys: fetchedKeys, passPhrase: passPhrase)

        guard matchingKeys.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        let existedKeys = keysService.keys?.compactMap { $0.private } ?? []
        // compare keys by fingerprints
        let newKeys = fetchedKeys.flatMap { $0.ids.map { $0.fingerprint } }
        let isKeyAlreadyAdded = Set(newKeys).isSubset(of: Set(existedKeys))

        guard !isKeyAlreadyAdded else {
            showAlert(message: "import_key_error_added".localized)
            return
        }

        keysService.addKeys(keyDetails: fetchedKeys, passPhrase: passPhrase, source: .generated)
        moveToMainFlow()
    }

    private func handleAnotherKeySelection() {
        navigationController?.popViewController(animated: true)
    }

    private func moveToMainFlow() {
        router.proceed()
    }
}

/**
 Also if the  [KeyDetails] contains two keys with the same fingerprint, you only add the first one that matches the pass phrase.
 The second one you'd silently skip, if you have already just imported another key with the same fingerprint that did match

 For example, the array may contain two keys with the same fingerprint but different pass phrase
 In which case you only import one of them and skip the other



 If I'm importing some keys and all of them are already present in the database,
 than they are all duplicate and the user should know (some alert would show).
 If at least one of them is a new key by fingerprint, then it can let the user go through successfully
 */
