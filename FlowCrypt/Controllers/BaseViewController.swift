//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import Promises

class BaseViewController: UIViewController {

    var spinner: MBProgressHUD?

    func instantiate<T>(viewController vcType: T.Type) -> T {
        return self.storyboard?.instantiateViewController(withIdentifier: String(describing: vcType.self)) as! T
    }

    func showSpinner(_ message: String = Language.loading, isUserInteractionEnabled: Bool = false) {
        DispatchQueue.main.async {
            self.spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.spinner?.label.text = message
            self.spinner?.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    func hideSpinner() {
        DispatchQueue.main.async {
            self.spinner?.hide(animated: true)
        }
    }

    func showErrAlert(_ message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.spinner?.hide(animated: true) // safe on main thread
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

    func async<T>(_ work: @escaping () throws -> T, then thenOnMain: @escaping (T) throws -> Void, fail errHandlerOnMain: @escaping (Error) -> Void) {
        Promise<Void> { _, _ in
            let workResult = try work()
            DispatchQueue.main.async {
                do {
                    try thenOnMain(workResult)
                } catch {
                    self.spinner?.hide(animated: true) // safe on main thread
                    errHandlerOnMain(error)
                }
            }
        }.catch { error in
            DispatchQueue.main.async {
                self.spinner?.hide(animated: true) // safe on main thread
                errHandlerOnMain(error)
            }
        }
    }

    func async<T>(_ work: @escaping () throws -> T, then: @escaping (T) throws -> Void, fail alertMsg: String = "Action failed") {
        self.async(work, then: then, fail: { error in self.showErrAlert("\(alertMsg)\n\n \(error)") })
    }

}
