//
//  TentacleMember.swift
//  ScrollyShooty
//
//  Created by Ryan Anderson on 7/6/16.
//  Copyright © 2016 hmmmmm. All rights reserved.
//

import Foundation
import SpriteKit

class TentacleMember: SKSpriteNode {
    
    //Should be true if this member is the last one in the string. Set in GameScene
    var isControllableTentacle = false {
        didSet {
            if isControllableTentacle {
                zPosition = 2
                texture = SKSpriteNode(color: SKColor.brownColor(), size: size).texture
            } else {
                zPosition = 0
                texture = SKSpriteNode(color: SKColor.blackColor(), size: size).texture
            }
        }
    }
    var isBeingManipulated = false //Turns true when the player taps and holds the tentacle
//    var controllingTouch: UITouch?
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        if !isControllableTentacle {return}
//        for touch in touches {
//            if controllingTouch === nil {
//                controllingTouch = touch
//                isBeingManipulated = true
//            }
//        }
//    }
//    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        if !isControllableTentacle {return}
//        for touch in touches {
//            if touch === controllingTouch {
//                controllingTouch = nil
//                isBeingManipulated = false
//            }
//        }
//    }
//    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        if !isControllableTentacle {return}
//        for touch in touches {
//            if touch === controllingTouch {
//                //print("touch on tentacle moved")
//            }
//        }
//    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
