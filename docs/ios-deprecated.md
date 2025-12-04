# Przestarzałe frameworki/klasy i zamienniki (iOS 26)

Ten dokument zawiera listę przestarzałych elementów iOS, które należy unikać w nowym kodzie i migrować w istniejącym kodzie. Lista jest aktualizowana w trakcie developmentu, gdy znajdziemy kolejne przestarzałe elementy.

## Tabela przestarzałych elementów

| Przestarzały element | Framework | Zamiennik | Uwagi |
|---------------------|-----------|-----------|--------------------------------|
| `MKPlacemark` | MapKit | `MKMapItem(coordinate:address:)` + `MKAddress` | Używać `location`, `address`, `addressRepresentations` |
| `CLGeocoder` | CoreLocation | `MKReverseGeocodingRequest` (MapKit) | Pełna migracja do MapKit |
| `CLPlacemark` | CoreLocation | `MKMapItem.addressRepresentations` | Brak pełnej parzystości funkcji |
| `SceneKit` | SceneKit | `RealityKit` | "Soft deprecated" - RealityKit dla 3D/spatial |
| `MKMapType` | MapKit | `MKMapConfiguration` (np. `standard`, `hybrid`) | Od iOS 16, obowiązkowe w 26 |
| `showsUserLocation` (stary init) | MapKit/SwiftUI | Nowe inicjalizatory `Map` z `interactionModes` | SwiftUI Map bez deprecated init |

## Kluczowe migracje MapKit/CoreLocation

- **Geokodowanie odwrotne**: `CLGeocoder.reverseGeocodeLocation` → `MKReverseGeocodingRequest`
- **Adresy**: `CLPlacemark` → `MKAddress` lub `MKAddressRepresentation`
- **Regiony**: `CLCircularRegion` → `CLCircularGeographicCondition`

## Sprawdzenie projektu

```swift
// Build z iOS 26 SDK pokaże wszystkie deprecated
// Xcode → Product → Analyze
```

Szczegóły w [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes) i WWDC25 sesje MapKit. Testuj na symulatorze iOS 26.

## Historia zmian

- **2025-01-XX**: Utworzono dokument z początkową listą przestarzałych elementów iOS 26

---

## Źródła

1. [CoreLocation iOS xcode26.0 b1 · dotnet/macios Wiki - GitHub](https://github.com/dotnet/macios/wiki/CoreLocation-iOS-xcode26.0-b1)
2. [iOS & iPadOS 26 Release Notes | Apple Developer Documentation](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)
3. [WWDC 2025 - Go further with MapKit & MapKit JavaScript](https://dev.to/arshtechpro/wwdc-2025-go-further-with-mapkit-mapkit-javascript-a5l)
4. [Maps and Location | Apple Developer Forums](https://developer.apple.com/forums/forums/topics/maps-and-location)
5. [CLGeocoder & CLPlacemark Deprecated - How To Get Structured ...](https://stackoverflow.com/questions/79795351/clgeocoder-clplacemark-deprecated-how-to-get-structured-fields)
6. [Go further with MapKit - WWDC25 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2025/204/)
7. [iOS 26 Explained: Apple's Biggest Update for Developers - Index.dev](https://www.index.dev/blog/ios-26-developer-guide)
8. [How do you track what changed in Apple frameworks after a ... - Reddit](https://www.reddit.com/r/swift/comments/1l3u5ct/how_do_you_track_what_changed_in_apple_frameworks/)
9. [iOS 26 marks the end of UIKit and SceneKit. RealityKit is the new 3D ...](https://www.linkedin.com/posts/andrewsallen_ios-26-turns-a-page-on-apples-legacy-frameworks-activity-7357088423708430336-QSQQ)
10. [Running unsupported iOS on deprecated devices](https://nyansatan.github.io/run-unsupported-ios/)
11. [New MapKit Configurations with SwiftUI](https://holyswift.app/new-mapkit-configurations-with-swiftui/)
12. [Apple streamlines MDM migrations in iOS 26 and macOS 26](https://simplemdm.com/blog/apple-streamlines-mdm-migrations-in-ios-26-and-macos-26/)
13. [Now that SceneKit is formally deprecated in iOS 26, it seems ...](https://x.com/twostraws/status/1935675784150052921)
14. [What's new in MapKit | Documentation](https://wwdcnotes.com/documentation/wwdcnotes/wwdc22-10035-whats-new-in-mapkit/)
15. [Device migration to Relution with iOS 26, iPadOS 26, macOS](https://relution.io/en/insights/simplified-migration-to-relution/)
16. [Upgrading Existing Apps for iOS 26 & iPhone 17: Migration Tips ...](https://www.developerperhour.com/blog/upgrading-existing-apps-ios-26-iphone-17-migration-tips/)
17. [showsUserLocation: ) deprecated in iOS 17.0 - swiftui](https://stackoverflow.com/questions/76865201/mapcoordinateregion-showsuserlocation-deprecated-in-ios-17-0)
18. [macOS, iOS and iPadOS 26: Seamless Apple Device ...](https://addigy.com/blog/os-26-device-management-migration/)
19. [Will Apple accept Apps with deprecated code? - Stack Overflow](https://stackoverflow.com/questions/7909986/will-apple-accept-apps-with-deprecated-code)
20. [MapKit annotations | Apple Developer Documentation](https://developer.apple.com/documentation/mapkit/mapkit-annotations)
21. [Migrate Apple devices running iOS 26, iPadOS 26, and ...](https://www.miradore.com/knowledge/apple/ios-ipados-macos26-migration-without-factory-reset/)
