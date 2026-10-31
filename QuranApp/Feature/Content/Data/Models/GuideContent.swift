//
//  GuideContent.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - GuideKey

enum GuideKey: String, CaseIterable {
    case umrah
    case hajj
}

// MARK: - GuideSectionKind

enum GuideSectionKind: String, CaseIterable, Decodable {
    case journey
    case learn
}

// MARK: - GuideStage

struct GuideStage: Identifiable, Hashable {
    let key: String
    let section: GuideSectionKind
    let parent: String?
    let titleAr: String
    let titleEn: String

    var id: String { key }

    var displayTitle: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !titleEn.isEmpty else { return titleAr }
        return titleEn
    }
}

// MARK: - GuideHeader

struct GuideHeader: Hashable {
    let stage: String
    let subtitle: String
    let text: String
    let source: String
}

// MARK: - GuidePage

struct GuidePage: Identifiable, Hashable {
    let slug: String
    let titleAr: String
    let titleEn: String
    let bodyAr: String
    let bodyEn: String

    var id: String { slug }

    var displayTitle: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !titleEn.isEmpty else { return titleAr }
        return titleEn
    }

    var displayBody: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !bodyEn.isEmpty else { return bodyAr }
        return bodyEn
    }
}

// MARK: - GuideItem

struct GuideItem: Identifiable, Hashable {
    let id: Int
    let stageKey: String
    let titleAr: String
    let titleEn: String
    let bodyAr: String
    let bodyEn: String
    let source: String

    var displayTitle: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !titleEn.isEmpty else { return titleAr }
        return titleEn
    }

    var displayBody: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !bodyEn.isEmpty else { return bodyAr }
        return bodyEn
    }

    var hasTitle: Bool { !displayTitle.isEmpty }
}

// MARK: - GuideContent

struct GuideContent {
    let key: String
    let dataVersion: String
    let stages: [GuideStage]
    let headers: [GuideHeader]
    let pages: [GuidePage]
    let items: [GuideItem]

    var overviewHeader: GuideHeader? { header(forStage: "overview") }

    func header(forStage stage: String) -> GuideHeader? {
        headers.first { $0.stage == stage }
    }

    func stages(in section: GuideSectionKind) -> [GuideStage] {
        stages.filter { $0.section == section && $0.parent == nil }
    }

    func substages(of stage: GuideStage) -> [GuideStage] {
        stages.filter { $0.parent == stage.key }
    }

    func items(forStage stage: String) -> [GuideItem] {
        items.filter { $0.stageKey == stage }
    }
}

// MARK: - Decoding

extension GuideContent: Decodable {

    private enum CodingKeys: String, CodingKey {
        case key
        case dataVersion
        case stages
        case headers
        case pages
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        dataVersion = try container.decodeIfPresent(String.self, forKey: .dataVersion) ?? ""
        stages = try container.decodeIfPresent([GuideStage].self, forKey: .stages) ?? []
        headers = try container.decodeIfPresent([GuideHeader].self, forKey: .headers) ?? []
        pages = try container.decodeIfPresent([GuidePage].self, forKey: .pages) ?? []
        items = try container.decodeIfPresent([GuideItem].self, forKey: .items) ?? []
    }
}

extension GuideStage: Decodable {

    private enum CodingKeys: String, CodingKey {
        case key
        case section
        case parent
        case titleAr
        case titleEn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        section = try container.decodeIfPresent(GuideSectionKind.self, forKey: .section) ?? .learn
        parent = try container.decodeIfPresent(String.self, forKey: .parent)
        titleAr = try container.decodeIfPresent(String.self, forKey: .titleAr) ?? ""
        titleEn = try container.decodeIfPresent(String.self, forKey: .titleEn) ?? ""
    }
}

extension GuideHeader: Decodable {

    private enum CodingKeys: String, CodingKey {
        case stage
        case subtitle
        case text
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stage = try container.decode(String.self, forKey: .stage)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
    }
}

extension GuidePage: Decodable {

    private enum CodingKeys: String, CodingKey {
        case slug
        case titleAr
        case titleEn
        case bodyAr
        case bodyEn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        titleAr = try container.decodeIfPresent(String.self, forKey: .titleAr) ?? ""
        titleEn = try container.decodeIfPresent(String.self, forKey: .titleEn) ?? ""
        bodyAr = try container.decodeIfPresent(String.self, forKey: .bodyAr) ?? ""
        bodyEn = try container.decodeIfPresent(String.self, forKey: .bodyEn) ?? ""
    }
}

extension GuideItem: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case variant
        case title
        case titleEn
        case textEn
        case source
        case segments
    }

    private struct RawSegment: Decodable {
        let kind: String
        let text: String

        private enum CodingKeys: String, CodingKey {
            case kind = "k"
            case text = "t"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "text"
            text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        stageKey = try container.decodeIfPresent(String.self, forKey: .variant) ?? ""
        titleAr = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        titleEn = try container.decodeIfPresent(String.self, forKey: .titleEn) ?? ""
        bodyEn = try container.decodeIfPresent(String.self, forKey: .textEn) ?? ""
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""

        let segments = try container.decodeIfPresent([RawSegment].self, forKey: .segments) ?? []
        bodyAr = segments
            .filter { $0.kind == "text" || $0.kind == "quran" }
            .map(\.text)
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
