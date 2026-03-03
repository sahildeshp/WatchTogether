import SwiftUI

// MARK: - Root pairing view

struct PairingView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var vm: PairingViewModel?

    var body: some View {
        Group {
            if let vm {
                pairingContent(vm: vm)
                    .animation(.easeInOut(duration: 0.25), value: vm.step)
            } else {
                ProgressView()
            }
        }
        .task {
            if vm == nil {
                vm = PairingViewModel(authViewModel: auth)
            }
        }
        .onOpenURL { url in
            if let code = inviteCode(from: url) {
                vm?.handleDeepLink(code: code)
            }
        }
    }

    @ViewBuilder
    private func pairingContent(vm: PairingViewModel) -> some View {
        switch vm.step {
        case .chooser:
            PairingChooserView(vm: vm)
        case .creating:
            PairingProgressView(message: "Creating your couple…")
        case .created(let code, let coupleId):
            PairingCreatedView(vm: vm, inviteCode: code, coupleId: coupleId)
        case .joining:
            PairingJoinView(vm: vm)
        case .joiningLoading:
            PairingProgressView(message: "Joining couple…")
        }
    }

    /// Parses `watchtogether://join?code=XXXXXX`
    private func inviteCode(from url: URL) -> String? {
        guard
            url.scheme?.lowercased() == "watchtogether",
            url.host?.lowercased() == "join",
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let code = items.first(where: { $0.name == "code" })?.value,
            !code.isEmpty
        else { return nil }
        return code
    }
}

// MARK: - Chooser

private struct PairingChooserView: View {

    let vm: PairingViewModel
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            VStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.purple)

                Text("WatchTogether")
                    .font(.largeTitle.bold())

                Text("Connect with your partner to build\nyour shared watchlist.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    Task { await vm.startCreateCouple() }
                } label: {
                    Label("Create a Couple", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    vm.startJoinFlow()
                } label: {
                    Label("Join with a Code", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(.rect(cornerRadius: 14))
                }

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Button("Sign Out", role: .destructive) { auth.signOut() }
                .font(.footnote)
                .padding(.top, 24)
                .padding(.bottom, 12)

#if DEBUG
            Button("⚙ Skip pairing (debug)") {
                auth.updateCoupleId("debug-couple")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
#endif
        }
        .padding()
    }
}

// MARK: - Created (show invite code)

private struct PairingCreatedView: View {

    let vm: PairingViewModel
    let inviteCode: String
    let coupleId: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("Your Invite Code")
                    .font(.title2.bold())

                Text("Share this code with your partner.\nIt expires in 48 hours.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Code display
                HStack(spacing: 16) {
                    Text(inviteCode)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .tracking(6)

                    Button {
                        UIPasteboard.general.string = inviteCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title2)
                            .foregroundStyle(.purple)
                    }
                    .accessibilityLabel("Copy code")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 28)
                .background(.purple.opacity(0.08), in: .rect(cornerRadius: 16))

                ShareLink(
                    item: "Join my WatchTogether couple! Enter code \(inviteCode) in the app, or tap: watchtogether://join?code=\(inviteCode)"
                ) {
                    Label("Share Code…", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }

            Spacer()

            Button {
                vm.finishCreation(coupleId: coupleId)
            } label: {
                Text("I've shared the code — continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding()
    }
}

// MARK: - Join (enter code)

private struct PairingJoinView: View {

    @Bindable var vm: PairingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 56))
                    .foregroundStyle(.purple)

                Text("Enter Invite Code")
                    .font(.title2.bold())

                Text("Ask your partner for their 6-character invite code.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("XXXXXX", text: $vm.inviteCodeInput)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.purple.opacity(0.08), in: .rect(cornerRadius: 12))
                    .onChange(of: vm.inviteCodeInput) { _, new in
                        // Enforce 6-char limit and uppercase
                        let capped = String(new.uppercased().prefix(6))
                        if vm.inviteCodeInput != capped { vm.inviteCodeInput = capped }
                    }

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await vm.submitJoinCode() }
                } label: {
                    Text("Join")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button("Back") {
                    vm.cancelJoin()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding()
    }
}

// MARK: - Loading

private struct PairingProgressView: View {
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}
