import Foundation

struct VehicleData: Codable {
    // Dane identyfikacyjne
    let documentCode: String
    let barcode: String
    let serialNumber: String
    
    // Dane organu wydającego
    let issuingAuthority: String
    let issuingDepartment: String
    let issuingAddress: String
    let issuingPostalCode: String
    
    // Dane pojazdu podstawowe
    let registrationNumber: String
    let brand: String
    let version: String
    let commercialDescription: String
    let nationalNumber: String
    let model: String
    let vin: String
    let registrationDate: String
    
    // Dane właściciela
    let ownerName: String
    let ownerAddress: String
    let ownerPostalCode: String
    let ownerCity: String
    let ownerRegion: String
    let ownerTaxNumber: String
    
    // Parametry techniczne
    let maxMass: String
    let allowedMass: String
    let maxTotalMass: String
    let emptyMass: String
    let category: String
    let approval: String
    let axles: String
    let enginePower: String
    let engineCapacity: String
    let fuelType: String
    let powerToWeight: String
    
    // Dane dodatkowe
    let firstRegistrationDate: String
    let seatsNumber: String
    let vehicleType: String
    let productionYear: String
    
    // Dane kontrolne
    let controlNumber: String
    let seriesNumber: String
    let documentSeries: String
    let documentNumber: String
    let securityCode: String
    let qrCode: String
    let controlDigits: String
    
    init(fromDecodedString decoded: String) {
        let components = decoded.components(separatedBy: "|")
        // Wyświetl wszystkie komponenty w konsoli
        for (index, component) in components.enumerated() {
            print("Komponent [\(index)]: \(component)")
        }

        // Inicjalizacja z wartościami domyślnymi
        documentCode = components.count > 0 ? components[0] : ""
        barcode = components.count > 1 ? components[1] : ""
        serialNumber = components.count > 2 ? components[2] : ""
        
        issuingAuthority = components.count > 3 ? components[3] : ""
        issuingDepartment = components.count > 4 ? components[4] : ""
        issuingAddress = components.count > 5 ? components[5] : ""
        issuingPostalCode = components.count > 6 ? components[6] : ""
        
        registrationNumber = components.count > 7 ? components[7] : ""
        brand = components.count > 8 ? components[8] : ""
        version = components.count > 9 ? components[9] : ""
        commercialDescription = components.count > 10 ? components[10] : ""
        nationalNumber = components.count > 11 ? components[11] : ""
        model = components.count > 12 ? components[12] : ""
        vin = components.count > 13 ? components[13] : ""
        registrationDate = components.count > 14 ? components[14] : ""
        
        ownerName = components.count > 15 ? components[15] : ""
        ownerTaxNumber = components.count > 20 ? components[20] : ""
        ownerPostalCode = components.count > 21 ? components[21] : ""
        ownerCity = components.count > 22 ? components[22] : ""
        ownerRegion = components.count > 23 ? components[23] : ""
        ownerAddress = components.count > 24 && components.count > 25 ?
            "\(components[24]) \(components[25]), \(components[21]) \(components[22])" : ""
        
        // Parametry techniczne
        maxMass = components.count > 35 ? components[35] : ""
        allowedMass = components.count > 36 ? components[36] : ""
        maxTotalMass = components.count > 37 ? components[37] : ""
        emptyMass = components.count > 38 ? components[38] : ""
        category = components.count > 39 ? components[39] : ""
        approval = components.count > 40 ? components[40] : ""
        axles = components.count > 41 ? components[41] : ""
        
        engineCapacity = components.count > 46 ? components[46] : ""
        enginePower = components.count > 47 ? components[47] : ""
        fuelType = components.count > 48 ? components[48] : ""
        
        // Dane dodatkowe
        firstRegistrationDate = components.count > 49 ? components[49] : ""
        seatsNumber = components.count > 50 ? components[50] : ""
        vehicleType = components.count > 51 ? components[51] : ""
        powerToWeight = components.count > 52 ? components[52] : ""
        productionYear = components.count > 53 ? components[53] : ""
        
        // Dane kontrolne
        controlNumber = components.count > 54 ? components[54] : ""
        seriesNumber = components.count > 55 ? components[55] : ""
        documentSeries = components.count > 56 ? components[56] : ""
        documentNumber = components.count > 57 ? components[57] : ""
        securityCode = components.count > 58 ? components[58] : ""
        qrCode = components.count > 59 ? components[59] : ""
        controlDigits = components.count > 60 ? components[60] : ""
    }
    
    func printAsJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Decoded vehicle data:")
                print(jsonString)
                
                // Wysyłanie do Zapier
                sendToZapier(jsonData: jsonData)
            }
        } catch {
            print("Error encoding to JSON: \(error)")
        }
    }
    
    private func sendToZapier(jsonData: Data) {
        let zapierURL = "https://hooks.zapier.com/hooks/catch/4628538/2kc399t/"
        guard let url = URL(string: zapierURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending data to Zapier: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Zapier response status: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Zapier response: \(responseString)")
                }
            }
        }
        task.resume()
    }
}

