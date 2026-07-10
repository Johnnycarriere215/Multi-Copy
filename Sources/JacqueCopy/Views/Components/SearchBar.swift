// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors

import SwiftUI

/// A customizable search bar with instant filtering and keyboard navigation support.
struct SearchBar: View {

    // MARK: - Properties

    @Binding var text: String
    let placeholder: String
    var onCommit: (() -> Void)?

    // MARK: - State

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit {
                    onCommit?()
                }
                .onAppear {
                    // Auto-focus after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isFocused
                                ? Color(hex: "#D4A017").opacity(0.5)
                                : Color.primary.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: !text.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    SearchBar(text: .constant(""), placeholder: "Search...")
        .frame(width: 280)
        .padding()
}
