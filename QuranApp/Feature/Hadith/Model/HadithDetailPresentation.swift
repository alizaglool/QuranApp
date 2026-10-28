//
//  HadithDetailPresentation.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

// MARK: - Tab

enum HadithDetailTab: String, Hashable, Identifiable, CaseIterable {
    case commentary
    case rulings
    case narrators
    case takhrij
    case ghareeb
    case notes
    case subjects
    case translation
    case info

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .commentary:  return "text.book.closed.fill"
        case .rulings:     return "seal.fill"
        case .narrators:   return "person.3.fill"
        case .takhrij:     return "books.vertical.fill"
        case .ghareeb:     return "character.book.closed.fill"
        case .notes:       return "text.quote"
        case .subjects:    return "square.grid.2x2.fill"
        case .translation: return "globe"
        case .info:        return "info.circle.fill"
        }
    }

    var titleKey: AppLocalizedKeys {
        switch self {
        case .commentary:  return .commentary
        case .rulings:     return .hadithTabRulings
        case .narrators:   return .narratorChain
        case .takhrij:     return .takhrij
        case .ghareeb:     return .hadithTabGhareeb
        case .notes:       return .hadithTabNotes
        case .subjects:    return .hadithTabSubjects
        case .translation: return .hadithTabTranslation
        case .info:        return .hadithTabInfo
        }
    }
}

struct HadithDetailTabItem: Identifiable, Hashable {
    let tab: HadithDetailTab
    let title: String
    let count: Int

    var id: HadithDetailTab { tab }

    var icon: String { tab.icon }
}

// MARK: - Grade tone

enum HadithGradeTone {
    case authentic
    case good
    case weak
    case neutral

    static func make(_ text: String) -> HadithGradeTone {
        let value = text.lowercased()
        if value.contains("صحيح") || value.contains("sahih") { return .authentic }
        if value.contains("حسن") || value.contains("hasan") { return .good }
        if value.contains("ضعيف") || value.contains("منكر") || value.contains("da") { return .weak }
        return .neutral
    }

    var color: Color {
        switch self {
        case .authentic: return .hadithGreen
        case .good:      return .hadithOrange
        case .weak:      return .hadithRed
        case .neutral:   return .hadithPrimary
        }
    }
}

// MARK: - Rows

struct HadithRulingItem: Identifiable, Hashable {
    let id: Int
    let text: String
    let scholar: String
    let source: String
    let tone: HadithGradeTone
}

struct HadithNarratorRow: Identifiable, Hashable {
    let id: Int
    let name: String
    let order: Int
    let layerLabel: String
}

struct HadithTakhrijSectionItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let groups: [HadithTakhrijGroup]
}

struct HadithNoteItem: Identifiable, Hashable {
    let id: Int
    let marker: String
    let text: String
}

// MARK: - Presentation

struct HadithDetailPresentation: Hashable {
    let tabs: [HadithDetailTabItem]
    let commentary: String
    let rulings: [HadithRulingItem]
    let narrators: [HadithNarratorRow]
    let takhrij: [HadithTakhrijSectionItem]
    let ghareeb: [HadithGhareebMeaning]
    let notes: [HadithNoteItem]
    let subjects: [HadithSubjectPath]
    let translation: String
    let info: [HadithLabeledValue]
    let emptyMessage: String

    static let empty = HadithDetailPresentation(
        tabs: [], commentary: "", rulings: [], narrators: [], takhrij: [],
        ghareeb: [], notes: [], subjects: [], translation: "", info: [],
        emptyMessage: ""
    )

    var isEmpty: Bool { tabs.isEmpty }

    static func make(from detail: HadithDetail) -> HadithDetailPresentation {
        let entry = detail.entry

        let rulings = Self.rulings(detail)
        let narrators = Self.narrators(entry)
        let takhrij = Self.takhrij(detail)
        let notes = Self.notes(detail)
        let info = Self.info(entry)

        var tabs: [HadithDetailTabItem] = []
        func add(_ tab: HadithDetailTab, _ count: Int) {
            guard count > 0 else { return }
            tabs.append(HadithDetailTabItem(tab: tab, title: tab.titleKey.value, count: count))
        }

        add(.commentary, entry.commentary.isEmpty ? 0 : 1)
        add(.rulings, rulings.count)
        add(.narrators, narrators.count)
        add(.takhrij, takhrij.reduce(0) { $0 + $1.groups.count })
        add(.ghareeb, detail.ghareeb.count)
        add(.notes, notes.count)
        add(.subjects, detail.subjects.count)
        add(.translation, entry.translation.isEmpty ? 0 : 1)
        add(.info, info.count)

        return HadithDetailPresentation(
            tabs: tabs,
            commentary: entry.commentary,
            rulings: rulings,
            narrators: narrators,
            takhrij: takhrij,
            ghareeb: detail.ghareeb,
            notes: notes,
            subjects: detail.subjects,
            translation: entry.translation,
            info: info,
            emptyMessage: AppLocalizedKeys.hadithDetailsEmpty.value
        )
    }

    // MARK: Builders

    private static func rulings(_ detail: HadithDetail) -> [HadithRulingItem] {
        var items = detail.rulings.map {
            HadithRulingItem(id: $0.id, text: $0.text, scholar: $0.scholar,
                             source: $0.source, tone: .make($0.text))
        }

        let inline = detail.entry.grade
        if !inline.isEmpty, !items.contains(where: { $0.text == inline }) {
            items.insert(HadithRulingItem(id: 0, text: inline, scholar: "",
                                          source: "", tone: .make(inline)), at: 0)
        }
        return items
    }

    private static func narrators(_ entry: HadithEntry) -> [HadithNarratorRow] {
        let layer = AppLocalizedKeys.hadithNarratorLayer.value
        var seen: Set<Int> = []
        var rows: [HadithNarratorRow] = []

        for reference in entry.markup.narrators {
            guard !reference.name.isEmpty, seen.insert(reference.rwahID).inserted else { continue }
            rows.append(HadithNarratorRow(id: reference.rwahID,
                                          name: reference.name,
                                          order: rows.count + 1,
                                          layerLabel: reference.depth > 0 ? "\(layer) \(reference.depth)" : ""))
        }
        return rows
    }

    private static func takhrij(_ detail: HadithDetail) -> [HadithTakhrijSectionItem] {
        detail.takhrij.map { section in
            HadithTakhrijSectionItem(id: section.id,
                                     title: Self.title(for: section.relation),
                                     groups: section.groups)
        }
    }

    private static func title(for relation: HadithTakhrijRelation) -> String {
        switch relation {
        case .sameBook:       return AppLocalizedKeys.hadithTakhrijSameBook.value
        case .corroboration:  return AppLocalizedKeys.hadithTakhrijCorroborations.value
        case .witness:        return AppLocalizedKeys.hadithTakhrijWitnesses.value
        case .unspecified:    return AppLocalizedKeys.hadithTakhrijOther.value
        }
    }

    private static func notes(_ detail: HadithDetail) -> [HadithNoteItem] {
        detail.notes.enumerated().map { offset, note in
            HadithNoteItem(id: note.id,
                           marker: HadithBodyText.marker(offset + 1),
                           text: note.text)
        }
    }

    private static func info(_ entry: HadithEntry) -> [HadithLabeledValue] {
        var rows: [HadithLabeledValue] = []

        func add(_ id: String, _ key: AppLocalizedKeys, _ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            rows.append(HadithLabeledValue(id: id, label: key.value, value: trimmed))
        }

        add("numbers", .hadithNumber, entry.numbersLabel)
        add("citation", .hadithInfoCitation, entry.referenceLabel)
        add("kind", .hadithInfoKind, entry.kind)
        add("narratedBy", .hadithInfoNarratedBy, entry.narrator)
        add("chapter", .hadithInfoChapter, entry.breadcrumb)
        add("brief", .hadithInfoBrief, entry.brief)
        return rows
    }
}
