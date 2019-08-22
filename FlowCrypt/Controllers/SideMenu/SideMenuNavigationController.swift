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
        sideMenu = ENSideMenu(sourceView: view, menuViewController: sideMenuVC, menuPosition: .left)
        sideMenu?.bouncingEnabled = false
        sideMenu?.menuWidth = UIScreen.main.bounds.size.width - Constants.menuOffset
        sideMenu?.delegate = self
    }
}

extension SideMenuNavigationController: ENSideMenuDelegate {
    func sideMenuShouldOpenSideMenu() -> Bool {
        return true
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
