//
//  SettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * User settings view controller
 * - Shows list of possible settings(backups, privacy, contacts, keys, atteseter, notifications, legal, experimental)
 * - User can be redirected here from side menu
 * - Tap on each row will navigate user to appropriate settings controller
 */
final class SettingsViewController: TableNodeViewController {
    private enum SettingsMenuItem: Int, CaseIterable {
        case backups, privacy, contacts, keys, attester, notifications, legal, experimental

        var title: String {
            switch self {
            case .backups: return "settings_screen_backup".localized
            case .privacy: return "settings_screen_security".localized
            case .contacts: return "settings_screen_contacts".localized
            case .keys: return "settings_screen_keys".localized
            case .attester: return "settings_screen_attester".localized
            case .notifications: return "settings_screen_notifications".localized
            case .legal: return "settings_screen_legal".localized
            case .experimental: return "settings_screen_experimental".localized
            }
        }

        static func filtered(with rules: ClientConfiguration) -> [SettingsMenuItem] {
            var cases = SettingsMenuItem.allCases

            if !rules.canBackupKeys {
                cases.removeAll(where: { $0 == .backups })
            }

            return cases
        }
    }

    private let decorator: SettingsViewDecoratorType
    private let currentUser: User?
    private let clientConfiguration: ClientConfiguration
    private let rows: [SettingsMenuItem]

    init(
        decorator: SettingsViewDecoratorType = SettingsViewDecorator(),
        currentUser: User? = DataService.shared.currentUser,
        clientConfigurationService: ClientConfigurationServiceType = ClientConfigurationService()
    ) {
        self.decorator = decorator
        self.currentUser = currentUser
        self.clientConfiguration = clientConfigurationService.getSavedClientConfigurationForCurrentUser()
        self.rows = SettingsMenuItem.filtered(with: self.clientConfiguration)
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
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SettingsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        rows.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            let setting = self.rows[indexPath.row]
            return SettingsCellNode(
                title: self.decorator.attributedSetting(setting.title),
                insets: self.decorator.insets
            )
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let setting = rows[indexPath.row]
        proceed(to: setting)
    }
}

// MARK: - Actions

extension SettingsViewController {
    private func proceed(to setting: SettingsMenuItem) {
        let viewController: UIViewController?

        switch setting {
        case .keys:
            viewController = KeySettingsViewController()
        case .legal:
            viewController = LegalViewController()
        case .contacts:
            viewController = ContactsListViewController()
        case .backups:
            guard let currentUser = currentUser,
                  clientConfiguration.canBackupKeys else {
                viewController = nil
                return
            }
            let userId = UserId(email: currentUser.email, name: currentUser.email)
            viewController = BackupViewController(userId: userId)
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
