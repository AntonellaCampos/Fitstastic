//
//  ViewController.swift
//  Fittastic
//
//  Created by Antonella Campos Iannacone on 6/20/21.
//

import UIKit
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var LineChartBox: LineChartView!
    @IBOutlet weak var Heart: UILabel!
    @IBOutlet weak var Motivation: UILabel!
    @IBOutlet weak var Steps: UILabel!
    let quote1 = "Let's go"
    let quote2 = "New day, new opportunity"
    let quote3 = "You are the only person stopping you from your dreams"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let data = [12,13,14,15,14,15,15,16]
        graphLineChart(dataArray: data)
    }

    @IBAction func NewQuote(_ sender: Any) {
        let n = Int.random(in: 1...3)
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
    }
    
    func graphLineChart(dataArray: [Int]){
        //Make chart size ahave width and height both equal to width and size of screen
        LineChartBox.frame = CGRect(x:0,y:0, width: self.view.frame.size.width,height: self.view.frame.size.width/2)
        
        //make chart center to be center, but towards top screen
        LineChartBox.center.x = self.view.center.x
        LineChartBox.center.y = self.view.center.y
        
        //when no data
        LineChartBox.noDataText = "No data available"
        LineChartBox.noDataTextColor = UIColor.black
        
        //
        var entries = [ChartDataEntry]()
        
        for i in 0..<dataArray.count{
            let value = ChartDataEntry(x: Double(i), y:Double(dataArray[i]))
            entries.append(value)
        }
    
        let dataSet = LineChartDataSet(entries: entries, label: "Line Chart")
        
        dataSet.colors = ChartColorTemplates.pastel()
        
        let data = LineChartData(dataSet: dataSet)
        LineChartBox.data = data
        
        LineChartBox.chartDescription?.text = "Heart Rate last 12 hours"
        
        LineChartBox.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .linear)
        
    }
}
