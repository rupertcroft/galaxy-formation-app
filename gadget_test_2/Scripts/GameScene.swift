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

class GameScene: SKScene {
    
    /*---Old Variables---*/
    //var points: [SKSpriteNode] // marks the location of particles
    var galaxySprite: [SKSpriteNode]
    
    var timeCounter: Int
    var touchTracker: SKShapeNode // tracks touch location for interaction
    //var accelLabel: SKLabelNode // displays acceleration used for interaction
    //var galaxyCounter: SKLabelNode // displays the number of galaxies
    //var highScore: SKLabelNode
    var prevPinchScale: CGFloat = 1.0
    
    //var chainMesh: [[[Int]]]
    var cellSize: Int = 500

    let dimrate : CGFloat = 0.001
    let cgepsilon : CGFloat = 0.00000001
    var clearlevel : CGFloat = 1
    //colors were retrieved from the following website http://cloford.com/resources/colours/500col.htm
    
        var vertices: [(x: CGFloat, y: CGFloat, z: CGFloat)] = [
            (0.0, 0.0, 0.0),
            (1.0, 0.0, 0.0),
            (0.0, 1.0, 0.0),
            (0.0, 0.0, 1.0),
            (0.0, 1.0, 1.0),
            (1.0, 0.0, 1.0),
            (1.0, 1.0, 0.0),
            (1.0, 1.0, 1.0)
        ]
    
    var minZ: CGFloat = CGFloat.greatestFiniteMagnitude
    var maxZ: CGFloat = CGFloat.leastNormalMagnitude
    
    /*---Constants---*/
    let galaxySizes: [CGSize] = [
        CGSize(width: 60.0, height: 50.0),
        CGSize(width: 60.0, height: 60.0),
        CGSize(width: 120.0, height: 120.0),
        CGSize(width: 180.0, height: 180.0),
        CGSize(width: 240.0, height: 240.0),
        CGSize(width: 300.0, height: 300.0),
        CGSize(width: 360.0, height: 360.0)
    ]
    let defaultColor: UIColor = UIColor.cyan
    let pointSize: CGSize = CGSize(width: 2.0, height: 2.0)
    let xOffset: CGFloat = 200
    let yOffset: CGFloat = 0
    let minDist: Float = 1750//250
    let cellDim: Float
    
    /*---Variables---*/
    var galaxySprites: [[SKSpriteNode]]
    var tempScoreCounter: Int
    var points: [SKSpriteNode]
    var zoomScale: CGFloat
    var gridCells: [[[Int]]]
    var gridDim: Int{
        return Int(simDim / cellDim)
    }
    var unionFindContainer: [(Int,[Int])] //Points to parent
    var isParticleInGraphArray: [Bool]
    var naiveGalaxies: [[Int]]
    var galaxyData: [Galaxy]
    
    /*---Old Init---*/
    override init(size: CGSize) {
        /*---New inits---*/
        points = []
        tempScoreCounter = 0
        cellDim = 2 * minDist
        zoomScale = min(size.width, size.height)
        unionFindContainer = [(Int,[Int])](repeating: (0, []), count: totalParticles + 1)
        isParticleInGraphArray = [Bool](repeating: false, count: totalParticles + 1)
        isParticleInGraphArray[0] = true //account for one indexing
        naiveGalaxies = []
        gridCells = []
        galaxyData = []
        galaxySprites = [[SKSpriteNode]](repeating: [], count: bounds.count + 1)
        
        
        let sound = try! AVAudioPlayer(contentsOf: url)
        audioPlayer = sound
        //let music = try! AVAudioPlayer(contentsOf: musicUrl)
        //musicPlayer = music
        //music.play();
        //music.numberOfLoops = -1
        //clusterLevel = 0;
        // initialize
        self.galaxySprite = []
        initTime = Date().timeIntervalSinceReferenceDate
            //self.equivClass[i+1] = (i + 1,false)
        //}
        //P[1].Vel=(0,0,0)
        //P[1].VelPred=(0,0,0);
        self.timeCounter = 0
        
        self.touchTracker = SKShapeNode(circleOfRadius: 20.0)
        self.touchTracker.fillColor = UIColor.white
        self.touchTracker.strokeColor = UIColor.clear
        
        /*self.accelLabel = SKLabelNode(text: "TESZTETSETSDKVADFBDND")
        self.accelLabel.color = UIColor.white
        
        self.galaxyCounter = SKLabelNode(text: "NUMBER OF GALAXIES:")
        self.galaxyCounter.color = UIColor.white
        
        self.highScore = SKLabelNode(text: "Hiscore")
        self.highScore.color = UIColor.white
        */
        //self.chainMesh = [[[Int]]](repeating: [[Int]](repeating: [Int](), count: Int(All.BoxSize)/self.cellSize), count: Int(All.BoxSize)/self.cellSize)
        
        // finalize
        super.init(size: size)
        setupGridCells()
        setupPoints()
        
        //add touch tracker
        self.addChild(self.touchTracker)
        /*
        self.accelLabel.position = CGPoint(x: self.frame.width / 2.0, y: self.frame.height - 100.0)
        self.galaxyCounter.position = CGPoint(x: self.frame.width - 70.0 , y: self.frame.height - 100.0)
        self.highScore.position = CGPoint(x: self.frame.width + 70.0 , y: self.frame.height - 100.0)
        self.addChild(self.accelLabel)
        self.addChild(self.galaxyCounter)
        self.addChild(self.highScore)
        */
        //add points and galaxy
    }
    
    /*---New Init---*/
    func setupPoints(){
        for _ in 0 ..< totalParticles{
            let point = SKSpriteNode(color: defaultColor, size: pointSize)
            points.append(point)
            addChild(point)
        }
    }
    
    func simToGrid(coord : Float) -> Int {
        if coord < 0 || coord.isNaN || coord > simDim{
            return 0
        }
        var res = Int(coord) % Int(simDim)
        if res < 0 {
            res = Int(simDim) + res
        }
        res /= Int(cellDim)
        return res % gridCells.count
    }
    
    func setupGridCells() {
        gridCells = [[[Int]]](repeating: [[Int]](repeating: [Int](), count: gridDim), count: gridDim)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        
        // set boundaries for color scale when using cuboid transform
        let vs = self.vertices.map({ v in self.transform(v, index: 0) })
        let zs = vs.map({ (x, y, z) -> CGFloat in
            return z
        })
        self.minZ = zs.reduce(CGFloat.greatestFiniteMagnitude, { (z1, z2) -> CGFloat in
            return min(z1, z2)
        })
        self.maxZ = zs.reduce(CGFloat.leastNormalMagnitude, { (z1, z2) -> CGFloat in
            return max(z1, z2)
        })
        
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.addTarget(self, action: #selector(GameScene.pinched(_:)))
        self.view?.addGestureRecognizer(pinchGesture)
        
        let shiftGesture = UIPanGestureRecognizer()
        shiftGesture.minimumNumberOfTouches = 2
        shiftGesture.addTarget(self, action: #selector(GameScene.shifted(_:)))
        self.view?.addGestureRecognizer(shiftGesture)
        
    }
    
    // handles pinch gesture
    func pinched(_ sender: UIPinchGestureRecognizer) {
        /*
        // set scale and transform
        let pinchScale = sender.scale
        sender.scale = 1
        
        if (sender.state == UIGestureRecognizerState.Ended) {
            self.prevPinchScale = 1.0
        }
        
        // modify scale value
        self.zoomScale *= pinchScale */
    }
    
    // handles shift gesture
    func shifted(_ sender: UIPanGestureRecognizer) {
        /*
        // get shift direction
        let vel = sender.velocityInView(self.view)
        let shiftScale: CGFloat = 10.0
        let (velX, velY) = (vel.x / shiftScale, vel.y / shiftScale)
        
        // modify shift value
        // note that UIView y-coordinates are opposite from Sprite Kit
        self.xShiftOffset += velX
        self.yShiftOffset -= velY */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        if (touches.count == 1) {
            // start particle interaction
            //            println("touches began")
            interaction = 1
            accelerationFactor = 1000000.0 * interactionFactor;
            P[1].Mass = accelerationFactor;
            self.updateTouchLocation(touches)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (touches.count == 1) {
            // update touch location for particle interaction
            //            println("touches moved, interaction: \(interaction)")
            //interaction = 0
            self.updateTouchLocation(touches)
            //interaction = 1
        }
    }
    
    func updateTouchLocation(_ touches: Set<NSObject>) {
        // inverse transfrom the touch location to the actual simulation
        // coordinates and update them
        if (touches.count < 1) {
            return
        }
        
        let touch: UITouch = touches.first as! UITouch
        let location = touch.location(in: self)
        
        let x = location.x
        let y = location.y
        let z = CGFloat(0) //(self.minZ + self.maxZ) / 2.0
        
        let result = self.inverseTransform((x, y, z))
        
        touchLocation.0 = Float(result.0)
        touchLocation.1 = Float(result.1)
        touchLocation.2 = Float(result.2)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // stop particle interaction
        //        println("touches ended")
        interaction = 0;
        P[1].Mass = 0;
        P[1].Vel=(0,0,0);
        P[1].VelPred=(0,0,0);
        P[1].Accel = (0,0,0);
    }
    
    /*---Update Loop---*/
    /*---Set Point Positions---*/
    
    /* Helper for the transform function, transforms from simulation space to
     game space for a single coordinate
     */
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
    
    /* For a point, returns the game space location of the point
     */
    func particlePositions(i: Int) -> (CGFloat, CGFloat, CGFloat){
        var (px, py, pz) = P[i + 1].Pos
        var pos = [px, py, pz]
        func mapPos(f: Float) -> CGFloat{ return CGFloat(f) }
        var tpos = pos.map(mapPos)
        tpos = transformArr(pos: tpos)
        return (tpos[0], tpos[1], tpos[2])
    }
    
    /* Sets all the positions for the points on the game screen
     */
    func setPositions(){
        for i in 0 ..< totalParticles{
            let (x, y, z) = particlePositions(i: i)
            let point = points[i]
            point.position = CGPoint(x: x, y: y)
            point.zPosition = z
        }
    }
    
    /*---Grouping Functions---*/
    
    func getGroupings() {
        setupInGraphArray()
        fillGridCells()
        setupUFContainer()
        resetNaiveGalaxies()
        resetVisited()
        
        iterThroughGrid()
        
        parseGalaxyData()
    }
    
    func setupInGraphArray() {
        func resetMap(in: Bool) -> Bool { return false }
        isParticleInGraphArray = isParticleInGraphArray.map(resetMap)
        isParticleInGraphArray[0] = true
    }
    
    func isFinished() {
        func checkReduce(acc: Bool, next: Bool) -> Bool { return acc && next }
        if isParticleInGraphArray.reduce(true, checkReduce) {
            print("Successful grouping")
        }
        else{
            print("There was an error in the grouping algo")
        }
    }
    
    func fillGridCells() {
        //print("(" + String(gridCells.count) + "," + String(gridCells[0].count) + ")")
        for i in 1 ..< totalParticles + 1{
            let (x, y, _) = P[i].Pos
            let (xGridCoord, yGridCoord) = (simToGrid(coord: x), simToGrid(coord: y))
            //print("(" + String(xGridCoord) + "," + String(yGridCoord) + ")")
            gridCells[xGridCoord][yGridCoord].append(i)
        }
    }
    
    /* Setup ufcontainer with pointers to self
     */
    func setupUFContainer() {
        for i in 1 ..< totalParticles + 1{
            unionFindContainer[i] = (i, [])
        }
    }
    
    func eraseGridCells(){
        for x in 0 ..< gridDim{
            for y in 0 ..< gridDim{
                gridCells[x][y] = [Int]()
            }
        }
    }
    
    func wasVisited(index: Int) -> Bool {
        return isParticleInGraphArray[index]
    }
    
    func markVisited(index: Int){
        isParticleInGraphArray[index] = true
    }
    
    func resetVisited(){
        func resetFn(notUsed: Bool) -> Bool { return false }
        isParticleInGraphArray = isParticleInGraphArray.map(resetFn)
        isParticleInGraphArray[0] = true //account for one indexing
    }
    
    func distByIndex(to: Int, from: Int) -> Float {
        let (tx, ty, _) = P[to].Pos
        let (fx, fy, _) = P[from].Pos
        let (dx, dy) = (tx - fx, ty - fy)
        let (sqx, sqy) = (dx * dx, dy * dy)
        let dist = sqrt(sqx + sqy)
        return dist
    }
    
    func resetNaiveGalaxies() {
        naiveGalaxies = []
    }
    
    func startChaining(parent: Int?, child: Int, childCell: (m: Int, n: Int)) {
        if !wasVisited(index: child) {
            markVisited(index: child)
            for x in -1 ... 1 {
                for y in -1 ... 1{
                    var (nx, ny) = (childCell.m + x, childCell.n + y)
                    var isInBounds = nx < 0 || ny < 0
                    isInBounds = !(isInBounds || nx >= gridDim || ny >= gridDim)
                    if !isInBounds {
                        nx = nx % gridCells.count
                        ny = ny % gridCells.count
                        if nx < 0 {
                            nx = nx + gridCells.count
                        }
                        if ny < 0 {
                            ny = ny + gridCells.count
                        }
                        isInBounds = nx < 0 || ny < 0
                        isInBounds = !(isInBounds || nx >= gridDim || ny >= gridDim)
                    }
                    if isInBounds {
                        let cellPoints = gridCells[nx][ny]
                        for i in cellPoints {
                            if !wasVisited(index: i) {
                                let dist = distByIndex(to: child, from: i)
                                if dist < minDist {
                                    startChaining(parent: child, child: i, childCell: (m: nx,n: ny))
                                }
                            }
                        }
                    }
                }
            }
            var (_, chchildren) = unionFindContainer[child]
            chchildren.append(child)
            if parent == nil {
                naiveGalaxies.append(chchildren)
            }
            else{
                var (_, pachildren) = unionFindContainer[parent!]
                pachildren.append(contentsOf: chchildren)
                unionFindContainer[child] = (parent!, [])
                unionFindContainer[parent!] = (parent!, pachildren)
            }
        }
    }
    
    func iterThroughGrid() {
        for x in 0 ..< gridDim{
            for y in 0 ..< gridDim{
                let cellPoints = gridCells[x][y]
                for i in cellPoints{
                    startChaining(parent: nil, child: i, childCell: (m: x, n: y))
                }
            }
        }
    }
    
    let bounds : [Int] = [15, 30, 60, 100, 150, 250]
    
    let classColors: [UIColor] = [
        UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
        UIColor(red: 132.0/255.0, green: 112.0/255.0, blue: 255.0/255.0, alpha: 1.0), //lightslateblue
        UIColor(red: 0.0, green: 197.0/255.0, blue: 205.0/255.0, alpha: 1.0), //turquoise3
        UIColor(red: 124.0/255.0, green: 205.0/255.0, blue: 124.0/255.0, alpha: 1.0), //palegreen3
        UIColor(red: 255.0/255.0, green: 215.0/255.0, blue: 0.0, alpha: 1.0), //gold1
        UIColor(red: 255.0/255.0, green: 130.0/255.0, blue: 171.0/255.0, alpha: 1.0), //palevioletred1
        UIColor(red: 255.0/255.0, green: 114.0/255.0, blue: 86.0/255.0, alpha: 1.0)] //coral1
    
    func indexFromBounds(particleCount : Int) -> Int{
        for i in 0 ..< self.bounds.count{
            if particleCount < bounds[i]{
                return i
            }
        }
        return bounds.count
    }
    
    func parseGalaxyData(){
        galaxyData = []
        for ngalaxy in naiveGalaxies{
            let newGalaxy = Galaxy()
            newGalaxy.particles = ngalaxy
            newGalaxy.sizeClass = indexFromBounds(particleCount: newGalaxy.size)
            newGalaxy.center = transform(pos: newGalaxy.centerInSimCoordinates)
            galaxyData.append(newGalaxy)
        }
    }
    
    /*---Set Particle Colors---*/
    var particlesVisible: Bool = true
    
    func setParticleVisibility(point: SKSpriteNode) {
        point.isHidden = !particlesAreOn
        particlesVisible = particlesAreOn
    }
    
    func turnParticleVisibility(){
        _ = points.map(setParticleVisibility)
    }
    
    func colorParticle(color: UIColor) -> ((Int) -> ()) {
        return {
            index in
            let node = self.points[index - 1]
            node.color = color
        }
    }
    
    func colorGalaxy(galaxy: Galaxy) -> (){
        let color = classColors[galaxy.sizeClass]
        let coloringFn = colorParticle(color: color)
        for particle in galaxy.particles{
            coloringFn(particle)
        }
        //let _ = galaxy.particles.map(coloringFn)
        
    }
    
    func setParticleColors() {
        for galaxy in galaxyData{
            colorGalaxy(galaxy: galaxy)
        }
        //let _ = galaxyData.map(colorGalaxy)
    }
    
    func setInteraction() {
        if (interaction == 0) {
            self.touchTracker.fillColor = UIColor.clear
        }
        else {
            self.touchTracker.fillColor = UIColor.white
            let touchX = CGFloat(touchLocation.0)
            let touchY = CGFloat(touchLocation.1)
            let touchZ = CGFloat(touchLocation.2)
            let trackerLocation = self.transform((touchX, touchY, touchZ), index: 0)
            self.touchTracker.position = CGPoint(x: trackerLocation.0, y: trackerLocation.1)
        }
    }
    
    func getScore() -> Int {
        return 0
    }
    
    func setLabel() {/*
        let time = (Float)(60 - (Date().timeIntervalSinceReferenceDate-initTime))
        if(time >= 0){
            self.accelLabel.text = "\(13.7 * time/60.0) Billion years ago"
            self.galaxyCounter.text = "\(scoreCounter)"
        }
        else{
            self.accelLabel.text = "\(-1 * 13.7 * time/60.0) Billion years after"
            self.galaxyCounter.text = "\(scoreCounter)"
        }*/
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isPaused{
            return
        }
        else{
            setPositions()
            getGroupings()
            //print(naiveGalaxies.count)
            setInteraction()
            tempScoreCounter = getScore()
            if isPlaying{
                if particlesAreOn {
                    if !particlesVisible{
                        turnParticleVisibility()
                    }
                    setParticleColors()
                }
                else {
                    if particlesVisible{
                        turnParticleVisibility()
                    }
                }
                if galaxiesAreOn{
                    drawAllGalaxies()
                }
                else{
                    if galaxiesVisible {
                        resetGalaxyImages()
                        galaxiesVisible = false
                    }
                }
            }
            setLabel()
        }
        
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
    
    /*---Drawing Galaxies---*/
    var galaxiesVisible: Bool = true
    
    func drawAllGalaxies(){
        resetGalaxyImages()
        _ = galaxyData.map(drawGalaxy)
        galaxiesVisible = true
    }
    
    func resetGalaxyImage(galaxyImage: SKSpriteNode) {
        galaxyImage.isHidden = true
    }
    
    func resetGalaxyImageByClass(galaxyImages: [SKSpriteNode]) {
        _ = galaxyImages.map(resetGalaxyImage)
    }
    
    func resetGalaxyImages() {
        _ = galaxySprites.map(resetGalaxyImageByClass)
    }
    
    let galaxyFiles: [String] = [
        "",
        "galaxy1.png",
        "galaxy2.png",
        "galaxy3.png",
        "galaxy4.png",
        "galaxy5.png",
        "galaxy6.png"
    ]
    
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

