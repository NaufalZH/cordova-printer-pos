import Foundation
import Cordova
import Network
import CoreBluetooth
import ExternalAccessory

@objc(ESCPosPrinter) class ESCPosPrinter : CDVPlugin {

    var connection: NWConnection?
    var centralManager: CBCentralManager?
    var foundPeripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?
    var accessorySession: EASession?
    var accessory: EAAccessory?
    var listenerCallbackId: String?

    // register JS listener
    @objc(registerListener:)
    func registerListener(command: CDVInvokedUrlCommand) {
        self.listenerCallbackId = command.callbackId
        let result = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        result?.setKeepCallbackAs(true)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    func sendEvent(type: String, msg: String) {
        if let cb = listenerCallbackId {
            let dict: [String:Any] = ["type": type, "msg": msg]
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dict)
            result?.setKeepCallbackAs(true)
            self.commandDelegate.send(result, callbackId: cb)
        }
    }

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
                    self.sendEvent(type: "connect", msg: "connected")
                    self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "connected"), callbackId: command.callbackId)
                } else {
                    self.sendEvent(type: "error", msg: msg)
                    self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
                }
            }
        } else {
            self.sendEvent(type: "error", msg: "unknown type")
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
            case .cancelled:
                self.sendEvent(type: "disconnect", msg: "cancelled")
            default:
                break
            }
        }
        connection?.start(queue: .global())
    }

    @objc(writeBase64:)
    func writeBase64(command: CDVInvokedUrlCommand) {
        guard let b64 = command.argument(at: 0) as? String, let data = Data(base64Encoded: b64) else {
            self.sendEvent(type: "error", msg: "invalid base64")
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "invalid base64"), callbackId: command.callbackId)
            return
        }
        writeRaw(data: data) { ok, msg in
            if !ok { self.sendEvent(type: "error", msg: msg) }
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
        completion(false, "no connection")
    }

    @objc(disconnect:)
    func disconnect(command: CDVInvokedUrlCommand) {
        if let conn = connection {
            conn.cancel()
            connection = nil
        }
        self.sendEvent(type: "disconnect", msg: "disconnected")
        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "disconnected"), callbackId: command.callbackId)
    }
}
