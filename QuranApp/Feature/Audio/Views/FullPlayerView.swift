//
//  FullPlayerView.swift
//  QuranApp
//

import SwiftUI
import Core

struct FullPlayerView: View {

    @EnvironmentObject private var audio: AudioEngine
    @State private var showReciterPicker = false
    @State private var showSpeedPicker = false
    @Environment(\.dismiss) private var dismiss

    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    artworkSection
                        .padding(.top, 24)

                    surahInfoSection
                        .padding(.top, 28)

                    progressSection
                        .padding(.top, 24)
                        .padding(.horizontal, 28)

                    controlsSection
                        .padding(.top, 32)

                    if showSpeedPicker {
                        speedChips
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    reciterSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("تلاوة")
                        .customStyle(.kitab(size: 16, bold: true))
                        .customForeground(.onSurface)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .medium))
                            .customForeground(.onSurface)
                    }
                    .accessibilityLabel("إغلاق")
                }
            }
        }
        .sheet(isPresented: $showReciterPicker) {
            ReciterSelectionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: Artwork

    private var artworkSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.primaryColor.opacity(0.3), Color.primaryColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)

            VStack(spacing: 4) {
                Text(audio.currentSurahArabicName)
                    .customStyle(.kitab(size: 22, bold: true))
                    .customForeground(.onSurface)
                    .multilineTextAlignment(.center)

                Text("\(audio.currentSurahNumber)")
                    .customStyle(.kitab(size: 14))                    .customForeground(.subtitle)
            }
        }
        .shadow(color: Color.primaryColor.opacity(0.2), radius: 16, x: 0, y: 8)
    }

    // MARK: Surah Info

    private var surahInfoSection: some View {
        VStack(spacing: 6) {
            Text(audio.currentSurahArabicName)
                .customStyle(.kitab(size: 26, bold: true))
                .customForeground(.onSurface)

            Text("سورة \(audio.currentSurahNumber) • آية \(audio.currentVerseNumber)")
                .customStyle(.kitab(size: 15))
                .customForeground(.subtitle)

            Text(audio.currentReciter.arabicName)
                .customStyle(.kitab(size: 13))                .customForeground(.subtitle)
        }
        .multilineTextAlignment(.center)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: Progress

    private var progressSection: some View {
        VStack(spacing: 6) {
            AudioProgressBar(value: audio.verseProgress) { newValue in
                audio.seek(to: newValue)
            }

            HStack {
                Text(formatTime(audio.verseElapsed))
                    .customStyle(.kitab(size: 11))                    .customForeground(.subtitle)

                Spacer()

                Text(formatTime(audio.verseDuration))
                    .customStyle(.kitab(size: 11))                    .customForeground(.subtitle)
            }
        }
    }

    // MARK: Controls

    private var controlsSection: some View {
        HStack(spacing: 36) {
            // Repeat
            Button { audio.cycleRepeatMode() } label: {
                Image(systemName: audio.repeatMode.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        audio.repeatMode == .off ? Color.subtitleText : Color.primaryColor
                    )
            }
            .accessibilityLabel(audio.repeatMode.label)

            // Previous
            Button { audio.previousVerse() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 26, weight: .medium))
                    .customForeground(.onSurface)
            }
            .accessibilityLabel("الآية السابقة")

            // Play / Pause
            Button {
                audio.isPlaying ? audio.pause() : audio.resume()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.primaryColor)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.primaryColor.opacity(0.35), radius: 12, x: 0, y: 4)

                    if audio.isLoadingVerse {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .offset(x: audio.isPlaying ? 0 : 2) // optical center for play icon
                    }
                }
            }
            .accessibilityLabel(audio.isPlaying ? "إيقاف مؤقت" : "تشغيل")

            // Next
            Button { audio.nextVerse() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 26, weight: .medium))
                    .customForeground(.onSurface)
            }
            .accessibilityLabel("الآية التالية")

            // Speed
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showSpeedPicker.toggle()
                }
            } label: {
                Text(audio.currentSpeedLabel)
                    .customStyle(.kitab(size: 13, bold: true))                    .foregroundStyle(showSpeedPicker ? Color.primaryColor : Color.subtitleText)
                    .frame(width: 38, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(showSpeedPicker
                                  ? Color.primaryColor.opacity(0.12)
                                  : Color.surfaceContainerLow)
                    )
            }
            .accessibilityLabel("سرعة التشغيل: \(audio.currentSpeedLabel)")
        }
    }

    // MARK: Speed chips

    private var speedChips: some View {
        HStack(spacing: 8) {
            ForEach(speedOptions, id: \.self) { speed in
                Button {
                    audio.setSpeed(speed)
                    withAnimation { showSpeedPicker = false }
                } label: {
                    let isSelected = audio.playbackSpeed == speed
                    Text(formatSpeed(speed))
                        .customStyle(.kitab(size: 13))                        .foregroundStyle(isSelected ? Color.white : Color.onSurface)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.primaryColor : Color.surfaceContainerLow)
                        )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Reciter section

    private var reciterSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("القارئ")
                    .customStyle(.kitab(size: 12))                    .customForeground(.subtitle)
                Text(audio.currentReciter.arabicName)
                    .customStyle(.kitab(size: 15, bold: true))
                    .customForeground(.onSurface)
            }
            Spacer()
            Button {
                showReciterPicker = true
            } label: {
                Text("تغيير")
                    .customStyle(.kitab(size: 14))                    .foregroundStyle(Color.primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryColor.opacity(0.1))
                    )
            }
            .accessibilityLabel("تغيير القارئ")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceContainerLow)
        )
    }

    // MARK: Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func formatSpeed(_ speed: Float) -> String {
        speed == Float(Int(speed)) ? "\(Int(speed))×" : "\(speed)×"
    }
}

// MARK: - AudioProgressBar

struct AudioProgressBar: View {

    var value: Double
    var onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragValue: Double = 0

    var displayValue: Double { isDragging ? dragValue : value }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.surfaceContainerLow)
                    .frame(height: isDragging ? 6 : 4)

                Capsule()
                    .fill(Color.primaryColor)
                    .frame(width: geo.size.width * displayValue, height: isDragging ? 6 : 4)

                Circle()
                    .fill(Color.primaryColor)
                    .frame(width: isDragging ? 16 : 0)
                    .shadow(color: Color.primaryColor.opacity(0.4), radius: 4)
                    .offset(x: geo.size.width * displayValue - (isDragging ? 8 : 0))
                    .animation(.spring(response: 0.2), value: isDragging)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        dragValue = max(0, min(1, gesture.location.x / geo.size.width))
                    }
                    .onEnded { _ in
                        onSeek(dragValue)
                        isDragging = false
                    }
            )
        }
        .frame(height: 20)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}
