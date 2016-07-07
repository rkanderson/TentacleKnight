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
        } else if direction == .Right {
            //Hit the right, turn left!
            physicsBody?.velocity.dx = -standardEnemySpeed
            self.direction = .Left
        }
    }
    
}
