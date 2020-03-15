//
//  TFLiteImageInterpreter.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import TensorFlowLite

struct TFLiteResult {
    // <#TODO#>
}

class TFLiteImageInterpreter {
    let interpreter: Interpreter
    
    init(options: Options) {
        guard let modelPath = Bundle.main.path(forResource: options.modelName, ofType: "tflite") else {
            fatalError("Failed to load the model file with name: \(options.modelName).")
        }
        
        // Specify the options for the `Interpreter`.
        var interpreterOptions = Interpreter.Options()
        interpreterOptions.threadCount = options.threadCount
        
        // Specify the delegates for the `Interpreter`.
        var delegates: [Delegate]?
        switch options.accelerator {
        case .metal:
            delegates = [MetalDelegate()]
        default:
            delegates = nil
        }
        
        guard let interpreter = try? Interpreter(modelPath: modelPath, options: interpreterOptions, delegates: delegates) else {
            fatalError("Failed to craete interpreter")
        }
        
        self.interpreter = interpreter
        
        do {
            try setupTensor(with: interpreter, options: options)
        } catch {
            fatalError("Failed to setup tensor: \(error.localizedDescription)")
        }
        
    }
    
    private func setupTensor(with interpreter: Interpreter, options: Options) throws {
        // Initialize input and output `Tensor`s.
        // Allocate memory for the model's input `Tensor`s.
        try interpreter.allocateTensors()
        
        // <#TODO#> - check input/output dimensions
        // <#TODO#> - check quantization or not
    }
    
    func preprocess(with pixelBuffer: CVPixelBuffer) -> Data? {
        // <#TODO#>
        return nil
    }
    
    func inference(with inputData: Data) -> TFLiteResult? {
        // <#TODO#>
        return nil
    }
}

extension TFLiteImageInterpreter {
    struct Options {
        let modelName: String
        let threadCount: Int
        let accelerator: Accelerator
        let isQuantized: Bool
        
        init(modelName: String, threadCount: Int = 1, accelerator: Accelerator = .metal, isQuantized: Bool = false) {
            self.modelName = modelName
            self.threadCount = threadCount
            self.accelerator = accelerator
            self.isQuantized = isQuantized
        }
    }
}

extension TFLiteImageInterpreter {
    enum Accelerator {
        case cpu
        case metal
    }
}

extension TFLiteImageInterpreter {
    struct ModelInput {
        static let batchSize = 1
        static let channel = 3 // rgb: 3, gray: 1
    }
}
