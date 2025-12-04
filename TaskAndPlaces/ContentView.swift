//
//  ContentView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import MapKit
import SwiftData

struct ContentView: View {
    // MARK: - Dane SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Location.createdAt, order: .reverse) private var locations: [Location]
    
    // MARK: - Stan Aplikacji
    // Menedżer lokalizacji użytkownika
    @State private var locationManager = LocationManager()
    
    // Wybrana lokalizacja
    @State private var selectedLocation: Location?
    
    // Pozycja kamery mapy
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Stan dla arkusza szczegółów
    @State private var sheetLocation: Location? = nil
    
    // Stan dla arkusza wyszukiwania
    @State private var showSearchSheet = false
    
    // Stan trasy
    @State private var route: MKRoute? // Przechowuje wyliczoną trasę
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Warstwa 0: Tło - Pełnoekranowa Mapa
            Map(position: $cameraPosition, selection: $selectedLocation) {
                // Pokaż lokalizację użytkownika (niebieska kropka)
                UserAnnotation()
                
                // Znaczniki miejsc
                ForEach(locations) { location in
                    // MARK: - Warstwa 1: Niestandardowe Znaczniki
                    Annotation(location.name, coordinate: location.coordinate) {
                        LocationAnnotationView(isSelected: selectedLocation == location)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .onTapGesture {
                                // Bezpośredni wybór lokalizacji po kliknięciu
                                selectedLocation = location
                                // Opcjonalnie: Automatyczne otwarcie szczegółów po kliknięciu
                                // sheetLocation = location 
                            }
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
            
            // MARK: - Warstwa 2: UI Overlay
            VStack {
                // Górny pasek z przyciskami
                HStack {
                    Spacer()
                    
                    Menu {
                        Button(action: addCurrentLocation) {
                            Label("Bieżąca lokalizacja", systemImage: "location.fill")
                        }
                        Button(action: { showSearchSheet = true }) {
                            Label("Szukaj adresu", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Karuzela Kart
                if !locations.isEmpty {
                    TabView(selection: $selectedLocation) {
                        ForEach(locations) { location in
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
                            .onTapGesture {
                                // Otwórz szczegóły również po kliknięciu w samą kartę (nie tylko guzik)
                                if selectedLocation == location {
                                     sheetLocation = location
                                } else {
                                    selectedLocation = location
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Styl karuzeli bez wskaźników
                    .frame(height: 200)
                    .padding(.bottom, 40) // Odstęp od Safe Area
                }
            }
        }
        // MARK: - Synchronizacja (Logika biznesowa)
        .onAppear {
            // Ustawienie początkowej kamery na pierwszy element, jeśli nie ustawiona
            if let first = locations.first, selectedLocation == nil {
                selectedLocation = first
                updateCamera(to: first)
            }
        }
        .onChange(of: selectedLocation) { oldValue, newLocation in
            if let newLocation = newLocation {
                updateCamera(to: newLocation)
            }
        }
        // MARK: - Obsługa wysuwanego arkusza szczegółów
        .sheet(item: $sheetLocation) { location in
            LocationDetailView(
                location: location,
                onGetDirections: {
                    calculateRoute(to: location)
                }
            )
            .presentationDetents([.medium, .large]) // Pozwala wysunąć do połowy lub na cały ekran
            .presentationDragIndicator(.visible)    // Pasek do przeciągania
        }
        // MARK: - Arkusz wyszukiwania
        .sheet(isPresented: $showSearchSheet) {
            SearchLocationView()
        }
    }
    
    // MARK: - Funkcje pomocnicze
    
    private func updateCamera(to location: Location) {
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            ))
        }
    }
    
    private func addCurrentLocation() {
        guard let userLoc = locationManager.userLocation else {
            locationManager.requestLocation()
            return
        }
        
        // Odwrócone geokodowanie, aby znaleźć nazwę miejsca
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            let placemark = placemarks?.first
            let name = placemark?.name ?? "Moja lokalizacja"
            let city = placemark?.locality ?? "Nieznane miasto"
            let details = "Lokalizacja dodana ręcznie: \(Date().formatted())"
            
            let newLocation = Location(
                name: name,
                cityName: city,
                details: details,
                latitude: userLoc.latitude,
                longitude: userLoc.longitude,
                imageName: "location.circle.fill"
            )
            
            modelContext.insert(newLocation)
            
            // Zaznacz nową lokalizację
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // Małe opóźnienie na odświeżenie listy
                selectedLocation = newLocation
            }
        }
    }
    
    // MARK: - Funkcja obliczająca trasę
    private func calculateRoute(to destination: Location) {
        print("🚀 Rozpoczynam wyznaczanie trasy do: \(destination.name)")
        
        guard let userLoc = locationManager.userLocation else {
            print("❌ Brak lokalizacji użytkownika - sprawdzam uprawnienia...")
            locationManager.requestLocation()
            return
        }
        
        let request = MKDirections.Request()
        let sourceLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        // Dostosowanie do wersji iOS (uproszczone, zakładam nowsze SDK dostępne)
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile
        
        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                guard let route = response.routes.first else { return }
                
                await MainActor.run {
                    withAnimation {
                        self.route = route
                        let rect = route.polyline.boundingMapRect
                        self.cameraPosition = .rect(rect)
                    }
                }
            } catch {
                print("❌ Błąd wyznaczania trasy: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Location.self, inMemory: true)
}
