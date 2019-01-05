//
//  File.swift
//  gadget_test_2
//
//  Created by Ray Ye on 2/1/18.
//  Copyright © 2018 Peter Lee. All rights reserved.
//

import Foundation
import SpriteKit

class Galaxy {
    var particles: [Int]
    
    var size: Int{
        return particles.count
    }
    
    var centerInSimCoordinates: (Float, Float, Float){
        var (cx, cy, cz) : (Float, Float, Float) = (0.0, 0.0, 0.0)
        for i in particles{
            let (px, py, _) = P[i].Pos
            cx += Float(px)
            cy += Float(py)
        }
        return (cx / Float(size), cy / Float(size), cz / Float(size))
    }
    
    var center: (CGFloat, CGFloat, CGFloat)
    
    var sizeClass: Int
    
    init(){
        particles = []
        sizeClass = 0
        center = (0.0, 0.0, 0.0)
        //spriteRotation = 0
    }
}
