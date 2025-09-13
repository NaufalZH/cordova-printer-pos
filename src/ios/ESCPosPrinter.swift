import Foundation
import Cordova
import Network
import CoreBluetooth
import ExternalAccessory

@objc(ESCPosPrinter) class ESCPosPrinter : CDVPlugin {

    // tcp connection
    var connection: NWConnection?

    // ble
    var centralManager: CBCentralManager?
    var foundPeripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?

    // external accessory
    var accessorySession: EASession?
    var accessory: EAAccessory?

    @objc(connect:)
    func connect(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? [String:Any],
              let type = opts["type"] as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "invalid args"), callbackId: command.callbackId)
            return
        }

        if type == "tcp" {
            guard let host = opts["host"] as? String, let port = opts["port"] as? Int else {
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "missing host/port"), callbackId: command.callbackId)
                return
            }
            connectTCP(host: host, port: port) { success, msg in
                if success {
                    self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "connected"), callbackId: command.callbackId)
                } else {
                    self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
                }
            }
        } else if type == "ble" {
            centralManager = CBCentralManager(delegate: self, queue: nil)
            // store peripheralId or name to search
            objc_setAssociatedObject(self, &AssociatedKeys.connectOptions, opts, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_NO_RESULT), callbackId: command.callbackId)
        } else if type == "externalAccessory" {
            // require MFi and EAAccessory selection - out of scope to auto-select
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "externalAccessory flow requires app-specific EAAccessory handling"), callbackId: command.callbackId)
        } else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "unknown type"), callbackId: command.callbackId)
        }
    }

    func connectTCP(host: String, port: Int, completion: @escaping (Bool, String) -> Void) {
        let params = NWParameters.tcp
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: UInt16(port))!, using: params)
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                completion(true, "ready")
            case .failed(let e):
                completion(false, "failed: \(e.localizedDescription)")
            default:
                break
            }
        }
        connection?.start(queue: .global())
    }

    @objc(writeBase64:)
    func writeBase64(command: CDVInvokedUrlCommand) {
        guard let b64 = command.argument(at: 0) as? String, let data = Data(base64Encoded: b64) else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "invalid base64"), callbackId: command.callbackId)
            return
        }
        writeRaw(data: data) { ok, msg in
            if ok {
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "written"), callbackId: command.callbackId)
            } else {
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
            }
        }
    }

    @objc(writeHex:)
    func writeHex(command: CDVInvokedUrlCommand) {
        guard let hex = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "invalid hex"), callbackId: command.callbackId)
            return
        }
        var data = Data()
        var tempHex = hex
        if tempHex.count % 2 != 0 { tempHex = "0" + tempHex }
        var idx = tempHex.startIndex
        while idx < tempHex.endIndex {
            let nextIdx = tempHex.index(idx, offsetBy: 2)
            let byteStr = String(tempHex[idx..<nextIdx])
            if let b = UInt8(byteStr, radix: 16) {
                data.append(b)
            }
            idx = nextIdx
        }
        writeRaw(data: data) { ok, msg in
            if ok {
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "written"), callbackId: command.callbackId)
            } else {
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
            }
        }
    }

    func writeRaw(data: Data, completion: @escaping (Bool, String) -> Void) {
        if let conn = connection {
            conn.send(content: data, completion: .contentProcessed({ (error) in
                if let e = error {
                    completion(false, e.localizedDescription)
                } else {
                    completion(true, "sent")
                }
            }))
            return
        }
        // BLE path
        if let peripheral = foundPeripheral, let char = writeCharacteristic {
            peripheral.writeValue(data, for: char, type: .withResponse)
            completion(true, "written-ble")
            return
        }
        // EA accessory
        if let session = accessorySession, let out = session.outputStream {
            data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                guard let bytes = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
                out.write(bytes, maxLength: data.count)
            }
            completion(true, "written-ea")
            return
        }
        completion(false, "no connection")
    }

    @objc(disconnect:)
    func disconnect(command: CDVInvokedUrlCommand) {
        if let conn = connection {
            conn.cancel()
            connection = nil
        }
        if let peripheral = foundPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            foundPeripheral = nil
        }
        if let session = accessorySession {
            session.inputStream?.close()
            session.outputStream?.close()
            accessorySession = nil
        }
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "disconnected"), callbackId: command.callbackId)
    }
}

// MARK: - BLE helpers

fileprivate struct AssociatedKeys {
    static var connectOptions = "connectOptions"
}

extension ESCPosPrinter: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        if let opts = objc_getAssociatedObject(self, &AssociatedKeys.connectOptions) as? [String:Any] {
            if let peripheralId = opts["peripheralId"] as? String {
                // try scan and match name or identifier
                central.scanForPeripherals(withServices: nil, options: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    central.stopScan()
                }
            } else if let name = opts["name"] as? String {
                central.scanForPeripherals(withServices: nil, options: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    central.stopScan()
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let opts = o
