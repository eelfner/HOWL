//
//  Master.swift
//  HOWL
//
//  Created by Daniel Clelland on 3/07/16.
//  Copyright © 2016 Daniel Clelland. All rights reserved.
//

import AudioKit
import Persistable

class Master {
    
    var effectsBitcrush = Persistent(value: 0.0, key: "masterEffectsBitcrush")
    var effectsReverb = Persistent(value: 0.0, key: "masterEffectsReverb")
    
}
