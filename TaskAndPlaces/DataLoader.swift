//
//  DataLoader.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import Foundation
import SwiftData

@MainActor
class DataLoader {
    static let shared = DataLoader()
    
    func seedData(context: ModelContext) {
        // Sprawdź czy baza jest pusta
        let descriptor = FetchDescriptor<Location>()
        do {
            let count = try context.fetchCount(descriptor)
            if count > 0 {
                print("Baza danych już zawiera dane. Pomijam seedowanie.")
                return
            }
        } catch {
            print("Błąd sprawdzania bazy danych: \(error)")
            return
        }
        
        print("Baza pusta. Rozpoczynam seedowanie danych...")
        
        let locations = [
            // --- GLIWICE ---
            Location(
                name: "Radiostacja Gliwicka",
                cityName: "Gliwice",
                details: "Najwyższa drewniana konstrukcja w Europie (111 m). Zbudowana z drewna modrzewiowego bez użycia ani jednego żelaznego gwoździa. Miejsce tzw. prowokacji gliwickiej, która stała się pretekstem do wybuchu II wojny światowej.",
                latitude: 50.3134,
                longitude: 18.6888,
                imageName: "antenna.radiowaves.left.and.right"
            ),
            Location(
                name: "Rynek i Ratusz",
                cityName: "Gliwice - Stare Miasto",
                details: "Centralny plac miasta o średniowiecznym układzie. W centralnym punkcie stoi Ratusz, którego historia sięga XV wieku. Wokół rynku znajdują się zabytkowe kamienice z podcieniami oraz Fontanna z Neptunem.",
                latitude: 50.2946,
                longitude: 18.6663,
                imageName: "building.columns.circle.fill"
            ),
            Location(
                name: "Palmiarnia Miejska",
                cityName: "Gliwice - Park Chopina",
                details: "Trzecia co do wielkości palmiarnia w Polsce. Znajduje się tu pięć pawilonów tematycznych z egzotycznymi roślinami, kaktusami oraz ogromnymi akwariami prezentującymi ekosystemy Amazonki i Tanganiki.",
                latitude: 50.3015,
                longitude: 18.6738,
                imageName: "leaf.circle.fill"
            ),
            Location(
                name: "Arena Gliwice",
                cityName: "Gliwice",
                details: "Jedna z największych i najnowocześniejszych hal widowiskowo-sportowych w Polsce. Obiekt składa się z dwóch hal: Głównej i Małej. Odbywają się tu koncerty gwiazd światowego formatu oraz Eurowizja Junior.",
                latitude: 50.2974,
                longitude: 18.6932,
                imageName: "sportscourt.fill"
            ),
            Location(
                name: "Politechnika Śląska",
                cityName: "Gliwice - Dzielnica Akademicka",
                details: "Serce technicznej edukacji na Śląsku. Wyróżnia się budynek Wydziału Chemicznego, zwany 'Czerwoną Chemią', będący przykładem historyzującej architektury z cegły.",
                latitude: 50.2921,
                longitude: 18.6755,
                imageName: "graduationcap.fill"
            ),
            Location(
                name: "Zamek Piastowski",
                cityName: "Gliwice",
                details: "Budowla będąca częścią średniowiecznych murów obronnych miasta. Obecnie mieści się tu oddział Muzeum w Gliwicach z wystawami archeologicznymi i historycznymi dotyczącymi regionu.",
                latitude: 50.2933,
                longitude: 18.6672,
                imageName: "shield.fill"
            ),
            Location(
                name: "Lotnisko Gliwice",
                cityName: "Gliwice - Trynek",
                details: "Historyczne lotnisko, na którym w 1999 roku papież Jan Paweł II odprawił mszę dla 300 tysięcy wiernych. Obecnie baza Aeroklubu Gliwickiego i centrum szkolenia lotniczego.",
                latitude: 50.2705,
                longitude: 18.6781,
                imageName: "airplane"
            ),
            Location(
                name: "Nowe Gliwice",
                cityName: "Gliwice",
                details: "Centrum Edukacji i Biznesu powstałe na terenie dawnej Kopalni Węgla Kamiennego 'Gliwice'. Przykład udanej rewitalizacji obiektów poprzemysłowych, gdzie historia łączy się z nowoczesnymi technologiami.",
                latitude: 50.2855,
                longitude: 18.6998,
                imageName: "briefcase.fill"
            ),
            
            // --- KATOWICE ---
            Location(
                name: "Spodek",
                cityName: "Katowice - Centrum",
                details: "Symbol Katowic i ikona architektury modernistycznej. Hala widowiskowa w kształcie latającego spodka, oddana do użytku w 1971 roku. Miejsce legendarnych koncertów i wydarzeń sportowych.",
                latitude: 50.2661,
                longitude: 19.0255,
                imageName: "circle.hexagonpath.fill"
            ),
            Location(
                name: "Muzeum Śląskie",
                cityName: "Katowice - Strefa Kultury",
                details: "Niezwykłe muzeum, którego główne wystawy znajdują się pod ziemią, na terenie dawnej kopalni 'Katowice'. Szklane sześciany na powierzchni doświetlają podziemne galerie.",
                latitude: 50.2635,
                longitude: 19.0347,
                imageName: "paintpalette.fill"
            ),
            Location(
                name: "NOSPR",
                cityName: "Katowice - Strefa Kultury",
                details: "Siedziba Narodowej Orkiestry Symfonicznej Polskiego Radia. Sala koncertowa o światowej klasy akustyce, zaprojektowana przez mistrzów z Nagata Acoustics. Elewacja z cegły nawiązuje do śląskiej tradycji.",
                latitude: 50.2628,
                longitude: 19.0285,
                imageName: "music.note.house.fill"
            ),
            Location(
                name: "MCK",
                cityName: "Katowice",
                details: "Międzynarodowe Centrum Kongresowe. Budynek wyróżnia się 'zieloną doliną' – trawiastym dachem, który przecina bryłę i służy jako ścieżka spacerowa łącząca Spodek ze strefą kultury.",
                latitude: 50.2652,
                longitude: 19.0281,
                imageName: "person.3.fill"
            ),
            Location(
                name: "Nikiszowiec",
                cityName: "Katowice - Dzielnica",
                details: "Zabytkowe osiedle robotnicze z początku XX wieku. Charakterystyczna zabudowa z czerwonej cegły, wewnętrzne dziedzińce i kościół św. Anny tworzą unikalny klimat. Pomnik Historii.",
                latitude: 50.2444,
                longitude: 19.0818,
                imageName: "house.lodge.fill"
            ),
            Location(
                name: "Dolina Trzech Stawów",
                cityName: "Katowice",
                details: "Rozległy teren rekreacyjny w centrum aglomeracji. Idealne miejsce na rolki, rower czy spacer. Znajduje się tu również lotnisko sportowe Muchowiec.",
                latitude: 50.2366,
                longitude: 19.0433,
                imageName: "water.waves"
            ),
            Location(
                name: "Ulica Mariacka",
                cityName: "Katowice - Deptak",
                details: "Główny deptak miasta tętniący życiem nocnym. Zamknięta dla ruchu kołowego ulica pełna restauracji, pubów i klubów, z widokiem na neogotycki Kościół Mariacki.",
                latitude: 50.2584,
                longitude: 19.0236,
                imageName: "wineglass.fill"
            ),
            Location(
                name: "Park Kościuszki",
                cityName: "Katowice",
                details: "Największy park w granicach miasta, utrzymany w stylu angielskim. Znajduje się tu zabytkowy drewniany kościół św. Michała Archanioła oraz jedyna w Polsce wieża spadochronowa.",
                latitude: 50.2431,
                longitude: 19.0069,
                imageName: "tree.fill"
            ),
            Location(
                name: "Pomnik Powstańców",
                cityName: "Katowice",
                details: "Monumentalny pomnik w centrum miasta, upamiętniający trzy powstania śląskie. Trzy orle skrzydła symbolizują trzy zrywy niepodległościowe.",
                latitude: 50.2642,
                longitude: 19.0238,
                imageName: "star.fill"
            ),
            Location(
                name: "Galeria Katowicka",
                cityName: "Katowice",
                details: "Nowoczesna galeria handlowa połączona z dworcem kolejowym. Jej architektura nawiązuje do surowego, industrialnego charakteru miasta (tzw. kielichy dworca).",
                latitude: 50.2596,
                longitude: 19.0177,
                imageName: "bag.fill"
            ),
            
            // --- OKOLICE ---
            Location(
                name: "Park Śląski",
                cityName: "Chorzów (Granica)",
                details: "Jeden z największych parków miejskich w Europie. Na jego terenie znajduje się Planetarium Śląskie, Ogród Zoologiczny, Skansen oraz Stadion Śląski (Kocioł Czarownic).",
                latitude: 50.2809,
                longitude: 18.9958,
                imageName: "ferry.fill"
            ),
            Location(
                name: "Szyb Maciej",
                cityName: "Zabrze (Blisko Gliwic)",
                details: "Zespół obiektów dawnej kopalni 'Concordia'. Obecnie znajduje się tu restauracja, bistro i studnia głębinowa. Przykład industrialnej elegancji.",
                latitude: 50.3168,
                longitude: 18.7369,
                imageName: "gearshape.fill"
            )
        ]
        
        for location in locations {
            context.insert(location)
        }
        
        do {
            try context.save()
            print("Zaseedowano \(locations.count) lokalizacji.")
        } catch {
            print("Błąd zapisu seedowania: \(error)")
        }
    }
}



