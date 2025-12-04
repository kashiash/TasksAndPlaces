//
//  LocationCardView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI

// MARK: - Komponent A: Karta Lokalizacji (Carousel Card)
// Styl: Nowoczesny, glassmorphism, lekkie zaokrąglenia (radius ~20px)
struct LocationCardView: View {
    let location: Location
    let isSelected: Bool
    var onReadMore: () -> Void // Closure do przekazania akcji otwarcia szczegółów
    
    var body: some View {
        HStack(spacing: 15) {
            // Lewa strona: Zdjęcie/Ikona lokalizacji (kwadratowe z zaokrąglonymi rogami)
            Image(systemName: location.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            
            // Prawa strona: Tytuł, Miasto, Opis, Przycisk akcji
            VStack(alignment: .leading, spacing: 5) {
                // Główna nazwa
                Text(location.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                // Miasto (np. Gliwice)
                Text(location.cityName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                // Długi opis (ograniczony do 2 linii na karcie)
                Text(location.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Przycisk akcji (Call to Action)
                Button {
                    onReadMore() // Wywołujemy akcję przekazaną z rodzica
                } label: {
                    Text("Czytaj więcej")
                        .frame(maxWidth: .infinity) // Rozciągnij przycisk
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent) // Bardziej widoczny styl
                .controlSize(.small)
                .padding(.top, 5)
            }
            
            Spacer()
        }
        .padding(20)
        .background {
            // Materiał: UltraThinMaterial (efekt mrożonego szkła)
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            // Opcjonalne: Subtelna ramka dla lepszego efektu glassmorphism
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
        // Wyraźny, miękki cień (drop-shadow) - odseparowanie karty od mapy
        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        // Efekt przygaszenia dla nieaktywnych kart (opcjonalnie)
        .opacity(isSelected ? 1.0 : 0.85)
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        LocationCardView(
            location: testLocations.first!,
            isSelected: true,
            onReadMore: {
                print("Preview: Czytaj więcej")
            }
        )
        .padding()
    }
}

