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

/// registry charset mirip dantsu
public class EscPosCharsetEncodings {
    public static let CP437 = EscPosCharsetEncoding(command: [0x1B, 0x74, 0], encoding: .ascii, name: "CP437")
    public static let CP850 = EscPosCharsetEncoding(command: [0x1B, 0x74, 2], encoding: .isoLatin1, name: "CP850")
    public static let CP860 = EscPosCharsetEncoding(command: [0x1B, 0x74, 3], encoding: .isoLatin1, name: "CP860")
    public static let CP863 = EscPosCharsetEncoding(command: [0x1B, 0x74, 4], encoding: .isoLatin1, name: "CP863")
    public static let CP865 = EscPosCharsetEncoding(command: [0x1B, 0x74, 5], encoding: .isoLatin1, name: "CP865")
    public static let CP1252 = EscPosCharsetEncoding(command: [0x1B, 0x74, 16], encoding: .windowsCP1252, name: "CP1252")
    public static let CP866 = EscPosCharsetEncoding(command: [0x1B, 0x74, 17], encoding: .utf8, name: "CP866") // fallback utf8
    public static let CP852 = EscPosCharsetEncoding(command: [0x1B, 0x74, 18], encoding: .isoLatin2, name: "CP852")
    public static let CP858 = EscPosCharsetEncoding(command: [0x1B, 0x74, 19], encoding: .isoLatin1, name: "CP858")

    /// tambahin sesuai list di java (ada 30+ codepages)
    public static let ALL: [EscPosCharsetEncoding] = [
        CP437, CP850, CP860, CP863, CP865, CP1252, CP866, CP852, CP858
    ]
}
