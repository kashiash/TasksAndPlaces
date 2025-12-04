import Foundation

class VehicleDocumentAztecDecoder {
    private let START_OFFSET = 4
    private var src: [UInt8] = []
    private var ilen = 4
    private var currentByte: Int = 0
    private var currentBit: Int = 0
    private var dst: [UInt8] = []
    
    func decode(text: String) -> String? {
        // Reset state
        ilen = START_OFFSET
        currentByte = 0
        currentBit = 0
        
        guard let decoded = base64Decode(text: text) else { return nil }
        do {
            let decompressed = try decompressNRV2E(sourceData: decoded)
            return String(data: Data(decompressed), encoding: .utf16LittleEndian)
        } catch {
            print("Błąd dekodowania: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func decompressNRV2E(sourceData: [UInt8]) throws -> [UInt8] {
        src = sourceData
        var olen: UInt32 = 0
        var last_m_off: UInt32 = 1
        
        guard sourceData.count >= 4 else { throw DecoderError.invalidData }
        let dstSize = sourceData.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
        dst = Array(repeating: 0, count: Int(dstSize))
        
        while ilen < src.count {
            while true {
                guard let bit = try? getBit() else { return dst }
                if bit != 1 { break }
                guard ilen < src.count else { return dst }
                dst[Int(olen)] = src[ilen]
                olen += 1
                ilen += 1
            }
            
            var m_off: UInt32 = 1
            while true {
                guard let bit = try? getBit() else { return dst }
                m_off = m_off * 2 + UInt32(bit)
                guard let nextBit = try? getBit() else { return dst }
                if nextBit == 1 { break }
                guard let followingBit = try? getBit() else { return dst }
                m_off = (m_off - 1) * 2 + UInt32(followingBit)
            }
            
            var m_len: UInt32
            if m_off == 2 {
                m_off = last_m_off
                guard let bit = try? getBit() else { return dst }
                m_len = UInt32(bit)
            } else {
                guard ilen < src.count else { return dst }
                m_off = (m_off - 3) * 256 + UInt32(src[ilen])
                ilen += 1
                if m_off == 0xffffffff { break }
                m_len = (m_off ^ 0xffffffff) & 1
                m_off >>= 1
                m_off += 1
                last_m_off = m_off
            }
            
            if m_len > 0 {
                guard let bit = try? getBit() else { return dst }
                m_len = 1 + UInt32(bit)
            } else {
                guard let bit = try? getBit() else { return dst }
                if bit == 1 {
                    guard let nextBit = try? getBit() else { return dst }
                    m_len = 3 + UInt32(nextBit)
                } else {
                    m_len += 1
                    repeat {
                        guard let bit = try? getBit() else { return dst }
                        m_len = m_len * 2 + UInt32(bit)
                        guard let nextBit = try? getBit() else { return dst }
                        if nextBit == 1 { break }
                    } while true
                    m_len += 3
                }
            }
            
            if m_off > 0x500 {
                m_len += 1
            }
            
            let m_pos = Int(olen) - Int(m_off)
            guard m_pos >= 0 && m_pos < dst.count else { return dst }
            dst[Int(olen)] = dst[m_pos]
            olen += 1
            
            for i in 0..<m_len {
                let srcPos = m_pos + Int(i) + 1
                let dstPos = Int(olen + i)
                guard srcPos < dst.count && dstPos < dst.count else { break }
                dst[dstPos] = dst[srcPos]
            }
            olen += m_len
        }
        
        return dst
    }
    
    private func getBit() throws -> UInt8 {
        if ilen >= src.count {
            throw DecoderError.outOfRange
        }
        
        if currentBit == 0 {
            currentByte = Int(src[ilen])
            ilen += 1
            currentBit = 8
        }
        
        currentBit -= 1
        return UInt8((UInt32(currentByte) >> UInt32(currentBit)) & 1)
    }
    
    private func base64Decode(text: String) -> [UInt8]? {
        guard !text.isEmpty else { return [] }
        
        var textToDecode = text
        if textToDecode.count % 2 == 1 {
            textToDecode = String(textToDecode.dropLast())
        }
        
        guard let data = Data(base64Encoded: textToDecode) else { return nil }
        return Array(data)
    }
}

enum DecoderError: Error {
    case outOfRange
    case invalidData
}

