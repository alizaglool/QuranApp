//
//  SheikhHeaderView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct SheikhHeaderView: View {
    let sheikh: Sheikh
    let isDescriptionExpanded: Bool
    let descriptionToggleTitle: String
    let descriptionToggleHint: String
    let onToggleDescription: () -> Void

    /// Purely a layout measurement, so it stays view-local. The expansion state
    /// itself lives in the view model.
    @State private var isDescriptionTruncated = false

    static let descriptionLineLimit = 3
    static let descriptionFontSize: CGFloat = 13

    private var heroUrl: URL? {
        let raw = sheikh.bannerImageUrl.isEmpty ? sheikh.thumbnailUrl : sheikh.bannerImageUrl
        return URL(string: raw)
    }

    var body: some View {
        VStack(spacing: 0) {
            heroWithAvatar
            infoSection
        }
    }
}

// MARK: - Hero + Avatar

extension SheikhHeaderView {

    var heroWithAvatar: some View {
        ZStack(alignment: .bottom) {
            heroBackground
            avatarView
                .offset(y: 48)
        }
    }

    var heroBackground: some View {
        WebImage(url: heroUrl) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Rectangle().customFill(.container)
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
        .clipped()
        .overlay(Color.black.opacity(0.42))
    }

    var avatarView: some View {
        WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
            image.resizable()
        } placeholder: {
            Circle()
                .customFill(.container)
                .withShimmerOverlay().redacted(reason: .placeholder)
        }
        .frame(width: 92, height: 92)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
    }
}

// MARK: - Info Section

extension SheikhHeaderView {

    var infoSection: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 56)

            Text(sheikh.name)
                .font(.system(size: 22, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            statsRow

            descriptionSection
        }
        .padding(.bottom, 16)
    }

    var statsRow: some View {
        HStack(spacing: 16) {
            Label(sheikh.formattedSubscriberCount, systemImage: "person.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.hadithGold)

            Label {
                HStack(spacing: 3) {
                    Text("\(sheikh.videoCount)")
                    Text(AppLocalizedKeys.lessonsCount.value)
                }
            } icon: {
                Image(systemName: "play.fill")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.hadithGold)
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}

// MARK: - Channel Description

extension SheikhHeaderView {

    @ViewBuilder
    var descriptionSection: some View {
        if !sheikh.channelDescription.isEmpty {
            VStack(spacing: 6) {
                Text(sheikh.channelDescription)
                    .font(.system(size: Self.descriptionFontSize))
                    .customForeground(.subtitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(isDescriptionExpanded ? nil : Self.descriptionLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(widthReader)
                    // VoiceOver reads the whole description even while it is clamped.
                    .accessibilityLabel(sheikh.channelDescription)

                if isDescriptionTruncated {
                    Button(action: onToggleDescription) {
                        Text(descriptionToggleTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.hadithGold)
                    }
                    .accessibilityLabel(descriptionToggleTitle)
                    .accessibilityHint(descriptionToggleHint)
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.22), value: isDescriptionExpanded)
        }
    }

    /// Reads the width the text actually got, so truncation is measured against
    /// the real layout rather than a guess.
    var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { updateTruncation(width: proxy.size.width) }
                .onChange(of: proxy.size.width) { _, width in updateTruncation(width: width) }
        }
    }

    /// `.font(.system(size:))` is a fixed size and does not scale with Dynamic
    /// Type, so measuring with the matching `UIFont` is exact.
    func updateTruncation(width: CGFloat) {
        guard width > 0 else { return }

        let font = UIFont.systemFont(ofSize: Self.descriptionFontSize)
        let bounds = (sheikh.channelDescription as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        // One point of tolerance absorbs sub-pixel rounding on a text that is
        // exactly three lines tall.
        let truncated = bounds.height > font.lineHeight * CGFloat(Self.descriptionLineLimit) + 1

        if truncated != isDescriptionTruncated {
            isDescriptionTruncated = truncated
        }
    }
}
