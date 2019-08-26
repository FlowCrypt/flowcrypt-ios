//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import Promises

final class GoogleApi: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {

    static let shared = GoogleApi()

    fileprivate var signInCallback: ((_ user: GIDGoogleUser?, _ error: Error?) -> Void)?
    private var signOutCallback: ((_ error: Error?) -> Void)?
    private var signInSilentlyCallback: ((_ accessToken: String?, _ error: Error?) -> Void)?
    private var viewController: UIViewController?

    private override init() { super.init() }

    func setup() {
        Imap.debug(100, "GoogleApi.setup()")
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = "679326713487-8f07eqt1hvjvopgcjeie4dbtni4ig0rc.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes = [
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://mail.google.com/"
        ]
        if GIDSignIn.sharedInstance().hasAuthInKeychain() == true {
            Imap.debug(101, "GoogleApi calling signInSilently")
            // from docs: Attempts to sign in a previously authenticated user without interaction.  The delegate will be
            // from docs: called at the end of this process indicating success or failure.
            GIDSignIn.sharedInstance().signInSilently() // todo - we are not waiting for the delegate to be called here. This cauess imap calls to fail and transparently retry
            // if we could force Imap calls to wait until this refresh is done, then imap calls would not have to needlessly retry
            // "sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!)" - here is where it gets called back
            Imap.debug(102, "GoogleApi calling signInSilently done")
        }
    }

    func isGoogleSessionValid() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }

    func signOut() -> Promise<VOID> { return Promise<VOID> { resolve, reject in
        Imap.debug(103, "GoogleApi.signOut()")
        GIDSignIn.sharedInstance().disconnect()
        self.signOutCallback = { error in
            Imap.debug(104, "GoogleApi.signOut() callback with err?=", value: error)
            if let error = error {
                reject(error)
            } else {
                resolve(VOID())
            }
            Imap.debug(105, "GoogleApi.signOut resolved/rejected")
        }
    }}

    func signIn(viewController: UIViewController) -> Promise<GIDGoogleUser> { return Promise<GIDGoogleUser> { resolve, reject in
        Imap.debug(106, "GoogleApi.signIn")
        self.viewController = viewController
        self.signInCallback = { user, err in
            Imap.debug(107, "GoogleApi.signIn callback - resolving with err?=", value: err)
            if let user = user {
                resolve(user)
            } else {
                reject(err ?? ImapError.general)
            }
            self.viewController = nil
        }
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }}

    func renewAccessToken() -> Promise<String> { return Promise<String> { resolve, reject in
        Imap.debug(108, "GoogleApi.renewAccessToken()")
        self.signInSilentlyCallback = { accessToken, err in
            Imap.debug(109, "GoogleApi.renewAccessToken - callback with err?=", value: err)
            if let accessToken = accessToken {
                resolve(accessToken)
            } else {
                reject(err ?? ImapError.general)
            }
            Imap.debug(110, "GoogleApi.renewAccessToken resolved/rejected")
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
        let at = UserDefaults.standard.value(forKey: "google_accessToken") as? String ?? ""
        Imap.debug(111, "GoogleApi.getAccessToken from storage")
        return at
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // NOTE - setup() calls this callback for silent login which we are not checking in that scenario, could be improved to tie the result back
        if error == nil {
            UserDefaults.standard.set(user.profile.email, forKey: "google_email")
            UserDefaults.standard.set(user.profile.name, forKey: "google_name")
            UserDefaults.standard.set(user.authentication.accessToken, forKey: "google_accessToken")
            UserDefaults.standard.synchronize()
        }
        Imap.debug(114, "GoogleApi.sign.didSignInFor calling callbacks")
        self.signInCallback?(user, error)
        self.signInCallback = nil
        self.signInSilentlyCallback?(user?.authentication.accessToken, error)
        self.signInSilentlyCallback = nil
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        Imap.debug(115, "GoogleApi.sign.didDisconnectWith err=nil, error?=", value: error)
        self.removeGoogleInfo()
        Imap.debug(116, "GoogleApi.sign.didDisconnectWith calling callbacks")
        self.signOutCallback?(error)
        self.signOutCallback = nil
    }

    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        Imap.debug(117, "GoogleApi present vc")
        self.viewController?.present(viewController, animated: true, completion: nil)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        Imap.debug(118, "GoogleApi dismiss vc")
        self.viewController?.dismiss(animated: true, completion: nil)
    }
}
