
import Central
import Combine
import CoreBluetooth
import Dispatch

class CentralManagerDelegate: NSObject {

    let centralState = PassthroughSubject<Central.State.Update, Never>()
    let peripherals = PassthroughSubject<(peripheral: CBPeripheral, rssi: NSNumber), Never>()
    let connections = PassthroughSubject<(peripheral: CBPeripheral, connected: Bool), Never>()
}

extension CentralManagerDelegate: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        let state = central.state
        Task(priority: .utility) {
            self.centralState.send(Central.State.Update.init(state))
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {

        Task(priority: .utility) {
            self.peripherals.send((peripheral: peripheral, rssi: RSSI))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        Task(priority: .utility) {
            self.connections.send((peripheral: peripheral, connected: true))
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {

        Task(priority: .utility) {
            self.connections.send((peripheral: peripheral, connected: false))
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

        Task(priority: .utility) {
            self.connections.send((peripheral: peripheral, connected: false))
        }
    }
}
