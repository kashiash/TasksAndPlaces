//
//  Location.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import Foundation
import SwiftData
import MapKit
import CoreLocation

// MARK: - Model Danych
// Definiujemy strukturę pojedynczej lokalizacji
@Model
final class Location {
    var name: String
    var cityName: String        // Np. "Gliwice, Śląsk"
    var details: String         // Długi opis miejsca (zmiana z description)
    var latitude: Double
    var longitude: Double
    var imageName: String       // W prawdziwej apce to nazwa zdjęcia w Assets
    var createdAt: Date
    
    init(name: String, cityName: String, details: String, latitude: Double, longitude: Double, imageName: String) {
        self.name = name
        self.cityName = cityName
        self.details = details
        self.latitude = latitude
        self.longitude = longitude
        self.imageName = imageName
        self.createdAt = Date()
    }
    
    // Computed property dla kompatybilności z MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
