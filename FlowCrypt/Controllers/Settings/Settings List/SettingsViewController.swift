//
//  SettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class SettingsViewController: ASViewController<TableNode> {
    private enum Settings: Int, CaseIterable {
        case backups, privacy, contacts, keys, atteseter, notifications, legal, experimental
        
        var title: String {
            switch self {
            case .backups: return "settings_screen_backup".localized
            case .privacy: return "settings_screen_security".localized
            case .contacts: return "settings_screen_contacts".localized
            case .keys: return "settings_screen_keys".localized
            case .atteseter: return "settings_screen_attester".localized
            case .notifications: return "settings_screen_notifications".localized
            case .legal: return "settings_screen_legal".localized
            case .experimental: return "settings_screen_experimental".localized
            }
        }
    }
    
    private let decorator: SettingsViewDecoratorType
    
    init(
        decorator: SettingsViewDecoratorType = SettingsViewDecorator()
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
    }

    private func setupUI() {
        node.delegate = self
        node.dataSource = self
        title = decorator.sceneTitle
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SettingsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Settings.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let setting = Settings(rawValue: indexPath.row) else { return ASCellNode() }
        
            return SettingsCellNode(
                title: self.decorator.attributedSetting(setting.title),
                insets: self.decorator.insets
           )
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let setting = Settings(rawValue: indexPath.row) else { return assertionFailure() }
        proceed(to: setting)
    }
}

// MARK: - Actions

extension SettingsViewController {
    private func proceed(to setting: Settings) {
        let viewController: UIViewController?
        
        switch setting {
        case .keys:
            viewController = KeySettingsViewController()
        case .legal:
            viewController = LegalViewController()
        default:
            viewController = nil
        }
        
        guard let vc = viewController else {
            showToast("\(setting.title) not yet implemented")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
