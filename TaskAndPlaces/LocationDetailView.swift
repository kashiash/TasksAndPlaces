//
//  LocationDetailView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import CoreLocation
import SwiftData

// MARK: - Widok Szczegółów Lokalizacji (Sheet)
// Arkusz wysuwany z dołu ekranu z pełnym opisem miejsca
struct LocationDetailView: View {
    @Bindable var location: Location
    var onGetDirections: () -> Void // Akcja wyznaczania trasy
    @Environment(\.dismiss) var dismiss // Pozwala zamknąć arkusz
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    
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
                        
                        // Warstwa tekstowa na zdjęciu (tylko w trybie podglądu)
                        if !isEditing {
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
                    }
                    
                    // MARK: - Sekcja Edycji / Wyświetlania
                    if isEditing {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Edycja lokalizacji")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading) {
                                Text("Nazwa miejsca")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Nazwa", text: $location.name)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Miasto")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Miasto", text: $location.cityName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Opis")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $location.details)
                                    .frame(minHeight: 150)
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    } else {
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
                            
                            Text(location.details)
                                .font(.body)
                                .lineSpacing(6) // Lepsza czytelność długiego tekstu
                                .foregroundStyle(.primary)
                        }
                        .padding()
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Usuń", role: .destructive) {
                            modelContext.delete(location)
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(isEditing ? "Gotowe" : "Edytuj") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        
                        if !isEditing {
                            Button("Zamknij") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Location.self, configurations: config)
    let example = Location(name: "Test", cityName: "City", details: "Details", latitude: 0, longitude: 0, imageName: "star")
    
    return LocationDetailView(
        location: example,
        onGetDirections: {
            print("Preview: Prowadź do celu")
        }
    )
    .modelContainer(container)
}
