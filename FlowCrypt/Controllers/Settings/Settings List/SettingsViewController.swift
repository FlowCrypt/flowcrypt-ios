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
            var cases = Self.allCases

            if !rules.canBackupKeys {
                cases.removeAll(where: { $0 == .backups })
            }

            return cases
        }
    }

    private let appContext: AppContextWithUser
    private let decorator: SettingsViewDecorator
    private let clientConfiguration: ClientConfiguration
    private let rows: [SettingsMenuItem]

    init(
        appContext: AppContextWithUser,
        decorator: SettingsViewDecorator = SettingsViewDecorator()
    ) async throws {
        self.appContext = appContext
        self.decorator = decorator
        self.clientConfiguration = try await appContext.clientConfigurationProvider.configuration
        self.rows = SettingsMenuItem.filtered(with: clientConfiguration)
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
            guard let self else { return ASCellNode() }
            let setting = self.rows[indexPath.row]
            return TitleCellNode(
                title: self.decorator.attributedSetting(setting.title),
                insets: self.decorator.insets
            )
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let setting = rows[indexPath.row]

        Task {
            await proceed(to: setting)
        }
    }
}

// MARK: - Actions

extension SettingsViewController {
    private func proceed(to setting: SettingsMenuItem) async {
        let viewController: UIViewController?

        switch setting {
        case .keys:
            showSpinner()
            do {
                viewController = try await KeySettingsViewController(appContext: appContext)
            } catch {
                viewController = nil
                showAlert(message: error.localizedDescription)
            }
            hideSpinner()
        case .legal:
            viewController = LegalViewController()
        case .contacts:
            viewController = ContactsListViewController(appContext: appContext)
        case .backups:
            guard clientConfiguration.canBackupKeys else {
                viewController = nil
                return
            }
            viewController = BackupViewController(appContext: appContext)
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
