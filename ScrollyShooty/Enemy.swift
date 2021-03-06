//
//  Enemy.swift
//  ScrollyShooty
//
//  Created by Ryan Anderson on 7/7/16.
//  Copyright © 2016 hmmmmm. All rights reserved.
//

import Foundation
import SpriteKit

class Enemy: SKSpriteNode {
    
    let standardEnemySpeed: CGFloat = 100
    var direction: Direction = .Right
    var isBeingHeld = false { //set to true when it is held by the player.
        didSet {
            physicsBody!.allowsRotation = isBeingHeld
            if !isBeingHeld {
                let rotateAction = SKAction.rotateToAngle(0, duration: 0.2)
                runAction(rotateAction)
            }
        }
    }
    
    func setUp() {
        physicsBody?.velocity.dx = standardEnemySpeed
    }
    
    /* You are required to implement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(currentTime: CFTimeInterval) {
        //Artificial update that should be called from GameScene.swift! 🍬
        if self.direction == .Right {
            physicsBody?.velocity.dx = standardEnemySpeed
        } else {
            physicsBody?.velocity.dx = -standardEnemySpeed
        }
    }
    
    
    //This enemy is kinda going to act like the goomba from mario 🍄
    func hitWall(direction: Direction) {
        if direction == .Left {
            //This enemy hit the wall on the left, move Right Now!
            physicsBody?.velocity.dx = standardEnemySpeed
            self.direction = .Right
            xScale = abs(xScale)
        } else if direction == .Right {
            //Hit the right, turn left!
            physicsBody?.velocity.dx = -standardEnemySpeed
            self.direction = .Left
            xScale = -abs(xScale)
        }
    }
    
//    func die () {
//        
//        //load particle effect
//        let particles = SKEmitterNode(fileNamed: "EnemyExplosion")!
//        particles.position = position
//        particles.numParticlesToEmit = 25
//        parent!.addChild(particles)
//        
//        let removeAction = SKAction.runBlock({
//            self.parent!.removeFromParent()
//            self.removeFromParent()
//        })
//        
//        self.runAction(removeAction)
//        
//    }
//
    
}
