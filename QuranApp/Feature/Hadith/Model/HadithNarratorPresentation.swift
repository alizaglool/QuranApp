//
//  HadithNarratorPresentation.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import Foundation
import Core

struct HadithNarratorVerdictItem: Identifiable, Hashable {
    let id: Int
    let scholar: String
    let text: String
}

struct HadithNarratorPresentation: Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let rows: [HadithLabeledValue]
    let verdictsTitle: String
    let verdicts: [HadithNarratorVerdictItem]
    let sourcesTitle: String
    let sources: [String]
    let emptyMessage: String

    var isEmpty: Bool {
        title.isEmpty && rows.isEmpty && verdicts.isEmpty && sources.isEmpty
    }

    static func make(_ profile: HadithNarratorProfile?, id: Int, fallbackName: String) -> HadithNarratorPresentation {
        guard let profile else { return .unknown(id: id, name: fallbackName) }

        var rows: [HadithLabeledValue] = []

        func add(_ id: String, _ key: AppLocalizedKeys, _ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            rows.append(HadithLabeledValue(id: id, label: key.value, value: trimmed))
        }

        add("kunya", .hadithNarratorKunya, profile.kunya)
        add("lineage", .hadithNarratorLineage, profile.lineage)
        add("epithet", .hadithNarratorEpithet, profile.epithet)
        add("knownAs", .hadithNarratorKnownAs, profile.knownAs)
        add("generation", .hadithNarratorGeneration, profile.generation)
        add("country", .hadithNarratorCountry, profile.country)
        add("lifespan", .hadithNarratorLifespan, profile.lifespan)
        add("birthPlace", .hadithNarratorBirthPlace, profile.birthPlace)
        add("deathPlace", .hadithNarratorDeathPlace, profile.deathPlace)
        add("ibnHajar", .hadithNarratorIbnHajar, profile.ibnHajarVerdict)
        add("summary", .hadithNarratorVerdictsSummary, profile.verdictsSummary)
        add("notes", .hadithNarratorNotes, profile.notes)
        add("source", .hadithSource, profile.source)

        let title = profile.displayName.isEmpty ? fallbackName : profile.displayName
        let subtitle = profile.knownAs == title ? profile.shortName : profile.knownAs

        return HadithNarratorPresentation(
            id: profile.id,
            title: title,
            subtitle: subtitle == title ? "" : subtitle,
            rows: rows,
            verdictsTitle: AppLocalizedKeys.hadithNarratorVerdicts.value,
            verdicts: profile.verdicts.map {
                HadithNarratorVerdictItem(id: $0.id, scholar: $0.scholarLabel, text: $0.verdict)
            }.filter { !$0.text.isEmpty },
            sourcesTitle: AppLocalizedKeys.hadithNarratorSources.value,
            sources: profile.sources.filter { !$0.isEmpty },
            emptyMessage: AppLocalizedKeys.hadithNarratorUnknown.value
        )
    }

    private static func unknown(id: Int, name: String) -> HadithNarratorPresentation {
        HadithNarratorPresentation(
            id: id,
            title: name,
            subtitle: "",
            rows: [],
            verdictsTitle: "",
            verdicts: [],
            sourcesTitle: "",
            sources: [],
            emptyMessage: AppLocalizedKeys.hadithNarratorUnknown.value
        )
    }
}

struct HadithGlossPresentation: Hashable, Identifiable {
    let id: String
    let title: String
    let headline: String
    let text: String

    static func ghareeb(_ meaning: HadithGhareebMeaning) -> HadithGlossPresentation {
        HadithGlossPresentation(id: "ghareeb-\(meaning.id)",
                                title: AppLocalizedKeys.hadithGhareebWord.value,
                                headline: meaning.word,
                                text: meaning.meaning)
    }

    static func note(_ note: HadithNoteItem) -> HadithGlossPresentation {
        HadithGlossPresentation(id: "note-\(note.id)",
                                title: AppLocalizedKeys.hadithNoteTitle.value,
                                headline: note.marker,
                                text: note.text)
    }
}
