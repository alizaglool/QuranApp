//
//  QiblaDirectionCalculator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import CoreLocation

enum QiblaDirectionCalculator {

    static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    static func bearingToKaaba(from coordinate: CLLocationCoordinate2D) -> Double {
        let originLatitude = coordinate.latitude.degreesAsRadians
        let kaabaLatitude = kaabaCoordinate.latitude.degreesAsRadians
        let longitudeDelta = (kaabaCoordinate.longitude - coordinate.longitude).degreesAsRadians

        let eastWestComponent = sin(longitudeDelta) * cos(kaabaLatitude)
        let northSouthComponent = cos(originLatitude) * sin(kaabaLatitude)
            - sin(originLatitude) * cos(kaabaLatitude) * cos(longitudeDelta)

        let bearing = atan2(eastWestComponent, northSouthComponent).radiansAsDegrees
        return normalizedBearing(bearing)
    }

    static func distanceToKaaba(from coordinate: CLLocationCoordinate2D) -> Double {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let kaaba = CLLocation(latitude: kaabaCoordinate.latitude,
                               longitude: kaabaCoordinate.longitude)
        return kaaba.distance(from: origin)
    }

    static func normalizedBearing(_ bearing: Double) -> Double {
        let wrapped = bearing.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    static func shortestRotation(from currentAngle: Double, to targetAngle: Double) -> Double {
        let difference = (targetAngle - currentAngle).truncatingRemainder(dividingBy: 360)
        if difference > 180 { return difference - 360 }
        if difference < -180 { return difference + 360 }
        return difference
    }
}

// MARK: - Angle Units

private extension Double {

    var degreesAsRadians: Double { self * .pi / 180 }
    var radiansAsDegrees: Double { self * 180 / .pi }
}
