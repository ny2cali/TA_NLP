//
//  ViewController.swift
//  TargetAnnhilator
//
//  Created by Jaspal Singh on 3/7/18.
//  Copyright © 2018 Jaspal Singh. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Speech


enum BodyType:Int {
    
    case plane = 1
    case ball = 2
    case target = 4
}



class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var curTargetPlaneNode: SCNNode? = nil
    
    var curBall: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap(gesture:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)

        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //add plane for placing target cylinders
        let plane = SCNPlane(width: CGFloat(1.5), height: CGFloat(1))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(0, -0.5, -1)
        
        planeNode.eulerAngles.x = -.pi / 2
        
        planeNode.opacity = 0.5
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: planeNode))
        
        planeNode.name = "Plane"
        
        planeNode.physicsBody?.categoryBitMask = BodyType.plane.rawValue
        planeNode.physicsBody?.collisionBitMask = BodyType.ball.rawValue
        planeNode.physicsBody?.contactTestBitMask = BodyType.ball.rawValue
        
        planeNode.physicsBody?.restitution = 1
        
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        createTargetArray(extentX:1.5, extentZ:1, planeNode:planeNode)
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gesture:)))
        tapGesture2.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture2)
    }
    
    
    @objc func doubleTap(gesture: UITapGestureRecognizer) {
  //      print("double tap called")
        
        curBall?.physicsBody?.applyForce(SCNVector3(0, 1, -3), asImpulse: true)

        
    }
    
    @objc func singleTap(gesture: UITapGestureRecognizer) {
      //  print("single tap called")
        curBall = createBall()
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
       
        print(contact.nodeA.name, contact.nodeB.name, contact.contactPoint)
        print(contact.contactPoint)

        
        if contact.nodeA.name != "Ball" && contact.nodeB.name != "Ball" {return}
        
        print(contact.contactPoint)
    }
    
    /*
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        
        if (planeAnchor.extent.x < Config.minHorzPlaneLength) || (planeAnchor.extent.z < Config.minHorzPlaneWidth) { return }
        
        //check if target plane is already added
        if (curTargetPlaneNode != nil) {
            return
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        // Add the plane visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(planeNode)
        
        //store the current targetplane node
        planeNode.name = "targetPlane"
        curTargetPlaneNode = planeNode
        
   //     let numofRowsCols = calcRowsCols(dim1: planeAnchor.extent.x, dim2: planeAnchor.extent.z)
   //     let target = createTarget()
        createTargetArray(planeAnchor: planeAnchor, planeNode: planeNode)
    }
    */
    
    func createBall() -> SCNNode {
        let shape = Config.ballShape(radius: CGFloat(Config.ballSize))
        shape.firstMaterial?.diffuse.contents = UIColor.green
        shape.firstMaterial?.specular.contents = UIColor.white
        let node = SCNNode(geometry: shape)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: node))
        node.physicsBody?.mass = 1.0
        node.position = (sceneView.pointOfView?.position)!
        node.name = "Ball"
        
        node.physicsBody?.categoryBitMask = BodyType.ball.rawValue
        node.physicsBody?.collisionBitMask = BodyType.plane.rawValue
        node.physicsBody?.contactTestBitMask = BodyType.plane.rawValue
        
        node.physicsBody?.restitution = 1
        sceneView.scene.rootNode.addChildNode(node)
        
        return(node)
        
    }
    
    func createTarget() -> Config.targetShape {
        let target = Config.targetShape(radius: CGFloat(Config.targetSizeRadius), height: CGFloat(Config.targetSizeHeight))
        target.firstMaterial?.diffuse.contents = UIColor.red
        target.firstMaterial?.specular.contents = UIColor.white
        return(target)
    }
   
    //func createTargetArray(planeAnchor: planeAnchor, planeNode: planeNode) {
    func createTargetArray(extentX:Float, extentZ:Float, planeNode: SCNNode) {
       
        //let numofRowsCols = calcRowsCols(dim1: planeAnchor.extent.x, dim2: planeAnchor.extent.z)
        let numofRowsCols = calcRowsCols(dim1: extentX, dim2: extentZ)

        for row in 0..<numofRowsCols.rows {
            for col in 0..<numofRowsCols.cols {
                //let targetPos = calcLoc(row: row, col: col, numofRowsCols: numofRowsCols)
                var targetPos = calcLoc(row: col, col: row, numofRowsCols: numofRowsCols)

                print("target: col:\(col) row:\(row) loc: x:\(targetPos.x) y:\(targetPos.y) z:\(targetPos.z) ")
                
                //       let targetPos = SCNVector3(0, 0, 0)
                let targetGeo = createTarget()
                let targetNode = SCNNode(geometry: targetGeo)
                //targetNode.position = targetPos
                targetNode.simdPosition = float3(targetPos.x, targetPos.y, targetPos.z)
                targetNode.worldPosition = targetPos
                targetNode.eulerAngles.x = -.pi / 2
                targetNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: targetNode))
                targetNode.name = "Target"
                targetNode.physicsBody?.categoryBitMask = BodyType.target.rawValue
                targetNode.physicsBody?.collisionBitMask = BodyType.ball.rawValue
                targetNode.physicsBody?.contactTestBitMask = BodyType.ball.rawValue
                
                targetNode.physicsBody?.restitution = 1
                
                planeNode.addChildNode(targetNode)
            }
            
            
        }

        
    }
    
    func calcLoc(row: Int, col: Int, numofRowsCols: (Int, Int)) -> SCNVector3 {
        
        var x: Float
        var z: Float
        
        if (col - (numofRowsCols.1 - 1) / 2) <= 0 || (((numofRowsCols.0 - 1) / 2) - row) <= 0 {
            x = Float((col - (numofRowsCols.1 - 1) / 2))
            x =  x * Config.unitSpace + Config.targetSizeRadius
            z = Float(((numofRowsCols.0 - 1) / 2) - row)
            z = z * Config.unitSpace - Config.targetSizeRadius
        } else {
            x = Float((col - (numofRowsCols.1 - 1) / 2))
            x =  x * Config.unitSpace - Config.targetSizeRadius
            z = Float(((numofRowsCols.0 - 1) / 2) - row)
            z = z * Config.unitSpace + Config.targetSizeRadius

        }
      
        
        return(SCNVector3(x,z,0))
    
    }

    
    
    func calcRowsCols(dim1: Float, dim2: Float) -> (rows: Int, cols: Int) {
        let rows = Int((dim1/(2 * (Config.targetSpacing + Config.targetSizeRadius))).rounded(.down))
        let cols = Int((dim2 / (2 * (Config.targetSpacing + Config.targetSizeRadius))).rounded(.down))
        
        return(rows: rows, cols: cols)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        //check if it is target plane
        if (planeNode.name != curTargetPlaneNode!.name) {
            return
        }
        
        /*
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
        */
 
 
        //remove all existing targets on the plane
        //curTargetPlaneNode?.enumerateChildNodes({(node, _) in node.removeFromParentNode()})
        
        //createTargetArray(planeAnchor: planeAnchor, planeNode: planeNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        //check if it is target plane
        if planeNode.name != curTargetPlaneNode!.name {
            return
        }
        
        curTargetPlaneNode?.enumerateChildNodes({(node, _) in node.removeFromParentNode()})
        curTargetPlaneNode?.removeFromParentNode()
        curTargetPlaneNode = nil
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]
        
        sceneView.autoenablesDefaultLighting = true


        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
