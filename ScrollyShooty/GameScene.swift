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
    let tentacleMemberWidth: CGFloat = 50, tentacleMemberHeight: CGFloat = 30
    var tentacleMovingTouch: UITouch?
    var tentacleDragger: SKNode!
    var tentacleDragJoint: SKPhysicsJointPin?

    override func didMoveToView(view: SKView) {
        physicsWorld.contactDelegate = self
        //physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        player = childNodeWithName("player") as! SKSpriteNode
        playerFoot = childNodeWithName("foot") as! SKSpriteNode
        //pin the foot on the player
        let footJoint = SKPhysicsJointPin.jointWithBodyA(player.physicsBody!, bodyB: playerFoot.physicsBody!, anchor: playerFoot.position)
        physicsWorld.addJoint(footJoint)
        tentacleDragger = childNodeWithName("tentacleDragger")
        
        for _ in 1...5 {
            addTentacleMember()
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            if tentacleMovingTouch == nil && nodeAtPoint(location).name == "tentacle" &&
                (nodeAtPoint(location) as! TentacleMember).isControllableTentacle {
                tentacleMovingTouch = touch
                // move the tentacleDraggerNode to the touch location
                // then create a joint
                tentacleDragger.position = location
                tentacleDragJoint = SKPhysicsJointPin.jointWithBodyA(tentacleDragger.physicsBody!, bodyB: nodeAtPoint(location).physicsBody!, anchor: tentacleDragger.position)
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
                tentacleDragger.position = location
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
        camera!.position.x = player.position.x
        
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
        //contactB.node?.name
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
        tentacle.zPosition = 2
        tentacle.anchorPoint = CGPoint(x: 0, y: 0.5)
        tentacle.physicsBody = SKPhysicsBody(rectangleOfSize: tentacle.size, center: CGPoint(x: tentacle.size.width/2, y: tentacle.size.height/2))
        tentacle.physicsBody?.dynamic = true
        tentacle.physicsBody?.allowsRotation = true
        tentacle.physicsBody?.affectedByGravity = false
        tentacle.physicsBody?.pinned = false
        tentacle.physicsBody?.restitution = 0.2
        tentacle.physicsBody?.categoryBitMask = 8
        tentacle.physicsBody?.collisionBitMask = 12
        let attatchPosition: CGPoint
        if let lastTentacleMember = lastTentacleMember {
            attatchPosition = convertPoint(CGPoint(x: lastTentacleMember.size.width, y: 0), fromNode: lastTentacleMember)
        } else {
            attatchPosition = player.position
        }
        tentacle.position = attatchPosition
        lastTentacleMember?.isControllableTentacle = false
        tentacle.isControllableTentacle = true
        tentacle.userInteractionEnabled = true
        addChild(tentacle)
        
        //Add a joint
        let tentacleJoint = SKPhysicsJointPin.jointWithBodyA(lastTentacleMember?.physicsBody ?? player.physicsBody!, bodyB: tentacle.physicsBody!, anchor: tentacle.position)
        physicsWorld.addJoint(tentacleJoint)
        
        lastTentacleMember = tentacle

    }
}
