//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

@MainActor
protocol SideMenuViewController {
    func didOpen()
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

    private var menuViewController: SideMenuViewController?

    convenience init(appContext: AppContextWithUser, contentViewController: UIViewController) throws {
        let menu = try MyMenuViewController(appContext: appContext)
        self.init(menuViewController: menu, contentViewController: contentViewController)
        menuViewController = menu
        sideMenu = ENSideMenu(sourceView: view, menuViewController: menu, menuPosition: .left).then {
            $0.bouncingEnabled = false
            $0.delegate = self
            $0.animationDuration = Constants.animationDuration
        }
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
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

extension SideMenuNavigationController: ENSideMenuDelegate {
    func sideMenuShouldOpenSideMenu() -> Bool {
        guard let topViewController else { return false }
        return viewControllers.firstIndex(of: topViewController) == 0
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
        menuViewController?.didOpen()
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
            navigationButton = NavigationBarActionButton(
                imageSystemName: "line.3.horizontal",
                action: nil,
                accessibilityIdentifier: "aid-menu-btn"
            )
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
            navigationButton = NavigationBarActionButton(
                imageSystemName: "line.3.horizontal",
                action: { [weak self] in
                    self?.toggleSideMenuView()
                },
                accessibilityIdentifier: "aid-menu-btn"
            )
            // Hide side bar menu button for InboxViewContainerController
            if viewController is InboxViewContainerController {
                navigationButton.customView?.isHidden = true
            }
        default:
            sideMenu?.allowPanGesture = false
            sideMenu?.allowLeftSwipe = false
            interactivePopGestureRecognizer?.isEnabled = true
            navigationButton = .defaultBackButton { [weak self] in
                guard let self else { return }
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
