//
//  MyAdhkarView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-24.
//

import SwiftUI
import Core

// MARK: - Main View

struct MyAdhkarView: View {

    let coordinator: AdhkarCoordinating
    @StateObject private var viewModel = MyAdhkarViewModel()
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var isAddPresenting = false
    @State private var newDhikrText = ""
    @State private var newDhikrCount = 33
    @State private var readingIndex: Int? = nil

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                if viewModel.myAdhkar.isEmpty {
                    emptyState
                } else if let idx = readingIndex, idx < viewModel.myAdhkar.count {
                    readingView(idx: idx)
                } else {
                    adhkarList
                }
            }
        }
        .navigationBarHidden(true)
        .customSheet(isPresented: $isAddPresenting, fraction: 0.75, detents: [.medium, .large]) {
            addSheet
        }
    }
}

// MARK: - Nav Bar

extension MyAdhkarView {

    private var navBar: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .customCornerRadius(10)
            }
            Spacer()
            Text("أذكاري")
                .customStyle(.heading3, .onSurface)
            Spacer()
            if readingIndex == nil {
                Button(action: { isAddPresenting = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .customForeground(.primary)
                        .frame(width: 36, height: 36)
                        .background(ColorStyle.primary.color.opacity(0.08))
                        .customCornerRadius(10)
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private func handleBack() {
        if readingIndex != nil {
            readingIndex = nil
            viewModel.resetSession()
        } else {
            coordinator.coordinateBack()
        }
    }
}

// MARK: - Empty State

extension MyAdhkarView {

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.text.square")
                .font(.system(size: 52))
                .customForeground(.onSurfaceVariant)

            VStack(spacing: 8) {
                Text("أذكارك الخاصة")
                    .customStyle(.heading3, .onSurface)
                Text("أضف أذكارك المفضلة وتابعها بسهولة")
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            Button(action: { isAddPresenting = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("أضف ذكراً")
                }
                .customStyle(.headline, .onPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ColorStyle.primary.color)
                .customCornerRadius(12)
            }
            Spacer()
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Adhkar List

extension MyAdhkarView {

    private var adhkarList: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 0) {
                if !viewModel.myAdhkar.isEmpty {
                    startButton
                        .padding(.horizontal, .big)
                        .padding(.top, .sm)
                        .padding(.bottom, 16)
                }

                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.myAdhkar.enumerated()), id: \.element.id) { index, dhikr in
                        MyAdhkarCard(dhikr: dhikr, index: index + 1, colorScheme: colorScheme) {
                            viewModel.delete(dhikr)
                        } onTap: {
                            viewModel.resetSession()
                            readingIndex = index
                        }
                    }
                }
                .padding(.horizontal, .big)
                .padding(.bottom, 40)
            }
        }
    }

    private var startButton: some View {
        Button(action: {
            viewModel.resetSession()
            readingIndex = 0
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                Text("ابدأ الأذكار")
                    .customStyle(.headline, .onPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ColorStyle.primary.color)
            .cornerRadius(14)
        }
    }
}

// MARK: - Reading / Counter View

extension MyAdhkarView {

    private func readingView(idx: Int) -> some View {
        let dhikr = viewModel.myAdhkar[idx]
        let tapCount = viewModel.sessionCounts[dhikr.id] ?? 0
        let progress = dhikr.count > 0 ? Double(tapCount) / Double(dhikr.count) : 0
        let isLast = idx == viewModel.myAdhkar.count - 1

        return VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ColorStyle.outlineVariant.color.opacity(0.2))
                    Rectangle()
                        .fill(ColorStyle.primary.color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.2), value: progress)
                }
            }
            .frame(height: 3)

            Spacer()

            // Dhikr text
            Text(dhikr.textAr)
                .customStyle(.quranPageFixed(size: 26), .onSurface)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, .big)

            Spacer()

            // Counter display
            VStack(spacing: 8) {
                Text("\(tapCount)")
                    .customStyle(.adhkar(size: 52, bold: true), .primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tapCount)

                Text("/ \(dhikr.count)")
                    .customStyle(.bodySmall, .onSurfaceVariant)
            }
            .padding(.bottom, 24)

            // Tap button
            Button(action: { handleTap(dhikr: dhikr, idx: idx) }) {
                ZStack {
                    Circle()
                        .fill(ColorStyle.primary.color)
                        .frame(width: 90, height: 90)
                        .shadow(color: ColorStyle.primary.color.opacity(0.3), radius: 12, y: 4)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 32)

            // Navigation row
            HStack(spacing: 20) {
                Button(action: {
                    if idx > 0 {
                        readingIndex = idx - 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .customForeground(idx > 0 ? .onSurface : .outlineVariant)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(12)
                }
                .disabled(idx == 0)

                Button(action: {
                    viewModel.resetCount(for: dhikr)
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                        .customForeground(.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(12)
                }

                Button(action: {
                    if !isLast {
                        readingIndex = idx + 1
                    } else {
                        readingIndex = nil
                        viewModel.resetSession()
                    }
                }) {
                    Image(systemName: isLast ? "checkmark" : "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .customForeground(!isLast ? .onSurface : .secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func handleTap(dhikr: MyDhikr, idx: Int) {
        let newCount = viewModel.incrementCount(for: dhikr)
        if newCount >= dhikr.count {
            let nextIdx = idx + 1
            if nextIdx < viewModel.myAdhkar.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    readingIndex = nextIdx
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    readingIndex = nil
                    viewModel.resetSession()
                }
            }
        }
    }
}

// MARK: - Add Sheet

extension MyAdhkarView {

    private var addSheet: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.surfaceContainerHigh)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text("أضف ذكراً جديداً")
                    .customStyle(.heading3, .onSurface)
                    .padding(.top, 8)

                TextEditor(text: $newDhikrText)
                    .customStyle(.quranPageFixed(size: 20))                    .multilineTextAlignment(.center)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(12)
                    .environment(\.layoutDirection, .rightToLeft)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("العدد:")
                            .customStyle(.bodySmall, .onSurfaceVariant)
                        Spacer()
                        Text("\(newDhikrCount)")
                            .customStyle(.headline, .primary)
                    }
                    HStack(spacing: 12) {
                        ForEach([33, 100, 1, 7], id: \.self) { count in
                            Button(action: { newDhikrCount = count }) {
                                Text("\(count)")
                                    .customStyle(.bodySmall, newDhikrCount == count ? .onPrimary : .onSurface)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(newDhikrCount == count
                                        ? ColorStyle.primary.color
                                        : Color.surfaceContainerLow)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Button(action: {
                    let trimmed = newDhikrText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        viewModel.add(trimmed, count: newDhikrCount)
                        newDhikrText = ""
                        newDhikrCount = 33
                        isAddPresenting = false
                    }
                }) {
                    Text("حفظ")
                        .customStyle(.headline, .onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(newDhikrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? ColorStyle.primary.color.opacity(0.4)
                            : ColorStyle.primary.color)
                        .cornerRadius(12)
                }
                .disabled(newDhikrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Card

struct MyAdhkarCard: View {
    let dhikr: MyDhikr
    let index: Int
    let colorScheme: ColorScheme
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ColorStyle.primary.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        .frame(width: 36, height: 36)
                    Text("\(index)")
                        .customStyle(.adhkar(size: 13, bold: true), .primary)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dhikr.textAr)
                        .customStyle(.quranPageFixed(size: 17), .onSurface)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text("\(dhikr.count) مرة")
                        .customStyle(.caption2, .onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .customForeground(.onSurfaceVariant)
                        .padding(8)
                }
            }
            .padding(14)
            .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Model

struct MyDhikr: Identifiable, Codable {
    let id: String
    let textAr: String
    let count: Int
    let createdAt: Date

    init(id: String = UUID().uuidString, textAr: String, count: Int = 33, createdAt: Date = Date()) {
        self.id = id
        self.textAr = textAr
        self.count = count
        self.createdAt = createdAt
    }
}

// MARK: - ViewModel

@MainActor
final class MyAdhkarViewModel: ObservableObject {

    @Published private(set) var myAdhkar: [MyDhikr] = []
    @Published private(set) var sessionCounts: [String: Int] = [:]

    private let storageKey = "my_adhkar_v2"

    init() { load() }

    func add(_ text: String, count: Int = 33) {
        let dhikr = MyDhikr(textAr: text, count: count)
        myAdhkar.insert(dhikr, at: 0)
        save()
    }

    func delete(_ dhikr: MyDhikr) {
        myAdhkar.removeAll { $0.id == dhikr.id }
        sessionCounts.removeValue(forKey: dhikr.id)
        save()
    }

    @discardableResult
    func incrementCount(for dhikr: MyDhikr) -> Int {
        let current = sessionCounts[dhikr.id] ?? 0
        let next = min(current + 1, dhikr.count)
        sessionCounts[dhikr.id] = next
        return next
    }

    func resetCount(for dhikr: MyDhikr) {
        sessionCounts[dhikr.id] = 0
    }

    func resetSession() {
        sessionCounts = [:]
    }

    private func save() {
        if let data = try? JSONEncoder().encode(myAdhkar) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MyDhikr].self, from: data) else {
            migrateLegacyData()
            return
        }
        myAdhkar = decoded
    }

    private func migrateLegacyData() {
        guard let data = UserDefaults.standard.data(forKey: "my_adhkar_v1"),
              let legacy = try? JSONDecoder().decode([LegacyMyDhikr].self, from: data) else { return }
        myAdhkar = legacy.map { MyDhikr(id: $0.id, textAr: $0.textAr, count: 33, createdAt: $0.createdAt) }
        save()
    }
}

private struct LegacyMyDhikr: Codable {
    let id: String
    let textAr: String
    let createdAt: Date
}
