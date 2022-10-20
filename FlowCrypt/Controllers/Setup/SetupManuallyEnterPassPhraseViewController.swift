//
//  EnterPassPhraseViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * Controller which is responsible for entering pass phrase after key/keys was imported or pasted
 * User will be sent here from **SetupManuallyImportKeyViewController** from setup flow or from settings
 * After user enters pass phrase sccessfully, account will be set up and they will be sent to main flow (inbox view)
 */
final class SetupManuallyEnterPassPhraseViewController: TableNodeViewController, PassPhraseSaveable {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, saveLocally, saveInMemory, enterPhrase, chooseAnother
    }

    private let appContext: AppContext
    private let decorator: SetupViewDecorator
    private let email: String
    private let fetchedKeys: [KeyDetails]
    private let keyMethods: KeyMethodsType

    private var passPhrase: String?

    var storageMethod: PassPhraseStorageMethod = .persistent {
        didSet {
            handleSelectedPassPhraseOption()
        }
    }

    var passPhraseIndexes: [IndexPath] {
        [Parts.saveLocally, Parts.saveInMemory]
            .map { IndexPath(row: $0.rawValue, section: 0) }
    }

    init(
        appContext: AppContext,
        decorator: SetupViewDecorator = SetupViewDecorator(),
        keyMethods: KeyMethodsType = KeyMethods(),
        email: String,
        fetchedKeys: [KeyDetails]
    ) {
        self.appContext = appContext
        self.fetchedKeys = fetchedKeys.getUniqueByFingerprintByPreferingLatestLastModified()
        self.email = email
        self.decorator = decorator
        self.keyMethods = keyMethods

        super.init(node: TableNode())
    }

    @available(*, unavailable)
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
        title = decorator.sceneTitle(for: .enterPassPhrase)
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

extension SetupManuallyEnterPassPhraseViewController {
    // swiftlint:disable discarded_notification_center_observer
    /// Observation should be removed in a place where subscription is
    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
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

extension SetupManuallyEnterPassPhraseViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.title(for: .enterPassPhrase),
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.subtitleStyle(self.email),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .passPhrase:
                return TextFieldCellNode(input: .passPhraseTextFieldStyle) { [weak self] action in
                    switch action {
                    case let .didEndEditing(value):
                        self?.passPhrase = value
                    case let .didPaste(textField, value):
                        textField.text = value
                        self?.submitPassphrase()
                    default:
                        break
                    }
                }
                .then {
                    $0.becomeFirstResponder()
                }
                .onShouldReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    return true
                }
            case .enterPhrase:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .passPhraseContinue)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.submitPassphrase()
                }
            case .chooseAnother:
                return ButtonCellNode(input: .chooseAnotherAccount) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            case .divider:
                return DividerCellNode(inset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
            case .saveLocally:
                return self.saveLocallyNode
            case .saveInMemory:
                return self.saveInMemoryNode
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let part = Parts(rawValue: indexPath.row) else { return }

        switch part {
        case .saveLocally:
            storageMethod = .persistent
        case .saveInMemory:
            storageMethod = .memory
        default:
            break
        }
    }
}

// MARK: - Actions

extension SetupManuallyEnterPassPhraseViewController {
    private func submitPassphrase() {
        Task {
            do {
                try await self.handleContinueAction()
            } catch {
                self.showAlert(message: error.errorMessage)
            }
        }
    }

    private func handleContinueAction() async throws {
        view.endEditing(true)
        guard let passPhrase else { return }
        guard passPhrase.isNotEmpty else {
            showAlert(message: "setup_enter_pass_phrase".localized)
            return
        }
        showSpinner()
        let matchingKeys = try await keyMethods.filterByPassPhraseMatch(
            keys: fetchedKeys,
            passPhrase: passPhrase
        )
        guard matchingKeys.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        let privateKeys = try appContext.encryptedStorage.getKeypairs(by: email).map(\.private)
        let keyDetails = try await keyMethods.parseKeys(armored: privateKeys)
        try importKeys(with: keyDetails, and: passPhrase)
    }

    private func importKeys(with existingKeys: [KeyDetails], and passPhrase: String) throws {
        let keysToUpdate = existingKeys
            .getUniqueByFingerprintByPreferingLatestLastModified()
            .filter { existingKey in
                return fetchedKeys.contains(where: { $0.fingerprints == existingKey.fingerprints })
            }
        let newKeysToAdd = fetchedKeys.filter { fetchedKey in
            return !existingKeys.contains(where: { $0.fingerprints == fetchedKey.fingerprints })
        }

        try appContext.encryptedStorage.putKeypairs(
            keyDetails: newKeysToAdd,
            passPhrase: passPhrase,
            source: .imported,
            for: email
        )
        try appContext.encryptedStorage.putKeypairs(
            keyDetails: keysToUpdate,
            passPhrase: passPhrase,
            source: .imported,
            for: email
        )

        if storageMethod == .memory {
            let updatedPassPhrases = keysToUpdate.map {
                PassPhrase(
                    value: passPhrase,
                    email: email,
                    fingerprintsOfAssociatedKey: $0.fingerprints
                )
            }
            for updatedPassPhrase in updatedPassPhrases {
                try appContext.combinedPassPhraseStorage.updatePassPhrase(
                    with: updatedPassPhrase,
                    storageMethod: storageMethod
                )
            }

            let newPassPhrases = newKeysToAdd.map {
                PassPhrase(
                    value: passPhrase,
                    email: email,
                    fingerprintsOfAssociatedKey: $0.fingerprints
                )
            }
            for newPassPhrase in newPassPhrases {
                try appContext.combinedPassPhraseStorage.savePassPhrase(
                    with: newPassPhrase,
                    storageMethod: storageMethod
                )
            }
        }

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
            throw AppErr.general("Could not be empty, checked all possible casses of updated and imported keys' emptines")
        }

        showAlert(title: nil, message: msg) { [weak self] in
            self?.moveToMainFlow()
        }
    }

    private func moveToMainFlow() {
        appContext.globalRouter.proceed()
    }
}
