//
//  EnterPassPhraseViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class EnterPassPhraseViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case title, description, passPhrase, divider, enterPhrase, chooseAnother

        var indexPath: IndexPath {
            IndexPath(row: self.rawValue, section: 0)
        }
    }

    private let decorator: ImportKeyDecoratorType
    private let email: String
    private let fetchedKeys: [KeyDetails]
    private let keyMethods: KeyMethodsType
    private let storage: StorageServiceType
    private let router: GlobalRouterType

    private var passPhrase: String?

    init(
        decorator: ImportKeyDecoratorType = ImportKeyDecorator(),
        keyMethods: KeyMethodsType = KeyMethods(core: .shared),
        storage: StorageServiceType = StorageService(),
        router: GlobalRouterType = GlobalRouter(),
        email: String,
        fetchedKeys: [KeyDetails]
    ) {
        self.fetchedKeys = fetchedKeys
        self.email = email
        self.decorator = decorator
        self.keyMethods = keyMethods
        self.storage = storage
        self.router = router
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
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

    private func observeKeyboardNotifications() {
        _ = keyboardHeight
            .map { UIEdgeInsets(top: self.node.contentInset.top, left: 0, bottom: $0 + 10, right: 0) }
            .subscribe(onNext: { [weak self] inset in
                self?.node.contentInset = inset
                self?.node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
            })
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension EnterPassPhraseViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
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
                }.then {
                    $0.shouldReturn = { _ in
                        self.view.endEditing(true)
                        return true
                    }
                }
            case .enterPhrase:
                 return SetupButtonNode(
                    title: self.decorator.passPhraseContine,
                    insets: self.decorator.passPhraseInsets
                 ) { [weak self] in
                    self?.handleContinueAction()
                 }
            case .chooseAnother:
                return SetupButtonNode(
                    title: self.decorator.passPhraseChooseAnother,
                    insets: self.decorator.buttonInsets,
                    color: .lightGray
                ) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            case .divider:
                return DividerNode(inset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
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

        guard matchingKeys.count > 0 else {
            showAlert(message: "setup_wrong_pass_phrase_retry".localized)
            return
        }

        storage.addKeys(keyDetails: fetchedKeys, passPhrase: passPhrase, source: .generated)
        moveToMainFlow()
    }


    private func handleAnotherKeySelection() {
        navigationController?.popViewController(animated: true)
    }

    private func moveToMainFlow() {
        router.reset()
    }
}
