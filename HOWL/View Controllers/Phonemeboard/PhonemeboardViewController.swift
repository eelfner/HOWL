//
//  PhonemeboardViewController.swift
//  HOWL
//
//  Created by Daniel Clelland on 14/11/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import UIKit
import MultitouchGestureRecognizer
import ProtonomeAudioKitControls

class PhonemeboardViewController: UIViewController {
    
    @IBOutlet weak var phonemeboardView: PhonemeboardView!
    
    @IBOutlet weak var multitouchGestureRecognizer: MultitouchGestureRecognizer! {
        didSet {
            multitouchGestureRecognizer.sustain = Settings.phonemeboardSustain.value
        }
    }
    
    @IBOutlet weak var flipButton: UIButton?
    
    @IBOutlet weak var holdButton: UIButton? {
        didSet {
            holdButton?.selected = Settings.phonemeboardSustain.value
        }
    }
    
    // MARK: - Overrides
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserverForName(Audio.didStartNotification, object: nil, queue: nil) { notification in
            self.reloadVocoder()
        }
    }
    
    // MARK: - Life cycle
    
    func reloadVocoder() {
        guard let location = locationForTouches(multitouchGestureRecognizer.touches) else {
            Audio.client.vocoder.stop()
            return
        }
        
        Audio.client.vocoder.start()
        Audio.client.vocoder.location = location
    }
    
    func stopVocoder() {
        Audio.client.vocoder.stop()
    }
    
    func reloadView() {
        phonemeboardView.highlighted = multitouchGestureRecognizer.multitouchState == .Live
        phonemeboardView.selected = multitouchGestureRecognizer.touches.isEmpty == false
    }
    
    // MARK: - Button events
    
    @IBAction func flipButtonTapped(button: UIButton) {
        flipViewController?.flip()
        
        if !Settings.phonemeboardSustain.value {
            stopVocoder()
            reloadView()
        }
    }
    
    @IBAction func holdButtonTapped(button: UIButton) {
        let sustain = !Settings.phonemeboardSustain.value
        
        holdButton?.selected = sustain
        Settings.phonemeboardSustain.value = sustain
        multitouchGestureRecognizer.sustain = sustain
    }
    
    // MARK: - Private Getters
    
    private func locationForTouches(touches: [UITouch]) -> CGPoint? {
        guard touches.count > 0 else {
            return nil
        }
        
        let location = touches.reduce(CGPointZero) { (location, touch) -> CGPoint in
            let touchLocation = touch.locationInView(phonemeboardView)
            
            return CGPoint(
                x: location.x + touchLocation.x / CGFloat(touches.count),
                y: location.y + touchLocation.y / CGFloat(touches.count)
            )
        }
        
        return location.clamp(rect: phonemeboardView.bounds).ilerp(rect: phonemeboardView.bounds)
    }
    
}

// MARK: - Multitouch gesture recognizer delegate

extension PhonemeboardViewController: MultitouchGestureRecognizerDelegate {
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidBegin touch: UITouch) {
        reloadVocoder()
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidMove touch: UITouch) {
        reloadVocoder()
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidCancel touch: UITouch) {
        reloadVocoder()
        reloadView()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidEnd touch: UITouch) {
        reloadVocoder()
        reloadView()
    }
    
}
