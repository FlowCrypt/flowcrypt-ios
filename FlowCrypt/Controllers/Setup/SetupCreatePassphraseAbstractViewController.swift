//
//  SetupCreatePassphraseAbstractViewController.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 13.08.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * Controller which decalres a base logic for passphrase setup
 * - Has not to have an instance!
 */

@MainActor
class SetupCreatePassphraseAbstractViewController: TableNodeViewController, PassPhraseSaveable, NavigationChildController {

    enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, saveLocally, saveInMemory, action, subtitle, fetchedKeys
    }

    var parts: [Parts] {
        Parts.allCases
    }

    let appContext: AppContext
    let decorator: SetupViewDecorator
    let user: UserId
    let fetchedKeysCount: Int

    var storageMethod: StorageMethod = .persistent {
        didSet {
            handleSelectedPassPhraseOption()
        }
    }

    var passPhraseIndexes: [IndexPath] {
        [Parts.saveLocally, Parts.saveInMemory]
            .map { IndexPath(row: $0.rawValue, section: 0) }
    }

    private var passPhrase: String?

    private lazy var logger = Logger.nested(in: Self.self, with: .setup)

    init(
        appContext: AppContext,
        user: UserId,
        fetchedKeysCount: Int = 0,
        router: GlobalRouterType = GlobalRouter(),
        decorator: SetupViewDecorator = SetupViewDecorator()
    ) {
        self.appContext = appContext
        self.user = user
        self.fetchedKeysCount = fetchedKeysCount
        self.decorator = decorator
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationItem.leftBarButtonItem = nil
    }

    func setupAccount(with passphrase: String) {
        fatalError("This method has to be overriden")
    }

    func setupUI() {
        node.delegate = self
        node.dataSource = self

        title = decorator.sceneTitle(for: .createKey)
        observeKeyboardNotifications()
    }

    func handleBackButtonTap() {
        do {
            try appContext.globalRouter.signOut(appContext: self.appContext)
        } catch {
            showAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - UI

extension SetupCreatePassphraseAbstractViewController {
    // TODO: - Ticket? - Unify this logic for all controllers
    // swiftlint:disable discarded_notification_center_observer
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
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
    }
}

// MARK: - Setup

extension SetupCreatePassphraseAbstractViewController {

    func validateAndConfirmNewPassPhraseOrReject(passPhrase: String) async throws {
        let strength = try await Core.shared.zxcvbnStrengthBar(passPhrase: passPhrase)
        guard strength.word.pass else {
            throw CreateKeyError.weakPassPhrase(strength)
        }
        let confirmPassPhrase = try await self.awaitUserPassPhraseEntry()
        guard confirmPassPhrase != nil else {
            throw CreateKeyError.conformingPassPhraseError
        }
        guard confirmPassPhrase == passPhrase else {
            throw CreateKeyError.doesntMatch
        }
    }

    private func awaitUserPassPhraseEntry() async throws -> String? {
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "setup_pass_phrase_title".localized,
                    message: "setup_pass_phrase_confirm".localized,
                    preferredStyle: .alert
                )
                alert.addTextField { textField in
                    textField.isSecureTextEntry = true
                    textField.accessibilityLabel = "textField"
                }
                alert.addAction(UIAlertAction(title: "cancel".localized, style: .default) { _ in
                    return continuation.resume(returning: nil)
                })
                alert.addAction(UIAlertAction(title: "ok".localized, style: .default) { [weak alert] _ in
                    return continuation.resume(returning: alert?.textFields?[0].text)
                })

                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension SetupCreatePassphraseAbstractViewController {
    func moveToMainFlow() {
        appContext.globalRouter.proceed()
    }

    private func showChoosingOptions() {
        showToast("Not implemented yet")
    }

    private func handleButtonAction() {
        view.endEditing(true)
        guard let passPhrase = passPhrase, passPhrase.isNotEmpty else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }
        logger.logInfo("Setup account with passphrase")
        setupAccount(with: passPhrase)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SetupCreatePassphraseAbstractViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        parts.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            let part = self.parts[indexPath.row]
            switch part {
            case .title:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.title(for: .setup),
                        insets: self.decorator.insets.titleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .description:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.subtitle(for: .choosingPassPhrase),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            case .passPhrase:
                return TextFieldCellNode(input: .passPhraseTextFieldStyle) { [weak self] action in
                    guard case let .didEndEditing(value) = action else { return }
                    self?.passPhrase = value
                }
                .onShouldReturn { [weak self] _ in
                    self?.view.endEditing(true)
                    self?.handleButtonAction()
                    return true
                }
                .then {
                    $0.becomeFirstResponder()
                }
            case .action:
                let input = ButtonCellNode.Input(
                    title: self.decorator.buttonTitle(for: .setPassPhrase)
                )
                return ButtonCellNode(input: input) { [weak self] in
                    self?.handleButtonAction()
                }
            case .subtitle:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.passPhraseLostDescription,
                        insets: .side(8),
                        backgroundColor: .backgroundColor
                    )
                )
            case .divider:
                return DividerCellNode(inset: self.decorator.insets.dividerInsets)
            case .saveLocally:
                return self.saveLocallyNode
            case .saveInMemory:
                return self.saveInMemoryNode
            case .fetchedKeys:
                return SetupTitleNode(
                    SetupTitleNode.Input(
                        title: self.decorator.subtitle(for: .fetchedEKMKeys(self.fetchedKeysCount)),
                        insets: self.decorator.insets.subTitleInset,
                        backgroundColor: .backgroundColor
                    )
                )
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let part = parts[indexPath.row]

        switch part {
        case .description:
            showChoosingOptions()
        case .saveLocally:
            storageMethod = .persistent
        case .saveInMemory:
            storageMethod = .memory
        default:
            break
        }
    }
}
