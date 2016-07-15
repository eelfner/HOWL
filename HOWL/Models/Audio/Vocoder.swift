//
//  Vocoder.swift
//  HOWL
//
//  Created by Daniel Clelland on 3/07/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit
import Lerp
import Persistable

class Vocoder: AKNode {
    
    // MARK: - Properties
    
    var xIn = Persistent(value: 0.5, key: "vocoderXIn") {
        didSet {
            filterBank[value: .XIn] = xIn.value
        }
    }
    
    var yIn = Persistent(value: 0.5, key: "vocoderYIn") {
        didSet {
            filterBank[value: .YIn] = yIn.value
        }
    }
    
//    var xOut = AKInstrumentProperty(value: 0.5)
//    var yOut = AKInstrumentProperty(value: 0.5)
    
    var lfoXShape = Persistent(value: 0.25, key: "vocoderLfoXShape") {
        didSet {
            filterBank[value: .LfoXShape] = lfoXShape.value
        }
    }
    
    var lfoXDepth = Persistent(value: 0.0, key: "vocoderLfoXDepth") {
        didSet {
            filterBank[value: .LfoXDepth] = lfoXDepth.value
        }
    }
    
    var lfoXRate = Persistent(value: 0.0, key: "vocoderLfoXRate") {
        didSet {
            filterBank[value: .LfoXRate] = lfoXRate.value
        }
    }
    
    var lfoYShape = Persistent(value: 0.25, key: "vocoderLfoYShape") {
        didSet {
            filterBank[value: .LfoXShape] = lfoXShape.value
        }
    }
    
    var lfoYDepth = Persistent(value: 0.0, key: "vocoderLfoYDepth") {
        didSet {
            filterBank[value: .LfoYDepth] = lfoYDepth.value
        }
    }
    
    var lfoYRate = Persistent(value: 0.0, key: "vocoderLfoYRate") {
        didSet {
            filterBank[value: .LfoYRate] = lfoYRate.value
        }
    }
    
    var formantsFrequency = Persistent(value: 1.0, key: "vocoderFormantsFrequency") {
        didSet {
            filterBank[value: .FormantsFrequency] = formantsFrequency.value
        }
    }
    
    var formantsBandwidth = Persistent(value: 1.0, key: "vocoderFormantsBandwidth") {
        didSet {
            filterBank[value: .FormantsBandwidth] = formantsBandwidth.value
        }
    }
    
    // MARK: Special properties
    
    var location: CGPoint {
        get {
            return CGPoint(x: xIn.value, y: yIn.value)
        }
        set {
            xIn.value = Double(newValue.x)
            yIn.value = Double(newValue.y)
        }
    }
    
    // MARK: - Nodes
    
    private let mixer: AKMixer
    
    private let filterBank: FilterBank
    
    private let balancer: AKBalancer
    
    enum Parameters: Int {
        case LFOXRate
    }
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        self.mixer = AKMixer(input)
        self.mixer.stop()
        
        self.filterBank = FilterBank(
            self.mixer,
            xIn: self.xIn.value,
            yIn: self.yIn.value,
            lfoXShape: self.lfoXShape.value,
            lfoXDepth: self.lfoXDepth.value,
            lfoXRate: self.lfoXRate.value,
            lfoYShape: self.lfoYShape.value,
            lfoYDepth: self.lfoYDepth.value,
            lfoYRate: self.lfoYRate.value,
            formantsFrequency: self.formantsFrequency.value,
            formantsBandwidth: self.formantsBandwidth.value
        )
        
        self.balancer = AKBalancer(self.filterBank, comparator: self.mixer)
        
        super.init()
        
        self.avAudioNode = self.balancer.avAudioNode
        input.addConnectionPoint(self.mixer)
    }

}

private class FilterBank: AKOperationEffect {
    
    enum Parameter: Int {
        case XIn
        case YIn
        case XOut
        case YOut
        case LfoXShape
        case LfoXDepth
        case LfoXRate
        case LfoYShape
        case LfoYDepth
        case LfoYRate
        case FormantsFrequency
        case FormantsBandwidth
    }

    convenience init(
        _ input: AKNode,
          xIn: Double,
          yIn: Double,
          lfoXShape: Double,
          lfoXDepth: Double,
          lfoXRate: Double,
          lfoYShape: Double,
          lfoYDepth: Double,
          lfoYRate: Double,
          formantsFrequency: Double,
          formantsBandwidth: Double
        ) {
        
        let xInParameter = AKOperation.parameters(Parameter.XIn.rawValue)
        let yInParameter = AKOperation.parameters(Parameter.YIn.rawValue)
        
        let xOutParameter = AKOperation.parameters(Parameter.XOut.rawValue)
        let yOutParameter = AKOperation.parameters(Parameter.YOut.rawValue)
        
        let lfoXShapeParameter = AKOperation.parameters(Parameter.LfoXShape.rawValue)
        let lfoXDepthParameter = AKOperation.parameters(Parameter.LfoXDepth.rawValue)
        let lfoXRateParameter = AKOperation.parameters(Parameter.LfoXRate.rawValue)
        
        let lfoYShapeParameter = AKOperation.parameters(Parameter.LfoYShape.rawValue)
        let lfoYDepthParameter = AKOperation.parameters(Parameter.LfoYDepth.rawValue)
        let lfoYRateParameter = AKOperation.parameters(Parameter.LfoYRate.rawValue)
        
        let formantsFrequencyParameter = AKOperation.parameters(Parameter.FormantsFrequency.rawValue) + 0.01
        let formantsBandwidthParameter = AKOperation.parameters(Parameter.FormantsBandwidth.rawValue) + 0.01
        
        let sporth =
        "((\(lfoXRateParameter) (\(lfoXDepthParameter) 0.5 *) sine) \(xInParameter) +) \(Parameter.XOut.rawValue) pset" ++
        "((\(lfoYRateParameter) (\(lfoYDepthParameter) 0.5 *) sine) \(yInParameter) +) \(Parameter.YOut.rawValue) pset" ++
        "" ++
        "'frequencies' 4 zeros" ++
        "" ++
        "(\(yOutParameter) (\(xOutParameter) 844.0 768.0 scale) (\(xOutParameter) 324.0 378.0 scale) scale) 0 'frequencies' tset" ++
        "(\(yOutParameter) (\(xOutParameter) 1656.0 1333.0 scale) (\(xOutParameter) 2985.0 997.0 scale) scale) 1 'frequencies' tset" ++
        "(\(yOutParameter) (\(xOutParameter) 2437.0 2522.0 scale) (\(xOutParameter) 3329.0 2343.0 scale) scale) 2 'frequencies' tset" ++
        "(\(yOutParameter) (\(xOutParameter) 3704.0 3687.0 scale) (\(xOutParameter) 3807.0 3357.0 scale) scale) 3 'frequencies' tset" ++
        "" ++
        "\(AKOperation.input)" ++
        "((0 'frequencies' tget) \(formantsFrequencyParameter) *) (((dup 0.02 *) 50.0 +) \(formantsBandwidthParameter) *) reson" ++
        "((1 'frequencies' tget) \(formantsFrequencyParameter) *) (((dup 0.02 *) 50.0 +) \(formantsBandwidthParameter) *) reson" ++
        "((2 'frequencies' tget) \(formantsFrequencyParameter) *) (((dup 0.02 *) 50.0 +) \(formantsBandwidthParameter) *) reson" ++
        "((3 'frequencies' tget) \(formantsFrequencyParameter) *) (((dup 0.02 *) 50.0 +) \(formantsBandwidthParameter) *) reson" ++
        "dup"

        self.init(input, sporth: sporth)
        self.parameters = [
            xIn,
            yIn,
            0.5,
            0.5,
            lfoXShape,
            lfoXDepth,
            lfoXRate,
            lfoYShape,
            lfoYDepth,
            lfoYRate,
            formantsFrequency,
            formantsBandwidth
        ]
    }
    
    subscript(value parameter: Parameter) -> Double {
        get {
            return parameters[parameter.rawValue]
        }
        set {
            parameters[parameter.rawValue] = newValue
        }
    }
    
}

infix operator ++ {
    associativity left
    precedence 140
}

private func ++ (left: String, right: String) -> String {
    return left + "\n" + right
}

extension AKOperation {
    
    /// This scales from 0 to 1 to a range defined by a minimum and maximum point in the input and output domain.
    ///
    /// - Parameters:
    ///   - minimum: Minimum value to scale to. (Default: 0)
    ///   - maximum: Maximum value to scale to. (Default: 1)
    ///
    public func lerp(
        minimum minimum: AKParameter = 0,
                maximum: AKParameter = 1
        ) -> AKOperation {
        return AKOperation("(\(self) \(minimum) \(maximum) scale)")
    }
    
}

private class LFO: AKOperationGenerator {
    
    private enum Parameters: Int {
        case Frequency
        case Amplitude
    }
    
    convenience init(frequency: Double = 10.0, amplitude: Double = 1.0) {
        self.init(operation: AKOperation.sineWave(
            frequency: AKOperation.parameters(Parameters.Frequency.rawValue),
            amplitude: AKOperation.parameters(Parameters.Amplitude.rawValue)
            )
        )
        self.parameters = [frequency, amplitude]
    }
    
    var frequency: Double {
        get {
            return parameters[Parameters.Frequency.rawValue]
        }
        set {
            parameters[Parameters.Frequency.rawValue] = newValue
        }
    }
    
    var amplitude: Double {
        get {
            return parameters[Parameters.Amplitude.rawValue]
        }
        set {
            parameters[Parameters.Amplitude.rawValue] = newValue
        }
    }
    
}

private class ResonantFilter: AKOperationEffect {
    
    private enum Parameters: Int {
        case Frequency
        case Bandwidth
    }
    
    convenience init(_ input: AKNode, frequency: Double = 1000.0, bandwidth: Double = 100.0) {
        self.init(input, operation: AKOperation.input.resonantFilter(
            frequency: AKOperation.parameters(Parameters.Frequency.rawValue),
            bandwidth: AKOperation.parameters(Parameters.Bandwidth.rawValue)
            )
        )
        self.parameters = [frequency, bandwidth]
    }
    
    var frequency: Double {
        get {
            return parameters[Parameters.Frequency.rawValue]
        }
        set {
            parameters[Parameters.Frequency.rawValue] = newValue
        }
    }
    
    var bandwidth: Double {
        get {
            return parameters[Parameters.Bandwidth.rawValue]
        }
        set {
            parameters[Parameters.Bandwidth.rawValue] = newValue
        }
    }
    
}

extension Vocoder: AKToggleable {
    
    var isStarted: Bool {
        return mixer.isStarted
    }
    
    func start() {
        mixer.start()
    }
    
    func stop() {
        mixer.stop()
    }
    
}
