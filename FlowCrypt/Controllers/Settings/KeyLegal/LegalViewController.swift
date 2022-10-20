//
//  LegalViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller which shows legal information (privacy, license, sources, terms)
 * - User can be redirected here from settings *SettingsViewController*
 */
final class LegalViewController: TableNodeViewController {

    private enum Items: Int, CaseIterable {
        case privacy, terms, license, sources

        var title: String {
            switch self {
            case .privacy: return "settings_legal_privacy".localized
            case .terms: return "settings_legal_terms".localized
            case .license: return "settings_legal_license".localized
            case .sources: return "settings_legal_sources".localized
            }
        }

        var url: URL {
            switch self {
            case .privacy: return URL(string: "https://flowcrypt.com/privacy")!
            case .terms: return URL(string: "https://flowcrypt.com/terms")!
            case .license: return URL(string: "https://flowcrypt.com/license")!
            case .sources: return URL(string: "https://github.com/FlowCrypt/flowcrypt-ios")!
            }
        }
    }

    private let decorator: LegalViewDecorator
    private let rows = Items.allCases

    init(
        decorator: LegalViewDecorator = LegalViewDecorator()
    ) {
        self.decorator = decorator
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
        view.backgroundColor = .backgroundColor
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension LegalViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        rows.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }
            let legal = self.rows[indexPath.row]
            return TitleCellNode(
                title: self.decorator.attributedSetting(legal.title),
                insets: self.decorator.insets
            )
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let legal = rows[indexPath.row]
        UIApplication.shared.open(legal.url)
    }
}
