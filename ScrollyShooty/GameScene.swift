//
//  GameScene.swift
//  ScrollyShooty
//
//  Created by Ryan Anderson on 7/5/16.
//  Copyright (c) 2016 hmmmmm. All rights reserved.
//

import Foundation
import CoreMotion
import SpriteKit

enum Direction {
    case Left, Right
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let fixedDelta: CFTimeInterval = 1/60 //60 FPS
    let maxPlayerSpeed: CGFloat = 200
    var player: SKSpriteNode!
    var canJump = false
    var canJumpCounter: CFTimeInterval = 0
    var playerMovingTouchOriginalPosition: CGPoint? //represents the first location recorded when the player put their finger down. Gets nullified when the touch is released
    var playerMovingTouch: UITouch? //a reference to the touch that is currently moving the player
    
    var lastTentacleMember: TentacleMember? = nil
    let tentacleMemberWidth: CGFloat = 30, tentacleMemberHeight: CGFloat = 20
    var tentacleMovingTouch: UITouch?
    var tentacleDragger: SKNode!
    var colorPartOfTentacleDragger: SKNode!
    var tentacleDragJoint: SKPhysicsJointSpring?
    var tentacleCount = 0 {
        didSet {
            //We only want the tentacle dragger to be visible as a draggy thing at the
            // end of the tentacle structure. Otherwise it would just be floating around and looking weird.
            if tentacleCount == 0 {
                tentacleDragger.hidden = true
                colorPartOfTentacleDragger.hidden = true
            } else {
                tentacleDragger.hidden = false
                colorPartOfTentacleDragger.hidden = false
            }

        }
    }
    var enemyLayer: SKNode!
    var grabJoint: SKPhysicsJointPin?

    override func didMoveToView(view: SKView) {
        physicsWorld.contactDelegate = self
        //physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        player = childNodeWithName("player") as! SKSpriteNode
        tentacleDragger = childNodeWithName("tentacleDragger")
        colorPartOfTentacleDragger = childNodeWithName("colorPartOfTentacleDragger")
        let cpotdJoint = SKPhysicsJointPin.jointWithBodyA(tentacleDragger.physicsBody!, bodyB: colorPartOfTentacleDragger.physicsBody! , anchor: colorPartOfTentacleDragger.position)
        physicsWorld.addJoint(cpotdJoint)
        tentacleCount = 0
        
        enemyLayer = childNodeWithName("enemyLayer")
        for ref in enemyLayer.children {
            let enemy = ref.childNodeWithName("//avatar") as! Enemy
            enemy.setUp()
        }
        
        //spawn some tentacles outright
        for _ in 1...6 {
            addTentacleMember()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            //Check for touching end tentacle. check just for clicking on the tentacleDragger itself
            if tentacleMovingTouch == nil && nodeAtPoint(location).name == "tentacleDragger" {
                tentacleMovingTouch = touch
                // move the tentacleDraggerNode to the touch location
                // then create a joint
                tentacleDragger.position = location
                
            //Check for touch anywhere else (player movement)
            } else if playerMovingTouch === nil {
                playerMovingTouch = touch
                playerMovingTouchOriginalPosition = touch.locationInNode(camera!)
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch === playerMovingTouch {
                playerMovingTouch = nil
                playerMovingTouchOriginalPosition = nil
                player.physicsBody?.velocity.dx = 0
            } else if touch === tentacleMovingTouch {
                tentacleMovingTouch = nil
                if let _ = grabJoint {
                    runAction(SKAction.runBlock{
                        self.physicsWorld.removeJoint(self.grabJoint!)
                        self.grabJoint = nil
                    })
                }
            }
        }
    }

    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(camera!)
            if touch === playerMovingTouch {
                //Move the player horizontally based on touch
                let deltaX = location.x - playerMovingTouchOriginalPosition!.x
                player.physicsBody!.velocity.dx = deltaX*4
                player.physicsBody!.velocity.dx.clamp(-maxPlayerSpeed, maxPlayerSpeed)
                
                if player.physicsBody!.velocity.dx > 0 {
                    player.xScale = abs(player.xScale)
                } else {
                    player.xScale = -abs(player.xScale)
                }
                
                
            } else if touch === tentacleMovingTouch {
                // move the tentacleDragger
                
                //caps the distance the player can drag
                let desiredTentacleDraggerPosition: CGPoint
                if player.position.distanceTo(touch.locationInNode(self)) > tentacleMemberWidth * CGFloat(tentacleCount) {
                    //Here I need to move the tentacle dragger to be in the same direction
                    let distX = touch.locationInNode(self).x - player.position.x
                    let distY = touch.locationInNode(self).y - player.position.y
                    let angle = atan(distY/distX)
                    let desiredDistance = tentacleMemberWidth * CGFloat(tentacleCount)
                    
                    let newX: CGFloat, newY: CGFloat
                    if touch.locationInNode(self).x < player.position.x {
                        newY = player.position.y - (sin(angle) * desiredDistance)
                        newX = player.position.x - (cos(angle) * desiredDistance)
                    } else {
                        newY = player.position.y + (sin(angle) * desiredDistance)
                        newX = player.position.x + (cos(angle) * desiredDistance)
                    }
                    
                    desiredTentacleDraggerPosition = CGPoint(x: newX, y: newY)
                } else {
                    desiredTentacleDraggerPosition = touch.locationInNode(self)
                }
                
                tentacleDragger.physicsBody?.velocity.dx = desiredTentacleDraggerPosition.x - tentacleDragger.position.x
                tentacleDragger.physicsBody?.velocity.dy = desiredTentacleDraggerPosition.y - tentacleDragger.position.y
                
            }
            
            if touch !== tentacleMovingTouch {
                //Test for jumping. Notice how it is outside of the playerMovingTouchTest, so that any touch
                // can make the player jump
                let yMove = location.y - touch.previousLocationInNode(camera!).y
                if yMove > 14 && canJump { //*** the canJump boolean is set in didBeginContact and didEndContact
                    //Jump
                    player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1000))
                    playerMovingTouchOriginalPosition!.y = location.y
                    canJump = false
                }
            }

        }
    }

   
    override func update(currentTime: CFTimeInterval) {
        if let _ = tentacleMovingTouch {
            camera!.position.x = lastTentacleMember!.position.x
        } else {
            camera!.position.x = player.position.x
        }
        for ref in enemyLayer.children {
            let enemy = ref.childNodeWithName("//avatar") as! Enemy
            enemy.update(currentTime)
        }

    }
    
    
    // Physics category bitmasks
    // 1 = player
    // 2 = player foot
    // 4 = platform
    // 8 = tentacle
    // 16 = tentacle grow orb
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        //Player landed on ground
        if (contactA.categoryBitMask == 1 && contactB.categoryBitMask == 4) || (contactA.categoryBitMask == 4 && contactB.categoryBitMask == 1) {
            let playerPoint = player.position
            let difference = playerPoint.y - player.size.height/2 - contact.contactPoint.y
            if(difference < 6 && difference > -6) {
                canJump = true
            } else {
                canJump = false
            }
        }
        
        //Did the contact happen between the player and a tentacleGrowOrb?
        if (contactA.categoryBitMask == 1 && contactB.categoryBitMask == 16) ||
            (contactA.categoryBitMask == 16 && contactB.categoryBitMask == 1) {
            addTentacleMember()
            let growOrb = contactA.categoryBitMask == 16 ? contactA.node : contactB.node
            runAction(SKAction.runBlock {
                growOrb?.removeFromParent()
            })
        }
        
        //Between an enemy and a platform. Let's test if it was hit from the left or right
        // and then call the enemy's hit wall method
        if (contactA.categoryBitMask == 256 && contactB.categoryBitMask == 4) ||
            (contactA.categoryBitMask == 4 && contactB.categoryBitMask == 256) {
            let enemy = (contactA.categoryBitMask == 256 ? nodeA : nodeB) as! Enemy
            let enemyPosition = convertPoint(enemy.position, fromNode: enemy.parent!)
            let contactPosition = contact.contactPoint
            if contactPosition.x < enemyPosition.x - 6 { //The 6's act as buffer space.
                enemy.hitWall(.Left)
            } else if contactPosition.x > enemyPosition.x + 6 {
                enemy.hitWall(.Right)
            } else {
                //The enemy probably is touching the ground
                return
            }
        }
        
        //Between player hand and a solid object
        if (contactA.categoryBitMask == 512 && contactB.categoryBitMask == 32) ||
            (contactA.categoryBitMask == 32 && contactB.categoryBitMask == 512) {
            let hand = contactA.categoryBitMask == 512 ? nodeA : nodeB
            let solidObject = nodeA !== tentacleDragger ? nodeA : nodeB
            if grabJoint != nil || tentacleMovingTouch == nil
            { //If there already is a grab joint that exists, don't make another. Also, the player has to be touching to grab
                return
            } else {
                // Ok so there isn't a joint and the player's hand touched some solid object. Time to make a joint between the two. They better have physics bodies.......
                grabJoint = SKPhysicsJointPin.jointWithBodyA(hand.physicsBody!, bodyB: solidObject.physicsBody!, anchor: hand.position)
                physicsWorld.addJoint(grabJoint!)
            }
        }
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
//        let nodeA = contactA.node as! SKSpriteNode
//        let nodeB = contactB.node as! SKSpriteNode

        //player-platform contact end
        if (contactA.categoryBitMask == 1 && contactB.categoryBitMask == 4) || (contactA.categoryBitMask == 4 && contactB.categoryBitMask == 1) {
            let playerPoint = player.position
            let difference = playerPoint.y - player.size.height/2 - contact.contactPoint.y
            if(difference >= 6) {
                canJump = false
            } else {
                canJump = true
            }
        }


    }
    
    func addTentacleMember() {
        //Initialize the tentacle
//        let tentacle = TentacleMember(color: UIColor.blackColor(), size: CGSize(width: tentacleMemberWidth, height: tentacleMemberHeight))
        
        let tentacle = TentacleMember(texture: SKTexture(imageNamed: "imgres-1"), size: CGSize(width: tentacleMemberWidth, height: tentacleMemberHeight))
        
        tentacle.zPosition = 0
        tentacle.name = "tentacle"
        tentacle.anchorPoint = CGPoint(x: 0, y: 0.5)
        tentacle.physicsBody = SKPhysicsBody(rectangleOfSize: tentacle.size, center: CGPoint(x: tentacle.size.width/2, y: 0))
        tentacle.physicsBody?.dynamic = true
        tentacle.physicsBody?.allowsRotation = true
        tentacle.physicsBody?.affectedByGravity = false
        tentacle.physicsBody?.pinned = false
        tentacle.physicsBody?.restitution = 0.2
        tentacle.physicsBody?.categoryBitMask = 8
        tentacle.physicsBody?.collisionBitMask = 12
        tentacle.physicsBody?.mass = 0.01
        let attatchPosition: CGPoint
        if let lastTentacleMember = lastTentacleMember {
            attatchPosition = convertPoint(CGPoint(x: lastTentacleMember.size.width, y: 0), fromNode: lastTentacleMember)
        } else {
            attatchPosition = player.position
        }
        tentacle.position = attatchPosition
        //lastTentacleMember?.isControllableTentacle = false
        //tentacle.isControllableTentacle = true
        //tentacle.userInteractionEnabled = true
        addChild(tentacle)
        
        //Add a joint to connect the new tentacle member to the evergrowing main tentacle structure
        let tentacleJoint = SKPhysicsJointPin.jointWithBodyA(lastTentacleMember?.physicsBody ?? player.physicsBody!, bodyB: tentacle.physicsBody!, anchor: attatchPosition)
        physicsWorld.addJoint(tentacleJoint)
        
        lastTentacleMember = tentacle
        
        tentacleDragger.position = convertPoint(CGPoint(x: tentacle.size.width, y: 0), fromNode: lastTentacleMember!)
        tentacleDragger.childNodeWithName("colorPartOfTentacleDragger")?.position = tentacleDragger.convertPoint(CGPoint(x: tentacle.size.width, y: 0), fromNode: lastTentacleMember!)
        if let tentacleDragJoint = tentacleDragJoint {
            physicsWorld.removeJoint(tentacleDragJoint)
        }
        let tentacleDragJointBindPoint = convertPoint(CGPoint(x: tentacle.size.width, y: 0), fromNode: lastTentacleMember!)
        tentacleDragJoint = SKPhysicsJointSpring.jointWithBodyA(tentacleDragger.physicsBody!, bodyB: tentacle.physicsBody!, anchorA: tentacleDragger.position, anchorB: tentacleDragJointBindPoint)
        physicsWorld.addJoint(tentacleDragJoint!)

        
        tentacleCount += 1
    }
}
