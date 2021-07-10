//
//  ViewController.swift
//  Fittastic
//
//  Created by Antonella Campos Iannacone on 6/20/21.
//



import UIKit
import Foundation
import CoreBluetooth
import Charts

// Initialize global variables
var curPeripheral: CBPeripheral?
var txCharacteristic: CBCharacteristic?
var rxCharacteristic: CBCharacteristic?

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Variable Initializations
    var centralManager: CBCentralManager!
    var rssiList = [NSNumber]()
    var peripheralList: [CBPeripheral] = []
    var characteristicList = [String: CBCharacteristic]()
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    
    let BLE_Service_UUID = CBUUID.init(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    let BLE_Characteristic_uuid_Rx = CBUUID.init(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    let BLE_Characteristic_uuid_Tx  = CBUUID.init(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    
    var receivedData = [Int]()
    var showGraphIsOn = true
    
    @IBOutlet weak var showGraphLbl: UILabel!
    @IBOutlet weak var connectStatusLbl: UILabel!
    @IBOutlet weak var LineChartBox: LineChartView!
    @IBOutlet weak var Heart: UILabel!
    @IBOutlet weak var Motivation: UILabel!
    @IBOutlet weak var Steps: UILabel!
    let quote1 = "Let's go"
    let quote2 = "New day, new opportunity"
    let quote3 = "You are the only person stopping you from your dreams"
    let quote4 = "Keep going"
    let quote5 = "Never give up"
    let quote6 = "Don't stop believing"
    let quote7 = "I created my first app :)"

  
    @IBAction func NewQuote(_ sender: Any) {
        let n = Int.random(in: 1...7)
        if n==1
        {
            Motivation.text = quote1
        }
        if n==2
        {
            Motivation.text = quote2
        }
        if n==3
        {
            Motivation.text = quote3
        }
        if n==4
        {
            Motivation.text = quote4
        }
        if n==5
        {
            Motivation.text = quote5
        }
        if n==6
        {
            Motivation.text = quote6
        }
        if n==7
        {
            Motivation.text = quote7
        }
    }
    
    @IBAction func refreshBtn(_ sender: Any) {
        receivedData.removeAll()
        clearGraph()
        if (curPeripheral != nil) {
            centralManager?.cancelPeripheralConnection(curPeripheral!)
        }
        usleep(1000000)
        startScan()
    }
    
    @IBAction func showGraphBtn(_ sender: Any) {
        if (showGraphIsOn) {
            clearGraph()
            showGraphIsOn = false
        }
        else {
            showGraphIsOn = true
        }
    }

    // This function is called before the storyboard view is loaded onto the screen.
    // Runs only once.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the label to say "Disconnected" and make the text red
        connectStatusLbl.text = "Disconnected"
        connectStatusLbl.textColor = UIColor.red
        
        // Initialize CoreBluetooth Central Manager object which will be necessary
        // to use CoreBlutooth functions
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // This function is called right after the view is loaded onto the screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reset the peripheral connection with the app
        if curPeripheral != nil {
            centralManager?.cancelPeripheralConnection(curPeripheral!)
        }
        print("View Cleared")
    }
    
    // This function is called right before view disappears from screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Stop Scanning")
        
        // Central Manager object stops the scanning for peripherals
        centralManager?.stopScan()
    }

    // Called when manager's state is changed
    // Required method for setting up centralManager object
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        // If manager's state is "poweredOn", that means Bluetooth has been enabled
        // in the app. We can begin scanning for peripherals
        if central.state == CBManagerState.poweredOn {
            print("Bluetooth Enabled")
            startScan()
        }
        
        // Else, Bluetooth has NOT been enabled, so we display an alert message to the screen
        // saying that Bluetooth needs to be enabled to use the app
        else {
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")

            let alertVC = UIAlertController(title: "Bluetooth is not enabled",
                                            message: "Make sure that your bluetooth is turned on",
                                            preferredStyle: UIAlertController.Style.alert)
            
            let action = UIAlertAction(title: "ok",
                                       style: UIAlertAction.Style.default,
                                       handler: { (action: UIAlertAction) -> Void in
                                                self.dismiss(animated: true, completion: nil)
                                                })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    // Start scanning for peripherals
    func startScan() {
        print("Now Scanning...")
        print("Service ID Search: \(BLE_Service_UUID)")
        
        // Make an empty list of peripherals that were found
        peripheralList = []
        
        // Stop the timer
        self.timer.invalidate()
        
        // Call method in centralManager class that actually begins the scanning.
        // We are targeting services that have the same UUID value as the BLE_Service_UUID variable.
        // Use a timer to wait 10 seconds before calling cancelScan().
        centralManager?.scanForPeripherals(withServices: [BLE_Service_UUID],
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) {_ in
            self.cancelScan()
        }
    }
    
    // Cancel scanning for peripheral
    func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripheralList.count)")
    }

    // Called when a peripheral is found.
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        // The peripheral that was just found is stored in a variable and
        // is added to a list of peripherals. Its rssi value is also added to a list
        curPeripheral = peripheral
        self.peripheralList.append(peripheral)
        self.rssiList.append(RSSI)
        peripheral.delegate = self

        // Connect to the peripheral if it exists / has services
        if curPeripheral != nil {
            centralManager?.connect(curPeripheral!, options: nil)
        }
    }
    
    // Restore the Central Manager delegate if something goes wrong
    func restoreCentralManager() {
        centralManager?.delegate = self
    }

    // Called when app successfully connects with the peripheral
    // Use this method to set up the peripheral's delegate and discover its services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("-------------------------------------------------------")
        print("Connection complete")
        print("Peripheral info: \(String(describing: curPeripheral))")
        
        // Stop scanning because we found the peripheral we want
        cancelScan()
        
        // Set up peripheral's delegate
        peripheral.delegate = self
        
        // Only look for services that match our specified UUID
        peripheral.discoverServices([BLE_Service_UUID])
    }
    
    // Called when the central manager fails to connect to a peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        // Print error message to console for debugging purposes
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    // Called when the central manager disconnects from the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        connectStatusLbl.text = "Disconnected"
        connectStatusLbl.textColor = UIColor.red
    }
    
    // Called when the correct peripheral's services are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-------------------------------------------------------")
        
        // Check for any errors in discovery
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        // Store the discovered services in a variable. If no services are there, return
        guard let services = peripheral.services else {
            return
        }
        
        // Print to console for debugging purposes
        print("Discovered Services: \(services)")

        // For every service found...
        for service in services {
            
            // If service's UUID matches with our specified one...
            if service.uuid == BLE_Service_UUID {
                print("Service found")
                connectStatusLbl.text = "Connected!"
                connectStatusLbl.textColor = UIColor.blue
                
                // Search for the characteristics of the service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // Called when the characteristics we specified are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("-------------------------------------------------------")
        
        // Check if there was an error
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        // Store the discovered characteristics in a variable. If no characteristics, then return
        guard let characteristics = service.characteristics else {
            return
        }
        
        // Print to console for debugging purposes
        print("Found \(characteristics.count) characteristics!")
        
        // For every characteristic found...
        for characteristic in characteristics {
            // If characteritstic's UUID matches with our specified one for Rx...
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                // Subscribe to the this particular characteristic
                // This will also call didUpdateNotificationStateForCharacteristic
                // method automatically
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            
            // If characteritstic's UUID matches with our specified one for Tx...
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            
            // Find descriptors for each characteristic
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // Sets up notifications to the app from the Feather
    // Calls didUpdateValueForCharacteristic() whenever characteristic's value changes
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")

        // Check if subscription was successful
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")

        } else {
            print("Characteristic's value subscribed")
        }

        // Print message for debugging purposes
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    // Called when peripheral.readValue(for: characteristic) is called
    // Also called when characteristic value is updated in
    // didUpdateNotificationStateFor() method
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        // If characteristic is correct, read its value and save it to a string.
        // Else, return
        guard characteristic == rxCharacteristic,
        let characteristicValue = characteristic.value,
        let receivedString = NSString(data: characteristicValue,
                                      encoding: String.Encoding.utf8.rawValue)
        else { return }
        
        for i in 0..<receivedString.length {
            // Print for debugging purposes
            print(receivedString.character(at: i))
            let number:Int = Int(receivedString.character(at: i))
            receivedData.append(number)
        }
        
        if (receivedData.count > 100) {
            receivedData.removeFirst(receivedData.count-100)
        }
        if (showGraphIsOn && receivedData.count > 0) {
            displayGraph(dataDisplaying: receivedData)
            HeartRate(dataDisplaying: receivedData)
            ShowSteps(dataDisplaying: receivedData)
        }
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: self)
    }
    
    // Called when app wants to send a message to peripheral
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }

    // Called when descriptors for a characteristic are found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
        // Print for debugging purposes
        print("*******************************************************")
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        
        // Store descriptors in a variable. Return if nonexistent.
        guard let descriptors = characteristic.descriptors else { return }
            
        // For every descriptor, print its description for debugging purposes
        descriptors.forEach { descript in
            print("function name: DidDiscoverDescriptorForChar \(String(describing: descript.description))")
            print("Rx Value \(String(describing: rxCharacteristic?.value))")
            print("Tx Value \(String(describing: txCharacteristic?.value))")
        }
    }
    
    
    // Graph the dataset to storyboard
    func displayGraph(dataDisplaying: [Int]) {
        
        // Array that will eventually be displayed on the graph.
        var lineChartEntry  = [ChartDataEntry]()
        
        // For every element in given dataset
        // Set the X and Y status in a data chart entry
        // and add to the entry object
        for i in 0..<dataDisplaying.count {
            let value = ChartDataEntry(x: Double(i), y: Double(dataDisplaying[i]))
            lineChartEntry.append(value)
        }

        // Convert lineChartEntry to a LineChartDataSet
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "Heart Rate")
        
        // Customize graph settings to your liking
        line1.drawCirclesEnabled = false
        line1.colors = [NSUIColor.blue]

        // Make object that will be added to the chart
        // and set it to the variable in the Storyboard
        let lineData = LineChartData(dataSet: line1)
        
        //chartBox.dragEnabled = true
        LineChartBox.setScaleEnabled(true)
        LineChartBox.pinchZoomEnabled = true
        
        LineChartBox.data = lineData

        // Settings for the chartBox
        LineChartBox.chartDescription!.text = "Retrieving Data..."
    }
    
    // Clear the graph by displaying a dataset with no elements
    func clearGraph() {
        let nullGraph = [Int]()
        displayGraph(dataDisplaying: nullGraph)
    }
    
    func HeartRate(dataDisplaying: [Int]){
        let sumArray = dataDisplaying.reduce(0, +)
        
        let avgArrayValue = sumArray / dataDisplaying.count
        
        Heart.text = String(avgArrayValue)
    }
    
    func ShowSteps(dataDisplaying: [Int]){
        let sumArray = dataDisplaying.reduce(0, +)
        
        Steps.text = String(sumArray)
    }
}



