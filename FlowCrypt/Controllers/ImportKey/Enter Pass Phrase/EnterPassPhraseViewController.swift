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
    private let keysDataService: KeyDataServiceType
    private let keyService: KeyServiceType
    private let router: GlobalRouterType

    private var passPhrase: String?

    init(
        decorator: EnterPassPhraseViewDecoratorType = EnterPassPhraseViewDecorator(),
        keyMethods: KeyMethodsType = KeyMethods(core: .shared),
        keysService: KeyDataServiceType = DataService.shared,
        router: GlobalRouterType = GlobalRouter(),
        keyService: KeyServiceType = KeyService(),
        email: String,
        fetchedKeys: [KeyDetails]
    ) {
        self.fetchedKeys = fetchedKeys.unique()
        self.email = email
        self.decorator = decorator
        self.keyMethods = keyMethods
        self.keysDataService = keysService
        self.router = router
        self.keyService = keyService
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
                .then {
                    $0.becomeFirstResponder()
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

        let matchingKeys = keyMethods.filterByPassPhraseMatch(
            keys: fetchedKeys,
            passPhrase: passPhrase
        )

        guard matchingKeys.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        switch keyService.retrieveKeyDetails() {
        case let .failure(error):
            handleCommon(error: error)
        case let .success(existedKeys):
            importKeys(with: existedKeys, and: passPhrase)
        }
    }

    private func importKeys(with existedKeys: [KeyDetails], and passPhrase: String) {
        let keysToUpdate = Array(Set(existedKeys).intersection(fetchedKeys))
        let newKeysToAdd = Array(Set(fetchedKeys).subtracting(existedKeys))

        keysDataService.addKeys(
            keyDetails: newKeysToAdd,
            passPhrase: passPhrase,
            source: .imported
        )

        keysDataService.updateKeys(
            keyDetails: keysToUpdate,
            passPhrase: passPhrase,
            source: .imported
        )

        hideSpinner()

        let updated = keysToUpdate.count
        let imported = newKeysToAdd.count

        let message: String? = {
            if updated > 0, imported > 0 {
                return "import_key_add_both".localizeWithArguments(String(imported), String(updated))
            } else if updated > 0 {
                return "import_key_add_update".localizeWithArguments(String(updated))
            } else if imported > 0 {
                return "import_key_add_new".localizeWithArguments(String(imported))
            } else {
                return nil
            }
        }()

        guard let msg = message else {
            assertionFailure()
            handleCommon(error: KeyServiceError.unexpected)
            return
        }

        showAlert(title: nil, message: msg) { [weak self] in
            self?.moveToMainFlow()
        }
    }

    private func handleAnotherKeySelection() {
        navigationController?.popViewController(animated: true)
    }

    private func moveToMainFlow() {
        router.proceed()
    }
}
