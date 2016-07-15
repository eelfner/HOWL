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
    
//    var inputAmplitude = AKInstrumentProperty(value: 0.0)
    
    var xIn = Persistent(value: 0.5, key: "vocoderXIn")
    var yIn = Persistent(value: 0.5, key: "vocoderYIn")
    
//    var xOut = AKInstrumentProperty(value: 0.5)
//    var yOut = AKInstrumentProperty(value: 0.5)
    
    var lfoXShape = Persistent(value: 0.25, key: "vocoderLfoXShape")
    
    var lfoXDepth = Persistent(value: 0.0, key: "vocoderLfoXDepth")
    
    var lfoXRate = Persistent(value: 0.0, key: "vocoderLfoXRate") {
        didSet {
            
        }
    }
    
    var lfoYShape = Persistent(value: 0.25, key: "vocoderLfoYShape")
    
    var lfoYDepth = Persistent(value: 0.0, key: "vocoderLfoYDepth")
    
    var lfoYRate = Persistent(value: 0.0, key: "vocoderLfoYRate") {
        didSet {
            setFormants(formants(atLocation: location))
        }
    }
    
    var formantsFrequency = Persistent(value: 1.0, key: "vocoderFormantsFrequency") {
        didSet {
            setFormants(formants(atLocation: location))
        }
    }
    
    var formantsBandwidth = Persistent(value: 1.0, key: "vocoderFormantsBandwidth") {
        didSet {
            setFormants(formants(atLocation: location))
        }
    }
    
    var location: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            setFormants(formants(atLocation: location))
        }
    }
    
    // MARK: - Nodes
    
    private let mixer: AKMixer
    
    private let lfoX: LFO
    private let lfoY: LFO
    
    private let formant1: ResonantFilter
    private let formant2: ResonantFilter
    private let formant3: ResonantFilter
    private let formant4: ResonantFilter
    
    enum Parameters: Int {
        case LFOXRate
    }
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        self.mixer = AKMixer(input)
        self.mixer.stop()
        
        self.lfoX = LFO(frequency: lfoXRate.value, amplitude: lfoXDepth.value)
        self.lfoY = LFO(frequency: lfoYRate.value, amplitude: lfoYDepth.value)
        
        self.formant1 = ResonantFilter(self.mixer)
        self.formant2 = ResonantFilter(self.formant1)
        self.formant3 = ResonantFilter(self.formant2)
        self.formant4 = ResonantFilter(self.formant3)
        
        let balance = AKBalancer(self.formant4, comparator: self.mixer)
        
        super.init()
        
        self.avAudioNode = balance.avAudioNode
        input.addConnectionPoint(self.mixer)
    }
    
    // MARK: - Setters
    
    private func setFormants(formants: [Formant]) {
        self.formant1.frequency = formants[0].frequency
        self.formant1.bandwidth = formants[0].bandwidth
        
        self.formant2.frequency = formants[1].frequency
        self.formant2.bandwidth = formants[1].bandwidth
        
        self.formant3.frequency = formants[2].frequency
        self.formant3.bandwidth = formants[2].bandwidth
        
        self.formant4.frequency = formants[3].frequency
        self.formant4.bandwidth = formants[3].bandwidth
    }
    
    // MARK: - Formant calculations
    
    private typealias Formant = (frequency: Double, bandwidth: Double)
    
    private let topLeftFrequencies = [844.0, 1656.0, 2437.0, 3704.0] // /æ/
    private let topRightFrequencies = [768.0, 1333.0, 2522.0, 3687.0] // /α/
    private let bottomLeftFrequencies = [324.0, 2985.0, 3329.0, 3807.0] // /i/
    private let bottomRightFrequencies = [378.0, 997.0, 2343.0, 3357.0] // /u/
    
    private func formants(atLocation location: CGPoint) -> [Formant] {
        let topFrequencies = zip(topLeftFrequencies, topRightFrequencies).map { topLeftFrequency, topRightFrequency in
            return Double(location.x).lerp(min: topLeftFrequency, max: topRightFrequency)
        }
        
        let bottomFrequencies = zip(bottomLeftFrequencies, bottomRightFrequencies).map { bottomLeftFrequency, bottomRightFrequency in
            return Double(location.x).lerp(min: bottomLeftFrequency, max: bottomRightFrequency)
        }
        
        let frequencies = zip(topFrequencies, bottomFrequencies).map { topFrequency, bottomFrequency in
            return Double(location.y).lerp(min: topFrequency, max: bottomFrequency)
        }
        
        return frequencies.map { frequency in
            let frequency = frequency * formantsFrequency.value
            let bandwidth = (frequency * 0.02 + 50.0) * formantsBandwidth.value
            return (frequency: frequency, bandwidth: bandwidth)
        }
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
