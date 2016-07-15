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
    
    let synthesizer: Synthesizer
    let vocoder: Vocoder
    let master: Master
    
    init() {
        self.synthesizer = Synthesizer()
        
        let oscillator = AKOscillator(waveform: AKTable(.Sawtooth, size: 2048))
        oscillator.amplitude = 0.25
        oscillator.frequency = 120.0
        oscillator.start()
        
        self.vocoder = Vocoder(withInput: oscillator)
        self.master = Master(withInput: self.vocoder)
        
        AudioKit.output = self.master
    }
    
    static let didStartNotification = "AudioDidStartNotification"
    
    func start() {
        AudioKit.start()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Audio.didStartNotification, object: nil, userInfo: nil)
    }
    
    static let didStopNotification = "AudioDidStartNotification"
    
    func stop() {
        AudioKit.stop()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Audio.didStopNotification, object: nil, userInfo: nil)
    }
    
}
