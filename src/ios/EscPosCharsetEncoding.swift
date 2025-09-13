import Foundation

public struct EscPosCharsetEncoding {
    public let command: [UInt8]
    public let encoding: String.Encoding
    public let name: String
    
    public init(command: [UInt8], encoding: String.Encoding, name: String) {
        self.command = command
        self.encoding = encoding
        self.name = name
    }
}

public class EscPosCharsetEncodings {
    // mapping ESC t n
    public static let CP437   = EscPosCharsetEncoding(command: [0x1B, 0x74, 0],  encoding: .from(cfEnc: .DOSLatinUS),      name: "CP437")
    public static let KATAKANA= EscPosCharsetEncoding(command: [0x1B, 0x74, 1],  encoding: .from(cfEnc: .DOSJapanese),    name: "KATAKANA")
    public static let CP850   = EscPosCharsetEncoding(command: [0x1B, 0x74, 2],  encoding: .from(cfEnc: .DOSLatin1),      name: "CP850")
    public static let CP860   = EscPosCharsetEncoding(command: [0x1B, 0x74, 3],  encoding: .from(cfEnc: .DOSPortuguese),  name: "CP860")
    public static let CP863   = EscPosCharsetEncoding(command: [0x1B, 0x74, 4],  encoding: .from(cfEnc: .DOSCanadianFrench), name: "CP863")
    public static let CP865   = EscPosCharsetEncoding(command: [0x1B, 0x74, 5],  encoding: .from(cfEnc: .DOSNordic),      name: "CP865")
    public static let CP737   = EscPosCharsetEncoding(command: [0x1B, 0x74, 6],  encoding: .from(cfEnc: .DOSGreek),       name: "CP737")
    public static let CP775   = EscPosCharsetEncoding(command: [0x1B, 0x74, 7],  encoding: .from(cfEnc: .DOSBalticRim),   name: "CP775")
    public static let CP855   = EscPosCharsetEncoding(command: [0x1B, 0x74, 8],  encoding: .from(cfEnc: .DOSCyrillic),    name: "CP855")
    public static let CP857   = EscPosCharsetEncoding(command: [0x1B, 0x74, 9],  encoding: .from(cfEnc: .DOSTurkish),     name: "CP857")
    public static let CP862   = EscPosCharsetEncoding(command: [0x1B, 0x74, 15], encoding: .from(cfEnc: .DOSHebrew),     name: "CP862")
    public static let CP864   = EscPosCharsetEncoding(command: [0x1B, 0x74, 21], encoding: .from(cfEnc: .DOSArabic),     name: "CP864")
    public static let CP869   = EscPosCharsetEncoding(command: [0x1B, 0x74, 23], encoding: .from(cfEnc: .DOSGreek2),     name: "CP869")
    public static let CP1252  = EscPosCharsetEncoding(command: [0x1B, 0x74, 16], encoding: .from(cfEnc: .WindowsLatin1), name: "CP1252")
    public static let CP866   = EscPosCharsetEncoding(command: [0x1B, 0x74, 17], encoding: .from(cfEnc: .DOSCyrillic),   name: "CP866")
    public static let CP852   = EscPosCharsetEncoding(command: [0x1B, 0x74, 18], encoding: .from(cfEnc: .DOSLatin2),     name: "CP852")
    public static let CP858   = EscPosCharsetEncoding(command: [0x1B, 0x74, 19], encoding: .from(cfEnc: .DOSLatin1),     name: "CP858")
    public static let CP1125  = EscPosCharsetEncoding(command: [0x1B, 0x74, 44], encoding: .from(cfEnc: .DOSUkrainian),  name: "CP1125")
    
    public static let CP1250  = EscPosCharsetEncoding(command: [0x1B, 0x74, 45], encoding: .from(cfEnc: .WindowsLatin2),  name: "CP1250")
    public static let CP1251  = EscPosCharsetEncoding(command: [0x1B, 0x74, 46], encoding: .from(cfEnc: .WindowsCyrillic), name: "CP1251")
    public static let CP1253  = EscPosCharsetEncoding(command: [0x1B, 0x74, 47], encoding: .from(cfEnc: .WindowsGreek),   name: "CP1253")
    public static let CP1254  = EscPosCharsetEncoding(command: [0x1B, 0x74, 48], encoding: .from(cfEnc: .WindowsTurkish), name: "CP1254")
    public static let CP1255  = EscPosCharsetEncoding(command: [0x1B, 0x74, 49], encoding: .from(cfEnc: .WindowsHebrew),  name: "CP1255")
    public static let CP1256  = EscPosCharsetEncoding(command: [0x1B, 0x74, 50], encoding: .from(cfEnc: .WindowsArabic),  name: "CP1256")
    public static let CP1257  = EscPosCharsetEncoding(command: [0x1B, 0x74, 51], encoding: .from(cfEnc: .WindowsBalticRim), name: "CP1257")
    public static let CP1258  = EscPosCharsetEncoding(command: [0x1B, 0x74, 52], encoding: .from(cfEnc: .WindowsVietnamese), name: "CP1258")
    
    public static let ALL: [EscPosCharsetEncoding] = [
        CP437, KATAKANA, CP850, CP860, CP863, CP865,
        CP737, CP775, CP855, CP857, CP862, CP864, CP869,
        CP1252, CP866, CP852, CP858, CP1125,
        CP1250, CP1251, CP1253, CP1254, CP1255, CP1256, CP1257, CP1258
    ]
    
    /// cari encoding dari nama, misal "cp1252" atau "CP437"
    public static func from(name: String) -> EscPosCharsetEncoding? {
        return ALL.first { $0.name.lowercased() == name.lowercased() }
    }
}
