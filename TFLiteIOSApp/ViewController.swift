//
//  ViewController.swift
//  TFLiteIOSApp
//
//  Created by Wjciech Drewek on 12/09/2021.
//

import UIKit

class ViewController: UIViewController {
    
    let tfLiteIOSTest: TFLiteIOSTest
    @IBOutlet weak var batchSizeText: UITextField!
    @IBOutlet weak var LogText: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        self.tfLiteIOSTest = TFLiteIOSTest()
        super.init(coder: aDecoder)
        tfLiteIOSTest.setParentView(vC: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func runTestsClick(_ sender: Any) {
        if !batchSizeText.hasText {
            LogText.text = "specify batch size"
            return
        }
        
        let batchSize = Int(batchSizeText.text!)
        if batchSize != 1 && batchSize != 2 && batchSize != 4 && batchSize != 8 && batchSize != 16 &&
            batchSize != 32 {
            LogText.text = "wrong batch size"
            return
        }
        
        self.tfLiteIOSTest.run()
    }
    
    @IBAction func deviceChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.tfLiteIOSTest.setDevice(d: .CPU)
        case 1:
            self.tfLiteIOSTest.setDevice(d: .GPU)
        default:
            self.tfLiteIOSTest.setDevice(d: .CPU)
        }
    }
    @IBAction func versionChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.tfLiteIOSTest.setModelVersion(v: versionArray[0])
        case 1:
            self.tfLiteIOSTest.setModelVersion(v: versionArray[1])
        case 2:
            self.tfLiteIOSTest.setModelVersion(v: versionArray[2])
        default:
            self.tfLiteIOSTest.setModelVersion(v: versionArray[0])
        }
    }
}

