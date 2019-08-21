//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import ENSwiftSideMenu

final class MyNavigationController: ENSideMenuNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let sideMenuVC = self.storyboard?.instantiateViewController(withIdentifier: "MenuTableViewController") as? MyMenuTableViewController else {
            assertionFailure("Can't find view controller with identifier")
            return
        }
        sideMenu = ENSideMenu(sourceView: view, menuViewController: sideMenuVC, menuPosition: .left)
        sideMenu?.bouncingEnabled = false
        sideMenu?.menuWidth = UIScreen.main.bounds.size.width - 80
        sideMenu?.delegate = self

        // TODO: closing side menu won't work, to be fixed in https://github.com/FlowCrypt/flowcrypt-ios/issues/38
    }
}

extension MyNavigationController: ENSideMenuDelegate {
    func sideMenuShouldOpenSideMenu() -> Bool {
        return true
    }

    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }

    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }

    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }

    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }
}
