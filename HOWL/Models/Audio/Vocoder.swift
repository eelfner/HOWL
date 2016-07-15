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
        
        let topLeftFrequencies = [844.0, 1656.0, 2437.0, 3704.0] // /æ/
        let topRightFrequencies = [768.0, 1333.0, 2522.0, 3687.0] // /α/
        let bottomLeftFrequencies = [324.0, 2985.0, 3329.0, 3807.0] // /i/
        let bottomRightFrequencies = [378.0, 997.0, 2343.0, 3357.0] // /u/
        
        let xInParameter = AKOperation.parameters(Parameter.XIn.rawValue)
        let yInParameter = AKOperation.parameters(Parameter.YIn.rawValue)
        
//        let lfoXShapeParameter = AKOperation.parameters(Parameter.LfoXShape.rawValue)
//        let lfoXDepthParameter = AKOperation.parameters(Parameter.LfoXDepth.rawValue)
//        let lfoXRateParameter = AKOperation.parameters(Parameter.LfoXRate.rawValue)
//        
//        let lfoYShapeParameter = AKOperation.parameters(Parameter.LfoYShape.rawValue)
//        let lfoYDepthParameter = AKOperation.parameters(Parameter.LfoYDepth.rawValue)
//        let lfoYRateParameter = AKOperation.parameters(Parameter.LfoYRate.rawValue)
        
        let formantsFrequencyParameter = AKOperation.parameters(Parameter.FormantsFrequency.rawValue) + 0.01
        let formantsBandwidthParameter = AKOperation.parameters(Parameter.FormantsBandwidth.rawValue) + 0.01
        
//        let lfoX = AKOperation.sineWave(frequency: lfoXRateParameter, amplitude: lfoXDepthParameter).scale(minimum: 0.0, maximum: 1.0)
//        let lfoY = AKOperation.sineWave(frequency: lfoYRateParameter, amplitude: lfoYDepthParameter).scale(minimum: 0.0, maximum: 1.0)
        
        let topFrequencies = zip(topLeftFrequencies, topRightFrequencies).map { topLeftFrequency, topRightFrequency in
            return xInParameter * (topRightFrequency - topLeftFrequency) + topLeftFrequency
        }
        
        let bottomFrequencies = zip(bottomLeftFrequencies, bottomRightFrequencies).map { bottomLeftFrequency, bottomRightFrequency in
            return xInParameter * (bottomRightFrequency - bottomLeftFrequency) + bottomLeftFrequency
        }
        
        let frequencies = zip(topFrequencies, bottomFrequencies).map { topFrequency, bottomFrequency in
            return formantsBandwidthParameter * (yInParameter * (bottomFrequency - topFrequency) + topFrequency)
        }
        
        let bandwidths = frequencies.map { frequency in
            return formantsFrequencyParameter * (frequency * 0.02 + 50.0)
        }
        
        let filters = zip(frequencies, bandwidths).reduce(AKOperation.input) { input, parameters in
            let (frequency, bandwidth) = parameters
            return input.resonantFilter(frequency: frequency, bandwidth: bandwidth)
        }
        
//        let filter = AKOperation.input.resonantFilter(frequency: 1000.0, bandwidth: 100.0).resonantFilter(frequency: 2000.0, bandwidth: 200.0).resonantFilter(frequency: 3000.0, bandwidth: 300.0).resonantFilter(frequency: 4000.0, bandwidth: 400.0)
        
        self.init(input, operation: filters)
        self.parameters = [
            xIn,
            yIn,
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
