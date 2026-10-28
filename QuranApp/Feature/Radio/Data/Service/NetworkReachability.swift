//
//  NetworkReachability.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import Network

// MARK: - NetworkReachability

@MainActor
final class NetworkReachability: ObservableObject {

    static let shared = NetworkReachability()

    @Published private(set) var isOnline: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wird.reachability", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let reachable = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                if self.isOnline != reachable { self.isOnline = reachable }
            }
        }
        monitor.start(queue: queue)
    }
}
