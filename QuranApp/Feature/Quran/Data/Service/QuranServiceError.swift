//
//  QuranServiceError.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation

enum QuranServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

final class QuranService {
    
    static let shared = QuranService()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Fetch Quran Text (all ayahs)
    
    func fetchQuranText() async throws -> [QuranVerse] {
        let url = try buildURL("https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranuthman.json")
        let data = try await fetchData(from: url)
        
        do {
            let response = try decoder.decode(QuranTextResponse.self, from: data)
            print("📖 Fetched \(response.quran.count) verses")
            return response.quran
        } catch {
            throw QuranServiceError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Surahs Info
    
    func fetchSurahsInfo() async throws -> [String: ChapterInfo] {
        let url = try buildURL("https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/info.json")
        let data = try await fetchData(from: url)
        
        do {
            let response = try decoder.decode(QuranInfoResponse.self, from: data)
            print("📋 Fetched \(response.chapters.count) surahs info")
            return response.chapters
        } catch {
            throw QuranServiceError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Reciters
    
    func fetchReciters(language: String = "ar") async throws -> [ReciterDTO] {
        let url = try buildURL("https://mp3quran.net/api/v3/reciters?language=\(language)")
        let data = try await fetchData(from: url)
        
        do {
            let response = try decoder.decode(RecitersResponse.self, from: data)
            print("🎙️ Fetched \(response.reciters.count) reciters")
            return response.reciters
        } catch {
            throw QuranServiceError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Surah List (from mp3quran)
    
    func fetchSurahList(language: String = "ar") async throws -> [SurahListDTO] {
        let url = try buildURL("https://mp3quran.net/api/v3/suwar?language=\(language)")
        let data = try await fetchData(from: url)
        
        do {
            let response = try decoder.decode(SurahListResponse.self, from: data)
            print("📝 Fetched \(response.suwar.count) surahs from mp3quran")
            return response.suwar
        } catch {
            throw QuranServiceError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Prayer Times

    func fetchPrayerTimes(city: String = "Riyadh", country: String = "SA") async throws -> PrayerTimesData {
        let urlString = "https://api.aladhan.com/v1/timingsByCity?city=\(city)&country=\(country)"
        let url = try buildURL(urlString)
        let data = try await fetchData(from: url)
        
        do {
            let response = try decoder.decode(PrayerTimesAPIResponse.self, from: data)
            print("🕌 Fetched prayer times for \(city)")
            return response.data
        } catch {
            throw QuranServiceError.decodingError(error)
        }
    }
}

// MARK: - Private Helpers

private extension QuranService {
    
    func buildURL(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw QuranServiceError.invalidURL
        }
        return url
    }
    
    func fetchData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 \(url.absoluteString) → \(httpResponse.statusCode)")
            }
            
            return data
        } catch {
            throw QuranServiceError.networkError(error)
        }
    }
}

// MARK: - Surah List DTO (mp3quran)

struct SurahListResponse: Codable {
    let suwar: [SurahListDTO]
}

struct SurahListDTO: Codable {
    let id: Int
    let name: String
    let startPage: Int?
    let endPage: Int?
    let makkia: Int?
    let type: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, makkia, type
        case startPage = "start_page"
        case endPage = "end_page"
    }
}
