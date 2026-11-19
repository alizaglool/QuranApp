//
//  DeviceFaceDownDetector.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 19/11/2026.
//

import Foundation
import CoreMotion

@MainActor
protocol DeviceFaceDownDetector: AnyObject {

    var onFaceDown: (@MainActor () -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}

struct DeviceFaceDownGravityEvaluator {

    static let faceDownThreshold: Double = 0.8
    static let faceUpThreshold: Double = 0.5

    private var hasLeftFaceDown: Bool = false

    mutating func isNewlyFaceDown(gravityZ: Double) -> Bool {
        guard hasLeftFaceDown else {
            if gravityZ < Self.faceUpThreshold {
                hasLeftFaceDown = true
            }
            return false
        }

        guard gravityZ > Self.faceDownThreshold else { return false }
        hasLeftFaceDown = false
        return true
    }
}

@MainActor
final class MotionDeviceFaceDownDetector: DeviceFaceDownDetector {

    private static let updateInterval: TimeInterval = 0.2

    private let motionManager: CMMotionManager
    private var evaluator = DeviceFaceDownGravityEvaluator()
    private var isMonitoring: Bool = false

    var onFaceDown: (@MainActor () -> Void)?

    init(motionManager: CMMotionManager = CMMotionManager()) {
        self.motionManager = motionManager
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }

    func startMonitoring() {
        guard !isMonitoring, motionManager.isDeviceMotionAvailable else { return }

        isMonitoring = true
        evaluator = DeviceFaceDownGravityEvaluator()
        motionManager.deviceMotionUpdateInterval = Self.updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let gravityZ = motion?.gravity.z else { return }
            MainActor.assumeIsolated { self?.handleGravity(z: gravityZ) }
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Readings

    private func handleGravity(z: Double) {
        guard isMonitoring, evaluator.isNewlyFaceDown(gravityZ: z) else { return }

        stopMonitoring()
        onFaceDown?()
    }
}
