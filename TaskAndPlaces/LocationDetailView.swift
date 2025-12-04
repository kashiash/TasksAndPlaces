//
//  LocationDetailView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import CoreLocation

// MARK: - Widok Szczegółów Lokalizacji (Sheet)
// Arkusz wysuwany z dołu ekranu z pełnym opisem miejsca
struct LocationDetailView: View {
    let location: Location
    var onGetDirections: () -> Void // Akcja wyznaczania trasy
    @Environment(\.dismiss) var dismiss // Pozwala zamknąć arkusz
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Duże zdjęcie na górze
                    ZStack(alignment: .bottomLeading) {
                        Image(systemName: location.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.blue.opacity(0.1))
                            .overlay(
                                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .center)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(location.cityName.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(location.name)
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    
                    // MARK: - Przycisk Prowadzenia
                    Button {
                        onGetDirections() // Uruchom obliczanie trasy
                        dismiss()         // Zamknij arkusz, by pokazać mapę
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Prowadź do celu")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Treść opisu
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Współrzędne: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")", systemImage: "map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        Text("O Miejscu")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(location.description)
                            .font(.body)
                            .lineSpacing(6) // Lepsza czytelność długiego tekstu
                            .foregroundStyle(.primary)
                    }
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LocationDetailView(
        location: testLocations.first!,
        onGetDirections: {
            print("Preview: Prowadź do celu")
        }
    )
}

