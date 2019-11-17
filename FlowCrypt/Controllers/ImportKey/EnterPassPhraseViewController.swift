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

    init(
        decorator: ImportKeyDecoratorType = ImportKeyDecorator(),
        email: String
    ) {
        self.email = email
        self.decorator = decorator
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
                return TextFieldCellNode(input: self.decorator.passPhraseTextFieldStyle) { action in
                    print("^^ \(action)")
                }
            case .enterPhrase:
                 return SetupButtonNode(
                    title: self.decorator.passPhraseContine,
                    insets: self.decorator.passPhraseInsets
                 ) { [weak self] in

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
