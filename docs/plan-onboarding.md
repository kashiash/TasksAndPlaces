# Plan Onboarding: TaskAndPlaces

## Wprowadzenie

Ten dokument jest przewodnikiem dla nowego programisty, który dołącza do projektu **TaskAndPlaces**. Zawiera wszystkie informacje niezbędne do szybkiego rozpoczęcia pracy.

---

## 1. Wymagania Systemowe

### Minimalne Wymagania

> ⚠️ **WAŻNE:** Projekt korzysta z najnowszego API MapKit dostępnego od iOS 17.

- **iOS:** 17.0 lub wyższy
- **Xcode:** 15.0 lub wyższy (wymagane dla iOS 17 SDK)
- **Swift:** 5.9+
- **Platforma docelowa:** iPhone, iPad (opcjonalnie macOS, visionOS)

### Sprawdzenie Wersji

```bash
# Sprawdź wersję Xcode
xcodebuild -version

# Sprawdź deployment target w projekcie
# Otwórz: TaskAndPlaces.xcodeproj → Target → General → Deployment Info
```

**Jeśli używasz starszego symulatora:**
- Kod się nie skompiluje
- Błędy będą wskazywać na brak dostępności API
- Rozwiązanie: Zaktualizuj Xcode lub użyj fizycznego urządzenia z iOS 17+

---

## 2. Architektura Widoku (Mental Model)

### Struktura "Kanapki" (Layer Architecture)

Wyobraź sobie widok jako trzy warstwy nakładane jedna na drugą:

```
┌─────────────────────────────────┐
│  Warstwa 2: UI Overlay          │ ← TabView (karuzela kart)
│  (Karuzela na dole ekranu)      │
├─────────────────────────────────┤
│  Warstwa 1: Interaktywna Mapa   │ ← Annotations (znaczniki)
│  (Znaczniki na mapie)            │
├─────────────────────────────────┤
│  Warstwa 0: Tło                 │ ← Map (pełnoekranowa)
│  (Mapa Apple Maps)               │
└─────────────────────────────────┘
```

### Komponenty i Ich Relacje

```
ContentView (Główny Kontroler)
├── @StateObject locationManager (Lokalizacja użytkownika)
├── @State selectedLocation (Single Source of Truth)
├── @State cameraPosition
├── @State sheetLocation (Lokalizacja w arkuszu)
├── @State route (Wyznaczona trasa)
│
├── Map (Warstwa 0 + 1)
│   ├── position: $cameraPosition
│   ├── selection: $selectedLocation
│   ├── UserAnnotation() ← Lokalizacja użytkownika
│   ├── ForEach(testLocations) {  ← 20 lokalizacji
│   │   └── Annotation {
│   │       └── LocationAnnotationView(isSelected: ...)
│   │   }
│   │   .tag(location) ← Kluczowe!
│   └── MapPolyline(route) ← Trasa (jeśli wyznaczona)
│
└── TabView (Warstwa 2)
    ├── selection: $selectedLocation
    └── ForEach(testLocations) {  ← 20 lokalizacji
        └── LocationCardView(location: ..., isSelected: ..., onReadMore: ...)
            .tag(location) ← Kluczowe!
    }
```

### Zasada: "Głupie" Komponenty, "Mądry" Rodzic

- **ContentView (rodzic):** Zarządza stanem, logiką biznesową
- **LocationCardView (dziecko):** Tylko wyświetla dane, nie zarządza stanem
- **LocationAnnotationView (dziecko):** Tylko wyświetla animację, nie zarządza stanem

**Dlaczego?**
- Łatwiejsze testowanie
- Lepsza reużywalność komponentów
- Centralizacja logiki (łatwiejsze debugowanie)

---

## 3. Przepływ Danych (Data Flow)

### Single Source of Truth

```
┌─────────────────────────────────────┐
│  @State selectedLocation: Location? │ ← JEDYNE ŹRÓDŁO PRAWDY
│  (domyślnie: testLocations.first)    │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│    Map      │  │   TabView    │
│ selection:  │  │ selection:   │
│ $selected   │  │ $selected    │
│             │  │              │
│ ForEach(    │  │ ForEach(     │
│  testLocations)│  testLocations)│
└─────────────┘  └──────────────┘
```

### Synchronizacja Dwukierunkowa

**Scenariusz A: Użytkownik przesuwa karuzelę**
```
1. TabView zmienia selectedLocation (przez .tag())
   ↓
2. .onChange(of: selectedLocation) wykrywa zmianę
   ↓
3. withAnimation { cameraPosition = ... } (lot kamery)
   ↓
4. Map automatycznie aktualizuje wybór (przez selection: $selectedLocation)
```

**Scenariusz B: Użytkownik klika znacznik**
```
1. Map zmienia selectedLocation (przez selection: $selectedLocation)
   ↓
2. TabView automatycznie przewija się (przez .tag())
   ↓
3. .onChange(of: selectedLocation) wykrywa zmianę
   ↓
4. withAnimation { cameraPosition = ... } (lot kamery)
```

---

## 4. Kluczowe Mechanizmy

### 4.1. Tagging System (`.tag()`)

**Co to jest?**
Modyfikator `.tag()` łączy elementy UI z obiektami danych.

**Dlaczego jest ważny?**
Bez `.tag()` SwiftUI nie wie, który znacznik na mapie odpowiada której karcie w karuzeli.

**Przykład:**
```swift
// Na mapie:
Annotation(location.name, coordinate: location.coordinate) {
    LocationAnnotationView(isSelected: selectedLocation == location)
}
.tag(location) // ← Bez tego synchronizacja nie zadziała!

// W karuzeli:
ForEach(testLocations) { location in
    LocationCardView(
        location: location,
        isSelected: selectedLocation == location
    )
    .tag(location) // ← Ten sam obiekt!
}
```

**Uwaga:** 
- Używamy `testLocations` (nie `locations`)
- Oba komponenty wymagają parametru `isSelected` do synchronizacji stanu wizualnego

**Zasada:** Oba elementy (Annotation i CardView) muszą mieć `.tag()` z tym samym obiektem `Location`.

---

### 4.2. Reactive Side Effects (`.onChange`)

**Problem:**
Zmiana `selectedLocation` nie przesuwa automatycznie kamery mapy. SwiftUI tylko aktualizuje wybór, ale nie animuje kamery.

**Rozwiązanie:**
Używamy `.onChange(of: selectedLocation)` do nasłuchiwania zmian i ręcznego wywołania animacji.

**Przykład:**
```swift
.onChange(of: selectedLocation) { oldValue, newLocation in
    if let newLocation = newLocation {
        // Dłuższy czas animacji (1.5s) dla płynniejszego lotu przy większej liczbie punktów
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: newLocation.coordinate,
                // Mniejsza delta = większy zoom (bliżej ziemi)
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            ))
        }
    }
}
```

**Uwaga:** 
- Czas animacji: `1.5s` (zwiększony z `1.2s` dla płynniejszego lotu przy 17 lokalizacjach)
- Span przy wyborze: `0.015` (większy zoom niż początkowy `0.1`)

**Dlaczego nie `didSet`?**
- `didSet` nie działa z `@State` w SwiftUI
- `.onChange` jest dedykowany do reaktywnych efektów ubocznych

---

### 4.3. MapCameraPosition

**Co to jest?**
Nowy typ w iOS 17+ do deklaratywnego sterowania kamerą mapy.

**Zastosowanie:**
```swift
@State private var cameraPosition: MapCameraPosition = .region(...)

Map(position: $cameraPosition) {
    // ...
}
```

**Dlaczego nie `MKMapView`?**
- Stare API wymagało `UIViewRepresentable`
- Nowe API jest natywnie SwiftUI
- Lepsza integracja z systemem animacji

---

## 5. Struktura Plików

```
TaskAndPlaces/
├── TaskAndPlacesApp.swift          # Punkt wejścia aplikacji (konfiguracja SwiftData)
├── ContentView.swift               # Główny widok (zarządza stanem)
├── Location.swift                  # Model danych SwiftData (@Model)
├── LocationCardView.swift          # Komponent: Karta w karuzeli
├── LocationAnnotationView.swift    # Komponent: Znacznik na mapie
├── LocationDetailView.swift        # Komponent: Arkusz szczegółów miejsca (z edycją)
├── LocationManager.swift           # Menedżer lokalizacji użytkownika
├── SearchLocationView.swift        # Widok wyszukiwania i dodawania miejsc
├── DataLoader.swift                # Klasa do seedowania danych początkowych
├── VehicleData.swift               # Model danych pojazdu (funkcjonalność dodatkowa)
├── VehicleDocumentAztecDecoder.swift # Dekoder dokumentów pojazdu (funkcjonalność dodatkowa)
├── Info.plist                      # Konfiguracja (uprawnienia lokalizacji)
└── Assets.xcassets/                # Zasoby (ikony, kolory)
```

### Opis Plików

**`Location.swift`**
- Model danych: klasa `Location` z adnotacją `@Model` (SwiftData)
- Persystencja: Dane są zapisywane w bazie SwiftData
- Protokoły: Automatycznie `Identifiable` przez SwiftData
- Pola modelu:
  - `name: String` - główna nazwa miejsca
  - `cityName: String` - nazwa miasta (np. "Gliwice", "Katowice - Centrum")
  - `details: String` - długi opis miejsca z ciekawostkami historycznymi (zmienione z `description`)
  - `latitude: Double` - szerokość geograficzna
  - `longitude: Double` - długość geograficzna
  - `imageName: String` - nazwa ikony SF Symbols
  - `createdAt: Date` - data utworzenia (automatycznie ustawiana)
- Computed property: `coordinate: CLLocationCoordinate2D` - zwraca współrzędne z `latitude` i `longitude`

**`ContentView.swift`**
- Główny kontroler widoku
- Zarządza stanem (`@State`, `@Query`, `@Environment`)
- Koordynuje synchronizację między mapą a karuzelą
- Zarządza nawigacją i wyznaczaniem trasy
- Dane SwiftData:
  - `@Environment(\.modelContext) private var modelContext` - kontekst bazy danych
  - `@Query(sort: \Location.createdAt, order: .reverse) private var locations: [Location]` - zapytanie do bazy
- Stan aplikacji:
  - `@State private var locationManager: LocationManager` - lokalizacja użytkownika
  - `@State private var selectedLocation: Location?` - wybrana lokalizacja
  - `@State private var sheetLocation: Location?` - lokalizacja w arkuszu szczegółów
  - `@State private var showSearchSheet: Bool` - stan arkusza wyszukiwania
  - `@State private var route: MKRoute?` - wyznaczona trasa
  - `@State private var cameraPosition: MapCameraPosition` - pozycja kamery
  - `@State private var tappedCoordinate: CLLocationCoordinate2D?` - kliknięty punkt na mapie
  - `@State private var showAddLocationAlert: Bool` - alert dodawania lokalizacji
- Funkcje:
  - `addCurrentLocation()` - dodaje lokalizację użytkownika
  - `addNewLocation(at:)` - dodaje lokalizację z klikniętego punktu na mapie
  - `handleMapTap(at:)` - obsługuje kliknięcie na mapie
  - `updateCamera(to:)` - aktualizuje pozycję kamery
  - `calculateRoute(to:)` - wyznacza trasę do miejsca

**`LocationCardView.swift`**
- Komponent UI: karta w karuzeli
- Parametry: `location`, `isSelected`, `onReadMore: () -> Void`
- Styl: glassmorphism (`.ultraThinMaterial`)
- Układ treści:
  - Ikona po lewej (80x80px)
  - Tytuł, nazwa miasta (uppercase, niebieski), opis (2 linie), przycisk "Czytaj więcej" po prawej
- Akcja: przycisk wywołuje `onReadMore()` do otwarcia arkusza szczegółów

**`LocationAnnotationView.swift`**
- Komponent UI: znacznik na mapie
- Parametry: `isSelected`
- Animacja: efekt radaru (pulsowanie)

**`LocationDetailView.swift`**
- Komponent UI: arkusz szczegółów miejsca (Sheet)
- Parametry: `@Bindable var location: Location`, `onGetDirections: () -> Void`
- Funkcje:
  - Wyświetla pełny opis miejsca (bez ograniczenia linii)
  - Duże zdjęcie na górze z gradientem
  - Wyświetla współrzędne geograficzne
  - Przycisk "Prowadź do celu" do wyznaczania trasy
  - ScrollView dla długich tekstów
  - **Tryb edycji:** Możliwość edycji nazwy, miasta i opisu miejsca
  - **Usuwanie:** Przycisk usuwania lokalizacji (w trybie edycji)
- Modyfikatory prezentacji:
  - `.presentationDetents([.medium, .large])` - wysuwanie do połowy lub pełnego ekranu
  - `.presentationDragIndicator(.visible)` - pasek do przeciągania
- Stan:
  - `@State private var isEditing: Bool` - tryb edycji
  - `@Environment(\.modelContext) private var modelContext` - kontekst bazy danych

**`LocationManager.swift`**
- Klasa zarządzająca lokalizacją użytkownika
- Implementuje `CLLocationManagerDelegate`
- Publikuje `@Published var userLocation: CLLocationCoordinate2D?`
- Funkcje:
  - Prośba o zgodę na lokalizację (`requestWhenInUseAuthorization`)
  - Automatyczne aktualizowanie lokalizacji (`startUpdatingLocation`)
  - Obsługa błędów i zmian uprawnień

**`SearchLocationView.swift`**
- Widok wyszukiwania i dodawania nowych lokalizacji
- Funkcje:
  - Wyszukiwanie miejsc przez `MKLocalSearch`
  - Wyświetlanie wyników wyszukiwania w liście
  - Automatyczne zapisywanie wybranej lokalizacji do bazy SwiftData
  - Odwrócone geokodowanie dla nazwy miejsca
- Stan:
  - `@State private var searchText: String` - tekst wyszukiwania
  - `@State private var searchResults: [MKMapItem]` - wyniki wyszukiwania
  - `@Environment(\.modelContext) private var modelContext` - kontekst bazy danych
- Interfejs:
  - `.searchable()` - pole wyszukiwania
  - Lista wyników z możliwością wyboru
  - Przycisk "Anuluj" w toolbarze

**`DataLoader.swift`**
- Klasa do seedowania danych początkowych
- Singleton: `static let shared = DataLoader()`
- Funkcje:
  - `seedData(context:)` - wypełnia bazę danymi początkowymi (17 lokalizacji z Górnego Śląska)
  - Sprawdza czy baza jest pusta przed seedowaniem
  - Automatyczne zapisywanie do kontekstu SwiftData
- Użycie: Wywoływane przy pierwszym uruchomieniu aplikacji

**`VehicleData.swift` i `VehicleDocumentAztecDecoder.swift`**
- Funkcjonalność dodatkowa niezwiązana z główną funkcjonalnością aplikacji
- `VehicleData`: Model danych pojazdu z dekodowaniem z formatu Aztec
- `VehicleDocumentAztecDecoder`: Dekoder dokumentów pojazdu (format Aztec/Base64)
- Uwaga: Te komponenty mogą być używane w przyszłości lub są częścią większego projektu

**`Info.plist`**
- Zawiera klucz `NSLocationWhenInUseUsageDescription`
- Komunikat dla użytkownika: "Potrzebujemy Twojej lokalizacji, aby wyznaczyć trasę do celu."

---

## 6. Typowe Zadania i Rozwiązania

### Zadanie 1: Dodanie Nowej Lokalizacji

**Metoda 1: Przez interfejs użytkownika (Zalecane)**

1. **Dodaj z bieżącej lokalizacji:**
   - Kliknij przycisk "+" w prawym górnym rogu
   - Wybierz "Bieżąca lokalizacja"
   - Lokalizacja zostanie automatycznie dodana do bazy

2. **Dodaj przez wyszukiwanie:**
   - Kliknij przycisk "+" w prawym górnym rogu
   - Wybierz "Szukaj adresu"
   - Wpisz nazwę miejsca lub adres
   - Wybierz wynik z listy
   - Lokalizacja zostanie automatycznie zapisana

3. **Dodaj przez kliknięcie na mapie:**
   - Kliknij dowolne miejsce na mapie
   - W wyświetlonym alercie wybierz "Dodaj"
   - Lokalizacja zostanie dodana z automatycznym geokodowaniem

**Metoda 2: Programatycznie (dla deweloperów)**

**Krok 1:** Użyj `DataLoader` lub dodaj bezpośrednio do kontekstu
```swift
let newLocation = Location(
    name: "Nowa Lokalizacja",
    cityName: "Gliwice",
    details: "Długi opis miejsca z ciekawostkami historycznymi...",
    latitude: 50.0,
    longitude: 18.0,
    imageName: "star.fill"
)

modelContext.insert(newLocation)
```

**Uwaga:** 
- Model wymaga 6 pól: `name`, `cityName`, `details`, `latitude`, `longitude`, `imageName`
- `details` (nie `description`) - długi opis miejsca
- `createdAt` jest ustawiane automatycznie
- Dane są zapisywane w bazie SwiftData

---

### Zadanie 2: Zmiana Stylu Karty

**Edytuj:** `LocationCardView.swift`

**Przykład zmiany koloru:**
```swift
// Znajdź:
.background {
    RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
}

// Zmień na:
.background {
    RoundedRectangle(cornerRadius: 20)
        .fill(Color.blue.opacity(0.3)) // Własny kolor
}
```

---

### Zadanie 3: Zmiana Prędkości Animacji Kamery

**Edytuj:** `ContentView.swift`

**Znajdź:**
```swift
// Dłuższy czas animacji dla płynniejszego lotu przy większej liczbie punktów
withAnimation(.easeInOut(duration: 1.5)) {
    cameraPosition = .region(MKCoordinateRegion(
        center: newLocation.coordinate,
        // Mniejsza delta = większy zoom (bliżej ziemi)
        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    ))
}
```

**Zmień `duration: 1.5` na inną wartość:**
- `0.5` - szybciej (może być zbyt szybkie przy większej liczbie punktów)
- `2.0` - wolniej (bardziej płynne, ale może być zbyt powolne)

**Uwaga:** Obecna wartość `1.5s` została dobrana dla 17 lokalizacji. Przy mniejszej liczbie możesz użyć krótszego czasu (np. `1.2s`).

---

### Zadanie 4: Otwieranie i Edycja Szczegółów Miejsca

**Aktualna implementacja:**
Przycisk "Czytaj więcej" w `LocationCardView` otwiera arkusz szczegółów (`LocationDetailView`).

**Jak to działa:**
1. Użytkownik klika "Czytaj więcej" na karcie lub kliknie w samą kartę
2. `onReadMore()` jest wywoływane
3. `ContentView` ustawia `sheetLocation = location`
4. Arkusz wysuwa się z dołu ekranu (`.sheet()`)

**Edycja lokalizacji:**
1. Otwórz arkusz szczegółów
2. Kliknij przycisk "Edytuj" w prawym górnym rogu
3. Zmień nazwę, miasto lub opis
4. Kliknij "Gotowe" aby zapisać zmiany
5. Zmiany są automatycznie zapisywane w bazie SwiftData

**Usuwanie lokalizacji:**
1. Otwórz arkusz szczegółów
2. Przejdź do trybu edycji
3. Kliknij przycisk "Usuń" w lewym górnym rogu
4. Lokalizacja zostanie usunięta z bazy danych

**Edycja akcji:**
```swift
// W ContentView:
.sheet(item: $sheetLocation) { location in
    LocationDetailView(
        location: location,
        onGetDirections: {
            calculateRoute(to: location)
        }
    )
}
```

**Uwaga:** 
- Przycisk ma tekst "Czytaj więcej" (nie "Więcej")
- Styl przycisku: `.borderedProminent` (bardziej widoczny)
- Przycisk rozciąga się na całą szerokość (`frame(maxWidth: .infinity)`)
- Lokalizacja jest `@Bindable`, więc zmiany są automatycznie synchronizowane

---

### Zadanie 5: Wyznaczanie Trasy do Miejsca

**Aktualna implementacja:**
Aplikacja może wyznaczyć trasę od lokalizacji użytkownika do wybranego miejsca.

**Jak to działa:**
1. Użytkownik otwiera arkusz szczegółów
2. Klika przycisk "Prowadź do celu"
3. `LocationManager` pobiera aktualną lokalizację użytkownika
4. `calculateRoute(to:)` wywołuje `MKDirections` API
5. Trasa jest rysowana na mapie jako niebieska linia (`MapPolyline`)
6. Kamera automatycznie dostosowuje się do widoku całej trasy

**Funkcja `calculateRoute(to:)`:**
```swift
private func calculateRoute(to destination: Location) {
    guard let userLoc = locationManager.userLocation else { return }
    
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
    request.transportType = .automobile // lub .walking
    
    Task {
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            await MainActor.run {
                withAnimation {
                    self.route = response.routes.first
                    if let rect = response.routes.first?.polyline.boundingMapRect {
                        self.cameraPosition = .rect(rect)
                    }
                }
            }
        } catch {
            print("Błąd wyznaczania trasy: \(error)")
        }
    }
}
```

**Uwaga:**
- Wymaga zgody użytkownika na lokalizację (Info.plist)
- W symulatorze ustaw lokalizację: `Features` → `Location` → `Custom Location...`
- Domyślnie trasa jest dla samochodu (`.automobile`), można zmienić na `.walking`

---

## 7. Debugowanie

### Problem: Karuzela nie synchronizuje się z mapą

**Sprawdź:**
1. Czy oba elementy mają `.tag(location)`?
2. Czy `selectedLocation` jest przekazywane przez `$` (binding)?
3. Czy `Location` implementuje `Hashable` poprawnie?

**Rozwiązanie:**
```swift
// ✅ DOBRZE:
Annotation(...) { ... }
    .tag(location)

LocationCardView(...)
    .tag(location)

// ❌ ŹLE:
Annotation(...) { ... }
    .tag(location.id) // Używasz ID zamiast obiektu
```

---

### Problem: Animacja kamery nie działa

**Sprawdź:**
1. Czy `.onChange` jest wywoływane? (dodaj `print()`)
2. Czy `newLocation` nie jest `nil`?
3. Czy `cameraPosition` jest zdefiniowane jako `@State`?

**Rozwiązanie:**
```swift
.onChange(of: selectedLocation) { oldValue, newLocation in
    print("Zmiana lokalizacji: \(newLocation?.name ?? "nil")") // Debug
    if let newLocation = newLocation {
        // ...
    }
}
```

---

### Problem: Znaczniki nie są widoczne

**Sprawdź:**
1. Czy `testLocations` nie jest pusta?
2. Czy współrzędne są poprawne?
3. Czy `Map` ma ustawiony odpowiedni `span` (zoom)?

**Rozwiązanie:**
```swift
// Sprawdź w konsoli:
print("Liczba lokalizacji: \(testLocations.count)")
print("Współrzędne: \(testLocations.first?.coordinate)")

// Sprawdź początkowy span w ContentView:
@State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
    center: testLocations.first!.coordinate,
    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // ← Początkowy widok
))

// Zwiększ zoom (zmniejsz span):
span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Bliżej
span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)  // Dalej
```

---

### Problem: Trasa nie jest wyznaczana

**Sprawdź:**
1. Czy użytkownik udzielił zgody na lokalizację?
2. Czy `Info.plist` zawiera `NSLocationWhenInUseUsageDescription`?
3. Czy `locationManager.userLocation` nie jest `nil`?
4. W symulatorze: czy ustawiono custom location?

**Rozwiązanie:**
```swift
// Sprawdź lokalizację użytkownika:
print("Lokalizacja użytkownika: \(locationManager.userLocation)")

// W symulatorze Xcode:
// Features → Location → Custom Location...
// Wpisz współrzędne np. 50.297, 18.670 (Gliwice)

// Sprawdź uprawnienia:
print("Status uprawnień: \(locationManager.manager.authorizationStatus)")
```

---

### Problem: Arkusz szczegółów nie otwiera się

**Sprawdź:**
1. Czy `sheetLocation` jest ustawiane w `onReadMore`?
2. Czy `LocationDetailView` ma wszystkie wymagane parametry?
3. Czy `.sheet()` jest poprawnie podłączony?

**Rozwiązanie:**
```swift
// W LocationCardView:
Button {
    onReadMore() // ← Musi być wywołane
} label: {
    Text("Czytaj więcej")
}

// W ContentView:
.sheet(item: $sheetLocation) { location in
    LocationDetailView(
        location: location,
        onGetDirections: { calculateRoute(to: location) }
    )
}
```

**Uwaga:** 
- Używamy `testLocations` (nie `locations`)
- Projekt zawiera 20 lokalizacji z Górnego Śląska (Gliwice, Katowice, okolice)
- Początkowy span `0.1` jest ustawiony, aby pokazać wszystkie lokalizacje na starcie

---

## 8. Najlepsze Praktyki

### 1. Nie Duplikuj Stanu

❌ **ŹLE:**
```swift
@State private var selectedLocation: Location?
@State private var selectedIndex: Int? // Duplikacja!
```

✅ **DOBRZE:**
```swift
@State private var selectedLocation: Location? // Single Source of Truth
```

---

### 2. Używaj `.tag()` Zawsze

❌ **ŹLE:**
```swift
TabView {
    ForEach(locations) { location in
        LocationCardView(location: location)
        // Brak .tag()!
    }
}
```

✅ **DOBRZE:**
```swift
TabView(selection: $selectedLocation) {
    ForEach(testLocations) { location in
        LocationCardView(location: location, isSelected: selectedLocation == location)
            .tag(location) // Zawsze!
    }
}
```

**Uwaga:** 
- Używamy `testLocations` (nie `locations`)
- `LocationCardView` wymaga parametrów: `location`, `isSelected`, `onReadMore`
- `LocationDetailView` wymaga parametrów: `location`, `onGetDirections`

---

### 3. Nie Mieszaj Deklaratywnego z Imperatywnym Niepotrzebnie

❌ **ŹLE:**
```swift
// Próba ręcznego sterowania TabView
TabView {
    // ...
}
.onAppear {
    // Ręczne przewijanie - nie działa dobrze!
}
```

✅ **DOBRZE:**
```swift
// Pozwól SwiftUI zarządzać przez binding
TabView(selection: $selectedLocation) {
    // ...
}
```

---

## 9. Przydatne Linki

- [MapKit for SwiftUI - Dokumentacja Apple](https://developer.apple.com/documentation/mapkit/map)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/state)
- [iOS 17 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes)

---

## 10. Checklist Onboarding

- [ ] Zainstalowano Xcode 15.0+
- [ ] Sprawdzono deployment target (iOS 17+)
- [ ] Projekt kompiluje się bez błędów
- [ ] Aplikacja uruchamia się na symulatorze
- [ ] Zrozumiano architekturę warstwową
- [ ] Zrozumiano przepływ danych (Single Source of Truth)
- [ ] Zrozumiano mechanizm `.tag()`
- [ ] Zrozumiano `.onChange` dla efektów ubocznych
- [ ] Zrozumiano SwiftData i `@Model`
- [ ] Zrozumiano `@Query` i `@Environment(\.modelContext)`
- [ ] Przetestowano synchronizację (karuzela ↔ mapa)
- [ ] Przetestowano animacje (lot kamery, pulsowanie)
- [ ] Przetestowano arkusz szczegółów (otwieranie, zamykanie, edycja)
- [ ] Przetestowano dodawanie lokalizacji (bieżąca lokalizacja, wyszukiwanie, kliknięcie na mapie)
- [ ] Przetestowano edycję i usuwanie lokalizacji
- [ ] Przetestowano wyznaczanie trasy (wymaga lokalizacji)
- [ ] Sprawdzono uprawnienia lokalizacji (Info.plist)
- [ ] Sprawdzono seedowanie danych początkowych (DataLoader)

---

---

## 11. Ważne Zmiany i Aktualizacje

### Model Danych

**Klasa `Location` (SwiftData @Model) zawiera 7 pól:**
```swift
@Model
final class Location {
    var name: String              // Główna nazwa
    var cityName: String          // Nazwa miasta
    var details: String           // Rozszerzony opis (zmienione z description)
    var latitude: Double          // Szerokość geograficzna
    var longitude: Double         // Długość geograficzna
    var imageName: String         // Nazwa ikony SF Symbols
    var createdAt: Date           // Data utworzenia (automatycznie)
    
    // Computed property
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
```

**Uwaga:** 
- Model jest teraz klasą z `@Model` (SwiftData), nie strukturą
- Pola są `var`, nie `let` (wymagane przez SwiftData)
- `details` (nie `description`) - nazwa pola została zmieniona
- `createdAt` jest ustawiane automatycznie w inicjalizatorze
- Dane są persystowane w bazie SwiftData

---

### Źródło Danych

- **Używamy:** `@Query` do pobierania danych z SwiftData (nie `testLocations`)
- **Liczba lokalizacji początkowych:** 17 (Gliwice, Katowice, okolice)
- **Region:** Górny Śląsk
- **Zawartość:** Każda lokalizacja ma pełny opis historyczny i ciekawostki
- **Seedowanie:** `DataLoader.shared.seedData()` wypełnia bazę danymi początkowymi przy pierwszym uruchomieniu
- **Dodawanie:** Użytkownik może dodawać nowe lokalizacje przez:
  - Bieżącą lokalizację
  - Wyszukiwanie adresu
  - Kliknięcie na mapie

---

### Parametry Animacji

**Aktualne wartości:**
- Początkowy span: `0.1` (szerszy widok)
- Span przy wyborze: `0.015` (większy zoom)
- Czas animacji: `1.5s` (płynniejszy lot)

**Dlaczego te wartości?**
- Zoptymalizowane dla 20 lokalizacji
- Lepsze doświadczenie użytkownika przy większej liczbie punktów

---

### Interfejs Karty

**Układ treści:**
1. Tytuł (bold, `.title3`, `lineLimit(1)`)
2. Nazwa miasta (uppercase, niebieski, `.caption`, bold)
3. Opis (2 linie, `.subheadline`, secondary)
4. Przycisk "Czytaj więcej" (`.borderedProminent` style, pełna szerokość)

**Uwaga:** Karta wyświetla `cityName` jako dodatkowy kontekst - szczególnie przydatne przy większej liczbie lokalizacji.

---

### Arkusz Szczegółów

**Funkcje:**
- Pełny opis miejsca (bez ograniczenia linii)
- Duże zdjęcie na górze z gradientem
- Wyświetlanie współrzędnych geograficznych
- Przycisk "Prowadź do celu" do wyznaczania trasy
- ScrollView dla długich tekstów
- Możliwość wysunięcia do połowy lub pełnego ekranu
- **Tryb edycji:** Edycja nazwy, miasta i opisu miejsca
- **Usuwanie:** Przycisk usuwania lokalizacji (w trybie edycji)

**Interakcje:**
- Przeciąganie w dół zamyka arkusz
- Przycisk "Zamknij" w toolbarze (tylko w trybie podglądu)
- Przycisk "Edytuj/Gotowe" przełącza tryb edycji
- Przycisk "Usuń" usuwa lokalizację z bazy (w trybie edycji)
- Przycisk "Prowadź do celu" zamyka arkusz i wyznacza trasę
- Zmiany w trybie edycji są automatycznie zapisywane w bazie SwiftData

---

### System Nawigacji

**Komponenty:**
- `LocationManager` - zarządza lokalizacją użytkownika
- `MKDirections` - wyznacza trasę
- `MapPolyline` - rysuje trasę na mapie
- `UserAnnotation` - pokazuje lokalizację użytkownika

**Funkcje:**
- Automatyczne dostosowanie kamery do widoku trasy
- Niebieska linia trasy (grubość 6px)
- Kontrolki mapy: przycisk lokalizacji i kompas
- Obsługa błędów i brakujących uprawnień

**Wymagania:**
- Zgoda użytkownika na lokalizację (Info.plist)
- Połączenie internetowe (dla MKDirections API)

---

## Podsumowanie

Projekt wykorzystuje nowoczesne podejście SwiftUI z:
- **Centralnym zarządzaniem stanem** (Single Source of Truth)
- **Deklaratywnym UI** (zamiast imperatywnego)
- **Reaktywnymi efektami ubocznymi** (`.onChange`)
- **Kompozycją komponentów** (Composition Pattern)

**Kluczowe mechanizmy:**
- `.tag()` - łączy elementy UI z danymi
- `.onChange` - nasłuchuje zmian i wywołuje akcje
- `MapCameraPosition` - deklaratywne sterowanie kamerą

**Aktualne funkcje:**
- 17 lokalizacji początkowych z Górnego Śląska z pełnymi opisami historycznymi
- Rozszerzony model danych (`cityName`, `details`) z persystencją SwiftData
- Arkusz szczegółów z pełnym opisem miejsca i możliwością edycji
- System nawigacji - wyznaczanie trasy do miejsca
- Lokalizacja użytkownika i rysowanie trasy na mapie
- **Dodawanie lokalizacji:** Bieżąca lokalizacja, wyszukiwanie, kliknięcie na mapie
- **Edycja i usuwanie:** Możliwość modyfikacji i usuwania lokalizacji
- Ulepszony interfejs z dodatkowym kontekstem
- Zoptymalizowane animacje dla większej liczby punktów
- Automatyczne seedowanie danych początkowych przy pierwszym uruchomieniu

Jeśli masz pytania, skontaktuj się z zespołem lub sprawdź dokumentację techniczną (`analiza-techniczna.md`).

