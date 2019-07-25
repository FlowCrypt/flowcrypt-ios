//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn

class GoogleApi: NSObject, UIApplicationDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    static let instance = GoogleApi()
    var signInCallback: ((_ user: GIDGoogleUser?, _ error: Error?) -> Void)?
    var signOutCallback: ((_ error: Error?) -> Void)?
    var viewController: UIViewController?

    func setup() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/"
        ]
        if GIDSignIn.sharedInstance().hasAuthInKeychain() == true {
            GIDSignIn.sharedInstance().signInSilently()
        }
    }

    func signOut(_ callback: @escaping ((_ error: Error?) -> Void)) {
        self.signOutCallback = callback
        GIDSignIn.sharedInstance().disconnect()
    }

    func isGoogleSessionValid() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }

    func signIn(viewController: UIViewController, callback: @escaping ((_ user: GIDGoogleUser?, _ error: Error?) -> Void)) {
        self.viewController = viewController
        self.signInCallback = callback
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }

    func removeGoogleInfo() {
        UserDefaults.standard.removeObject(forKey: "google_email")
        UserDefaults.standard.removeObject(forKey: "google_name")
        UserDefaults.standard.removeObject(forKey: "google_accessToken")
        UserDefaults.standard.synchronize()
    }

    func getEmail() -> String {
        if let email = UserDefaults.standard.value(forKey: "google_email") as? String {
            return email
        }
        return ""
    }

    func getName() -> String {
        if let name = UserDefaults.standard.value(forKey: "google_name") as? String {
            return name
        }
        return ""
    }

    func getAccessToken() -> String {
        if let token = UserDefaults.standard.value(forKey: "google_accessToken") as? String {
            return token
        }
        return ""
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            UserDefaults.standard.set(user.profile.email, forKey: "google_email")
            UserDefaults.standard.set(user.profile.name, forKey: "google_name")
            UserDefaults.standard.set(user.authentication.accessToken, forKey: "google_accessToken")
            UserDefaults.standard.synchronize()
        }
        if let signinCallback = self.signInCallback {
            signinCallback(user, error)
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        self.removeGoogleInfo()
        if let signOutCallback = self.signOutCallback {
            signOutCallback(error)
        }
        self.signOutCallback!(error)
    }

    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.viewController?.present(viewController, animated: true, completion: nil)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.viewController?.dismiss(animated: true, completion: nil)
    }
}
