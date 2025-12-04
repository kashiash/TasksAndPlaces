//
//  LocationAnnotationView.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI

// MARK: - Komponent B: Znacznik na Mapie (Custom Annotation)
// Nie używamy standardowych czerwonych szpilek Apple
struct LocationAnnotationView: View {
    let isSelected: Bool
    @State private var animate = false
    
    // Kolorystyka: Kontrastowa do mapy (intensywny niebieski lub brandowy kolor)
    private let activeColor = Color.blue
    private let inactiveColor = Color.gray
    
    var body: some View {
        ZStack {
            if isSelected {
                // MARK: - Stan Aktywny: Efekt "Radar" - Koncentryczne kręgi
                // Wymagane zaprojektowanie koncentrycznych kręgów wokół punktu
                // Animacja: rozchodzenie się i zanikanie
                
                // Pierwszy krąg (zewnętrzny)
                Circle()
                    .stroke(activeColor.opacity(0.4), lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .scaleEffect(animate ? 2.0 : 1.0)
                    .opacity(animate ? 0 : 0.6)
                
                // Drugi krąg (średni)
                Circle()
                    .stroke(activeColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(animate ? 1.8 : 1.0)
                    .opacity(animate ? 0 : 0.7)
                
                // Trzeci krąg (wewnętrzny)
                Circle()
                    .stroke(activeColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .scaleEffect(animate ? 1.5 : 1.0)
                    .opacity(animate ? 0 : 0.8)
            }
            
            // MARK: - Główny punkt
            // Stan Spoczynku (Nieaktywny): Mniejsza ikona
            // Stan Aktywny (Wybrany): Większa skala ikony
            Image(systemName: "map.circle.fill")
                .resizable()
                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                .foregroundStyle(.white, isSelected ? activeColor : inactiveColor)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                )
                .scaleEffect(isSelected ? 1.2 : 0.9)
        }
        .onAppear {
            if isSelected {
                // Animacja pulsowania tylko dla aktywnego znacznika
                withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                // Restart animacji gdy znacznik staje się aktywny
                animate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        animate = true
                    }
                }
            } else {
                // Zatrzymaj animację gdy znacznik staje się nieaktywny
                animate = false
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 50) {
        LocationAnnotationView(isSelected: false)
        LocationAnnotationView(isSelected: true)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

