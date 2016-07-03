//
//  Vocoder.swift
//  HOWL
//
//  Created by Daniel Clelland on 3/07/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit
import Persistable

class Vocoder: AKNode {
    
    let topLeftFrequencies: [Float] = [844, 1656, 2437, 3704] // /æ/
    let topRightFrequencies: [Float] = [768, 1333, 2522, 3687] // /α/
    let bottomLeftFrequencies: [Float] = [324, 2985, 3329, 3807] // /i/
    let bottomRightFrequencies: [Float] = [378, 997, 2343, 3357] // /u/
    
//    var amplitude = AKInstrumentProperty(value: 0.0)
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
    var lfoYRate = Persistent(value: 0.0, key: "vocoderLfoYRate")
    
    var formantsFrequency = Persistent(value: 1.0, key: "vocoderFormantsFrequency")
    var formantsBandwidth = Persistent(value: 1.0, key: "vocoderFormantsBandwidth")
    
    var enabled: Bool = false
    
    var location: CGPoint = CGPoint(x: 0.5, y: 0.5)
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        let mix = AKMixer(input, input)
        
        super.init()
        
        self.avAudioNode = mix.avAudioNode
        input.addConnectionPoint(self)
    }

}
