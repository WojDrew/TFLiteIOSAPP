//
//  TFLiteIOSTest.swift
//  TFLiteIOSApp
//
//  Created by Wojciech Drewek on 12/09/2021.
//

import TensorFlowLite

let versionArray = [
    "mobilenet_v1",
    "mobilenet_v2",
    "mobilenet_v3"
]

enum Device {
    case CPU
    case GPU
    
    var description : String {
      switch self {
      case .CPU: return "CPU"
      case .GPU: return "GPU"
      }
    }
}

class TFLiteIOSTest {
    
    private var mainController: ViewController?
    
    private var interpreter: Interpreter?
    
    private var modelVersion: String
    
    private var currentDevice: Device
    
    private let gpuDelegate: MetalDelegate
    
    var dataArray:[Dictionary<String, AnyObject>] =  Array()
    
    var batchSize: Int
    
    init() {
        //default config is CPU and mobilenet_v1
        self.modelVersion = versionArray[0]
        self.currentDevice = .CPU
        self.gpuDelegate = MetalDelegate()
        self.batchSize = 1
    }
    
    func setParentView(vC: ViewController) {
        self.mainController = vC
    }
    
    func run() {
        let models = getListOfModels()
        var interval: TimeInterval
        for model in models! {
            initInterpreter(modelPath: model.path)
            let data = initInputBuffer()
            for _ in 1...330 {
                do {
                    print(model.lastPathComponent)
                    try interpreter?.copy(data!, toInputAt: 0)
                    let startDate = Date()
                    try interpreter?.invoke()
                    interval = Date().timeIntervalSince(startDate) * 1000
                    print(model.deletingPathExtension().lastPathComponent)
                    saveData(time: interval, modelName: model.deletingPathExtension().lastPathComponent)
                    print(interval)
                } catch {
                    print(error.localizedDescription)
                }
            }
            //break
        }
        createCSV()
        
    }
    
    func createCSV() {
            var csvString = "ModelName,Label,InferenceTime,Recognition,Accuraccy\n"
            for dct in  dataArray{
                csvString = csvString.appending("\(String(describing: dct["ModelName"]!)),\(String(describing: dct["Label"]!)),\(String(describing: dct["InferenceTime"]!)),\(String(describing: dct["Recognition"]!)),\(String(describing: dct["Accuraccy"]!))\n")
            }

            let fileManager = FileManager.default
            do {
                let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                print(path)
                let fileURL = path.appendingPathComponent("results_" + modelVersion + "_" + currentDevice.description + "_bs_" + String(batchSize) + ".csv")
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("error creating file")
            }

        }
    
    func saveData(time: TimeInterval, modelName: String) {
        var dct = Dictionary<String, AnyObject>()
        dct.updateValue(modelName as AnyObject, forKey: "ModelName")
        dct.updateValue("" as AnyObject, forKey: "Label")
        dct.updateValue(time as AnyObject, forKey: "InferenceTime")
        dct.updateValue("" as AnyObject, forKey: "Recognition")
        dct.updateValue("" as AnyObject, forKey: "Accuraccy")
        dataArray.append(dct)
        for _ in 1...5 {
            dct.updateValue("" as AnyObject, forKey: "ModelName")
            dct.updateValue("" as AnyObject, forKey: "Label")
            dct.updateValue("" as AnyObject, forKey: "InferenceTime")
            dct.updateValue("" as AnyObject, forKey: "Recognition")
            dct.updateValue("" as AnyObject, forKey: "Accuraccy")
            dataArray.append(dct)
        }
        
    }
    
    func initInterpreter(modelPath: String) {
        do {
            switch self.currentDevice {
            case .CPU:
                self.interpreter = try Interpreter(modelPath: modelPath)
            case .GPU:
                if modelPath.contains("quant"){
                    return
                }
                self.interpreter = try Interpreter(modelPath: modelPath, delegates: [gpuDelegate])
            }
        
            try self.interpreter!.allocateTensors()
        } catch {
            
        }
    }
    
    func initInputBuffer() -> Data? {
        do {
            var shape =  try interpreter!.input(at: 0).shape
            var newShape = Tensor.Shape([shape.dimensions[0]*batchSize, shape.dimensions[1], shape.dimensions[2], shape.dimensions[3]])
            print(shape.dimensions[0])
            print(shape.dimensions[1])
            print(shape.dimensions[2])
            print(shape.dimensions[3])
            try interpreter?.resizeInput(at: 0, to: newShape)
            
            let size = newShape.dimensions[0] * newShape.dimensions[1] * newShape.dimensions[2] * newShape.dimensions[3]
            //print(size)
            
            var bytes = Array<UInt8>()
            
            for _ in 0...size-1 {
                bytes.append(1)
            }
                
            
            let byteData = Data(bytes)
            if try interpreter?.input(at: 0).dataType == .uInt8 {
                return byteData
            }
            var floats = [Float]()
            for i in 0..<bytes.count {
                floats.append(Float(bytes[i]) / 255.0)
            }
            let floatsData = Data(buffer: UnsafeBufferPointer(start: &floats, count: size))
            return floatsData
        } catch {
            return nil
        }
    }
    
    func getListOfModels() -> [URL]? {
        do {
            let fileManager = FileManager.default
            let bundleURL = Bundle.main.bundleURL
            let assetURL = bundleURL.appendingPathComponent( modelVersion + ".bundle")
            let models = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)
            return models
          }
          catch {
              print(error.localizedDescription)
          }
        return nil
    }
    
    func setModelVersion(v: String) {
        self.modelVersion = v
    }
    
    func setDevice(d: Device) {
        self.currentDevice = d
    }
}

extension String {
    func getModelName(fileName: URL) -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
}
