//
//  Master.swift
//  HOWL
//
//  Created by Daniel Clelland on 3/07/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit
import Persistable

class Master: AKNode {
    
    // MARK: - Properties
    
    var effectsBitcrush = Persistent(value: 0.0, key: "masterEffectsBitcrush") {
        didSet {
            bitcrushMix.balance = effectsBitcrush.value
        }
    }
    
    var effectsReverb = Persistent(value: 0.0, key: "masterEffectsReverb") {
        didSet {
            reverbMix.balance = effectsReverb.value
        }
    }
    
    // MARK: - Nodes
    
    private let bitcrush: AKBitCrusher
    private let bitcrushMix: AKDryWetMixer
    
    private let reverb: AKCostelloReverb
    private let reverbMix: AKDryWetMixer
    
    // MARK: - Initialization
    
    init(withInput input: AKNode) {
        bitcrush = AKBitCrusher(input, bitDepth: 24.0, sampleRate: 4000.0)
        bitcrushMix = AKDryWetMixer(input, bitcrush, balance: effectsBitcrush.value)
        
        reverb = AKCostelloReverb(bitcrushMix, feedback: 0.75, cutoffFrequency: 16000.0)
        reverbMix = AKDryWetMixer(bitcrushMix, reverb, balance: effectsReverb.value)
        
        super.init()
        
        avAudioNode = reverbMix.avAudioNode
        input.addConnectionPoint(self)
    }
    
}
