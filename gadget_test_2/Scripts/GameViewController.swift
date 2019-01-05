//
//  GameViewController.swift
//  gadget_test_2
//
//  Created by Peter Lee on 6/2/15.
//  Copyright (c) 2015 Peter Lee. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

extension SKNode {
    class func unarchiveFromFile(_ file : String) -> SKNode? {
        if let path = Bundle.main.path(forResource: file, ofType: "sks") {
            let sceneData = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let archiver = NSKeyedUnarchiver(forReadingWith: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {
    var semaphore: DispatchSemaphore
    
    var levelLength : Int = 0
    var levelArray : [String] = []
    let levelsFd = (Bundle.main.resourcePath! as NSString).appendingPathComponent("levels.txt")
    var isLevelsLoaded = false
    
    func getLevels(){
        do{
            let contents = try NSString(contentsOfFile : levelsFd, encoding: String.Encoding.ascii.rawValue)
            contents.enumerateLines({(line,stop) -> () in self.levelArray.append(line)})
        } catch{
            print("ERROR: WRONG TEXT FILE")
        }
        self.levelLength = self.levelArray.count
        if(levelLength > 0){
            self.isLevelsLoaded = true
        }
    }
    
    @IBOutlet weak var menu: UIButton!
    
    @IBOutlet weak var dmSwitch: UISwitch!{
        didSet{
            dmSwitch.setOn(true, animated: true)
        }
    }
    
    @IBOutlet weak var galSwitch: UISwitch!{
        didSet{
            galSwitch.setOn(true, animated: true)
        }
    }
    
    @IBAction func actionBeforeUnwind(_ sender: Any) {
            //musicPlayer.stop()
            playing = 0
    }
    
    @IBAction func unwindSegue(unwindSegue:UIStoryboardSegue)
    {
    }
    
    @IBOutlet weak var verticalSlider: UISlider!{
        didSet{
            verticalSlider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2));   }
    }
    
    @IBOutlet weak var verticalProgress: UIProgressView!{
        didSet{
            verticalProgress.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        }
    }
    
    @IBAction func attractOrRepel(_ sender: UISwitch) {
        print("sadgaergeqhrtwhwrthwrthwrthwtrhwtrh")
        interactionFactor *= -1
        print(interactionFactor)
    }
    
    @IBAction func attractToRepel(_ sender: UISlider) {
        print("sadgaergeqhrtwhwrthwrthwrthwtrhwtrh")
        interactionFactor = sender.value
        print(interactionFactor)
    }
    
    @IBAction func switchAlpha(_ sender: UISwitch) {
        particlesAreOn = sender.isOn
        print("Particles Are Visible: " + String(particlesAreOn))
    }
    
    @IBAction func switchGalaxy(_ sender: UISwitch) {
        galaxiesAreOn = sender.isOn
        print("Galaxies Are Visible: " + String(galaxiesAreOn))
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.semaphore = DispatchSemaphore(value: 0)
        
        super.init(coder: aDecoder)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        // start Gadget on background thread
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
        
        if(!isLevelsLoaded){
            getLevels()
        }
        
        queue.async(execute: { () -> Void in
            var input = ""
            if(level < self.levelLength){
                input = self.levelArray[Int(level)]
            } else{
                input = "ics_100_32_zero_a_slice"
            /*switch(level)
            {
            case(1):
                input = "ics_100_32_neg1_a_slice"
                break
            case(2):
                input = "ics_100_32_plus1_a_slice"
                break
            case(3):
                input = "ics_100_64_neg2_a_slice"
                break
            case(4):
                input = "ics_ring_test"
                break
            default:
                input = "ics_100_32_zero_a_slice"
                break*/
                
            }
            gadget_main_setup(strdup(input))
            
            // release semaphore
            self.semaphore.signal()
            gadget_main_run()
            
            // Gadget ended, free memory
            free_memory()
            
            print("gadget end")
        })
        
        // semaphore lock
        let t: Int64 = 10000000000 // wait time in ns
        let timeout = DispatchTime.now() + Double(t) / Double(NSEC_PER_SEC)
        let semaphoreSuccess = self.semaphore.wait(timeout: timeout)
        switch semaphoreSuccess {
        case .timedOut:
            print("error")
            exit(EXIT_FAILURE)
        default:
            ()
        }

        // set up Sprite Kit view
        let scene = GameScene(size: self.view.bounds.size)
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.backgroundColor = UIColor.black
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        
    }
    

    
    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
}
