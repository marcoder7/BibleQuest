import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift

// MARK: - Auth Errors

enum AuthError: Error {
  case presentingControllerNotFound
  case appleTokenMissing
  case googleIDTokenMissing
  case generic(String)
}

// MARK: - AuthService

struct AuthService {

  // Realtime Database root
  static var db: DatabaseReference { Database.database().reference() }

  // Keep the Apple nonce accessible within this file (fixes the "private" access error)
  fileprivate static var currentNonce: String?

  // MARK: - Google Sign-In

  /// Call this if you already have a presenter (e.g., from your SwiftUI wrapper)
  static func signInWithGoogle(presenting: UIViewController? = nil,
                               completion: @escaping (Result<User, Error>) -> Void) {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      completion(.failure(AuthError.generic("Missing Google clientID in GoogleService-Info.plist")))
      return
    }

    // Configure GID
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config

    // Find a presenter if not provided
    let presenterVC: UIViewController
    if let presenting = presenting {
      presenterVC = presenting
    } else if let found = topViewController() {
      presenterVC = found
    } else {
      completion(.failure(AuthError.presentingControllerNotFound))
      return
    }

    // Start Google flow
    GIDSignIn.sharedInstance.signIn(withPresenting: presenterVC) { result, error in
      if let error = error { return completion(.failure(error)) }

      guard
        let gUser = result?.user,
        let idToken = gUser.idToken?.tokenString
      else {
        return completion(.failure(AuthError.googleIDTokenMissing))
      }

      let accessToken = gUser.accessToken.tokenString
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

      Auth.auth().signIn(with: credential) { authResult, error in
        if let error = error { return completion(.failure(error)) }
        guard let user = authResult?.user else {
          return completion(.failure(AuthError.generic("No Firebase user after Google sign-in")))
        }

        // Save/update user
        let profile = [
          "givenName": gUser.profile?.givenName ?? "",
          "familyName": gUser.profile?.familyName ?? ""
        ]
        saveUser(user: user, provider: "google", extraProfile: profile) { _ in
          completion(.success(user))
        }
      }
    }
  }

  // MARK: - Apple Sign-In

  static func startSignInWithApple(completion: @escaping (Result<User, Error>) -> Void) {
    let nonce = randomNonceString()
    AuthService.currentNonce = nonce

    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let controller = ASAuthorizationController(authorizationRequests: [request])
    let delegate = AppleDelegate { result in completion(result) }
    controller.delegate = delegate
    controller.presentationContextProvider = delegate

    // Hold strongly for the duration of the request so it isn't deallocated
    delegate.retainSelf = delegate
    controller.performRequests()
  }

  // MARK: - Save user into /Users/{uid}

  private static func saveUser(user: User,
                               provider: String,
                               extraProfile: [String: Any] = [:],
                               completion: @escaping (Error?) -> Void) {
    let ref = db.child("Users").child(user.uid)
    var dict: [String: Any] = [
      "uid": user.uid,
      "email": user.email ?? "",
      "displayName": user.displayName ?? "",
      "provider": provider,
      "photoURL": user.photoURL?.absoluteString ?? "",
      "updatedAt": Date().timeIntervalSince1970
    ]

    // Merge in any extra fields (e.g., Apple fullName or Google given/family)
      extraProfile.forEach { dict[$0.key] = $0.value }

    ref.updateChildValues(dict) { error, _ in
      completion(error)
    }
  }

  // MARK: - Presenter helper

  private static func topViewController(base: UIViewController? = UIApplication.shared
    .connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap { $0.windows }
    .first { $0.isKeyWindow }?
    .rootViewController) -> UIViewController? {

    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }
}

// MARK: - Apple Delegate

fileprivate final class AppleDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  var completion: (Result<User, Error>) -> Void
  // keep alive during the request
  var retainSelf: AppleDelegate?

  init(completion: @escaping (Result<User, Error>) -> Void) {
    self.completion = completion
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
      .windows.first { $0.isKeyWindow } ?? UIWindow()
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    defer { self.retainSelf = nil } // release the self-hold when done

    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      completion(.failure(AuthError.generic("Invalid Apple credential"))); return
    }

    guard let tokenData = credential.identityToken,
          let idTokenString = String(data: tokenData, encoding: .utf8) else {
      completion(.failure(AuthError.appleTokenMissing)); return
    }

    guard let rawNonce = AuthService.currentNonce else {
      completion(.failure(AuthError.generic("Missing nonce"))); return
    }

      let firebaseCred = OAuthProvider.appleCredential(
        withIDToken: idTokenString,
        rawNonce: rawNonce,
        fullName: credential.fullName // you can pass nil if you want
      )

    Auth.auth().signIn(with: firebaseCred) { result, error in
      // Clear nonce after use
      AuthService.currentNonce = nil

      if let error = error { self.completion(.failure(error)); return }
      guard let user = result?.user else {
        self.completion(.failure(AuthError.generic("No Firebase user after Apple sign-in"))); return
      }

      let extra: [String: Any] = [
        "appleID": credential.user,
        "givenName": credential.fullName?.givenName ?? "",
        "familyName": credential.fullName?.familyName ?? ""
      ]

      AuthService.db.child("Users").child(user.uid).updateChildValues([
        "uid": user.uid,
        "email": user.email ?? "Hidden",
        "provider": "apple",
        "updatedAt": Date().timeIntervalSince1970
      ]) { _, _ in
        // Also merge name/appleID fields
        AuthService.db.child("Users").child(user.uid).updateChildValues(extra) { _, _ in
          self.completion(.success(user))
        }
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    AuthService.currentNonce = nil
    completion(.failure(error))
    retainSelf = nil
  }
}

// MARK: - Nonce Helpers

fileprivate func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    let randoms: [UInt8] = (0..<16).map { _ in
      var random: UInt8 = 0
      let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if status != errSecSuccess { fatalError("Unable to generate nonce.") }
      return random
    }

    randoms.forEach { random in
      if remainingLength == 0 { return }
      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }
  return result
}

fileprivate func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashed = SHA256.hash(data: inputData)
  return hashed.map { String(format: "%02x", $0) }.joined()
}
