//
//  ContentView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    // MARK: - Stan Aplikacji
    // Menedżer lokalizacji użytkownika
    @State private var locationManager = LocationManager()
    
    // Wybrana lokalizacja (domyślnie pierwsza)
    @State private var selectedLocation: Location? = testLocations.first
    // Pozycja kamery mapy
    // Zwiększamy 'delta' do 0.1, aby widok nie był zbyt zbliżony na start
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: testLocations.first!.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    // Stan dla arkusza szczegółów
    @State private var sheetLocation: Location? = nil
    // Stan trasy
    @State private var route: MKRoute? // Przechowuje wyliczoną trasę
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Warstwa 0: Tło - Pełnoekranowa Mapa
            Map(position: $cameraPosition, selection: $selectedLocation) {
                // Pokaż lokalizację użytkownika (niebieska kropka)
                UserAnnotation()
                
                // Znaczniki miejsc
                ForEach(testLocations) { location in
                    // MARK: - Warstwa 1: Niestandardowe Znaczniki
                    Annotation(location.name, coordinate: location.coordinate) {
                        LocationAnnotationView(isSelected: selectedLocation == location)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .tag(location) // Ważne: łączy znacznik z wyborem
                }
                
                // MARK: - Rysowanie trasy (jeśli istnieje)
                if let route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 6) // Niebieska linia
                }
            }
            .mapStyle(.hybrid(elevation: .realistic)) // Tryb hybrydowy/satelitarny
            .mapControls {
                MapUserLocationButton() // Przycisk "Gdzie jestem"
                MapCompass()
            }
            .safeAreaInset(edge: .bottom) {
                // Pusty obszar, żeby karuzela nie zasłaniała "Legal" mapy
                Color.clear.frame(height: 250)
            }
            .ignoresSafeArea()
            
            // MARK: - Warstwa 2: UI Overlay - Karuzela Kart
            VStack {
                Spacer()
                
                TabView(selection: $selectedLocation) {
                    ForEach(testLocations) { location in
                        LocationCardView(
                            location: location,
                            isSelected: selectedLocation == location,
                            onReadMore: {
                                // Przypisujemy lokalizację do zmiennej arkusza
                                sheetLocation = location
                            }
                        )
                        .tag(location) // Ważne: łączy kartę z wyborem
                        .padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Styl karuzeli bez wskaźników
                .frame(height: 200)
                .padding(.bottom, 40) // Odstęp od Safe Area (uwzględnienie iPhone'ów bez przycisku Home)
            }
        }
        // MARK: - Synchronizacja (Logika biznesowa)
        // Scenariusz 1: Przesuwanie Karuzeli - Kamera płynnie leci do nowej lokalizacji
        // Scenariusz 2: Kliknięcie Znacznika - Karuzela automatycznie przewija się
        .onChange(of: selectedLocation) { oldValue, newLocation in
            if let newLocation = newLocation {
                // Fly-over animation - płynny lot kamery z dostosowaniem zoomu
                // Dłuższy czas animacji dla płynniejszego lotu przy większej liczbie punktów
                withAnimation(.easeInOut(duration: 1.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: newLocation.coordinate,
                        // Mniejsza delta = większy zoom (bliżej ziemi)
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    ))
                }
            }
        }
        // MARK: - Obsługa wysuwanego arkusza szczegółów
        .sheet(item: $sheetLocation) { location in
            LocationDetailView(
                location: location,
                onGetDirections: {
                    // Wywołanie funkcji liczącej trasę
                    calculateRoute(to: location)
                }
            )
            .presentationDetents([.medium, .large]) // Pozwala wysunąć do połowy lub na cały ekran
            .presentationDragIndicator(.visible)    // Pasek do przeciągania
        }
    }
    
    // MARK: - Funkcja obliczająca trasę
    private func calculateRoute(to destination: Location) {
        print("🚀 Rozpoczynam wyznaczanie trasy do: \(destination.name)")
        
        // Sprawdź dostępność lokalizacji użytkownika
        guard let userLoc = locationManager.userLocation else {
            print("❌ Brak lokalizacji użytkownika - sprawdzam uprawnienia...")
            // Spróbuj ponownie pobrać lokalizację
            locationManager.requestLocation()
            return
        }
        
        print("✅ Lokalizacja użytkownika: \(userLoc.latitude), \(userLoc.longitude)")
        print("📍 Cel: \(destination.coordinate.latitude), \(destination.coordinate.longitude)")
        
        let request = MKDirections.Request()
        
        // Tworzenie map item dla źródła (lokalizacja użytkownika)
        let sourceLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        // Używamy nowego API dla iOS 26+, fallback do starego API
        if #available(iOS 26.0, *) {
            request.source = MKMapItem(location: sourceLocation, address: nil)
        } else {
            // Dla iOS < 26 używamy przestarzałego API
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
        }
        
        // Tworzenie map item dla celu
        let destinationLocation = CLLocation(
            latitude: destination.coordinate.latitude,
            longitude: destination.coordinate.longitude
        )
        
        if #available(iOS 26.0, *) {
            request.destination = MKMapItem(location: destinationLocation, address: nil)
        } else {
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        }
        
        request.transportType = .automobile
        
        print("🔄 Wysyłam żądanie wyznaczenia trasy...")
        
        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                print("✅ Trasa wyznaczona pomyślnie!")
                
                guard let route = response.routes.first else {
                    print("⚠️ Brak tras w odpowiedzi")
                    return
                }
                
                print("📏 Długość trasy: \(route.distance) metrów")
                print("⏱️ Szacowany czas: \(route.expectedTravelTime) sekund")
                
                // Zapisujemy trasę do stanu - mapa sama ją narysuje
                await MainActor.run {
                    withAnimation {
                        self.route = route
                        
                        // Ustaw kamerę tak, by widzieć całą trasę
                        let rect = route.polyline.boundingMapRect
                        self.cameraPosition = .rect(rect)
                        print("📷 Kamera ustawiona na widok trasy")
                    }
                }
            } catch {
                print("❌ Błąd wyznaczania trasy: \(error.localizedDescription)")
                print("🔍 Szczegóły błędu: \(error)")
                
                // Wyświetl bardziej szczegółowe informacje o błędzie
                if let mkError = error as? MKError {
                    print("MKError code: \(mkError.code.rawValue)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

