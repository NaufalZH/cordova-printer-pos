import Foundation

/// EscPosTextEncoder
/// parse formatted text (DantSu-like tags) -> escpos Data
/// supported tags: [L],[C],[R], <b>, <u>, <font size='big'|'tall'|'normal'>
public class EscPosTextEncoder {
    private var buffer = Data()
    private var charset: EscPosCharsetEncoding
    
    public init(charset: EscPosCharsetEncoding = EscPosCharsetEncodings.CP437) {
        self.charset = charset
        setCharset(charset)
    }
    
    /// ganti charset (kirim ESC t n)
    public func setCharset(_ charset: EscPosCharsetEncoding) {
        self.charset = charset
        buffer.append(contentsOf: charset.command)
    }
    
    /// reset buffer (clear semua data)
    public func reset() {
        buffer.removeAll()
        setCharset(charset)
    }
    
    /// tambah teks dengan encoding sesuai charset
    public func text(_ string: String) {
        if let d = string.data(using: charset.encoding, allowLossyConversion: true) {
            buffer.append(d)
        } else {
            // fallback: UTF-8 kalau gagal encode
            if let d = string.data(using: .utf8) {
                buffer.append(d)
            }
        }
    }
    
    /// tambah teks + newline
    public func textLine(_ string: String) {
        text(string)
        newline()
    }
    
    /// tambah newline
    public func newline(_ count: Int = 1) {
        for _ in 0..<count {
            buffer.append(0x0A)
        }
    }
    
    /// potong kertas (ESC i)
    public func cut(full: Bool = true) {
        if full {
            buffer.append(contentsOf: [0x1D, 0x56, 0x00])
        } else {
            buffer.append(contentsOf: [0x1D, 0x56, 0x01])
        }
    }
    
    /// bold on/off
    public func bold(_ on: Bool) {
        buffer.append(contentsOf: [0x1B, 0x45, on ? 1 : 0])
    }
    
    /// underline (0=off, 1=thin, 2=thick)
    public func underline(_ mode: Int) {
        buffer.append(contentsOf: [0x1B, 0x2D, UInt8(mode & 0xFF)])
    }
    
    /// align: 0=left, 1=center, 2=right
    public func align(_ mode: Int) {
        buffer.append(contentsOf: [0x1B, 0x61, UInt8(mode & 0xFF)])
    }
    
    /// ambil hasil data siap kirim ke printer
    public func data() -> Data {
        return buffer
    }

    // ---------- ESC/POS low level helpers ----------
    private func appendInit() {
        buffer.append(contentsOf: [0x1B, 0x40]) // ESC @
    }

    private func appendAlign(_ n: UInt8) {
        // 0 left, 1 center, 2 right
        buffer.append(contentsOf: [0x1B, 0x61, n])
    }

    private func appendBold(_ on: Bool) {
        buffer.append(contentsOf: [0x1B, 0x45, on ? 1 : 0]) // ESC E n
    }

    private func appendUnderline(_ mode: UInt8) {
        // mode: 0 off, 1 single, 2 double (we use 1)
        buffer.append(contentsOf: [0x1B, 0x2D, mode]) // ESC - n
    }

    private func appendFontSize(width: UInt8, height: UInt8) {
        // GS ! n  -> n = (width-1)<<4 | (height-1)
        // but easier: compute n directly: width and height are multipliers 1..8
        let w = max(1, min(8, width))
        let h = max(1, min(8, height))
        let n = UInt8(((w - 1) << 4) | (h - 1))
        buffer.append(contentsOf: [0x1D, 0x21, n])
    }

    private func appendText(_ txt: String) {
        if let d = txt.data(using: currentEncoding, allowLossyConversion: true) {
            buffer.append(d)
        } else {
            // fallback utf8
            if let d2 = txt.data(using: .utf8) {
                buffer.append(d2)
            }
        }
    }

    private func appendNewline() {
        buffer.append(0x0A)
    }

    // ---------- high level parser ----------
    /// parse formatted text and fill buffer
    /// supported minimal tags and simple nested tags
    public func encode(formattedText: String) -> Data {
        reset()
        appendInit()

        // we'll do a simple streaming parser: read char by char, detect tags
        var i = formattedText.startIndex

        // state stacks for styles
        var boldStack: [Bool] = []
        var underlineStack: [UInt8] = []
        var alignStack: [UInt8] = [] // keep last alignment
        var sizeStack: [(UInt8, UInt8)] = [] // (width, height)

        // ensure default states
        alignStack.append(0) // left

        func pushBold(_ on: Bool) {
            boldStack.append(on)
            appendBold(on)
        }
        func popBold() {
            _ = boldStack.popLast()
            let on = boldStack.last ?? false
            appendBold(on)
        }

        func pushUnderline(_ mode: UInt8) {
            underlineStack.append(mode)
            appendUnderline(mode)
        }
        func popUnderline() {
            _ = underlineStack.popLast()
            let mode = underlineStack.last ?? 0
            appendUnderline(mode)
        }

        func pushAlign(_ a: UInt8) {
            alignStack.append(a)
            appendAlign(a)
        }
        func popAlign() {
            _ = alignStack.popLast()
            let a = alignStack.last ?? 0
            appendAlign(a)
        }

        func pushSize(_ w: UInt8, _ h: UInt8) {
            sizeStack.append((w, h))
            appendFontSize(width: w, height: h)
        }
        func popSize() {
            _ = sizeStack.popLast()
            let (w, h) = sizeStack.last ?? (1,1)
            appendFontSize(width: w, height: h)
        }

        while i < formattedText.endIndex {
            let ch = formattedText[i]

            if ch == "[" {
                // possible alignment tag like [C], [L], [R]
                let remain = formattedText[i...]
                if remain.hasPrefix("[C]") {
                    pushAlign(1)
                    i = formattedText.index(i, offsetBy: 3)
                    continue
                } else if remain.hasPrefix("[L]") {
                    pushAlign(0)
                    i = formattedText.index(i, offsetBy: 3)
                    continue
                } else if remain.hasPrefix("[R]") {
                    pushAlign(2)
                    i = formattedText.index(i, offsetBy: 3)
                    continue
                } else if remain.hasPrefix("[/C]") || remain.hasPrefix("[/L]") || remain.hasPrefix("[/R]") {
                    // support explicit closing like [/C] to pop alignment
                    popAlign()
                    // move to after closing tag (find first ']')
                    if let idx = formattedText[i...].firstIndex(of: "]") {
                        i = formattedText.index(after: idx)
                        continue
                    } else {
                        break
                    }
                } else {
                    // not recognized, treat as normal char
                    appendText(String(ch))
                    i = formattedText.index(after: i)
                    continue
                }
            } else if ch == "<" {
                // html-like tag: <b>, </b>, <u>, </u>, <font size='big'>, </font>
                // find tag end '>'
                guard let tagEnd = formattedText[i...].firstIndex(of: ">") else {
                    // malformed -> append rest
                    appendText(String(formattedText[i...]))
                    break
                }
                let tagContent = String(formattedText[formattedText.index(after: i)..<tagEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                // handle open/close tags
                if tagContent.lowercased() == "b" {
                    pushBold(true)
                } else if tagContent.lowercased() == "/b" {
                    popBold()
                } else if tagContent.lowercased() == "u" {
                    pushUnderline(1)
                } else if tagContent.lowercased() == "/u" {
                    popUnderline()
                } else if tagContent.lowercased().starts(with: "font") {
                    // parse size attribute e.g. font size='big'
                    // find size value
                    if let sizeRange = tagContent.range(of: "size=", options: .caseInsensitive) {
                        let after = tagContent[sizeRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                        // allow forms: size='big' or size=\"big\" or size=big
                        var sizeVal = after
                        if sizeVal.hasPrefix("'") || sizeVal.hasPrefix("\"") {
                            sizeVal.removeFirst()
                        }
                        // take until space or closing
                        if let endIdx = sizeVal.firstIndex(where: { $0 == "'" || $0 == "\"" || $0 == " " }) {
                            sizeVal = String(sizeVal[..<endIdx])
                        }
                        sizeVal = sizeVal.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
                        // map common names
                        let s = sizeVal.lowercased()
                        if s == "big" || s == "large" {
                            // double width & height
                            pushSize(2, 2)
                        } else if s == "tall" {
                            pushSize(1, 2)
                        } else if s == "wide" {
                            pushSize(2, 1)
                        } else {
                            pushSize(1,1)
                        }
                    } else {
                        pushSize(1,1)
                    }
                } else if tagContent.lowercased() == "/font" {
                    popSize()
                } else {
                    // unknown tag -> ignore
                }

                i = formattedText.index(after: tagEnd)
                continue
            } else if ch == "\n" {
                appendNewline()
                i = formattedText.index(after: i)
                continue
            } else {
                // ordinary text: gather consecutive chars until next special tag to avoid many small data appends
                var end = i
                while end < formattedText.endIndex {
                    let c = formattedText[end]
                    if c == "[" || c == "<" || c == "\n" { break }
                    end = formattedText.index(after: end)
                }
                let segment = String(formattedText[i..<end])
                appendText(segment)
                i = end
                continue
            }
        }

        // reset any styles to defaults (important)
        appendBold(false)
        appendUnderline(0)
        appendFontSize(width: 1, height: 1)
        appendAlign(0)

        return data()
    }
}
