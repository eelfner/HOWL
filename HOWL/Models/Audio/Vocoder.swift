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
    
    private let formant1: AKOperationEffect
    private let formant2: AKOperationEffect
    private let formant3: AKOperationEffect
    private let formant4: AKOperationEffect
    
    enum Parameters: Int {
        case LFOXRate
    }
    
    enum Formant1Parameters: Int {
        case CutoffFrequency
    }
    
    enum Formant2Parameters: Int {
        case CutoffFrequency
    }
    
    enum Formant3Parameters: Int {
        case CutoffFrequency
    }
    
    enum Formant4Parameters: Int {
        case CutoffFrequency
    }
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        self.mixer = AKMixer(input)
        self.mixer.stop()
        
        let _ = AKOperation.sineWave(frequency: AKOperation.parameters(Parameters.LFOXRate.rawValue), amplitude: 500.0)
        
//        let filter = AKOperation.input.moogLadderFilter(cutoffFrequency: oscillator + 600.0, resonance: 0.5)
        
        let filter1 = AKOperation.input.moogLadderFilter(cutoffFrequency: AKOperation.parameters(Formant1Parameters.CutoffFrequency.rawValue), resonance: 0.75)
        let filter2 = AKOperation.input.moogLadderFilter(cutoffFrequency: AKOperation.parameters(Formant2Parameters.CutoffFrequency.rawValue), resonance: 0.75)
        let filter3 = AKOperation.input.moogLadderFilter(cutoffFrequency: AKOperation.parameters(Formant3Parameters.CutoffFrequency.rawValue), resonance: 0.75)
        let filter4 = AKOperation.input.moogLadderFilter(cutoffFrequency: AKOperation.parameters(Formant4Parameters.CutoffFrequency.rawValue), resonance: 0.75)
        
        self.formant1 = AKOperationEffect(self.mixer, operation: filter1)
        self.formant1.parameters = [844.0]
        
        self.formant2 = AKOperationEffect(self.formant1, operation: filter2)
        self.formant2.parameters = [1656.0]
        
        self.formant3 = AKOperationEffect(self.formant2, operation: filter3)
        self.formant3.parameters = [2437.0]
        
        self.formant4 = AKOperationEffect(self.formant3, operation: filter4)
        self.formant4.parameters = [3704.0]
        
        super.init()
        
        self.avAudioNode = self.formant4.avAudioNode
        input.addConnectionPoint(self.mixer)
    }
    
    // MARK: - Setters
    
    private func setFormants(formants: [Formant]) {
        self.formant1.parameters[Formant1Parameters.CutoffFrequency.rawValue] = formants[0].frequency
        self.formant2.parameters[Formant2Parameters.CutoffFrequency.rawValue] = formants[1].frequency
        self.formant3.parameters[Formant3Parameters.CutoffFrequency.rawValue] = formants[2].frequency
        self.formant4.parameters[Formant4Parameters.CutoffFrequency.rawValue] = formants[3].frequency
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
