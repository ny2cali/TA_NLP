//
//  Config.swift
//  TargetAnnhilator
//
//  Created by Jaspal Singh on 3/7/18.
//  Copyright © 2018 Jaspal Singh. All rights reserved.
//

import Foundation
import ARKit

class Config  {
    
    static let minHorzPlaneLength = 0.5 as Float
    static let minHorzPlaneWidth = 0.5 as Float
    static let minVerPlaneHeight = 0.2 as Float
    static let minVerPlaneWidth = 0.2 as Float
    
    static let targetSizeRadius = 0.05 as Float
    static let targetSizeHeight = 0.02 as Float

    static let targetSpacing = 0.1 as Float
    
    static let unitSpace = 2 * (targetSizeRadius + targetSpacing) as Float
    
    typealias targetShape = SCNCylinder
    
    typealias ballShape = SCNSphere
    
    static let ballSize = targetSizeRadius * 0.8 as Float
    static let ballWeight = 10 as Float
    
}
