//
//  SearchLocationView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import MapKit
import SwiftData

struct SearchLocationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            List(searchResults, id: \.self) { item in
                Button {
                    saveLocation(item)
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Nieznane miejsce")
                            .font(.headline)
                        if let addressString = formatAddressString(from: item.address, representations: item.addressRepresentations), !addressString.isEmpty {
                            Text(addressString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Szukaj miejsca")
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Wpisz adres lub nazwę...")
            .onChange(of: searchText) { oldValue, newValue in
                search(for: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func search(for query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            self.searchResults = response.mapItems
        }
    }
    
    private func formatAddressString(from address: MKAddress?, representations: MKAddressRepresentations?) -> String? {
        // W iOS 26 API dla adresów zostało zmienione
        // MKAddressRepresentations i MKAddress mają nową strukturę
        // Na razie zwracamy nil - można rozszerzyć gdy dokumentacja będzie dostępna
        // Podstawowe informacje (nazwa miejsca) są dostępne przez mapItem.name
        return nil
    }
    
    private func saveLocation(_ item: MKMapItem) {
        let name = item.name ?? "Nowe miejsce"
        // Użyj addressRepresentations do uzyskania miasta lub użyj fallback
        let addressString = formatAddressString(from: item.address, representations: item.addressRepresentations) ?? ""
        // W iOS 26 struktura MKAddress może się różnić, używamy podstawowego fallback
        let cityName = addressString.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Nieznane miasto"
        let details = addressString.isEmpty ? "Brak szczegółów" : addressString
        let coordinate = item.location.coordinate
        
        // Wybierz ikonę w zależności od kategorii (uproszczone)
        let imageName = "mappin.circle.fill" 
        
        let newLocation = Location(
            name: name,
            cityName: cityName,
            details: details,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            imageName: imageName
        )
        
        modelContext.insert(newLocation)
        dismiss()
    }
}

#Preview {
    SearchLocationView()
}

