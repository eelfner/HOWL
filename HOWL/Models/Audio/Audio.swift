//
//  Audio.swift
//  HOWL
//
//  Created by Daniel Clelland on 3/07/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit

class Audio {
    
    static let client = Audio()
    
    let oscillator: AKOscillator
    
    let synthesizer = Synthesizer()
    let vocoder = Vocoder()
    let master = Master()
    
    init() {
        self.oscillator = AKOscillator(waveform: AKTable(.Triangle, size: 2048))
        self.oscillator.amplitude = 1.0
        self.oscillator.frequency = 256.0
        
        AudioKit.output = oscillator
    }
    
    static let didStartNotification = "AudioDidStartNotification"
    
    func start() {
        AudioKit.start()
        
        oscillator.start()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Audio.didStartNotification, object: nil, userInfo: nil)
    }
    
    static let didStopNotification = "AudioDidStartNotification"
    
    func stop() {
        oscillator.stop()
        
        AudioKit.stop()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Audio.didStopNotification, object: nil, userInfo: nil)
    }
    
}
