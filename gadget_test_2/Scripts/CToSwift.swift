//
//  CToSwift.swift
//  gadget_test_2
//
//  Created by Ray Ye on 7/18/18.
//  Copyright © 2018 Peter Lee. All rights reserved.
//

import Foundation

var isPaused: Bool {
    set {
        if newValue{
            gamePause = 1
        }
        else{
            gamePause = 0
        }
    }
    get {
        return gamePause == 1
    }
}

var isPlaying: Bool {
    set {
        if newValue{
            playing = 1
        }
        else{
            playing = 0
        }
    }
    get {
        return playing == 1
    }
}

var particlesAreOn: Bool = true

var galaxiesAreOn: Bool = true

var totalParticles: Int {
    return Int(All.TotNumPart)
}

var simDim: Float {
    return Float(All.BoxSize)
}
