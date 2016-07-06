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

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let fixedDelta: CFTimeInterval = 1/60 //60 FPS
    let maxPlayerSpeed: CGFloat = 200
    var player: SKSpriteNode!
    var playerFoot: SKSpriteNode!
    var canJump = false
    var canJumpCounter: CFTimeInterval = 0
    //var camera: SKCameraNode!
    var playerMovingTouchOriginalPosition: CGPoint? //represents the first location recorded when the player put their finger down. Gets nullified when the touch is released
    var playerMovingTouch: UITouch? //a reference to the touch that is currently moving the player
    //let motionManager: CMMotionManager = CMMotionManager()
    
    var lastTentacleMember: TentacleMember? = nil
    let tentacleMemberWidth: CGFloat = 30, tentacleMemberHeight: CGFloat = 20
    var tentacleMovingTouch: UITouch?
    var tentacleDragger: SKNode!
    var tentacleDragJoint: SKPhysicsJointSpring?
    var tentacleCount = 0

    override func didMoveToView(view: SKView) {
        physicsWorld.contactDelegate = self
        //physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        player = childNodeWithName("player") as! SKSpriteNode
        playerFoot = childNodeWithName("foot") as! SKSpriteNode
        //pin the foot on the player
        let footJoint = SKPhysicsJointPin.jointWithBodyA(player.physicsBody!, bodyB: playerFoot.physicsBody!, anchor: playerFoot.position)
        physicsWorld.addJoint(footJoint)
        tentacleDragger = childNodeWithName("tentacleDragger")
        
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            //Check for touching end tentacle
            if tentacleMovingTouch == nil && nodeAtPoint(location).name == "tentacle" &&
                (nodeAtPoint(location) as! TentacleMember).isControllableTentacle {
                let tentacle = nodeAtPoint(location) as! TentacleMember
                tentacleMovingTouch = touch
                // move the tentacleDraggerNode to the touch location
                // then create a joint
                tentacleDragger.position = location
                let tentacleJointBindPoint = convertPoint(CGPoint(x: tentacle.size.width, y: tentacle.size.height/2), fromNode: tentacle)
                tentacleDragJoint = SKPhysicsJointSpring.jointWithBodyA(tentacleDragger.physicsBody!, bodyB: tentacle.physicsBody!, anchorA: tentacleDragger.position, anchorB: tentacleJointBindPoint)
                physicsWorld.addJoint(tentacleDragJoint!)
                //player.physicsBody!.pinned = true
                
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
                physicsWorld.removeJoint(tentacleDragJoint!)
                tentacleDragJoint = nil
                //player.physicsBody!.pinned = false
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
                
                //TODO cap the distance the player can drag
                if player.position.distanceTo(touch.locationInNode(self)) > tentacleMemberWidth * CGFloat(tentacleCount) {
                    print("too far for tentacle!")
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
                    tentacleDragger.position = CGPoint(x: newX, y: newY)
                } else {
                    tentacleDragger.position = touch.locationInNode(self)
                }
                
                
            }
            
            if touch !== tentacleMovingTouch {
                //Test for jumping. Notice how it is outside of the playerMovingTouchTest, so that any touch
                // can make the player jump
                let yMove = location.y - touch.previousLocationInNode(camera!).y
                if yMove > 13 && canJump { //*** the canJump boolean is set in didBeginContact and didEndContact
                    //Jump
                    player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
                    playerMovingTouchOriginalPosition!.y = location.y
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
        
        // So about the thing with the canJumpCounter
        // There's this bug where the contact between playerFoot and ground isn't registered,
        // so the player gets a little crippled and can't jump, so I'm going to every so often
        // manually check if the player foot is touching the ground and set canJump like that
        // **I should do this. sometime. once it starts to bug me. which it probably won't.
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
        
        //Did the contact happen between the player's foot and a platform?
        if (contactA.categoryBitMask == 2 && contactB.categoryBitMask == 4) ||
            (contactA.categoryBitMask == 4 && contactB.categoryBitMask == 2) {
            canJump = true
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
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        //Did the contact end between the player's foot and a platform?
        if (contactA.categoryBitMask == 2 && contactB.categoryBitMask == 4) ||
            (contactA.categoryBitMask == 4 && contactB.categoryBitMask == 2) {
            canJump = false
        }

    }
    
    func addTentacleMember() {
        //Initialize the tentacle
        let tentacle = TentacleMember(color: UIColor.blackColor(), size: CGSize(width: tentacleMemberWidth, height: tentacleMemberHeight))
        tentacle.zPosition = 0
        tentacle.name = "tentacle"
        tentacle.anchorPoint = CGPoint(x: 0, y: 0.5)
        tentacle.physicsBody = SKPhysicsBody(rectangleOfSize: tentacle.size, center: CGPoint(x: tentacle.size.width/2, y: tentacle.size.height/2))
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
        lastTentacleMember?.isControllableTentacle = false
        tentacle.isControllableTentacle = true
        //tentacle.userInteractionEnabled = true
        addChild(tentacle)
        
        //Add a joint
        let tentacleJoint = SKPhysicsJointPin.jointWithBodyA(lastTentacleMember?.physicsBody ?? player.physicsBody!, bodyB: tentacle.physicsBody!, anchor: attatchPosition)
        physicsWorld.addJoint(tentacleJoint)
        
        lastTentacleMember = tentacle
        tentacleCount += 1
    }
}
