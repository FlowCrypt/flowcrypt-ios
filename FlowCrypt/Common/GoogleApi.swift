//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import Promises

class GoogleApi: NSObject, UIApplicationDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    static let instance = GoogleApi()

    private var signInCallback: ((_ user: GIDGoogleUser?, _ error: Error?) -> Void)?
    private var signOutCallback: ((_ error: Error?) -> Void)?
    private var signInSilentlyCallback: ((_ accessToken: String?, _ error: Error?) -> Void)?
    private var viewController: UIViewController?

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

    func isGoogleSessionValid() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }

    func signOut() -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        GIDSignIn.sharedInstance().disconnect()
        self.signOutCallback = { error in error == nil ? resolve(VOID()) : reject(error!) }
    }}

    func signIn(viewController: UIViewController) -> Promise<GIDGoogleUser> { return Promise<GIDGoogleUser> { resolve, reject in
        self.viewController = viewController
        self.signInCallback = { user, error in
            error == nil ? resolve(user!) : reject(error!)
            self.viewController = nil
        }
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }}

    func renewAccessToken() -> Promise<String> { return Promise<String> { resolve, reject in
        self.signInSilentlyCallback = { accessToken, error in
            error != nil ? resolve(accessToken!) : reject(error!)
        }
        GIDSignIn.sharedInstance().signInSilently()
    }}

    func removeGoogleInfo() {
        UserDefaults.standard.removeObject(forKey: "google_email")
        UserDefaults.standard.removeObject(forKey: "google_name")
        UserDefaults.standard.removeObject(forKey: "google_accessToken")
        UserDefaults.standard.synchronize()
    }

    func getEmail() -> String {
        return UserDefaults.standard.value(forKey: "google_email") as? String ?? ""
    }

    func getName() -> String {
        return UserDefaults.standard.value(forKey: "google_name") as? String ?? ""
    }

    func getAccessToken() -> String {
        return UserDefaults.standard.value(forKey: "google_accessToken") as? String ?? ""
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            UserDefaults.standard.set(user.profile.email, forKey: "google_email")
            UserDefaults.standard.set(user.profile.name, forKey: "google_name")
            UserDefaults.standard.set(user.authentication.accessToken, forKey: "google_accessToken")
            UserDefaults.standard.synchronize()
        }
        self.signInCallback?(user, error)
        self.signInCallback = nil
        self.signInSilentlyCallback?(user?.authentication.accessToken, error)
        self.signInSilentlyCallback = nil
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        self.removeGoogleInfo()
        self.signOutCallback?(error)
        self.signOutCallback = nil
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
