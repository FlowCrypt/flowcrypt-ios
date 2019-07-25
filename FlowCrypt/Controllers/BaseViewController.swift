//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class BaseViewController: UIViewController {

    var spinner: MBProgressHUD?

    func instantiate<T>(viewController vcType: T.Type) -> T {
        return self.storyboard?.instantiateViewController(withIdentifier: String(describing: vcType.self)) as! T
    }

    func showSpinner(_ message: String = Language.loading, isUserInteractionEnabled: Bool = false) {
        DispatchQueue.main.async {
            self.spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.spinner!.label.text = message
            self.spinner!.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    func hideSpinner() {
        DispatchQueue.main.async {
            self.spinner?.hide(animated: true)
        }
    }

    func showErrAlert(_ message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.hideSpinner()
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { action in onOk?() })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showToast(_ message: String) {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.view.makeToast(message)
        }
    }

    func setPadding(textField: UITextField) {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: textField.frame.size.height))
        textField.leftView = v
        textField.leftViewMode = .always
    }

}
