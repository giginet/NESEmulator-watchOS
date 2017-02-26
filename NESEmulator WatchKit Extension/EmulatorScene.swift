import Foundation
import SpriteKit
import WatchKit
import PVNES

class EmulatorScene: SKScene {
    var sprite = SKSpriteNode()
    let emulatorCore = PVNESEmulatorCore()
    let fpsLabelNode: SKLabelNode = SKLabelNode()
    var shouldShowFPS = false
    private let controllerNode = SKSpriteNode(imageNamed: "controller")
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        let rom = Bundle.main.path(forResource: "smb3", ofType: "nes")
        emulatorCore.loadFile(atPath: rom)
        
        addChild(sprite)
        emulatorCore.startEmulation()
        emulatorCore.setPauseEmulation(false)
        
        controllerNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(controllerNode)
        
        fpsLabelNode.fontSize = 32
        fpsLabelNode.fontColor = UIColor.red
        addChild(fpsLabelNode)
        fpsLabelNode.position = CGPoint(x: 100, y: 5)
        fpsLabelNode.isHidden = !shouldShowFPS
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        controllerNode.position = CGPoint(x: frame.width / 2.0,
                                          y: frame.height / 2.0)
    
        let canvasSize = emulatorCore.bufferSize()
        let scale = min(size.width / canvasSize.width, size.height / canvasSize.height)
        sprite.setScale(scale)
        sprite.size = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        sprite.texture = texture
        sprite.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        
        fpsLabelNode.text = String(floor(emulatorCore.emulationFPS))
    }
    
    var bufferCount: Int {
        return 256 * 240 * 4
    }
    
    var texture: SKTexture {
        guard let videoBuffer: UnsafeRawPointer = emulatorCore.videoBuffer() else {
            fatalError()
        }
        let data = Data(bytes: videoBuffer, count: Int(bufferCount))
        
        let size = CGSize(width: 256, height: 240)
        return SKTexture(data: data, size: size, flipped: true)
    }
}
