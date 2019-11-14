//
//  ImportKeyViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class ImportKeyViewController: ASViewController<TableNode> {
    private enum Parts: Int, CaseIterable {
        case title
    }

    private let decorator: ImportKeyDecoratorType

    init(
        decorator: ImportKeyDecoratorType = ImportKeyDecorator()
    ) {
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

        title = "import_key_title".localized
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ImportKeyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .title:
                return SetupTitleNode(self.decorator.attributedTitle, insets: self.decorator.titleInsets)
            }
        }
    }
}

protocol ImportKeyDecoratorType {
    var attributedTitle: NSAttributedString { get }
    var titleInsets: UIEdgeInsets { get }
}

struct ImportKeyDecorator: ImportKeyDecoratorType {
    let attributedTitle = "import_key_description".localized.attributed(.bold(35), color: .black, alignment: .center)
    let titleInsets = SetupStyle.titleInset
}
