// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI
import Sparkle

/// Manages application updates via the Sparkle framework.
///
/// This view is embedded in the Settings window to provide
/// automatic update checking and installation.
public final class UpdateChecker: ObservableObject {

    // MARK: - Published Properties

    /// Whether an update is currently being checked.
    @Published public private(set) var isCheckingForUpdates: Bool = false

    /// Whether an update is available.
    @Published public private(set) var updateAvailable: Bool = false

    /// The latest available version string.
    @Published public private(set) var latestVersion: String?

    /// Whether the app can check for updates (Sparkle configured).
    @Published public private(set) var canCheckForUpdates: Bool = false

    // MARK: - Singleton

    public static let shared = UpdateChecker()

    // MARK: - Properties

    private let updaterController: SPUStandardUpdaterController

    // MARK: - Initialization

    private init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        self.canCheckForUpdates = true
    }

    // MARK: - Public Methods

    /// Triggers a manual check for updates.
    public func checkForUpdates() {
        isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isCheckingForUpdates = false
        }
    }

    /// Returns the Sparkle updater controller for use in SwiftUI views.
    public var updater: SPUStandardUpdaterController {
        updaterController
    }
}

/// Sparkle updater settings view for embedding in SwiftUI.
public struct UpdaterSettingsView: View {
    @ObservedObject private var updateChecker: UpdateChecker

    public init(updateChecker: UpdateChecker = .shared) {
        self.updateChecker = updateChecker
    }

    public var body: some View {
        HStack {
            if updateChecker.isCheckingForUpdates {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
                Text("Checking for updates...")
                    .font(.body)
            } else if updateChecker.updateAvailable {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .padding(.trailing, 8)
                Text("Update available: \(updateChecker.latestVersion ?? "New version")")
                    .font(.body)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                Text("You're up to date!")
                    .font(.body)
            }

            Spacer()

            Button("Check for Updates") {
                updateChecker.checkForUpdates()
            }
            .disabled(updateChecker.isCheckingForUpdates)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
