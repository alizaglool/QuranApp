//
//  AdhanVoiceRenderReviewTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import XCTest
import SwiftUI
import Core
@testable import QuranApp

private typealias RenderLanguage = LocalizationManager.Language

final class AdhanVoiceRenderCoordinatorDouble: AdhanVoiceCoordinating {

    private(set) var backCount = 0

    func coordinateBack() { backCount += 1 }
}

@MainActor
final class AdhanVoiceRenderReviewTests: XCTestCase {

    private var coordinator: AdhanVoiceRenderCoordinatorDouble!
    private var originalLanguage: RenderLanguage!
    private var retainedViewModels: [AdhanVoiceViewModel] = []
    private var retainedManagers: [PrayerNotificationManager] = []
    private var writtenFiles: [String] = []
    private var scratchDirectories: [URL] = []

    private let viewportSize = CGSize(width: 393, height: 862)
    private let tallSize = CGSize(width: 393, height: 1500)

    override func setUp() {
        super.setUp()
        coordinator = AdhanVoiceRenderCoordinatorDouble()
        originalLanguage = LocalizationManager.shared.currentLanguage
        retainedViewModels = []
        retainedManagers = []
        writtenFiles = []
        scratchDirectories = []
    }

    override func tearDown() {
        for directory in scratchDirectories {
            try? FileManager.default.removeItem(at: directory)
        }

        scratchDirectories = []
        LocalizationManager.shared.currentLanguage = originalLanguage
        retainedViewModels = []
        retainedManagers = []
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testRendersEveryAdhanVoiceStateInEveryConfiguration() throws {
        let outputDirectory = try makeOutputDirectory(named: "Viewport")

        try renderAllConfigurations(named: "01-default-selection", in: outputDirectory) { [self] in
            AnyView(adhanVoiceView(hasBundledAudio: true,
                                   recordingIdentifier: AdhanRecording.defaultIdentifier))
        }

        try renderAllConfigurations(named: "02-other-selection", in: outputDirectory) { [self] in
            AnyView(adhanVoiceView(hasBundledAudio: true, recordingIdentifier: "islam_sobhey"))
        }

        try renderAllConfigurations(named: "03-unavailable", in: outputDirectory) { [self] in
            AnyView(adhanVoiceView(hasBundledAudio: false,
                                   recordingIdentifier: AdhanRecording.defaultIdentifier))
        }

        XCTAssertEqual(writtenFiles.count, 12)
        print("ADHAN_VOICE_RENDER_DIRECTORY=\(outputDirectory.path)")
    }

    func testRendersTallVariantsToProveNoRecordingIsClipped() throws {
        let outputDirectory = try makeOutputDirectory(named: "Tall")

        for language in [RenderLanguage.English, RenderLanguage.Arabic] {
            LocalizationManager.shared.currentLanguage = language
            let view = AnyView(adhanVoiceView(hasBundledAudio: true,
                                              recordingIdentifier: AdhanRecording.defaultIdentifier))
            let image = renderImage(view, size: tallSize, language: language, isDark: false)
            try write(image, named: "T1-all-recordings-\(language == .Arabic ? "ar" : "en")", in: outputDirectory)
        }

        XCTAssertEqual(writtenFiles.count, 2)
        print("ADHAN_VOICE_TALL_DIRECTORY=\(outputDirectory.path)")
    }

    func testRenderedStateMatchesTheBundledCatalog() throws {
        let viewModel = makeViewModel(hasBundledAudio: true,
                                      recordingIdentifier: AdhanRecording.defaultIdentifier)

        XCTAssertEqual(viewModel.items.count, AdhanRecording.bundled.count)
        XCTAssertTrue(viewModel.isFullAdhanAvailable)
        XCTAssertEqual(viewModel.items.filter(\.isSelected).count, 1)
        XCTAssertEqual(viewModel.items.first(where: \.isSelected)?.id, AdhanRecording.defaultIdentifier)
        XCTAssertFalse(viewModel.items.contains { $0.title.isEmpty || $0.caption.isEmpty })
    }

    func testRendersThePlaybackFailureBanner() throws {
        let outputDirectory = try makeOutputDirectory(named: "Failure")
        let catalog = try corruptedAudioCatalog()

        try renderAllConfigurations(named: "04-playback-failed", in: outputDirectory) { [self] in
            AnyView(failedPlaybackView(catalog: catalog))
        }

        XCTAssertEqual(writtenFiles.count, 4)
        print("ADHAN_VOICE_FAILURE_DIRECTORY=\(outputDirectory.path)")
    }

    func testAFailedPreviewSurfacesAMessageThatClearsOnStop() async throws {
        let viewModel = makeViewModel(catalog: try corruptedAudioCatalog())

        XCTAssertNil(viewModel.playbackFailureMessage)
        XCTAssertEqual(viewModel.items.count, AdhanRecording.bundled.count)

        viewModel.onPreviewTapped(AdhanRecording.defaultIdentifier)
        await drainMainQueue()

        XCTAssertEqual(viewModel.playbackFailureMessage, AppLocalizedKeys.adhanVoicePlaybackFailed.value)

        viewModel.onDisappear()
        await drainMainQueue()

        XCTAssertNil(viewModel.playbackFailureMessage)
    }

    func testUnavailableStateRendersNoRecordingRows() throws {
        let viewModel = makeViewModel(hasBundledAudio: false,
                                      recordingIdentifier: AdhanRecording.defaultIdentifier)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isFullAdhanAvailable)
        XCTAssertFalse(viewModel.unavailableMessage.isEmpty)
    }
}

// MARK: - State Seeding

private extension AdhanVoiceRenderReviewTests {

    func adhanVoiceView(hasBundledAudio: Bool, recordingIdentifier: String) -> AdhanVoiceView {
        AdhanVoiceView(coordinator: coordinator,
                       viewModel: makeViewModel(hasBundledAudio: hasBundledAudio,
                                                recordingIdentifier: recordingIdentifier))
    }

    func makeViewModel(hasBundledAudio: Bool, recordingIdentifier: String) -> AdhanVoiceViewModel {
        let manager = makeNotificationManager(hasBundledAudio: hasBundledAudio,
                                              recordingIdentifier: recordingIdentifier)
        let viewModel = AdhanVoiceViewModel(coordinator: coordinator, notificationManager: manager)
        retainedManagers.append(manager)
        retainedViewModels.append(viewModel)
        return viewModel
    }

    func makeViewModel(catalog: PrayerNotificationSoundCatalog) -> AdhanVoiceViewModel {
        let manager = PrayerNotificationManagerBuilder
            .manager(center: LocalNotificationCenterDouble(status: .authorized),
                     defaults: PrayerNotificationFixture.defaults(),
                     preferences: PrayerNotificationFixture
                         .preferences(isInAppAdhanEnabled: true,
                                      recordingIdentifier: AdhanRecording.defaultIdentifier),
                     now: PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                         minutesSinceMidnight: 30),
                     soundCatalog: catalog)
        let viewModel = AdhanVoiceViewModel(coordinator: coordinator, notificationManager: manager)
        retainedManagers.append(manager)
        retainedViewModels.append(viewModel)

        return viewModel
    }

    func failedPlaybackView(catalog: PrayerNotificationSoundCatalog) -> AdhanVoiceView {
        let viewModel = makeViewModel(catalog: catalog)
        viewModel.onPreviewTapped(AdhanRecording.defaultIdentifier)
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))

        return AdhanVoiceView(coordinator: coordinator, viewModel: viewModel)
    }

    func drainMainQueue() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    func corruptedAudioCatalog() throws -> PrayerNotificationSoundCatalog {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let resources = root.appendingPathComponent("Adhan.bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        scratchDirectories.append(root)

        let source = PrayerNotificationFixture.soundCatalogWithBundledAudio()

        for recording in AdhanRecording.bundled {
            let tone = try XCTUnwrap(source.shortAdhanToneURL(for: recording))
            let full = try XCTUnwrap(source.fullAdhanAudioURL(for: recording))
            try FileManager.default.copyItem(at: tone,
                                             to: resources.appendingPathComponent(tone.lastPathComponent))
            try FileManager.default.copyItem(at: full,
                                             to: resources.appendingPathComponent(full.lastPathComponent))
        }

        let corrupted = try XCTUnwrap(AdhanRecording
            .recording(forIdentifier: AdhanRecording.defaultIdentifier))
        try Data("not audio".utf8)
            .write(to: resources.appendingPathComponent("\(corrupted.notificationToneResource).caf"))

        return PrayerNotificationSoundCatalog(bundle: try XCTUnwrap(Bundle(url: resources)))
    }

    func makeNotificationManager(hasBundledAudio: Bool,
                                 recordingIdentifier: String) -> PrayerNotificationManager {
        let catalog = hasBundledAudio
            ? PrayerNotificationFixture.soundCatalogWithBundledAudio()
            : PrayerNotificationFixture.soundCatalogWithoutAudio()
        return PrayerNotificationManagerBuilder
            .manager(center: LocalNotificationCenterDouble(status: .authorized),
                     defaults: PrayerNotificationFixture.defaults(),
                     preferences: PrayerNotificationFixture
                         .preferences(isInAppAdhanEnabled: true,
                                      recordingIdentifier: recordingIdentifier),
                     now: PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                         minutesSinceMidnight: 30),
                     soundCatalog: catalog)
    }
}

// MARK: - Rendering

private extension AdhanVoiceRenderReviewTests {

    func renderAllConfigurations(named name: String,
                                 in directory: URL,
                                 content: () -> AnyView) throws {
        for language in [RenderLanguage.English, RenderLanguage.Arabic] {
            for isDark in [false, true] {
                LocalizationManager.shared.currentLanguage = language
                let view = content()
                let image = renderImage(view, size: viewportSize, language: language, isDark: isDark)
                let suffix = "\(language == .Arabic ? "ar" : "en")-\(isDark ? "dark" : "light")"
                try write(image, named: "\(name)-\(suffix)", in: directory)
            }
        }
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
            .appendingPathComponent("AdhanVoiceRenderReview", isDirectory: true)
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
