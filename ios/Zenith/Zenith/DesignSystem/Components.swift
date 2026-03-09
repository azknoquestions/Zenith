import SwiftUI

struct ZenithTopBar: View {
    let title: String
    let subtitle: String?
    var onMenuTap: () -> Void
    var onAccountTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ZenithColors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(ZenithColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onAccountTap) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 15, weight: .medium))
                    Text("Account")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(ZenithColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ZenithColors.surface)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial.opacity(0.6))
        .background(ZenithColors.background.ignoresSafeArea(edges: .top))
    }
}

struct ZenithCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(ZenithColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ZenithColors.separator, lineWidth: 1)
            )
    }
}

struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textMuted)
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(ZenithColors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ZenithColors.surfaceElevated)
        .clipShape(Capsule())
    }
}

struct ZenithAIButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text("Zenith AI")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(ZenithColors.background)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ZenithColors.accent)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 10)
        }
    }
}

