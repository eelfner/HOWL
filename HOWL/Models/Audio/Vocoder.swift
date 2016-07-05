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

class Vocoder: AKOperationEffect {
    
    // MARK: - Properties
    
//    var inputAmplitude = AKInstrumentProperty(value: 0.0)
    
    var xIn = Persistent(value: 0.5, key: "vocoderXIn")
    var yIn = Persistent(value: 0.5, key: "vocoderYIn")
    
//    var xOut = AKInstrumentProperty(value: 0.5)
//    var yOut = AKInstrumentProperty(value: 0.5)
    
    var lfoXShape = Persistent(value: 0.25, key: "vocoderLfoXShape")
    
    var lfoXDepth = Persistent(value: 0.0, key: "vocoderLfoXDepth")
    
    var lfoXRate = Persistent(value: 0.0, key: "vocoderLfoXRate")
    
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
    
//    private let mixer: AKMixer
    
    
    
    
//
//    private let filter1: AKOperationEffect
//    private let filter2: AKOperationEffect
//    private let filter3: AKOperationEffect
//    private let filter4: AKOperationEffect
    
    // MARK: - Initialization
    
    
    
    convenience init(withInput input: AKNode) {
//        self.mixer = AKMixer(input)
//        self.mixer.stop()
        
        let oscillator = AKOperation.sineWave(frequency: 0.5, amplitude: 1000.0)
        
        let filter = AKOperation.input.lowPassButterworthFilter(cutoffFrequency: oscillator)
        
//        self.lfoX = AKOperation.sineWave(frequency: self.lfoXRate.value).scale(minimum: -0.5, maximum: 0.5)
//        self.lfoY = AKOperation.sineWave(frequency: self.lfoYRate.value).scale(minimum: -0.5, maximum: 0.5)

//        self.filter1 = AKOperation.input.modalResonanceFilter(frequency: 324.0 * self.lfoX, qualityFactor: 50.0)
//        self.filter2 = AKOperation.input.modalResonanceFilter(frequency: 2985.0 * self.lfoX, qualityFactor: 50.0)
//        self.filter3 = AKOperation.input.modalResonanceFilter(frequency: 3329.0 * self.lfoX, qualityFactor: 50.0)
//        self.filter4 = AKOperation.input.modalResonanceFilter(frequency: 3807.0 * self.lfoX, qualityFactor: 50.0)
//
//        let effect1 = AKOperationEffect(self.mixer, operation: self.filter1)
//        let effect2 = AKOperationEffect(effect1, operation: self.filter2)
//        let effect3 = AKOperationEffect(effect2, operation: self.filter3)
//        let effect4 = AKOperationEffect(effect3, operation: self.filter4)
        
//        self.filter1 = AKLowPassFilter(self.mixer, cutoffFrequency: 378.0, resonance: 40.0)
//        self.filter2 = AKLowPassFilter(self.filter1, cutoffFrequency: 997.0, resonance: 40.0)
//        self.filter3 = AKLowPassFilter(self.filter2, cutoffFrequency: 2343.0, resonance: 40.0)
//        self.filter4 = AKLowPassFilter(self.filter3, cutoffFrequency: 3357.0, resonance: 40.0)
        
//        self.filter1.start()
//        self.filter2.start()
//        self.filter3.start()
//        self.filter4.start()
        
        self.init(input, operation: filter)
        
//        super.init(input, operation: filter)
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

//extension Vocoder: AKToggleable {
//    
//    var isStarted: Bool {
//        return mixer.isStarted
//    }
//    
//    func start() {
//        mixer.start()
//    }
//    
//    func stop() {
//        mixer.stop()
//    }
//    
//}
