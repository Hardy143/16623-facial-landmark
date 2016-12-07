//
//  SessionHandler.swift
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 15.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

import AVFoundation

class SessionHandler : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {
    var session = AVCaptureSession()
    let layer = AVSampleBufferDisplayLayer()
    let sampleQueue = dispatch_queue_create("com.zweigraf.DisplayLiveSamples.sampleQueue", DISPATCH_QUEUE_SERIAL)
    let faceQueue = dispatch_queue_create("com.zweigraf.DisplayLiveSamples.faceQueue", DISPATCH_QUEUE_SERIAL)
    let wrapper = DlibWrapper()
    
    var currentMetadata: [AnyObject]
    
    override init() {
        currentMetadata = []
        super.init()
    }
    
    func openSession() {
        let device = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            .map { $0 as! AVCaptureDevice }
            .filter { $0.position == .Front}
            .first!
        
        let input = try! AVCaptureDeviceInput(device: device)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        
        let metaOutput = AVCaptureMetadataOutput()
        metaOutput.setMetadataObjectsDelegate(self, queue: faceQueue)
    
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        if session.canAddOutput(metaOutput) {
            session.addOutput(metaOutput)
        }
        
        session.commitConfiguration()
        
        let settings: [NSObject : AnyObject] = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        output.videoSettings = settings
    
        // availableMetadataObjectTypes change when output is added to session.
        // before it is added, availableMetadataObjectTypes is empty
        metaOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        wrapper.prepare()
        
        
        
        
        session.startRunning()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        
        if !currentMetadata.isEmpty {
            let boundsArray = currentMetadata
                .flatMap { $0 as? AVMetadataFaceObject }
                .map { (faceObject) -> NSValue in
                    let convertedObject = captureOutput.transformedMetadataObjectForMetadataObject(faceObject, connection: connection)
                    //var Yaw=NSValue(CGRect: convertedObject.)
                    return NSValue(CGRect: convertedObject.bounds)
            }
            //speed estimate
//            let durationtime = currentMetadata
//                .flatMap { $0 as? AVMetadataFaceObject }
//                .map { (faceObject) -> NSValue in
//                    let convertedObject = captureOutput.transformedMetadataObjectForMetadataObject(faceObject, connection: connection)
//                    return NSValue(CMTime: convertedObject.duration)
            }
            
            
// Pose Estimation
//            let YawAngle = currentMetadata
//                .flatMap { $0 as? AVMetadataFaceObject }
//                .map { (faceObject) -> NSValue in
//                    return NSValue(nonretainedObject: faceObject.yawAngle)
//            }
//             print("YawAngle =", YawAngle)
            
            let RollAngle = currentMetadata
                .flatMap { $0 as? AVMetadataFaceObject }
                .map { (faceObject) -> NSValue in
                    return NSValue(nonretainedObject: faceObject.rollAngle)
            }
            print("RollAngle = \(RollAngle)")
            
            
            wrapper.doWorkOnSampleBuffer(sampleBuffer, inRects: boundsArray)
            
            
            //print(durationtime)//speed estimate
        }

        layer.enqueueSampleBuffer(sampleBuffer)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        print("DidDropSampleBuffer")
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        currentMetadata = metadataObjects
    }


