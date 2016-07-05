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
            effect.parameters[0] = lfoXRate.value
        }
    }
    
    var lfoYShape = Persistent(value: 0.25, key: "vocoderLfoYShape")
    
    var lfoYDepth = Persistent(value: 0.0, key: "vocoderLfoYDepth")
    
    var lfoYRate = Persistent(value: 0.0, key: "vocoderLfoYRate") {
        didSet {
            print(formants(atLocation: location))
        }
    }
    
    var formantsFrequency = Persistent(value: 1.0, key: "vocoderFormantsFrequency") {
        didSet {
            print(formants(atLocation: location))
        }
    }
    
    var formantsBandwidth = Persistent(value: 1.0, key: "vocoderFormantsBandwidth") {
        didSet {
            print(formants(atLocation: location))
        }
    }
    
    var location: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            print(formants(atLocation: location))
        }
    }
    
    // MARK: - Nodes
    
    private let mixer: AKMixer
    
    private let effect: AKOperationEffect
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        self.mixer = AKMixer(input)
        self.mixer.stop()
        
        let oscillator = AKOperation.sineWave(frequency: AKOperation.parameters(0), amplitude: 1000.0)
        
        let filter = AKOperation.input.lowPassButterworthFilter(cutoffFrequency: oscillator)
        
        self.effect = AKOperationEffect(self.mixer, operation: filter)
        self.effect.parameters = [0.0]
        
        super.init()
        
        self.avAudioNode = self.effect.avAudioNode
        input.addConnectionPoint(self.mixer)
    }
    
    // MARK: - Setters
    
    private func setFormants(formants: [Formant]) {
        
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
