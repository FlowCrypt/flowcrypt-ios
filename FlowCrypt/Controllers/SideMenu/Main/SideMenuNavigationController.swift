//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import ENSwiftSideMenu
import FlowCryptUI
import UIKit

@MainActor
protocol SideMenuViewController {
    func didOpen()
}

enum RefreshKeyError: Error {
    case cancelPassPhrase

    var description: String {
        switch self {
        case .cancelPassPhrase:
            return "refresh_key_cancel_pass_phrase".localized
        }
    }
}
/**
 * Navigation Controller inherited from ENSideMenuNavigationController
 * - Encapsulates logic of status bar appearance, burger menu width, offsets and etc
 * - Responsible for disabling gestures on side controllers when menu is shown
 * - Adds menu button or back button as part of navigation item, based on pushed controller
 */
final class SideMenuNavigationController: ENSideMenuNavigationController {
    private var isStatusBarHidden = false {
        didSet {
            updateStatusBar()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }

    override var prefersStatusBarHidden: Bool {
        isStatusBarHidden
    }

    private enum Constants {
        static let iPadMenuWidth: CGFloat = 300
        static let menuOffset: CGFloat = 80
        static let animationDuration: TimeInterval = 0.3
    }

    private lazy var gestureView = SideMenuOptionalView { [weak self] in
        self?.hideMenu()
    }

    let keyMethods = KeyMethods()
    var askedUserPassPhrase = false

    private var menuViewContoller: SideMenuViewController?

    convenience init(appContext: AppContextWithUser, contentViewController: UIViewController) {
        let menu = MyMenuViewController(appContext: appContext)
        self.init(menuViewController: menu, contentViewController: contentViewController)
        menuViewContoller = menu
        sideMenu = ENSideMenu(sourceView: view, menuViewController: menu, menuPosition: .left).then {
            $0.bouncingEnabled = false
            $0.delegate = self
            $0.animationDuration = Constants.animationDuration
        }
        refreshKeysFromEKMIfNeeded(context: appContext)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        delegate = self
        interactivePopGestureRecognizer?.delegate = self

        if let vc = viewControllers.first {
            navigationController(self, didShow: vc, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateSideMenuSize()
    }

    private func updateSideMenuSize() {
        sideMenu?.menuWidth = UIDevice.isIpad
            ? Constants.iPadMenuWidth
            : min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) - Constants.menuOffset

        fixSideMenuSize()

        if gestureView.superview != nil {
            gestureView.frame = view.frame
        }
    }

    private func updateStatusBar() {
        UIView.animate(withDuration: 0.3, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
}

// MARK: Refresh keys from EKM
extension SideMenuNavigationController {
    private func refreshKeysFromEKMIfNeeded(context: AppContextWithUser) {
        Task {
            let configuration = try await context.clientConfigurationService.configuration
            guard configuration.checkUsesEKM() == .usesEKM else {
                return
            }
            let emailKeyManagerApi = EmailKeyManagerApi(clientConfiguration: configuration)
            let idToken = try await IdTokenUtils.getIdToken(userEmail: context.user.email)
            let result = try await emailKeyManagerApi.getPrivateKeys(idToken: idToken)
            let localKeys = try context.encryptedStorage.getKeypairs(by: context.user.email)
            var savedPassPhrase = localKeys.first(where: { $0.passphrase != nil })?.passphrase
            guard case let .success(keys) = result, !keys.isEmpty else {
                return
            }
            var isKeyUpdated = false
            do {
                for keyDetail in keys {
                    guard let savedLocalKey = localKeys.first(where: { $0.primaryFingerprint == keyDetail.primaryFingerprint }) else {
                        // No keys found in local. Add it
                        savedPassPhrase = try await saveKeyToLocal(
                            context: context,
                            keyDetail: keyDetail,
                            passPhrase: savedPassPhrase,
                            isNewKey: true
                        )
                        isKeyUpdated = true
                        continue
                    }
                    guard let lastModified = keyDetail.lastModified else {
                        continue
                    }
                    // Key exists in local. Check if saved key is outdated by checking lastModified and update if needed
                    if savedLocalKey.lastModified ?? 0 < lastModified {
                        savedPassPhrase = try await saveKeyToLocal(
                            context: context,
                            keyDetail: keyDetail,
                            passPhrase: savedPassPhrase
                        )
                        isKeyUpdated = true
                    }
                }
                if isKeyUpdated {
                    showToast("refresh_key_success".localized)
                }
            }
        }
    }

    private func saveKeyToLocal(
        context: AppContextWithUser,
        keyDetail: KeyDetails,
        passPhrase: String?,
        isNewKey: Bool = false
    ) async throws -> String? {
        var newPassPhrase = passPhrase
        if newPassPhrase == nil {
            if askedUserPassPhrase {
                return nil
            }
            newPassPhrase = try await requestPassPhraseWithModal(context: context, for: keyDetail, isNewKey: isNewKey)
        }
        guard let newPassPhrase = newPassPhrase else {
            return nil
        }

        guard let privateKey = keyDetail.private else {
            throw CreatePassphraseWithExistingKeyError.noPrivateKey
        }
        let encryptedPrv = try await Core.shared.encryptKey(
            armoredPrv: privateKey,
            passphrase: newPassPhrase
        )
        let parsedKey = try await Core.shared.parseKeys(armoredOrBinary: encryptedPrv.encryptedKey.data())
        try context.encryptedStorage.putKeypairs(
            keyDetails: parsedKey.keyDetails,
            passPhrase: nil,
            source: .ekm,
            for: context.user.email
        )
        return newPassPhrase
    }

    private func requestPassPhraseWithModal(context: AppContextWithUser, for keyDetail: KeyDetails, isNewKey: Bool) async throws -> String {
        self.askedUserPassPhrase = true
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = AlertsFactory.makePassPhraseAlert(
                title: "refresh_key_alert_title".localized,
                onCancel: {
                    return continuation.resume(throwing: RefreshKeyError.cancelPassPhrase)
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }
                    Task<Void, Never> {
                        do {
                            let matched = try await self.handlePassPhraseEntry(
                                appContext: context,
                                passPhrase,
                                for: keyDetail,
                                isNewKey: isNewKey
                            )
                            if matched {
                                return continuation.resume(returning: passPhrase)
                            }
                            // Pass phrase mismatch, display error alert and ask again
                            try await self.showAsyncAlert(message: "refresh_key_invalid_pass_phrase".localized)
                            let newPassPhrase = try await self.requestPassPhraseWithModal(
                                context: context,
                                for: keyDetail,
                                isNewKey: isNewKey
                            )
                            return continuation.resume(returning: newPassPhrase)
                        } catch {
                            return continuation.resume(throwing: error)
                        }
                    }
                }
            )
            present(alert, animated: true, completion: nil)
        }
    }

    internal func handlePassPhraseEntry(
        appContext: AppContextWithUser,
        _ passPhrase: String,
        for keyDetail: KeyDetails,
        isNewKey: Bool
    ) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        //  let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyService.getPrvKeyInfo(email: appContext.user.email)
        guard allKeys.isNotEmpty else {
            // tom - todo - nonsensical error type choice https://github.com/FlowCrypt/flowcrypt-ios/issues/859
            //   I copied it from another usage, but has to be changed
            throw KeyServiceError.retrieve
        }
        let matchingKeys = try await self.keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        // For new key just check if there are any matching keys
        if isNewKey {
            return !matchingKeys.isEmpty
        }
        // now figure out if the pass phrase also matched the signing prv itself
        let matched = matchingKeys.first(where: { $0.fingerprints.first == keyDetail.primaryFingerprint })
        return matched != nil// true if the pass phrase matched signing key
    }
}
extension SideMenuNavigationController: ENSideMenuDelegate {
    func sideMenuShouldOpenSideMenu() -> Bool {
        guard let top = topViewController else { return false }
        return viewControllers.firstIndex(of: top) == 0
    }

    func sideMenuWillOpen() {
        addGestureView()
        gestureView.animate(to: .opened, with: Constants.animationDuration)
        updateNavigationItems(isShown: false)
    }

    func sideMenuWillClose() {
        gestureView.animate(to: .closed, with: Constants.animationDuration)
    }

    func sideMenuDidClose() {
        isStatusBarHidden = false
        gestureView.removeFromSuperview()
        updateNavigationItems(isShown: true)
    }

    func sideMenuDidOpen() {
        isStatusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
        gestureView.frame = view.frame
        menuViewContoller?.didOpen()
    }
}

extension SideMenuNavigationController {
    private func addGestureView() {
        topViewController?.view.addSubview(gestureView)
        gestureView.frame = view.frame
    }

    private func updateNavigationItems(isShown: Bool) {
        guard let items = topViewController?.navigationItem.rightBarButtonItems else { return }
        for item in items {
            item.isEnabled = isShown
        }

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: {
                for item in items {
                    item.customView?.alpha = isShown ? 1.0 : 0.3
                }
            }, completion: nil
        )
    }

    @objc private func hideMenu() {
        hideSideMenuView()
    }
}

extension SideMenuNavigationController: UINavigationControllerDelegate {
    func navigationController(_: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
        viewController.navigationItem.hidesBackButton = true
        let navigationButton: UIBarButtonItem
        switch viewControllers.firstIndex(of: viewController) {
        case 0:
            navigationButton = NavigationBarActionButton(UIImage(named: "menu_icn"), action: nil, accessibilityIdentifier: "menu")
        default:
            navigationButton = .defaultBackButton()
        }

        navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = navigationButton
    }

    func navigationController(_: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
        let navigationButton: UIBarButtonItem
        switch viewControllers.firstIndex(of: viewController) {
        case 0:
            sideMenu?.allowPanGesture = true
            sideMenu?.allowLeftSwipe = true
            interactivePopGestureRecognizer?.isEnabled = false
            navigationButton = NavigationBarActionButton(UIImage(named: "menu_icn")) { [weak self] in
                self?.toggleSideMenuView()
            }
            // Hide side bar menu button for InboxViewContainerController
            if viewController is InboxViewContainerController {
                navigationButton.customView?.isHidden = true
            }
        default:
            sideMenu?.allowPanGesture = false
            sideMenu?.allowLeftSwipe = false
            interactivePopGestureRecognizer?.isEnabled = true
            navigationButton = .defaultBackButton { [weak self] in
                guard let self = self else { return }
                if let viewController = self.viewControllers.compactMap({ $0 as? NavigationChildController }).last {
                    viewController.handleBackButtonTap()
                } else {
                    self.popViewController(animated: true)
                }
            }
        }

        viewController.navigationItem.leftBarButtonItem = navigationButton
    }
}

extension SideMenuNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == interactivePopGestureRecognizer {
            guard let top = topViewController else { return false }
            return viewControllers.firstIndex(of: top) != 0
        }
        return true
    }
}
