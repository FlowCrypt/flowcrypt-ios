//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

class MyNavigationController: ENSideMenuNavigationController, ENSideMenuDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let sideMenuVC = self.storyboard?.instantiateViewController(withIdentifier: "MenuTableViewController") as?  MyMenuTableViewController else {
            assertionFailure("Couldn't instantiate ViewController")
        }
        sideMenu = ENSideMenu(sourceView: view, menuViewController: sideMenuVC, menuPosition: .left)
        sideMenu?.bouncingEnabled = false
        sideMenu?.menuWidth = UIScreen.main.bounds.size.width - 80
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
