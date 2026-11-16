//
//  KhatmahRenderReviewTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import SwiftUI
import Core
@testable import QuranApp

private typealias RenderLanguage = LocalizationManager.Language

final class KhatmahRenderCoordinatorDouble: KhatmahCoordinating {

    private(set) var requestedPages: [Int] = []
    private(set) var scheduleCount = 0
    private(set) var backCount = 0

    func coordinateToQuranPage(_ page: Int) { requestedPages.append(page) }

    func coordinateToSchedule() { scheduleCount += 1 }

    func coordinateBack() { backCount += 1 }
}

@MainActor
final class KhatmahRenderReviewTests: XCTestCase {

    private let suiteName = "KhatmahRenderReviewTests"
    private var store: KhatmahPlanStore!
    private var coordinator: KhatmahRenderCoordinatorDouble!
    private var originalLanguage: RenderLanguage!
    private var writtenFiles: [String] = []

    private let viewportSize = CGSize(width: 393, height: 862)
    private let tallSize = CGSize(width: 393, height: 1500)

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        store = KhatmahPlanStore(defaults: UserDefaults(suiteName: suiteName)!)
        coordinator = KhatmahRenderCoordinatorDouble()
        originalLanguage = LocalizationManager.shared.currentLanguage
        writtenFiles = []
    }

    override func tearDown() {
        LocalizationManager.shared.currentLanguage = originalLanguage
        store.clearAll()
        store = nil
        coordinator = nil
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Tests

    func testRendersEveryKhatmahStateInEveryConfiguration() throws {
        let outputDirectory = try makeOutputDirectory(named: "Viewport")

        try renderAllConfigurations(named: "01-empty", in: outputDirectory) { [self] in
            AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderAllConfigurations(named: "02-active-on-schedule", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 5, completedDayNumbers: 1...5)
            return AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderAllConfigurations(named: "03-active-today-done", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 5, completedDayNumbers: 1...6)
            return AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderAllConfigurations(named: "04-active-behind", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 9, completedDayNumbers: 1...3)
            return AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderAllConfigurations(named: "05-completed", in: outputDirectory) { [self] in
            seedPlan(totalDays: 7, startedDaysAgo: 6, completedDayNumbers: 1...7)
            return AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderAllConfigurations(named: "06-schedule", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 9, completedDayNumbers: 1...3)
            return AnyView(KhatmahScheduleView(coordinator: coordinator, viewModel: scheduleViewModel()))
        }

        try renderAllConfigurations(named: "07-setup-duration", in: outputDirectory) { [self] in
            AnyView(setupView(paceMode: .duration, advanceToStartingPoint: false))
        }

        try renderAllConfigurations(named: "08-setup-target-date", in: outputDirectory) { [self] in
            AnyView(setupView(paceMode: .targetDate, advanceToStartingPoint: false))
        }

        try renderAllConfigurations(named: "09-setup-starting-point", in: outputDirectory) { [self] in
            AnyView(setupView(paceMode: .duration, advanceToStartingPoint: true))
        }

        XCTAssertEqual(writtenFiles.count, 36)
        print("KHATMAH_RENDER_DIRECTORY=\(outputDirectory.path)")
    }

    func testRendersTallVariantsToProveNoContentIsClipped() throws {
        let outputDirectory = try makeOutputDirectory(named: "Tall")

        try renderTall(named: "T1-active", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 9, completedDayNumbers: 1...3)
            return AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderTall(named: "T2-empty", in: outputDirectory) { [self] in
            AnyView(KhatmahPlanView(coordinator: coordinator, viewModel: planViewModel()))
        }

        try renderTall(named: "T3-schedule", in: outputDirectory) { [self] in
            seedPlan(totalDays: 30, startedDaysAgo: 9, completedDayNumbers: 1...3)
            return AnyView(KhatmahScheduleView(coordinator: coordinator, viewModel: scheduleViewModel()))
        }

        try renderTall(named: "T4-setup-starting-point", in: outputDirectory) { [self] in
            AnyView(setupView(paceMode: .duration, advanceToStartingPoint: true))
        }

        XCTAssertEqual(writtenFiles.count, 4)
    }
}

// MARK: - State Seeding

private extension KhatmahRenderReviewTests {

    func planViewModel() -> KhatmahPlanViewModel {
        KhatmahPlanViewModel(coordinator: coordinator, store: store)
    }

    func scheduleViewModel() -> KhatmahScheduleViewModel {
        KhatmahScheduleViewModel(coordinator: coordinator, store: store)
    }

    func setupView(paceMode: KhatmahPaceMode, advanceToStartingPoint: Bool) -> KhatmahSetupView {
        let viewModel = KhatmahSetupViewModel(store: store)
        viewModel.paceMode = paceMode
        if advanceToStartingPoint {
            _ = viewModel.onPrimaryTapped()
        }
        return KhatmahSetupView(viewModel: viewModel, onCancel: {}, onCreate: {})
    }

    func seedPlan(totalDays: Int, startedDaysAgo: Int, completedDayNumbers: ClosedRange<Int>) {
        store.clearAll()
        let startDate = store.date(byAddingDays: -startedDaysAgo, to: Date())
        _ = store.createPlan(totalDays: totalDays, startDate: startDate)
        for dayNumber in completedDayNumbers {
            store.markDayCompleted(dayNumber)
        }
    }
}

// MARK: - Rendering

private extension KhatmahRenderReviewTests {

    func renderAllConfigurations(named name: String,
                                 in directory: URL,
                                 content: () -> AnyView) throws {
        for language in [RenderLanguage.English, RenderLanguage.Arabic] {
            for isDark in [false, true] {
                store.clearAll()
                LocalizationManager.shared.currentLanguage = language
                let view = content()
                let image = renderImage(view, size: viewportSize, language: language, isDark: isDark)
                let suffix = "\(language == .Arabic ? "ar" : "en")-\(isDark ? "dark" : "light")"
                try write(image, named: "\(name)-\(suffix)", in: directory)
            }
        }
    }

    func renderTall(named name: String, in directory: URL, content: () -> AnyView) throws {
        store.clearAll()
        LocalizationManager.shared.currentLanguage = .English
        let view = content()
        let image = renderImage(view, size: tallSize, language: .English, isDark: false)
        try write(image, named: "\(name)-tall", in: directory)
    }

    func renderImage(_ view: AnyView, size: CGSize, language: RenderLanguage, isDark: Bool) -> UIImage {
        let hosted = view
            .environmentObject(LocalizationManager.shared)
            .environment(\.layoutDirection, language.direction)
            .environment(\.colorScheme, isDark ? .dark : .light)
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()

        let controller = UIHostingController(rootView: hosted)
        controller.overrideUserInterfaceStyle = isDark ? .dark : .light
        controller.view.frame = CGRect(origin: .zero, size: size)

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.overrideUserInterfaceStyle = isDark ? .dark : .light
        window.semanticContentAttribute = language == .Arabic ? .forceRightToLeft : .forceLeftToRight
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        controller.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }

        window.isHidden = true
        window.rootViewController = nil
        return image
    }

    func makeOutputDirectory(named name: String) throws -> URL {
        let documents = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        let directory = documents
            .appendingPathComponent("KhatmahRenderReview", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func write(_ image: UIImage, named name: String, in directory: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        let url = directory.appendingPathComponent("\(name).png")
        try data.write(to: url)

        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "\(name).png"
        attachment.lifetime = .keepAlways
        add(attachment)

        writtenFiles.append(name)
    }
}
