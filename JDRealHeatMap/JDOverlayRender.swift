//
//  JDOverlayRender.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/19.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

/**
 這個類別只需要知道畫圖相關的，不用記住任何點Data
 只要交給Producer製造還給他一個RowData
 */
class JDHeatOverlayRender:MKOverlayRenderer
{
    var Lastimage:CGImage?
    var CanDraw:Bool{
        get{
            return (dataReference.count != 0)
        }
    }
    var Bitmapsize:IntSize = IntSize()
    var dataReference:[UTF8Char] = []
    var BytesPerRow:Int = 0
    
    init(heat overlay: JDHeatOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.7
    }

    func caculateRowFormData()->(data:[RowFormHeatData],rect:CGRect)?
    {
        return nil
    }
    
    /**
     drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
     */
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return CanDraw
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if(!CanDraw)
        {
            return
        }
        guard let overlay = overlay as? JDHeatOverlay else {
            return
        }
        if let lastTimeMoreHighSolutionImgae = Lastimage
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            context.draw(lastTimeMoreHighSolutionImgae, in: mapCGRect)
            return
        }
        //
        func getHeatMapContextImage()->CGImage?
        {
            //More Detail
            func CreateContextOldWay()->CGImage?
            {
                func heatMapCGImage()->CGImage?
                {
                    let tempBuffer = malloc(Bitmapsize.width * Bitmapsize.height * 4)
                    memcpy(tempBuffer, &dataReference, BytesPerRow * Bitmapsize.height)
                    defer
                    {
                        free(tempBuffer)
                    }
                    let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
                    let alphabitmapinfo = CGImageAlphaInfo.premultipliedLast.rawValue
                    if let contextlayer:CGContext = CGContext(data: tempBuffer, width: Bitmapsize.width, height: Bitmapsize.height, bitsPerComponent: 8, bytesPerRow: BytesPerRow, space: rgbColorSpace, bitmapInfo: alphabitmapinfo)
                    {
                        return contextlayer.makeImage()
                    }
                    print("Create fail")
                    return nil
                }
                
                if let cgimage = heatMapCGImage()
                {
                    let cgsize:CGSize = CGSize(width: Bitmapsize.width, height: Bitmapsize.height)
                    UIGraphicsBeginImageContext(cgsize)
                    if let contexts = UIGraphicsGetCurrentContext()
                    {
                        let rect = CGRect(origin: CGPoint.zero, size: cgsize)
                        contexts.draw(cgimage, in: rect)
                        return contexts.makeImage()
                    }
                }
                
                defer {
                    UIGraphicsEndImageContext()
                }
                
                return nil
            }
            return CreateContextOldWay()
        }
        if let tempimage = getHeatMapContextImage()
        {
            let mapCGRect = rect(for: overlay.boundingMapRect)
            Lastimage = tempimage
            context.clear(mapCGRect)
            context.draw(Lastimage!, in: mapCGRect)
        }
        else{
            print("cgcontext error")
        }
    }
}

class JDRadiusPointOverlayRender:JDHeatOverlayRender
{
    override func caculateRowFormData()->(data:[RowFormHeatData],rect:CGRect)?
    {
        guard let overlay = overlay as? JDHeatRadiusPointOverlay else {
            return nil
        }
        var rowformArr:[RowFormHeatData] = []
        //
        for heatpoint in overlay.HeatPointsArray
        {
            let mkmappoint = heatpoint.MidMapPoint
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            let localX = GlobalCGpoint.x - (rect(for: overlay.boundingMapRect).origin.x)
            let localY = GlobalCGpoint.y - (rect(for: overlay.boundingMapRect).origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let radiusinMKDistanse:Double = heatpoint.radiusInMKDistance
            let radiusmaprect = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistanse, height: radiusinMKDistanse))
            let radiusCGDistance = rect(for: radiusmaprect).width
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel), localCGpoint: loaclCGPoint, radius: radiusCGDistance)
            rowformArr.append(newRow)
        }
        let cgsize = rect(for: overlay.boundingMapRect)
        return (rect:cgsize,data:rowformArr)
    }
}

class JDDotPointOverlayRender:JDHeatOverlayRender
{    
    override func caculateRowFormData()->(data:[RowFormHeatData],rect:CGRect)?
    {
        guard let DotPointoverlay = overlay as? JDHeatDotPointOverlay else {
            return nil
        }
        //
        var rowformArr:[RowFormHeatData] = []
        let OverlayCGRect:CGRect = rect(for: DotPointoverlay.boundingMapRect)
        for heatpoint in DotPointoverlay.HeatPointsArray
        {
            let mkmappoint = heatpoint.MidMapPoint
            let GlobalCGpoint:CGPoint = self.point(for: mkmappoint)
            
            let localX = GlobalCGpoint.x - (OverlayCGRect.origin.x)
            let localY = GlobalCGpoint.y - (OverlayCGRect.origin.y)
            let loaclCGPoint = CGPoint(x: localX, y: localY)
            //
            let newRow:RowFormHeatData = RowFormHeatData(heatlevel: Float(heatpoint.HeatLevel), localCGpoint: loaclCGPoint, radius: 0.0)
            rowformArr.append(newRow)
        }
        let cgsize = rect(for: overlay.boundingMapRect)
        return (rect:cgsize,data:rowformArr)
    }
}


