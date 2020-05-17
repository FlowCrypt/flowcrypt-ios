//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import ENSwiftSideMenu
import FlowCryptUI
import UIKit

protocol NavigationChildController {
    func handleBackButtonTap()
}

protocol SideMenuViewController {
    func didOpen()
}

final class SideMenuNavigationController: ENSideMenuNavigationController {
    private var isStatusBarHidden = false {
        didSet {
            updateStatusBar()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }

    private enum Constants {
        static let menuOffset: CGFloat = 80
        static let sideOffset: CGFloat = 100
        static let animationDuration: TimeInterval = 0.3
    }

    private lazy var gestureView = SideMenuOptionalView { [weak self] in
        self?.hideMenu()
    }

    private var menuViewContoller: SideMenuViewController?

    convenience init() {
        let menu = MyMenuViewController()
        let contentViewController = InboxViewController()
        self.init(menuViewController: menu, contentViewController: contentViewController)
        menuViewContoller = menu
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
        sideMenu?.menuWidth =
            min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
                - Constants.menuOffset
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
        items.forEach {
            $0.isEnabled = isShown
        }

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: {
                items.forEach {
                    $0.customView?.alpha = isShown ? 1.0 : 0.3
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
            navigationButton = NavigationBarActionButton(UIImage(named: "menu_icn"), action: nil)
        default:
            navigationButton = NavigationBarActionButton(UIImage(named: "arrow-left-c"), action: nil)
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
        default:
            sideMenu?.allowPanGesture = false
            sideMenu?.allowLeftSwipe = false
            interactivePopGestureRecognizer?.isEnabled = true
            navigationButton = NavigationBarActionButton(UIImage(named: "arrow-left-c")) { [weak self] in
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
