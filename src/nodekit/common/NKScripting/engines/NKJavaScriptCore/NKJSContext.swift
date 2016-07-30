/*
* nodekit.io
*
* Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
* Portions Copyright 2015 XWebView
* Portions Copyright (c) 2014 Intel Corporation.  All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import JavaScriptCore

extension JSContext: NKScriptContextHost {
    
    public var NKid: Int { get { return objc_getAssociatedObject(self, unsafeAddressOf(NKJSContextId)) as! Int; } }

    public func NKgetScriptContext(id: Int, options: [String: AnyObject] = Dictionary<String, AnyObject>(), delegate cb: NKScriptContextDelegate) -> Void {
        
        let context = self

        log("+NodeKit JavaScriptCore JavaScript Engine E\(id)")
        
        objc_setAssociatedObject(context, unsafeAddressOf(NKJSContextId), id, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        
        context.NKPrepareEnvironment()
  
        cb.NKScriptEngineDidLoad(context)
        
        cb.NKScriptEngineReady(context)
    
    }
    
    internal func NKPrepareEnvironment() -> Void {
        
        let context = self;
        
        let logjs: @convention(block) (String) -> () = { body in
            
            log(body)
            
        }
        
        let scriptingBridge = JSValue(newObjectInContext: context)
        
        scriptingBridge.setObject(unsafeBitCast(logjs, AnyObject.self), forKeyedSubscript: "log")
        context.setObject(unsafeBitCast(scriptingBridge, AnyObject.self), forKeyedSubscript: "NKScriptingBridge")
        
        let appjs = NKStorage.getResource("lib-scripting/init_jsc.js", NKScriptChannel.self)
        
        let script = "function loadinit(){\n" + appjs! + "\n}\n" + "loadinit();" + "\n"
        
        context.NKinjectJavaScript(NKScriptSource(source: script, asFilename: "io.nodekit.scripting/lib-scripting/init_jsc", namespace: "io.nodekit.scripting.init"))
    }
}

extension JSContext: NKScriptContext {

    public func NKloadPlugin(object: AnyObject, namespace: String, options: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>() ) -> Void {
    
        let mainThread: Bool = (options["MainThread"] as? Bool) ?? false

        let bridge: NKScriptExportType = NKScriptExportType(rawValue: ((options["PluginBridge"] as? Int) ?? NKScriptExportType.NKScriptExport.rawValue))!
        
        switch bridge {
        
        case .JSExport:
        
            self.setObjectForNamespace(object, namespace: namespace)
            
            log("+Plugin object \(object) is bound to \(namespace) with JSExport channel")
            
            objc_setAssociatedObject(self, unsafeAddressOf(object), object, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            return
        default:
            
            let channel: NKScriptChannel
            
            if (mainThread) {
            
                channel = NKScriptChannel(context: self, queue: dispatch_get_main_queue() )
           
            } else {
            
                channel = NKScriptChannel(context: self)
           
            }
            
            channel.userContentController = self
            
            guard let pluginValue = channel.bindPlugin(object, toNamespace: namespace) else {return;}
            
            objc_setAssociatedObject(self, unsafeAddressOf(pluginValue), pluginValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func NKinjectJavaScript(script: NKScriptSource) -> Void {
      
        let item = NKJSCScript(context: self, script: script)
        
        objc_setAssociatedObject(self, unsafeAddressOf(item), item, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private class var evalSequenceNumber: Int {
        
        struct sequence {
        
            static var number: Int = 0
        
        }
        
        let temp = sequence.number
        
        sequence.number += 1
        
        return temp
    }


    public func NKevaluateJavaScript(javaScriptString: String,
        completionHandler: ((AnyObject?,
        NSError?) -> Void)?) {
        
        let result = self.evaluateScript(javaScriptString)
        
        completionHandler?(result, nil)
    }
    
    internal func NKevaluateJavaScript(javaScriptString: String, withSourceURL: NSURL,
        completionHandler: ((AnyObject?,
        NSError?) -> Void)?) {
     
        let result = self.evaluateScript(javaScriptString, withSourceURL: withSourceURL)
        completionHandler?(result, nil)
    }

    public func NKserialize(object: AnyObject?) -> String {
    
        var obj: AnyObject? = object
        
        if let val = obj as? NSValue {
        
            obj = val as? NSNumber ?? val.nonretainedObjectValue
       
        }

        
        if let o = obj as? NKScriptValue {
        
            return o.namespace
       
        } else if let o1 = obj as? NKScriptExport {
        
            if let o2 = o1 as? NSObject {
            
                if let scriptObject = o2.NKscriptObject {
                
                    return scriptObject.namespace
               
                } else {
                
                    let scriptObject = NKScriptValueNative(object: o2, inContext: self)
                    
                    objc_setAssociatedObject(o2, unsafeAddressOf(NKScriptValue), scriptObject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
                    return scriptObject.namespace
                }
            }
        } else if let s = obj as? String {
         
            let d = try? NSJSONSerialization.dataWithJSONObject([s], options: NSJSONWritingOptions(rawValue: 0))
            
            let json = NSString(data: d!, encoding: NSUTF8StringEncoding)!
            
            return json.substringWithRange(NSMakeRange(1, json.length - 2))
        } else if let n = obj as? NSNumber {
            
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
            
                return n.boolValue.description
            
            }
            
            return n.stringValue
        
        } else if let date = obj as? NSDate {
          
            return "\"\(date.toJSONDate())\""
        
        } else if let _ = obj as? NSData {
       
            // TODO: map to Uint8Array object
        
        } else if let a = obj as? [AnyObject] {
        
            return "[" + a.map(self.NKserialize).joinWithSeparator(", ") + "]"
       
        } else if let d = obj as? [String: AnyObject] {
        
            return "{" + d.keys.map {"\"\($0)\": \(self.NKserialize(d[$0]!))"}.joinWithSeparator(", ") + "}"
        
        } else if obj === NSNull() {
        
            return "null"
       
        } else if obj == nil {
       
            return "undefined"
       
        }
       
        return "'\(obj!.description)'"
    }

    public static func NKcurrentContext() -> NKScriptContext! {
        
        let currentContext = NSThread.currentThread().threadDictionary.objectForKey("nk.CurrentContext") as? NKScriptContext
        
        if (currentContext != nil) {
        
            return currentContext
            
        } else {
        
            return JSContext.currentContext()
        
        }
    }

    // private methods
    private func setObjectForNamespace(object: AnyObject, namespace: String) -> Void {

        let global = self.globalObject

        var fullNameArr = namespace.characters.split {$0 == "."}.map(String.init)
        
        let lastItem = fullNameArr.removeLast()
        
        if (fullNameArr.isEmpty) {
        
            self.setObject(object, forKeyedSubscript: lastItem)
            
            return
        
        }

        let jsv = fullNameArr.reduce(global, combine: {previous, current in

            if (previous.hasProperty(current)) {
            
                return previous.objectForKeyedSubscript(current)
           
            }
            
            let _jsv = JSValue(newObjectInContext: self)
            
            previous.setObject(_jsv, forKeyedSubscript: current)
            
            return _jsv
        })
        
        jsv.setObject(object, forKeyedSubscript: lastItem)
    }
}

extension JSContext: NKScriptContentController {
    internal func NKaddScriptMessageHandler (scriptMessageHandler: NKScriptMessageHandler, name: String) {
    
        let context: JSContext = self
        
        let name = name
        
        guard let messageHandlers = context.objectForKeyedSubscript("NKScripting")?.objectForKeyedSubscript("messageHandlers") else {return }

        var namedHandler: JSValue

        if (messageHandlers.hasProperty(name)) {
        
            namedHandler = messageHandlers.objectForKeyedSubscript(name)
       
        } else {
        
            namedHandler = JSValue(object: Dictionary<String, AnyObject>(), inContext: context)
            
            messageHandlers.setValue(namedHandler, forProperty: name)
        
        }
        
        let postMessage: @convention(block) [String: AnyObject] -> () = { body in
            
            NSThread.currentThread().threadDictionary.setObject(true, forKey: "nk.jsCallThread")
            
            scriptMessageHandler.userContentController(didReceiveScriptMessage: NKScriptMessage(name: name, body: body))
            
            NSThread.currentThread().threadDictionary.setObject(false, forKey: "nk.jsCallThread")
         
        }

        let postMessageSync: @convention(block) [String: AnyObject] -> AnyObject! = { body in
        
            NSThread.currentThread().threadDictionary.setObject(true, forKey: "nk.jsCallThread")
            
            let result = scriptMessageHandler.userContentControllerSync(didReceiveScriptMessage: NKScriptMessage(name: name, body: body))
            
            NSThread.currentThread().threadDictionary.setObject(false, forKey: "nk.jsCallThread")
            
            return self.NKserialize(result)
        }

        namedHandler.setObject(unsafeBitCast(postMessage, AnyObject.self), forKeyedSubscript: "postMessage")
        
        namedHandler.setObject(unsafeBitCast(postMessageSync, AnyObject.self), forKeyedSubscript: "postMessageSync")
      
    }

    internal func NKremoveScriptMessageHandlerForName (name: String) {
        
        let cleanup = "delete NKScripting.messageHandlers.\(name)"
        
        self.NKevaluateJavaScript(cleanup, completionHandler: nil)
    
    }

}