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
    
    // ⚠️ Swift ga punya semua encoding built-in, jadi beberapa fallback ke utf8 atau isoLatin1.
    // bisa di-extend dengan CoreFoundation CFStringEncodings kalau butuh precise.
    
    public static let CP437   = EscPosCharsetEncoding(command: [0x1B, 0x74, 0],  encoding: .ascii, name: "CP437 (USA: Standard Europe)")
    public static let CP850   = EscPosCharsetEncoding(command: [0x1B, 0x74, 2],  encoding: .isoLatin1, name: "CP850 (Multilingual)")
    public static let CP860   = EscPosCharsetEncoding(command: [0x1B, 0x74, 3],  encoding: .isoLatin1, name: "CP860 (Portuguese)")
    public static let CP863   = EscPosCharsetEncoding(command: [0x1B, 0x74, 4],  encoding: .isoLatin1, name: "CP863 (Canadian-French)")
    public static let CP865   = EscPosCharsetEncoding(command: [0x1B, 0x74, 5],  encoding: .isoLatin1, name: "CP865 (Nordic)")
    public static let CP1252  = EscPosCharsetEncoding(command: [0x1B, 0x74, 16], encoding: .windowsCP1252, name: "CP1252 (Western European Windows)")
    public static let CP866   = EscPosCharsetEncoding(command: [0x1B, 0x74, 17], encoding: .utf8, name: "CP866 (Cyrillic 2)")
    public static let CP852   = EscPosCharsetEncoding(command: [0x1B, 0x74, 18], encoding: .isoLatin2, name: "CP852 (Latin 2)")
    public static let CP858   = EscPosCharsetEncoding(command: [0x1B, 0x74, 19], encoding: .isoLatin1, name: "CP858 (Euro)")
    
    // contoh tambahan
    public static let CP737   = EscPosCharsetEncoding(command: [0x1B, 0x74, 6],  encoding: .utf8, name: "CP737 (Greek)")
    public static let CP775   = EscPosCharsetEncoding(command: [0x1B, 0x74, 7],  encoding: .utf8, name: "CP775 (Baltic)")
    public static let CP855   = EscPosCharsetEncoding(command: [0x1B, 0x74, 8],  encoding: .utf8, name: "CP855 (Cyrillic)")
    public static let CP857   = EscPosCharsetEncoding(command: [0x1B, 0x74, 9],  encoding: .utf8, name: "CP857 (Turkish)")
    public static let CP862   = EscPosCharsetEncoding(command: [0x1B, 0x74, 15], encoding: .utf8, name: "CP862 (Hebrew DOS)")
    public static let CP864   = EscPosCharsetEncoding(command: [0x1B, 0x74, 21], encoding: .utf8, name: "CP864 (Arabic)")
    public static let CP869   = EscPosCharsetEncoding(command: [0x1B, 0x74, 23], encoding: .utf8, name: "CP869 (Greek 2)")
    public static let CP1125  = EscPosCharsetEncoding(command: [0x1B, 0x74, 44], encoding: .utf8, name: "CP1125 (Ukrainian DOS)")
    
    // tambahkan semua mapping dari java -> swift di sini
    
    public static let ALL: [EscPosCharsetEncoding] = [
        CP437, CP850, CP860, CP863, CP865,
        CP1252, CP866, CP852, CP858,
        CP737, CP775, CP855, CP857,
        CP862, CP864, CP869, CP1125
    ]
}

