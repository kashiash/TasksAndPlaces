//
//  ContentView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

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
    
    // Stan dla klikniętego punktu na mapie
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showAddLocationAlert = false
    @State private var temporaryPinCoordinate: CLLocationCoordinate2D? // Tymczasowy pin na mapie
    @State private var tappedPlaceInfo: PlaceInfo? // Informacje o miejscu przed dodaniem
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Warstwa 0: Tło - Pełnoekranowa Mapa
            MapReader { proxy in
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
                                }
                        }
                        .tag(location) // Ważne: łączy znacznik z wyborem
                    }
                    
                    // Tymczasowy pin po kliknięciu na mapie
                    if let tempPin = temporaryPinCoordinate {
                        Annotation("Wybrane miejsce", coordinate: tempPin) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
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
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        handleMapTap(at: coordinate)
                    }
                }
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
        // MARK: - Alert dodawania nowej lokalizacji z mapy
        .alert("Dodaj miejsce", isPresented: $showAddLocationAlert) {
            Button("Dodaj", role: .none) {
                if let coordinate = tappedCoordinate {
                    addNewLocation(at: coordinate)
                }
                // Usuń tymczasowy pin po dodaniu
                temporaryPinCoordinate = nil
                tappedPlaceInfo = nil
            }
            Button("Anuluj", role: .cancel) {
                // Usuń tymczasowy pin po anulowaniu
                temporaryPinCoordinate = nil
                tappedPlaceInfo = nil
            }
        } message: {
            if let placeInfo = tappedPlaceInfo {
                let messageText = placeInfo.address.isEmpty 
                    ? "\(placeInfo.name)\n\nCzy chcesz dodać to miejsce do swoich miejsc?"
                    : "\(placeInfo.name)\n\(placeInfo.address)\n\nCzy chcesz dodać to miejsce do swoich miejsc?"
                Text(messageText)
            } else {
                Text("Czy chcesz dodać ten punkt do swoich miejsc?")
            }
        }
    }
    
    // MARK: - Funkcje pomocnicze
    
    /// Wykonuje reverse geocoding używając MKLocalSearch (iOS 26)
    /// Wyciąga dane z MKMapItem.addressRepresentations i MKAddress (zamiennik CLPlacemark)
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> (name: String, address: String, city: String) {
        // Używamy MKLocalSearch do znalezienia miejsca w pobliżu współrzędnych
        let request = MKLocalSearch.Request()
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001) // Mniejszy region dla dokładności
        )
        request.region = region
        request.resultTypes = [.address, .pointOfInterest]
        
        // Wykonujemy wyszukiwanie
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // Jeśli znaleziono wyniki, użyj pierwszego (najbliższego)
        if let firstResult = response.mapItems.first {
            // Nazwa miejsca
            let name = firstResult.name ?? "Zaznaczone miejsce"
            
            // Adres z MKAddress lub addressRepresentations (nowe API iOS 26)
            // MKAddressRepresentations to obiekt z właściwościami, nie kolekcja
            var fullAddress = name
            var city = "Nieznane miasto"
            
            // Próbujemy wyciągnąć adres z addressRepresentations (nowe API iOS 26)
            // MKAddressRepresentations ma metodę fullAddress(Bool, Bool) -> String?
            if let addressReps = firstResult.addressRepresentations {
                // Używamy pełnego adresu - fullAddress to metoda przyjmująca parametry
                // Parametry: includingRegion (Bool), singleLine (Bool)
                if let formattedAddress = addressReps.fullAddress(includingRegion: true, singleLine: true), !formattedAddress.isEmpty {
                    fullAddress = formattedAddress
                } else if let shortAddress = addressReps.fullAddress(includingRegion: false, singleLine: true), !shortAddress.isEmpty {
                    fullAddress = shortAddress
                }
                
                // Wyciągamy miasto z cityWithContext, jeśli dostępne
                if let cityWithContext = addressReps.cityWithContext, !cityWithContext.isEmpty {
                    city = cityWithContext
                } else if let region = addressReps.region {
                    // region to Locale.Region, używamy identifier do konwersji na String
                    city = region.identifier
                }
            }
            
            // Fallback: jeśli addressRepresentations nie ma adresu, użyj MKAddress
            // W iOS 26 MKAddress może mieć właściwości do formatowania adresu
            // Na razie używamy nazwy miejsca jako podstawy, gdy addressRepresentations nie ma danych
            if fullAddress == name, firstResult.address != nil {
                // MKAddress może mieć podobne właściwości, ale struktura może się różnić
                // Można rozszerzyć gdy dokumentacja będzie dostępna
            }
            
            // Jeśli nadal nie mamy adresu, użyj współrzędnych
            if fullAddress.isEmpty || fullAddress == name {
                fullAddress = "\(coordinate.latitude), \(coordinate.longitude)"
            }
            
            return (name: name, address: fullAddress, city: city)
        }
        
        // Fallback: jeśli nie znaleziono wyników, użyj podstawowych informacji
        let name = "Zaznaczone miejsce"
        let fullAddress = "\(coordinate.latitude), \(coordinate.longitude)"
        let city = "Nieznane miasto"
        
        return (name: name, address: fullAddress, city: city)
    }
    
    private func updateCamera(to location: Location) {
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            ))
        }
    }
    
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        print("📍 Kliknięto mapę: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Najpierw wbij szpilę na mapie
        temporaryPinCoordinate = coordinate
        tappedCoordinate = coordinate
        
        // Pobierz informacje o miejscu (reverse geocoding) używając nowego API MapKit
        Task {
            do {
                let result = try await reverseGeocode(coordinate: coordinate)
                await MainActor.run {
                    tappedPlaceInfo = PlaceInfo(name: result.name, address: result.address)
                    showAddLocationAlert = true
                }
            } catch {
                print("❌ Błąd reverse geocoding: \(error.localizedDescription)")
                // Fallback w przypadku błędu
                await MainActor.run {
                    tappedPlaceInfo = PlaceInfo(name: "Zaznaczone miejsce", address: "")
                    showAddLocationAlert = true
                }
            }
        }
    }
    
    
    private func addNewLocation(at coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let result = try await reverseGeocode(coordinate: coordinate)
                let details = "Dodano z mapy: \(Date().formatted())"
                
                let newLocation = Location(
                    name: result.name,
                    cityName: result.city,
                    details: details,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    imageName: "mappin.and.ellipse"
                )
                
                await MainActor.run {
                    modelContext.insert(newLocation)
                }
                
                // Zaznacz nową lokalizację
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    selectedLocation = newLocation
                }
            } catch {
                // Fallback w przypadku błędu
                let newLocation = Location(
                    name: "Zaznaczone miejsce",
                    cityName: "Nieznane miasto",
                    details: "Dodano z mapy: \(Date().formatted())",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    imageName: "mappin.and.ellipse"
                )
                
                await MainActor.run {
                    modelContext.insert(newLocation)
                    selectedLocation = newLocation
                }
            }
        }
    }
    
    private func addCurrentLocation() {
        guard let userLoc = locationManager.userLocation else {
            locationManager.requestLocation()
            return
        }
        
        // Odwrócone geokodowanie, aby znaleźć nazwę miejsca używając nowego API MapKit
        let coordinate = CLLocationCoordinate2D(latitude: userLoc.latitude, longitude: userLoc.longitude)
        
        Task {
            do {
                let result = try await reverseGeocode(coordinate: coordinate)
                let name = result.name == "Zaznaczone miejsce" ? "Moja lokalizacja" : result.name
                let details = "Lokalizacja dodana ręcznie: \(Date().formatted())"
                
                let newLocation = Location(
                    name: name,
                    cityName: result.city,
                    details: details,
                    latitude: userLoc.latitude,
                    longitude: userLoc.longitude,
                    imageName: "location.circle.fill"
                )
                
                await MainActor.run {
                    modelContext.insert(newLocation)
                }
                
                // Zaznacz nową lokalizację
                try? await Task.sleep(nanoseconds: 500_000_000) // Małe opóźnienie na odświeżenie listy
                await MainActor.run {
                    selectedLocation = newLocation
                }
            } catch {
                // Fallback w przypadku błędu
                let newLocation = Location(
                    name: "Moja lokalizacja",
                    cityName: "Nieznane miasto",
                    details: "Lokalizacja dodana ręcznie: \(Date().formatted())",
                    latitude: userLoc.latitude,
                    longitude: userLoc.longitude,
                    imageName: "location.circle.fill"
                )
                
                await MainActor.run {
                    modelContext.insert(newLocation)
                    selectedLocation = newLocation
                }
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
        
        // Użycie nowego API iOS 26 - MKMapItem z init(location:address:) zamiast przestarzałego MKPlacemark
        let sourceLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        request.source = MKMapItem(location: sourceLocation, address: nil)
        
        let destinationLocation = CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude)
        request.destination = MKMapItem(location: destinationLocation, address: nil)
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

// MARK: - Struktura pomocnicza dla informacji o miejscu
struct PlaceInfo {
    let name: String
    let address: String
}

#Preview {
    ContentView()
        .modelContainer(for: Location.self, inMemory: true)
}
