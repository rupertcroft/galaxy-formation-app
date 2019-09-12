//
//  GameScene.swift
//  gadget_test_2
//
//  Created by Peter Lee on 9/20/15.
//  Copyright © 2015 Peter Lee. All rights reserved.
//
//  Modifications: adding colors and a chaining mesh
//  chaining mesh is used as a friend of friends to find galaxies clustered together
//  cuboid representation removed since it no longer needed when examining a slice
//

import Foundation
import SpriteKit
import AVFoundation

var audioPlayer: AVAudioPlayer!

let path = Bundle.main.path(forResource: "Sounds/254031__jagadamba__space-sound", ofType:"wav")!
let url = URL(fileURLWithPath: path)

//var musicPlayer: AVAudioPlayer!
//let musicPath = Bundle.main.path(forResource: "Sounds/DST-PhaserSwitch", ofType:"mp3")!
//let musicUrl = URL(fileURLWithPath: musicPath)
var initTime = Date().timeIntervalSinceReferenceDate

class TempGameScene: SKScene {
    /*
     Init:
     Init structures
     Init debug (separate for later deletion)
     
     Main Loop:
     0. Reset structures
     1. Fill temp structures
     2. Use BFS (maybe parallel) to find clusters
     3. Color and label clusters
     4. Draw screen
     */
    
    /* Useful Variables */
    //Structures
    
    //Adjustable Constants
    
    //Fixed Constants
    let galaxyFiles: [String] = [
        "",
        "galaxy1.png",
        "galaxy2.png",
        "galaxy3.png",
        "galaxy4.png",
        "galaxy5.png",
        "galaxy6.png"
    ]
    
    //Generators
    var randomColor : UIColor{
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
    }
    
    func pinched(_ sender: UIPinchGestureRecognizer) {
    }
    
    func shifted(_ sender: UIPanGestureRecognizer) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    func updateTouchLocation(_ touches: Set<NSObject>) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    /*---Update Loop---*/
    /*---Set Point Positions---*/
    
    func transformHelper(coord: CGFloat) -> CGFloat {
        let temp = Double(coord) / All.BoxSize
        let res = CGFloat(temp) * zoomScale
        return res
    }
    
    /* Transforms point from sim space to game space, offset included
     */
    func transformArr(pos: [CGFloat]) -> [CGFloat] {
        var res = pos.map(transformHelper)
        res[0] += xOffset
        res[1] += yOffset
        return res
    }
    
    func transform(pos: (x: Float, y: Float, z: Float)) -> (CGFloat, CGFloat, CGFloat) {
        let arrpos = [pos.x, pos.y, pos.z]
        func mapPos(f: Float) -> CGFloat{ return CGFloat(f) }
        var tpos = arrpos.map(mapPos)
        tpos = transformArr(pos: tpos)
        return (tpos[0], tpos[1], tpos[2])
    }
    
    func particlePositions(i: Int) -> (CGFloat, CGFloat, CGFloat){
        var (px, py, pz) = P[i + 1].Pos
        var pos = [px, py, pz]
        func mapPos(f: Float) -> CGFloat{ return CGFloat(f) }
        var tpos = pos.map(mapPos)
        tpos = transformArr(pos: tpos)
        return (tpos[0], tpos[1], tpos[2])
    }
    
    func setPositions(){
        for i in 0 ..< totalParticles{
            let (x, y, z) = particlePositions(i: i)
            let point = points[i]
            point.position = CGPoint(x: x, y: y)
            point.zPosition = z
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
    
    // cuboid tranform wrapper function
    func transform(_ pos: (x: CGFloat, y: CGFloat, z: CGFloat), index i: Int) -> (CGFloat, CGFloat, CGFloat) {
        // change into coordinates in the unit cube
        let x = Double(pos.x) / All.BoxSize
        let y = Double(pos.y) / All.BoxSize
        let z = Double(pos.z) / All.BoxSize
        
        // transform
        //let prevCellIdx = self.prevCells[i]
        //let result = C.transform(x: x, y: y, z: z, prevCell: prevCellIdx)
        //self.prevCells[i] = result.cell
        
        // test scaling and shifting
        var x1 = CGFloat(x) * self.zoomScale //CGFloat(result.pos.x) * self.zoomScale
        var y1 = CGFloat(y) * self.zoomScale //CGFloat(result.pos.y) * self.zoomScale
        let z1 = CGFloat(z) * self.zoomScale //CGFloat(result.pos.z) * self.zoomScale
        x1 += self.xOffset
        y1 += self.yOffset
        
        return (x1, y1, z1)
    }
    
    // cuboid inverse transform wrapper function
    func inverseTransform(_ pos: (x: CGFloat, y: CGFloat, z: CGFloat)) -> (CGFloat, CGFloat, CGFloat) {
        // undo scaling and shifting
        let scale = Double(self.zoomScale)
        var x1 = Double(pos.x - self.xOffset)
        var y1 = Double(pos.y - self.yOffset)
        var z1 = Double(pos.z)
        x1 /= scale
        y1 /= scale
        z1 /= scale
        
        //let result: (x: Double, y: Double, z: Double) = C.inverseTransform(x: x1, y: y1, z: z1)
        
        let x2 = CGFloat(x1 * All.BoxSize) //CGFloat(result.x * All.BoxSize)
        let y2 = CGFloat(y1 * All.BoxSize) //CGFloat(result.y * All.BoxSize)
        let z2 = CGFloat(z1 * All.BoxSize) //CGFloat(result.z * All.BoxSize)
        
        return (x2, y2, z2)
    }
    
    func newGalaxy(sizeClass: Int) -> SKSpriteNode {
        let galaxyImg = SKSpriteNode(imageNamed: galaxyFiles[sizeClass])
        galaxyImg.size = galaxySizes[sizeClass]
        galaxySprites[sizeClass].append(galaxyImg)
        addChild(galaxyImg)
        galaxyImg.isHidden = true
        return galaxyImg
    }
    
    func getGalaxy(sizeClass: Int) -> SKSpriteNode {
        let classGalaxyImages = galaxySprites[sizeClass]
        for galaxySprite in classGalaxyImages{
            if galaxySprite.isHidden {
                return galaxySprite
            }
        }
        return newGalaxy(sizeClass: sizeClass)
    }
    
    func drawGalaxy(galaxy: Galaxy){
        if galaxy.sizeClass == 0{
            return
        }
        let galaxySprite = getGalaxy(sizeClass: galaxy.sizeClass)
        let (gx, gy, _) = galaxy.center
        galaxySprite.isHidden = false
        galaxySprite.position = CGPoint(x: gx, y: gy)
        galaxySprite.zPosition = points[points.count - 1].zPosition
    }
}
