//
//  InterfaceController.swift
//  NESEmulator WatchKit Extension
//
//  Created by giginet on 2017/01/02.
//  Copyright © 2017 giginet. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, WKCrownDelegate {
    @IBOutlet var spriteKitScene: WKInterfaceSKScene!
    @IBOutlet var gestureRecognizer: WKLongPressGestureRecognizer!
    let scene = EmulatorScene()
    let canvasSize = CGSize(width: 256, height: 240)
    var audioPlayer: AudioPlayer!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        audioPlayer = AudioPlayer(emulatorCore: scene.emulatorCore)
        
        scene.size = screenSize
        scene.scaleMode = .fill
        crownSequencer.delegate = self
    }
    
    override func willActivate() {
        super.willActivate()
        
        // super rapidly long tap (1 frame)
        gestureRecognizer.minimumPressDuration = 1.0 / 60.0
        
        spriteKitScene.preferredFramesPerSecond = 10
        spriteKitScene.presentScene(scene)
    }
    
    override func didAppear() {
        super.didAppear()
        
        crownSequencer.focus()
        audioPlayer.start()
    }
    
    override func willDisappear() {
        super.willDisappear()
        
        audioPlayer.stop()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    var screenSize: CGSize {
        return WKInterfaceDevice.current().screenBounds.size
    }
    
    private var queue: DispatchQueue {
        return DispatchQueue(label: "org.giginet.NESSimulator")
    }
    
    @IBAction func didTapScreen(_ sender: WKLongPressGestureRecognizer) {
        queue.async { [weak self] in
            let point = sender.locationInObject()
            let horizontalDivider = (self?.screenSize.width)! / 3.0
            let horizontalIndex = Int(point.x / horizontalDivider)
            let verticalIndex = Int(point.y / horizontalDivider)
            
            guard let button = Button(xIndex: horizontalIndex, yIndex: verticalIndex) else {
                return
            }
            if sender.state == .began {
                self?.scene.emulatorCore.controllerState |= button.rawValue
            } else if sender.state == .ended {
                self?.scene.emulatorCore.controllerState &= ~button.rawValue
            }
        }
    }
    
    // MARK: WKCrownDelegate
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        queue.async {
            if rotationalDelta < 0 {
                self.scene.emulatorCore.controllerState |= Button.left.rawValue
            } else if rotationalDelta > 0 {
                self.scene.emulatorCore.controllerState |= Button.right.rawValue
            }
        }
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        queue.async {
            self.scene.emulatorCore.controllerState &= ~Button.left.rawValue
            self.scene.emulatorCore.controllerState &= ~Button.right.rawValue
        }
    }
}
