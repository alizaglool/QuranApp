//
//  MiniPlayerView.swift
//  QuranApp
//

import SwiftUI
import AVKit
import Core

struct MiniPlayerView: View {

    @EnvironmentObject private var audio: AudioEngine
    @State private var isExpanded: Bool = AudioEngine.shared.isPlaying
    @State private var showReciterSheet = false
    @State private var showRepeatSheet = false

    var onPlayTapped: (() -> Void)? = nil

    var body: some View {
        Group {
            if isExpanded {
                expandedCard
            } else {
                collapsedBar
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
        .onChange(of: audio.isPlaying) { _, playing in
            if playing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
        }
        .onChange(of: audio.hasActiveVerse) { _, active in
            if !active {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            }
        }
        .sheet(isPresented: $showReciterSheet) {
            ReciterSelectionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRepeatSheet) {
            RepeatSettingsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Collapsed Bar (Image #11 — audio not playing)

    private var collapsedBar: some View {
        HStack(spacing: 0) {
            // Play button — left side
            Button {
                if audio.hasActiveVerse {
                    audio.resume()
                } else {
                    onPlayTapped?()
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.playerControls)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("تشغيل")

            Spacer()

            // Reciter name + chevron — right side (RTL)
            Button { showReciterSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                    Text(audio.currentReciter.arabicName)
                        .font(.custom("Kitab-Bold", size: 15))
                }
                .foregroundColor(Color.playerControls)
            }
            .padding(.trailing, 4)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.mushafPage)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.playerControls.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = true
            }
        }
    }

    // MARK: - Expanded Card (Image #10 — audio playing or expanded)

    private var expandedCard: some View {
        VStack(spacing: 10) {
            headerRow
            progressRow
            controlsRow
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.mushafPage)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.playerControls.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Row 1: Close | Reciter + Verse | AirPlay

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 0) {
            // Close — collapses to mini bar (does not stop audio)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.secondary.opacity(0.13), in: Circle())
            }
            .accessibilityLabel("تصغير المشغل")

            Spacer()

            // Center: reciter name + surah:verse
            VStack(spacing: 3) {
                Button { showReciterSheet = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                        Text(audio.currentReciter.arabicName)
                            .font(.custom("Kitab-Bold", size: 15))
                    }
                    .foregroundColor(Color.playerControls)
                }

                Text("\(audio.currentSurahArabicName): \(audio.currentVerseNumber)")
                    .font(.custom("Kitab-Regular", size: 12))
                    .foregroundColor(.secondary)
            }
            .environment(\.layoutDirection, .rightToLeft)

            Spacer()

            // AirPlay
            AirPlayButton()
                .frame(width: 30, height: 30)
        }
    }

    // MARK: - Row 2: Elapsed | Progress Bar | Remaining

    private var progressRow: some View {
        HStack(spacing: 8) {
            Text(formatTime(audio.verseElapsed))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 34, alignment: .leading)

            GeometryReader { geo in
                let progress = CGFloat(audio.verseProgress)
                let trackW = geo.size.width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 3)

                    Capsule()
                        .fill(Color.playerControls)
                        .frame(width: trackW * progress, height: 3)

                    Circle()
                        .fill(Color.playerControls)
                        .frame(width: 11, height: 11)
                        .offset(x: max(0, trackW * progress - 5.5))
                }
                .contentShape(Rectangle().inset(by: -8))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let fraction = max(0, min(1, Double(val.location.x / trackW)))
                            audio.seek(to: fraction)
                        }
                )
            }
            .frame(height: 20)

            Text("-" + formatTime(max(0, audio.verseDuration - audio.verseElapsed)))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Row 3: Repeat | Prev | Play/Pause | Next | Speed

    private var controlsRow: some View {
        HStack(spacing: 0) {
            Button { showRepeatSheet = true } label: {
                Image(systemName: audio.repeatMode == .verse ? "repeat.1" : "repeat")
                    .font(.system(size: 17))
                    .foregroundColor(audio.repeatMode != .off ? Color.playerControls : .secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("إعدادات التكرار")

            Button { audio.previousVerse() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("الآية السابقة")

            // Large center play/pause
            Button {
                audio.isPlaying ? audio.pause() : audio.resume()
            } label: {
                Group {
                    if audio.isLoadingVerse {
                        ProgressView()
                            .tint(Color.playerControls)
                    } else {
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundColor(Color.playerControls)
                    }
                }
                .frame(width: 56, height: 56)
            }
            .accessibilityLabel(audio.isPlaying ? "إيقاف مؤقت" : "تشغيل")

            Button { audio.nextVerse() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("الآية التالية")

            Button { audio.cycleSpeed() } label: {
                Text(audio.currentSpeedLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 32)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("سرعة التشغيل")
        }
        .padding(.top, 2)
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        let secs = max(0, Int(t))
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }
}

// MARK: - AirPlay Route Picker

private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        let green = UIColor(red: 50/255, green: 116/255, blue: 64/255, alpha: 1)
        v.tintColor = green
        v.activeTintColor = green
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
