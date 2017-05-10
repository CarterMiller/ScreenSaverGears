//
//  ScreenSaverGears.swift
//  ScreenSaverGears
//
//  Created by Russell Morgan on 10/05/2017.
//  Copyright © 2017 Carter Miller. All rights reserved.
//

import Cocoa
import ScreenSaver

struct CogData {
    var centreX: Double = 100.0
    var centreY: Double = 100.0
    var radius: Double  = 50.0
    var toothCount      = 18
    var toothIndex      = 0
    var ratio           = 1.0
    var angleStart      = 0.0
    var spokeCount      = 5
    var alpha           = 1.0
    
    init(centreX : Double, centreY: Double, radius: Double, toothCount: Int, spokeCount: Int)
    {
        self.centreX    = centreX
        self.centreY    = centreY
        self.radius     = radius
        self.toothCount = toothCount
        self.spokeCount = spokeCount
    }
    
    init(radius: Double, toothIndex: Int, toothCount: Int, spokeCount: Int)
    {
        // toothIndex on previous cog
        self.radius     = radius
        self.toothIndex = toothIndex
        self.toothCount = toothCount
        self.spokeCount = spokeCount
    }
    
    init(centreX: Double, centreY: Double, toothCount: Int, spokeCount: Int)
    {
        self.centreX    = centreX
        self.centreY    = centreY
        self.toothCount = toothCount
        self.spokeCount = spokeCount
    }
}

class ScreenSaverGears: ScreenSaverView
{
    var screenHeight    : CGFloat   = 0.0
    var screenWidth     : CGFloat   = 0.0
    
    var cogs : [CogData] = []
    
    var angleMain   = 0
    var angleStep   = 2
    
    var countdownTimerMax   = 5
    var countdownTimer      = 5
    
    var alphaDelta          = 0.005
    
    var angleCos: [Double] = []
    var angleSin: [Double] = []
    

    
    override init?(frame: NSRect, isPreview: Bool)
    {
        super.init(frame: frame, isPreview: isPreview)
        
        let screen : NSScreen = NSScreen.main()!
        screenHeight = screen.frame.size.height
        screenWidth = screen.frame.size.width
        
        initialiseTrig()
        for _ in 0...20
        {
            addGear()
        }
        initialiseCogs()
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func startAnimation()
    {
        super.startAnimation()
    }
    
    override func stopAnimation()
    {
        super.stopAnimation()
    }
    
    override func animateOneFrame()
    {
        self.needsDisplay = true
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }

    func addGear()
    {
        if cogs.count == 0
        {
            // add the first one
            let radius          = Double(arc4random_uniform(100) + 30)
            let widthAvailable  = Double(self.frame.width) - 2.0 * radius * 1.3
            let heightAvailable = Double(self.frame.height) - 2.0 * radius * 1.3
            
            let x           = Double(arc4random_uniform(UInt32(widthAvailable))) + radius * 1.3
            let y           = Double(arc4random_uniform(UInt32(heightAvailable))) + radius * 1.3
            let toothCount  = Int(arc4random_uniform(10) + 10)
            let spokeCount  = Int(arc4random_uniform(10) + 2)
            
            cogs.append(CogData(centreX : x, centreY: y, radius: radius, toothCount: toothCount, spokeCount: spokeCount))
        }
        else
        {
            let cogPrevious = cogs[cogs.count - 1]
            
            let radius      = cogPrevious.radius * (1.0 + (20 - Double(arc4random_uniform(40))) / 100.0) // +/- 20%
            
            var toothCount  = cogPrevious.toothCount + 1 - Int(arc4random_uniform(3))
            
            if toothCount < 6 {
                toothCount = 6
            }
            if toothCount > 24 {
                toothCount = 24
            }
            let spokeCount  = Int(arc4random_uniform(10) + 3)
            
            let toothIndex  = Int(arc4random_uniform(UInt32(cogPrevious.toothCount)))
            
            // check for valid position by moving round toothIndex
            cogs.append(CogData(radius: radius, toothIndex: toothIndex, toothCount: toothCount, spokeCount: spokeCount))
            
            initialiseCog(cogs.count - 1)
            
            var toothIndexOffset = 0
            while !validCog(cogs.last!) && (toothIndexOffset < cogPrevious.toothCount - 1) && cogs[cogs.count - 1].radius > 30
            {
                toothIndexOffset += 1
                
                if toothIndexOffset == cogPrevious.toothCount - 1
                {
                    toothIndexOffset = 0
                    cogs[cogs.count - 1].radius -= 5
                }
                cogs[cogs.count - 1].toothIndex = (cogs[cogs.count - 1].toothIndex + 1) % cogPrevious.toothCount
                
                initialiseCog(cogs.count - 1)
                
            }
            
            if !validCog(cogs[cogs.count - 1])
            {
                cogs.removeLast()
            }
            
            /**
             if cogs.count > 50
             {
             cogs.remove(at: 0)
             }
             **/
            /**
             if cogs.count == 0
             {
             addGear()
             NSLog("Back to zero, start again")
             }
             initialiseCogs()
             **/
            countdownTimer = countdownTimerMax
            
        }
    }
    
    func validCog(_ cog: CogData)-> Bool
    {
        // the cog is valid if it fits into the screen
        // and if it doesn't overlap with any other cog
        // return false as soon as it breaks a condition
        
        if cog.radius < 30 {
            return false
        }
        
        if cog.radius < cogs[cogs.count - 1].radius * 0.8 {
            return false
        }
        if cog.radius > cogs[cogs.count - 1].radius * 1.2 {
            return false
        }
        
        // check for fitting on-screen
        if cog.centreX < cog.radius * 1.3 {
            return false
        }
        if cog.centreY < cog.radius * 1.3 {
            return false
        }
        if cog.centreX > Double(self.frame.width) - cog.radius * 1.3 {
            return false
        }
        if cog.centreY > Double(self.frame.height) - cog.radius * 1.3 {
            return false
        }
        
        // check for overlap with any other cog (ignoring previous)
        for index in 0..<cogs.count - 2
        {
            let xDelta = cogs[index].centreX - cog.centreX
            let yDelta = cogs[index].centreY - cog.centreY
            
            let spacing = sqrt(pow(xDelta, 2) + pow(yDelta, 2))
            
            if spacing < 1.5 * (cog.radius + cogs[index].radius)
            {
                return false
            }
            
        }
        
        return true
    }
    
    func initialiseTrig()
    {
        for angle in 0..<360 {
            angleCos.append(cos(Double(angle).toRadians()))
            angleSin.append(sin(Double(angle).toRadians()))
        }
    }
    
    func initialiseGears()
    {
        // we don't need to do this if it is already defined
        if cogs.count > 0 {
            return
        }
        
        cogs.append(CogData(centreX : 75.0, centreY: 95.0, radius: 50.0, toothCount: 15, spokeCount: 7))
        cogs.append(CogData(radius: 25.0, toothIndex: 14, toothCount: 9, spokeCount: 4))
        cogs.append(CogData(radius: 30.0, toothIndex: 1, toothCount: 12, spokeCount: 5))
        cogs.append(CogData(radius: 22.0, toothIndex: 2, toothCount: 13, spokeCount: 3))
        cogs.append(CogData(radius: 35.0, toothIndex: 5, toothCount: 15, spokeCount: 4))
        cogs.append(CogData(radius: 50.0, toothIndex: 7, toothCount: 15, spokeCount: 6))
    }
    
    func initialiseCog(_ index: Int)
    {
        if index == 0 {
            return
        }
        
        // set the turn ratio
        cogs[index].ratio = -cogs[index - 1].ratio * (Double(cogs[index - 1].toothCount) / Double(cogs[index].toothCount))
        
        // set the centre
        let r = (cogs[index - 1].radius + cogs[index].radius) * 1.25
        let angleStepPrevious = 360.0 / Double(cogs[index - 1].toothCount)
        let angle = Double(cogs[index].toothIndex) * angleStepPrevious
        
        cogs[index].centreX = r * cosAngle(angle) + cogs[index - 1].centreX
        cogs[index].centreY = r * sinAngle(angle) + cogs[index - 1].centreY
        
        cogs[index].angleStart = angle - 180.0 - Double(180 / cogs[index].toothCount) - cogs[index - 1].angleStart.truncatingRemainder(dividingBy: angleStepPrevious)
    }
    
    func initialiseCogs()
    {
        // assumes each cog is engaged in turn - so +ve / -ve / +ve, etc.,
        for index in 0..<cogs.count {
            initialiseCog(index)
        }
        
    }
    
    func removeExpiredCogs()
    {
        // should only ever be the first one
        if cogs[0].alpha <= 0 {
            cogs.remove(at: 0)
        }
        if cogs.count == 0
        {
            addGear()
            initialiseCogs()
        }
        
    }

    override func draw(_ rect: NSRect)
    {
        countdownTimer -= 1
        if countdownTimer == 0
        {
            addGear()
            initialiseCogs()
        }
        
        removeExpiredCogs()
        
        angleMain += angleStep
        // if angleMain > 360 {
        //     angleMain -= 360
        // }
        let context: CGContext = NSGraphicsContext.current()!.cgContext;
        
        for (index, cog) in self.cogs.enumerated() {
            
            cogs[index].alpha -= alphaDelta
            
            context.setStrokeColor(NSColor.black.withAlphaComponent(CGFloat(cog.alpha)).cgColor)
            context.setLineWidth(2.0)
            
            let toothSpaceAngle = 360.0 / Double(cog.toothCount)
            let toothStepAngle  = toothSpaceAngle / 8.0
            
            // draw teeth
            var x0Initial = 0.0
            var y0Initial = 0.0
            
            for toothIndex in 0..<cog.toothCount {
                
                let toothIndexDouble = Double(toothIndex)
                
                let angleCentre = Double(cog.angleStart + cog.ratio * Double(self.angleMain) + toothIndexDouble * toothSpaceAngle)
                let radiusTooth = cog.radius * 1.3
                
                let x0 = cog.centreX + radiusTooth * self.cosAngle(angleCentre - 4.0 * toothStepAngle)
                let y0 = cog.centreY + radiusTooth * self.sinAngle(angleCentre - 4.0 * toothStepAngle)
                if toothIndex == 0 {
                    x0Initial = x0
                    y0Initial = y0
                }
                
                let x1 = cog.centreX + radiusTooth * self.cosAngle(angleCentre - 3.0 * toothStepAngle)
                let y1 = cog.centreY + radiusTooth * self.sinAngle(angleCentre - 3.0 * toothStepAngle)
                
                let x2 = cog.centreX + cog.radius * self.cosAngle(angleCentre - toothStepAngle)
                let y2 = cog.centreY + cog.radius * self.sinAngle(angleCentre - toothStepAngle)
                
                let x3 = cog.centreX + cog.radius * self.cosAngle(angleCentre + toothStepAngle)
                let y3 = cog.centreY + cog.radius * self.sinAngle(angleCentre + toothStepAngle)
                
                let x4 = cog.centreX + radiusTooth * self.cosAngle(angleCentre + 3.0 * toothStepAngle)
                let y4 = cog.centreY + radiusTooth * self.sinAngle(angleCentre + 3.0 * toothStepAngle)
                
                let x5 = cog.centreX + radiusTooth * self.cosAngle(angleCentre + 4.0 * toothStepAngle)
                let y5 = cog.centreY + radiusTooth * self.sinAngle(angleCentre + 4.0 * toothStepAngle)
                
                context.move(to: CGPoint(x: x0, y: y0))
                context.addLine(to: CGPoint(x: x1, y: y1))
                context.addLine(to: CGPoint(x: x2, y: y2))
                context.addLine(to: CGPoint(x: x3, y: y3))
                
                context.addLine(to: CGPoint(x: x4, y: y4))
                context.addLine(to: CGPoint(x: x5, y: y5))
                
                if toothIndex == cog.toothCount - 1 {
                    context.addLine(to: CGPoint(x: x0Initial, y: y0Initial))
                }
            }
            context.strokePath()
            
            // draw spokes
            context.setStrokeColor(NSColor.gray.withAlphaComponent(CGFloat(cog.alpha)).cgColor)
            context.setLineWidth(1.0)
            
            // inner circle
            let radiusInner = cog.radius * 0.2
            for angle in stride(from: 0, through: 360, by: 10){
                let x = cog.centreX + radiusInner * self.cosAngle(Double(angle))
                let y = cog.centreY + radiusInner * self.sinAngle(Double(angle))
                if angle == 0 {
                    context.move(to: CGPoint(x: x, y: y))
                }
                else
                {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
            }
            // outer circle
            let radius = cog.radius * 0.9
            for angle in stride(from: 0, through: 360, by: 5){
                let x = cog.centreX + radius * self.cosAngle(Double(angle))
                let y = cog.centreY + radius * self.sinAngle(Double(angle))
                if angle == 0 {
                    context.move(to: CGPoint(x: x, y: y))
                }
                else
                {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let angleDelta = 180 / cog.spokeCount
            for spokeIndex in 0..<cog.spokeCount {
                let angle = Int(360 * Double(spokeIndex) / Double(cog.spokeCount)) + Int(cog.ratio * Double(self.angleMain))
                
                let xTop1 = cog.centreX + radius * self.cosAngle(Double(angle - 5))
                let yTop1 = cog.centreY + radius * self.sinAngle(Double(angle - 5))
                let xTop2 = cog.centreX + radius * self.cosAngle(Double(angle + 5))
                let yTop2 = cog.centreY + radius * self.sinAngle(Double(angle + 5))
                
                let xBottom1 = cog.centreX + radiusInner * self.cosAngle(Double(angle - angleDelta))
                let yBottom1 = cog.centreY + radiusInner * self.sinAngle(Double(angle - angleDelta))
                let xBottom2 = cog.centreX + radiusInner * self.cosAngle(Double(angle + angleDelta))
                let yBottom2 = cog.centreY + radiusInner * self.sinAngle(Double(angle + angleDelta))
                
                context.move(to: CGPoint(x: xTop1, y: yTop1))
                context.addLine(to: CGPoint(x: xBottom1, y: yBottom1))
                context.move(to: CGPoint(x: xTop2, y: yTop2))
                context.addLine(to: CGPoint(x: xBottom2, y: yBottom2))
                
            }
            context.strokePath()
        }

    }
    func cosAngle(_ angle : Double) -> Double
    {
        let angleInRange = Int(angle) % 360
        if angleInRange < 0 {
            return angleCos[angleInRange + 360]
        }
        return angleCos[angleInRange]
    }
    
    
    func sinAngle(_ angle : Double) -> Double
    {
        let angleInRange = Int(angle) % 360
        if angleInRange < 0 {
            return angleSin[angleInRange + 360]
        }
        return angleSin[angleInRange]
    }

}

extension Double
{
    func toRadians() -> Double
    {
        return self * Double.pi / 180
    }
}

