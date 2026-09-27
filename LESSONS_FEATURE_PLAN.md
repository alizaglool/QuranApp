# Lessons Feature — Implementation Plan

> Created: 2026-06-07  
> Status: Ready to implement — waiting for start signal  
> Architecture: MVVM + Coordinator (matches existing app pattern)

---

## Overview

Add a fully functional **Lessons** tab to the existing app.  
The tab already exists in `TabBarController` but returns an empty `UIViewController()`.  
This plan replaces it with a complete feature.

---

## User Flow

```
Lessons Tab
    ↓
Sheikh List Screen
  → Grid of sheikh cards (photo + name + subscribers)
  → Infinite scroll + sort
    ↓
Sheikh Detail Screen
  → Header: photo + name + subscribers
  → 3 tabs: Playlists | Videos | Reels
    ↓
Player Screen
  → YouTubePlayerKit embedded player
  → Plays inside app (no redirect)
```

---

## Data Flow

```
Google Sheets (CSV) ← anyone can edit to add/remove sheikhs
      ↓
App fetches channel IDs
      ↓
Chunk into groups of 50
      ↓
YouTube channels API (parallel batch calls)
      ↓
Merge → Sort → Paginate (page size: 20)
      ↓
Sheikh List

Tap Sheikh
      ↓
3 separate YouTube API calls (lazy per tab):
  Playlists → playlists?channelId=...
  Videos    → search?type=video&videoDuration=medium,long
  Reels     → search?type=video&videoDuration=short
      ↓
Player Screen (YouTubePlayerKit)
```

---

## Remote Config — Google Sheets

**How to add a new sheikh (no app update needed):**
1. Find the sheikh on YouTube
2. Get the channel ID:
   ```
   GET https://www.googleapis.com/youtube/v3/channels
     ?part=snippet
     &forHandle=CHANNEL_HANDLE
     &key=API_KEY
   ```
3. Open the Google Sheet link
4. Add a new row: `channelId | channelHandle | name`
5. Done — app picks it up automatically on next fetch

**Sheet columns:**
| channelId | channelHandle | notes |
|---|---|---|
| UCPuLTQ4ftEgpxfdSlN3Guhg | @drhazemshouman | د. حازم شومان |

**App fetches from:**
```
https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv
```

---

## Folder Structure

```
QuranApp/Feature/Lessons/
├── LessonsCoordinator.swift
│
├── SheikhList/
│   ├── SheikhListView.swift
│   ├── SheikhListViewModel.swift
│   └── Components/
│       ├── SheikhCardView.swift
│       └── SheikhSortPickerView.swift
│
├── SheikhDetail/
│   ├── SheikhDetailView.swift
│   ├── SheikhDetailViewModel.swift
│   └── Components/
│       ├── SheikhHeaderView.swift
│       ├── PlaylistCardView.swift
│       ├── VideoCardView.swift
│       └── ReelCardView.swift
│
├── Player/
│   ├── LessonPlayerView.swift
│   └── LessonPlayerViewModel.swift
│
├── Models/
│   ├── Sheikh.swift
│   ├── LessonPlaylist.swift
│   └── LessonVideo.swift
│
└── Services/
    ├── SheetConfigService.swift
    ├── YouTubeChannelService.swift
    ├── YouTubeContentService.swift
    └── BatchService.swift
```

---

## Data Models

Match existing patterns in `/Core/Sources/Core/Models/`

```swift
// Sheikh.swift
struct Sheikh: Identifiable, Codable {
    let id: String            // YouTube channel ID
    let name: String          // channel title from YouTube
    let thumbnailUrl: String
    let subscriberCount: Int
    let videoCount: Int
    let channelHandle: String
}

// LessonPlaylist.swift
struct LessonPlaylist: Identifiable, Codable {
    let id: String            // YouTube playlist ID
    let title: String
    let thumbnailUrl: String
    let itemCount: Int
    let category: String      // auto-detected from title keywords
}

// LessonVideo.swift
struct LessonVideo: Identifiable, Codable {
    let id: String            // YouTube video ID
    let title: String
    let thumbnailUrl: String
    let publishedAt: String
    let channelTitle: String
    enum ContentType { case video, reel }
    let type: ContentType
}
```

---

## Services

### SheetConfigService.swift
```swift
// Fetches channel IDs from Google Sheets CSV
// Caches to disk for 1 hour
// Falls back to disk cache if offline

final class SheetConfigService {
    static let shared = SheetConfigService()
    private let csvURL = "https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv"
    private let cacheKey = "cached_channel_ids"
    private let cacheTTL: TimeInterval = 3600 // 1 hour

    func fetchChannelIds() async throws -> [String]
    private func parseCSV(_ csv: String) -> [String]
    private func loadFromCache() -> [String]?
    private func saveToCache(_ ids: [String])
}
```

### BatchService.swift
```swift
// Chunks channel IDs into groups of 50
// Fires all chunks in parallel via TaskGroup
// Merges results into one array

final class BatchService {
    static let shared = BatchService()

    func fetchSheikhs(from channelIds: [String]) async throws -> [Sheikh] {
        let chunks = channelIds.chunked(into: 50)
        return try await withThrowingTaskGroup(of: [Sheikh].self) { group in
            for chunk in chunks {
                group.addTask {
                    try await YouTubeChannelService.shared.fetchChannels(ids: chunk)
                }
            }
            var result: [Sheikh] = []
            for try await sheikhs in group {
                result.append(contentsOf: sheikhs)
            }
            return result
        }
    }
}
```

### YouTubeChannelService.swift
```swift
// Calls: channels?part=snippet,statistics&id=id1,id2,...&key=API_KEY
// Maps response to [Sheikh]
// Matches URLSession pattern from QuranService.swift

final class YouTubeChannelService {
    static let shared = YouTubeChannelService()
    private let apiKey = "API_KEY" // move to xcconfig before shipping

    func fetchChannels(ids: [String]) async throws -> [Sheikh]
}
```

### YouTubeContentService.swift
```swift
// Three independent methods, each paginated via nextPageToken

final class YouTubeContentService {
    static let shared = YouTubeContentService()

    func fetchPlaylists(channelId: String, pageToken: String?) async throws -> (items: [LessonPlaylist], nextPageToken: String?)
    func fetchVideos(channelId: String, pageToken: String?) async throws -> (items: [LessonVideo], nextPageToken: String?)
    func fetchReels(channelId: String, pageToken: String?) async throws -> (items: [LessonVideo], nextPageToken: String?)

    private func detectCategory(_ title: String) -> String {
        // keyword matching: تفسير → Tafsir, عقيدة → Aqeedah, etc.
    }
}
```

---

## ViewModels

### SheikhListViewModel.swift

Match `HomeViewModel` pattern exactly.

```swift
@MainActor
final class SheikhListViewModel: MainViewModel {
    @Published var sheikhs: [Sheikh] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var sortOption: SortOption = .subscribers
    @Published var hasMorePages: Bool = true

    weak var coordinator: LessonsCoordinating?

    enum SortOption: String, CaseIterable {
        case subscribers = "الأكثر متابعين"
        case nameAZ      = "الاسم أ-ي"
        case nameZA      = "الاسم ي-أ"
        case videoCount  = "الأكثر فيديوهات"
    }

    private var allChannelIds: [String] = []
    private var loadedIds: [String] = []
    private let pageSize = 20

    func onAppear() { loadInitialData() }

    func loadInitialData() async   // fetch config → first page
    func loadNextPage()            // load next 20 IDs
    func refreshData()             // pull to refresh
    func updateSort(_ option: SortOption)  // re-sort loaded data
    func onSheikhTapped(_ sheikh: Sheikh)  // coordinate to detail
}
```

### SheikhDetailViewModel.swift

```swift
@MainActor
final class SheikhDetailViewModel: MainViewModel {
    @Published var selectedTab: Tab = .playlists
    @Published var playlists: [LessonPlaylist] = []
    @Published var videos: [LessonVideo] = []
    @Published var reels: [LessonVideo] = []
    @Published var isLoadingPlaylists = false
    @Published var isLoadingVideos = false
    @Published var isLoadingReels = false

    enum Tab { case playlists, videos, reels }

    private var playlistsPageToken: String?
    private var videosPageToken: String?
    private var reelsPageToken: String?

    let sheikh: Sheikh

    func onAppear() { loadTab(.playlists) }          // load first tab only
    func onTabSelected(_ tab: Tab)                   // lazy load on tab tap
    func loadMorePlaylists()
    func loadMoreVideos()
    func loadMoreReels()
    func onItemTapped(_ item: Any)                   // coordinate to player
}
```

### LessonPlayerViewModel.swift

```swift
@MainActor
final class LessonPlayerViewModel: MainViewModel {
    @Published var playerState: PlayerState = .idle

    enum PlayerState { case idle, ready, error(String) }
    enum Source {
        case playlist(id: String)
        case video(id: String)
    }

    let source: Source
    let title: String
    let sheikhName: String
}
```

---

## Views

All views follow the existing pattern from `HomeView.swift`:

```swift
struct SheikhListView: View {
    @StateObject var viewModel: SheikhListViewModel

    init(coordinator: LessonsCoordinating) {
        _viewModel = StateObject(wrappedValue: SheikhListViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            VStack(spacing: 0) {
                navBar          // title + sort picker button
                NoIndicatorsScrollView {
                    LazyVGrid(columns: [...]) {
                        ForEach(viewModel.sheikhs) { sheikh in
                            SheikhCardView(sheikh: sheikh)
                                .onTapGesture { viewModel.onSheikhTapped(sheikh) }
                        }
                        if viewModel.hasMorePages {
                            ProgressView()
                                .onAppear { viewModel.loadNextPage() }
                        }
                    }
                }
            }
            .customBackground(.background)
        }
        .onAppear { viewModel.onAppear() }
    }
}
```

**Sheikh Card** — shows:
- Channel thumbnail (SDWebImage for caching, already in project)
- Sheikh name
- Subscriber count formatted (e.g. "2.8M")

**Sheikh Detail** — 3 tabs:
- Segmented picker using existing `CustomPicker` from Core
- Each tab content is a `LazyVStack` with load-more trigger at bottom

**Player** — full screen:
```swift
import YouTubePlayerKit

struct LessonPlayerView: View {
    @StateObject var viewModel: LessonPlayerViewModel
    @StateObject private var player = YouTubePlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            YouTubePlayerView(player) { state in
                switch state {
                case .idle:  ProgressView()
                case .ready: EmptyView()
                case .error: Text("خطأ في التشغيل").customStyle(.body2, .error)
                }
            }
            .frame(height: 220)
            .cornerRadius(12)

            Text(viewModel.title)
                .customStyle(.heading3, .onSurface)
                .padding(.horizontal)

            Text(viewModel.sheikhName)
                .customStyle(.body2, .onSurfaceVariant)
                .padding(.horizontal)
        }
        .onAppear {
            switch viewModel.source {
            case .playlist(let id): player.source = .playlist(id: id)
            case .video(let id):    player.source = .video(id: id)
            }
        }
    }
}
```

---

## Coordinator

```swift
// Protocol
protocol LessonsCoordinating: AnyObject {
    func coordinateToSheikhDetail(sheikh: Sheikh)
    func coordinateToPlayer(source: LessonPlayerViewModel.Source, title: String, sheikhName: String)
    func coordinateBack()
}

// Implementation — matches HomeCoordinator pattern exactly
class LessonsCoordinator: MainCoordinator, LessonsCoordinating {
    var navigationController: UINavigationController
    weak var tabBarController: TabBarController?

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func coordinateToSheikhDetail(sheikh: Sheikh) {
        let view = SheikhDetailView(sheikh: sheikh, coordinator: self)
        let vc = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToPlayer(source: LessonPlayerViewModel.Source, title: String, sheikhName: String) {
        let view = LessonPlayerView(source: source, title: title, sheikhName: sheikhName)
        let vc = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
```

---

## Tab Bar Wiring

**File:** `QuranApp/Feature/Common/TabBar/TabBarController.swift`

Replace the existing empty implementation:
```swift
// BEFORE (existing — empty)
private func getLessonsViewController() -> UIViewController {
    return UIViewController()
}

// AFTER (new implementation)
private func getLessonsViewController() -> UIViewController {
    let navigationController = UINavigationController()
    let coordinator = LessonsCoordinator(
        navigationController: navigationController,
        tabBarController: self
    )
    let view = SheikhListView(coordinator: coordinator)
    let viewController = UIHostingController(
        rootView: view
            .environmentObject(LocalizationManager.shared)
            .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
    )
    navigationController.setViewControllers([viewController], animated: false)
    navigationController.isNavigationBarHidden = true
    return navigationController
}
```

---

## Core SPM — What Goes There

Shared components that other features can reuse go into `/Core/Sources/Core/`:

| Component | Location |
|---|---|
| `Sheikh` model | Core/Models/Sheikh.swift |
| `LessonPlaylist` model | Core/Models/LessonPlaylist.swift |
| `LessonVideo` model | Core/Models/LessonVideo.swift |
| `SheikhCardView` | Core/Common/Components/SheikhCardView.swift |

Services and ViewModels stay in `Feature/Lessons/` (not in Core).

---

## SPM Dependency to Add

Add `YouTubePlayerKit` to `Package.swift`:
```swift
.package(
    url: "https://github.com/SvenTiigi/YouTubePlayerKit.git",
    from: "1.0.0"
)
```

---

## YouTube API Endpoints Summary

| Purpose | Endpoint |
|---|---|
| Sheikh list | `channels?part=snippet,statistics&id=id1,id2,...&key=KEY` |
| Find channel by handle | `channels?part=snippet&forHandle=HANDLE&key=KEY` |
| Sheikh playlists | `playlists?part=snippet,contentDetails&channelId=ID&maxResults=50&key=KEY` |
| Sheikh videos | `search?part=snippet&channelId=ID&type=video&videoDuration=medium,long&order=date&key=KEY` |
| Sheikh reels | `search?part=snippet&channelId=ID&type=video&videoDuration=short&order=date&key=KEY` |

Pagination: add `&pageToken=TOKEN` to any paginated call.

---

## Implementation Steps (In Order)

1. Add `YouTubePlayerKit` via SPM
2. Create `channels_config` Google Sheet + publish as CSV
3. Add `Sheikh`, `LessonPlaylist`, `LessonVideo` models to Core SPM
4. Build `SheetConfigService` + `BatchService` + `YouTubeChannelService`
5. Build `YouTubeContentService` (playlists + videos + reels)
6. Build `SheikhListViewModel` + `SheikhListView` + `SheikhCardView`
7. Build `SheikhDetailViewModel` + `SheikhDetailView` (3 tabs)
8. Build `LessonPlayerViewModel` + `LessonPlayerView`
9. Build `LessonsCoordinator`
10. Wire into `TabBarController.getLessonsViewController()`
11. Move API key to `xcconfig`
12. Run `/qa → /ios-audit → /code-review`

---

## Security Notes

- YouTube API key must be stored in `.xcconfig` — never hardcoded in source
- Google Sheets CSV URL must be **public** (no auth required)
- Add `.xcconfig` to `.gitignore`

---

## Current State of Lessons Tab

```swift
// TabBarController.swift — line to find:
private func getLessonsViewController() -> UIViewController {
    return UIViewController()   // ← empty — ready to replace
}
```
