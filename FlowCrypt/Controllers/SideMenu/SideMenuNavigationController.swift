//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import ENSwiftSideMenu

final class SideMenuNavigationController: ENSideMenuNavigationController {
    private enum Constants {
        static let menuOffset: CGFloat = 80
    }

    private let gestureView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let sideMenuVC = self.storyboard?.instantiateViewController(withIdentifier: "MenuTableViewController") as? MyMenuTableViewController else {
            assertionFailure("Can't find view controller with identifier")
            return
        }
        sideMenu = ENSideMenu(sourceView: view, menuViewController: sideMenuVC, menuPosition: .left).then {
            $0.bouncingEnabled = false
            $0.menuWidth = UIScreen.main.bounds.size.width - Constants.menuOffset
            $0.delegate = self
        }

        navigationItem.backBarButtonItem = UIBarButtonItem()
            .then { $0.title = "" }

        interactivePopGestureRecognizer?.delegate = self
        delegate = self
    }
}

extension SideMenuNavigationController: ENSideMenuDelegate {
    func sideMenuShouldOpenSideMenu() -> Bool {
        guard let top = topViewController else { return false }
        return viewControllers.firstIndex(of: top) == 0
    }

    func sideMenuWillOpen() {
        addGestureView()
    }

    func sideMenuWillClose() {
        gestureView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.frame.size.width,
            height: view.frame.size.height
        )
    }

    func sideMenuDidClose() {
        gestureView.removeFromSuperview()
    }

    func sideMenuDidOpen() {
        gestureView.frame = CGRect(
            x: UIScreen.main.bounds.size.width - Constants.menuOffset,
            y: 0,
            width: Constants.menuOffset,
            height: view.frame.size.height
        )
    }

    private func addGestureView() {
        view.addSubview(gestureView)
        gestureView.backgroundColor = .clear
        gestureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideMenu)))
        gestureView.frame = CGRect(
            x: UIScreen.main.bounds.size.width - Constants.menuOffset,
            y: 0,
            width: Constants.menuOffset,
            height: view.frame.size.height
        )
    }

    @objc private func hideMenu() {
        hideSideMenuView()
    }
}

extension SideMenuNavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.hidesBackButton = true
        let navigationButton: UIBarButtonItem
        switch viewControllers.firstIndex(of: viewController) {
        case 0:
            navigationButton = NavigationBarActionButton(UIImage(named: "menu_icn")) { [weak self] in
                self?.toggleSideMenuView()
            }
        default: 
            navigationButton = NavigationBarActionButton(UIImage(named: "arrow-left-c")) { [weak self] in
                self?.popViewController(animated: true)
            }
        }

        navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = navigationButton
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
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
                self?.popViewController(animated: true)
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
