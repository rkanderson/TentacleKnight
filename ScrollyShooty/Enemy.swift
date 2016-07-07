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
    
    let standardEnemySpeed: CGFloat = 10
    
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
    
    //This enemy is kinda going to act like the goomba from mario 🍄
    func hitWall(direction: Direction) {
        if direction == .Left {
            //This enemy hit the wall on the left, move Right Now!
            physicsBody?.velocity.dx = standardEnemySpeed
            
        } else if direction == .Right {
            //Hit the right, turn left!
            physicsBody?.velocity.dx = -standardEnemySpeed
        }
    }
    
}
