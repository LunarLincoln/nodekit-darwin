//
//  NKBinding_FileSystem.swift
//  NodeKitMac
//
//  Created by Guy Barnard on 9/19/14.
//  Copyright (c) 2014 nodekit.io. All rights reserved.
//

import Cocoa

internal class NKFileSystem: NSObject {
    
    class func exists (path: String) -> Bool {
        return NSFileManager().fileExistsAtPath(path)
    }
    
    class func getDirectoryAsync(module: String, completionHandler: nodeCallBack) {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(defaultQueue) {
            completionHandler(NSNull(), self.getDirectory(module))
        }
    }
    
    class func getDirectory(module: String) -> NSArray {
            var path=self.getPath(module)
            
            let dirContents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil) as NSArray!
            
            return dirContents
    }
    
    class func statAsync(module: String, completionHandler: nodeCallBack) {
        
        let ret = self.stat(module)
        if (ret != nil)
        {
            completionHandler(NSNull(), ret)
            
        } else
        {
            completionHandler("stat error", NSNull())
        }
    }
    
    class func stat(module: String) -> Dictionary<String, NSObject>? {
        
        var path=module; //self.getPath(module)
        
        var storageItem  = Dictionary<String, NSObject>()
        
        var readError: NSError?
        
        let attr = NSFileManager.defaultManager().attributesOfItemAtPath(path, error: &readError) as NSDictionary!
        
        if let error = readError {
            return nil;
        }
        
        if (attr == nil)
        {
            return nil;
        }
        
        storageItem["birthtime"] = attr[NSFileCreationDate] as NSDate!
        storageItem["size"] = attr[NSFileSize] as NSNumber!
        storageItem["mtime"] = attr[NSFileModificationDate] as NSDate!
        storageItem["path"] = path as NSString!
        
        switch attr[NSFileType] as NSString!
        {
        case NSFileTypeDirectory:
            storageItem["filetype"] = "Directory"
            break
        case NSFileTypeRegular:
            storageItem["filetype"] = "File"
            break
        case NSFileTypeSymbolicLink:
            storageItem["filetype"] = "SymbolicLink"
            break
        default:
            storageItem["filetype"] = "File"
            break
        }
        
        return storageItem
    }
    
    class func getContentAsync(storageItem: NSDictionary! , completionHandler: nodeCallBack) {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(defaultQueue) {

            completionHandler(NSNull(), self.getContent(storageItem))
        }
    }
    
    class func getContent(storageItem: NSDictionary!) -> NSString {
        
        var path = storageItem["path"] as NSString!;
        
        var originalEncoding: UnsafeMutablePointer<UInt> = nil
        var readError: NSError?
        
        var content = NSString(contentsOfFile: path, usedEncoding: originalEncoding, error: &readError)
        
        return content!
    }


    class func getSource(module: String) -> NSString! {
        
        var path=getPath(module);
        
        if (path=="")
        {
          return ""
        }
        
        var originalEncoding: UnsafeMutablePointer<UInt> = nil
        var readError: NSError?
        
        var content = NSString(contentsOfFile: path, usedEncoding: originalEncoding, error: &readError)
        
        return content!
    }
    
    class func write (path: String, content: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> Bool {
        return content.writeToFile(path, atomically: true, encoding: encoding, error: nil)
    }
    
    class func getPath(module: String) -> String {
        
        var directory = module.stringByDeletingLastPathComponent
        var fileName = module.lastPathComponent
        var fileExtension = fileName.pathExtension
        fileName = fileName.stringByDeletingPathExtension
        
        if (fileExtension=="") {
            fileExtension = "js"
        }
        
        var mainBundle : NSBundle = NSBundle.mainBundle()
        var resourcePath:String! = mainBundle.resourcePath
        
        var path = mainBundle.pathForResource(fileName, ofType: fileExtension, inDirectory: directory)
        
        if (path == nil)
        {
            NSLog("Error - source file not found: %@", directory + "/" + fileName + "." + fileExtension)
            return ""
        }
        
        return path!;
        
    }
    
    class func getFullPath(parentModule: String, module: String) -> NSString!{
        
        if (parentModule != "")
        {
            var parentPath = parentModule.stringByDeletingLastPathComponent
            
            var id = parentPath + module
            return id
        }
        else
        {
            return module
        }
    }
    
    
}