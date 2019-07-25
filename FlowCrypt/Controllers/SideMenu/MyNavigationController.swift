//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

class MyNavigationController: ENSideMenuNavigationController, ENSideMenuDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sideMenuVC = self.storyboard?.instantiateViewController(withIdentifier: "MenuTableViewController") as! MyMenuTableViewController
        sideMenu = ENSideMenu(sourceView: self.view, menuViewController: sideMenuVC, menuPosition: .left)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
