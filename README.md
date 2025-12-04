# TaskAndPlaces

Aplikacja SwiftUI do przeglądania i nawigacji do ciekawych miejsc w Gliwicach, Katowicach i okolicach. Aplikacja wykorzystuje nowoczesne API MapKit (iOS 17+) do wyświetlania interaktywnej mapy z lokalizacjami oraz wyznaczania tras.

## Opis Aplikacji

**TaskAndPlaces** to aplikacja mobilna napisana w SwiftUI, która umożliwia:

- 🗺️ **Interaktywną mapę** z oznaczeniami ciekawych miejsc w regionie śląskim
- 📍 **Karuzelę kart** z informacjami o każdym miejscu
- 🧭 **Wyznaczanie tras** z aktualnej lokalizacji użytkownika do wybranego miejsca
- 📱 **Szczegółowe widoki** miejsc z opisami i możliwością nawigacji
- 🎨 **Nowoczesny interfejs** wykorzystujący natywne komponenty SwiftUI i MapKit

### Główne Funkcje

1. **Mapa z lokalizacjami**
   - Hybrydowy widok mapy (satelitarny + standardowy)
   - Niestandardowe znaczniki miejsc
   - Płynne animacje kamery przy przełączaniu lokalizacji
   - Wyświetlanie aktualnej pozycji użytkownika

2. **Karuzela kart**
   - Przewijalne karty z podstawowymi informacjami o miejscach
   - Synchronizacja z wyborem na mapie
   - Szybki dostęp do szczegółów miejsca

3. **Wyznaczanie tras**
   - Automatyczne obliczanie trasy samochodowej
   - Wizualizacja trasy na mapie
   - Automatyczne dostosowanie widoku kamery do całej trasy

4. **Szczegółowe widoki**
   - Pełne opisy miejsc
   - Przycisk do wyznaczania trasy
   - Wysuwany arkusz z możliwością rozszerzenia

## Wymagania

- **iOS:** 17.0 lub wyższy
- **Xcode:** 15.0 lub wyższy
- **Swift:** 5.9+

## Dokumentacja

Szczegółowa dokumentacja projektu znajduje się w katalogu `docs/`:

- [📋 Plan Onboarding](docs/plan-onboarding.md) - Przewodnik dla nowych programistów, zawiera informacje o architekturze, wymaganiach systemowych i procesie rozwoju
- [🔧 Analiza Techniczna](docs/analiza-techniczna.md) - Szczegółowy opis technik programistycznych, wzorców projektowych i implementacji

## Struktura Projektu

```
TaskAndPlaces/
├── TaskAndPlaces/
│   ├── TaskAndPlacesApp.swift      # Główny plik aplikacji
│   ├── ContentView.swift            # Główny widok z mapą i karuzelą
│   ├── Location.swift                # Model danych lokalizacji
│   ├── LocationManager.swift         # Menedżer lokalizacji użytkownika
│   ├── LocationCardView.swift       # Widok karty miejsca
│   ├── LocationDetailView.swift     # Szczegółowy widok miejsca
│   └── LocationAnnotationView.swift # Niestandardowy widok znacznika
├── docs/                             # Dokumentacja projektu
└── README.md                         # Ten plik
```

## Technologie

- **SwiftUI** - Framework UI
- **MapKit** - Mapy i nawigacja
- **CoreLocation** - Lokalizacja użytkownika
- **SwiftData** - Persystencja danych (przygotowane do przyszłego użycia)

## Źródła

Aplikacja została stworzona na bazie tutoriala z YouTube:

- [📺 SwiftUI MapKit Tutorial](https://youtu.be/S57F0BNs-bQ?si=lOGpCH_YLNRySILi) - Film instruktażowy, na podstawie którego powstała aplikacja

## Autor

Jacek Kosiński

## Licencja

Projekt prywatny - wszystkie prawa zastrzeżone.
