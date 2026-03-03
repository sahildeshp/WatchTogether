import SwiftUI
import AuthenticationServices

struct LoginView: View {

    @Environment(AuthViewModel.self) private var auth
    let onSwitch: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var nonce: String?

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && !auth.isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 56)
                    .padding(.bottom, 40)

                VStack(spacing: 14) {
                    inputField("Email", text: $email, keyboard: .emailAddress, content: .emailAddress)
                    inputField("Password", text: $password, isSecure: true, content: .password)
                }
                .padding(.bottom, 12)

                errorLabel
                    .padding(.bottom, 4)

                primaryButton("Sign In", loading: auth.isLoading, disabled: !canSubmit) {
                    Task { await auth.signIn(email: email, password: password) }
                }
                .padding(.bottom, 28)

                orDivider
                    .padding(.bottom, 28)

                appleSignInButton
                    .padding(.bottom, 36)

                switchButton(
                    prompt: "Don't have an account?",
                    action: "Create one",
                    onTap: onSwitch
                )

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 28)
        }
        .onChange(of: email) { _, _ in auth.clearError() }
        .onChange(of: password) { _, _ in auth.clearError() }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "popcorn.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            Text("WatchTogether")
                .font(.largeTitle.bold())
            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let error = auth.error {
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let n = AppleSignInHelper.randomNonceString()
            nonce = n
            request.requestedScopes = [.fullName, .email]
            request.nonce = AppleSignInHelper.sha256(n)
        } onCompletion: { result in
            guard case .success(let authorization) = result,
                  let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let rawNonce = nonce
            else { return }
            Task {
                await auth.signInWithApple(
                    idToken: token,
                    rawNonce: rawNonce,
                    fullName: credential.fullName
                )
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Shared helpers

extension LoginView {
    @ViewBuilder
    func inputField(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default,
        content: UITextContentType? = nil
    ) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(content)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textContentType(content)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func primaryButton(
        _ title: String,
        loading: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if loading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(disabled ? Color.purple.opacity(0.4) : Color.purple)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(disabled)
    }

    var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 1).foregroundStyle(Color(.separator))
            Text("or").font(.caption).foregroundStyle(.secondary)
            Rectangle().frame(height: 1).foregroundStyle(Color(.separator))
        }
    }

    func switchButton(prompt: String, action: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            (Text(prompt + " ").foregroundStyle(.secondary) + Text(action).foregroundStyle(.purple))
                .font(.subheadline)
        }
    }
}
