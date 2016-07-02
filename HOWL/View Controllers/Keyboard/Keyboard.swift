//
//  Keyboard.swift
//  HOWL
//
//  Created by Daniel Clelland on 15/11/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import UIKit
import Bezzy
import Parity

class Keyboard {
    
    var width: Int
    var height: Int
    
    var leftInterval: Int
    var rightInterval: Int
    
    var centerPitch: Pitch = 48
    
    init(width: Int, height: Int, leftInterval: Int, rightInterval: Int) {
        self.width = width
        self.height = height
        self.leftInterval = leftInterval
        self.rightInterval = rightInterval
    }
    
    // MARK: - Counts
    
    func numberOfRows() -> Int {
        return height * 2 + 1
    }
    
    func numberOfKeysInRow(row: Int) -> Int {
        return self.row(isOffset: row) ? width : height + 1
    }
    
    // MARK: - Keys
    
    func key(atIndex index: Int, inRow row: Int) -> Key? {
        if let coordinates = self.coordinates(forIndex: index, inRow: row) {
            let pitch = self.pitch(forCoordinates: coordinates)
            let path = self.path(forCoordinates: coordinates)
            
            return Key(withPitch: pitch, path: path, coordinates: coordinates)
        }
        
        return nil
    }
    
    func key(atLocation location: CGPoint) -> Key? {
        for row in 0..<numberOfRows() {
            for index in 0..<numberOfKeysInRow(row) {
                if let key = key(atIndex: index, inRow: row) where key.path.containsPoint(location) {
                    return key
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Keyboard coordinates
    
    private func coordinates(forIndex index: Int, inRow row: Int) -> KeyCoordinates? {
        if row >= numberOfRows() || index >= numberOfKeysInRow(row) {
            return nil
        }
        
        let x = self.row(isOffset: row) ? index * 2 + 1 : index * 2
        let y = row
        
        let verticalOffset = height - y
        let horizontalOffset = width - x
        
        let left = Float(verticalOffset + horizontalOffset) / 2
        let right = Float(verticalOffset - horizontalOffset) / 2
        
        return KeyCoordinates(left: Int(left), right: Int(right))
    }
    
    private func row(isOffset row: Int) -> Bool {
        if width.parity == height.parity {
            return row.isOdd
        } else {
            return row.isEven
        }
    }
    
    // MARK: - Transforms
    
    private func pitch(forCoordinates coordinates: KeyCoordinates) -> Pitch {
        return Pitch(number: centerPitch.number + coordinates.left * leftInterval + coordinates.right * rightInterval)
    }
    
    private func path(forCoordinates coordinates: KeyCoordinates) -> UIBezierPath {
        let location = self.location(forCoordinates: coordinates)
        
        let horizontalKeyRadius = 1.0 / CGFloat(width) / 2.0
        let verticalKeyRadius = 1.0 / CGFloat(height) / 2.0
        
        return UIBezierPath.makePath { make in
            make.move(x: location.x, y: location.y - verticalKeyRadius)
            make.line(x: location.x + horizontalKeyRadius, y: location.y)
            make.line(x: location.x, y: location.y + verticalKeyRadius)
            make.line(x: location.x - horizontalKeyRadius, y: location.y)
            make.closed()
        }
    }
    
    private func location(forCoordinates coordinates: KeyCoordinates) -> CGPoint {
        let horizontalKeyRadius = 1.0 / CGFloat(width) / 2.0
        let verticalKeyRadius = 1.0 / CGFloat(height) / 2.0
        
        let leftDifference = CGVector(
            dx: -horizontalKeyRadius * CGFloat(coordinates.left),
            dy: -verticalKeyRadius * CGFloat(coordinates.left)
        )
        
        let rightDifference = CGVector(
            dx: horizontalKeyRadius * CGFloat(coordinates.right),
            dy: -verticalKeyRadius * CGFloat(coordinates.right)
        )
        
        return CGPoint(
            x: 0.5 + leftDifference.dx + rightDifference.dx,
            y: 0.5 + leftDifference.dy + rightDifference.dy
        )
    }
}
