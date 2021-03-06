/*
* nodekit.io
*
* Copyright (c) 2016-7 OffGrid Networks. All Rights Reserved.
* Portions Copyright (c) 2013 GitHub, Inc. under MIT License
*
* Licensed under the Apache License, Version 2.0 (the "License") -> Void;
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

#if os(iOS)
    
import Foundation

import WebKit

class NKE_WebContentsUI: NKE_WebContentsBase {

    internal weak var webView: UIWebView? = nil

     override init() {
        
        super.init()
    
    }

    required init(window: NKE_BrowserWindow) {
    
        super.init()

         _window = window
        
        _id = window.id

        _window._events.on("did-finish-load") { (id: Int) in
        
            self.NKscriptObject?.invokeMethod("emit", withArguments: ["did-finish-load"], completionHandler: nil)
        
        }

        _window._events.on("did-fail-loading") { (id: Int, error: String) in
        
            self.NKscriptObject?.invokeMethod("emit", withArguments: ["did-fail-loading", error], completionHandler: nil)
        
        }

        webView = _window._webView as? UIWebView

        _initIPC()
       
    }

}

extension NKE_WebContentsUI: NKE_WebContentsProtocol {

    // Messages to renderer are sent to the window events queue for that renderer
    func ipcSend(channel: String, replyId: String, arg: [AnyObject]) -> Void {

        let payload = NKE_IPC_Event(sender: 0, channel: channel, replyId: replyId, arg: arg)
        
        _window._events.emit("nk.IPCtoRenderer", payload)
    
    }

    // Replies to renderer to the window events queue for that renderer
    func ipcReply(dest: Int, channel: String, replyId: String, result: AnyObject) -> Void {
        guard let window = _window else {return;}
    
        let payload = NKE_IPC_Event(sender: 0, channel: channel, replyId: replyId, arg: [result])
        
        window._events.emit("nk.IPCReplytoRenderer", payload)
    
    }

    func loadURL(url: String, options: [String: AnyObject]) -> Void {
    
        guard let webView = self.webView else {return;}
        
        let request = _getURLRequest(url, options: options)
        
        webView.loadRequest(request)
    
    }

    func getURL() -> String { return self.webView?.stringByEvaluatingJavaScriptFromString("window.location") ?? "" }
    
    func getTitle() -> String { return self.webView?.stringByEvaluatingJavaScriptFromString("document.title") ?? ""  }
    
    func isLoading()  -> Bool { return self.webView?.loading ?? false }

    func stop() -> Void { self.webView?.stopLoading() }
    
    func reload() -> Void { self.webView?.reload() }
    
    func reloadIgnoringCache() -> Void { self.webView?.reload() }
    
    func canGoBack() -> Bool { return self.webView?.canGoBack ?? false }
    
    func canGoForward() -> Bool { return self.webView?.canGoForward ?? false }
    
    func goBack() -> Void {self.webView?.goBack() }
    
    func goForward() -> Void { self.webView?.goForward() }

    func executeJavaScript(code: String, userGesture: String) -> Void {
    
        guard let context = _window._context else {return;}
    
        context.evaluateJavaScript(code, completionHandler: nil)
    
    }
    
    func setUserAgent(userAgent: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    
    func getUserAgent()  -> String {
        
        return self.webView?.stringByEvaluatingJavaScriptFromString("navigator.userAgent") ?? ""
        
    }

    /*  NOT IMPLEMENTED:
    func undo() -> Void { NKE_WebContentsBase.NotImplemented() }
    func redo() -> Void { NKE_WebContentsBase.NotImplemented() }
    func cut() -> Void { self.webView?.cut(self); }
    func copyclipboard() -> Void { self.webView?.copy(self); }
    func paste() -> Void { self.webView?.paste(self) }
    func pasteAndMatchStyle() -> Void { self.webView?.pasteAsPlainText(self) }
    func delete() -> Void { self.webView?.delete(self) }
    func selectAll() -> Void { self.webView?.selectAll(self) }
    func replace(text: String) -> Void { self.webView?.replaceSelectionWithText(text) }

    func downloadURL(url: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    func isWaitingForResponse()  -> Bool { NKE_WebContentsBase.NotImplemented(); return false }
    func canGoToOffset(offset: Int) -> Bool { NKE_WebContentsBase.NotImplemented() }
    func clearHistory() -> Void { NKE_WebContentsBase.NotImplemented() }
    func goToIndex(index: Int) -> Void { NKE_WebContentsBase.NotImplemented() }
    func goToOffset(offset: Int) -> Void { NKE_WebContentsBase.NotImplemented() }
    func isCrashed() -> Void { NKE_WebContentsBase.NotImplemented() }
    func insertCSS(css: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    func setAudioMuted(muted: Bool) -> Void { NKE_WebContentsBase.NotImplemented() }
    func isAudioMuted()  -> Bool { NKE_WebContentsBase.NotImplemented(); return false }
    func unselect() -> Void { NKE_WebContentsBase.NotImplemented() }
    func replaceMisspelling(text: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    func hasServiceWorker(callback: NKScriptValue) -> Void { NKE_WebContentsBase.NotImplemented() }
    func unregisterServiceWorker(callback: NKScriptValue) -> Void { NKE_WebContentsBase.NotImplemented() }
    func print(options: [String: AnyObject]) -> Void { NKE_WebContentsBase.NotImplemented() }
    func printToPDF(options: [String: AnyObject], callback: NKScriptValue) -> Void { NKE_WebContentsBase.NotImplemented() }
    func addWorkSpace(path: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    func removeWorkSpace(path: String) -> Void { NKE_WebContentsBase.NotImplemented() }
    func openDevTools(options: [String: AnyObject]) -> Void { NKE_WebContentsBase.NotImplemented() }
    func closeDevTools() -> Void { NKE_WebContentsBase.NotImplemented() }
    func isDevToolsOpened() -> Void { NKE_WebContentsBase.NotImplemented() }
    func toggleDevTools() -> Void { NKE_WebContentsBase.NotImplemented() }
    func isDevToolsFocused() -> Void { NKE_WebContentsBase.NotImplemented() }
    func inspectElement(x: Int, y: Int) -> Void { NKE_WebContentsBase.NotImplemented() }
    func inspectServiceWorker() -> Void { NKE_WebContentsBase.NotImplemented() }
    func enableDeviceEmulation(parameters: [String: AnyObject]) -> Void { NKE_WebContentsBase.NotImplemented() }
    func disableDeviceEmulation() -> Void { NKE_WebContentsBase.NotImplemented() }
    func sendInputEvent(event: [String: AnyObject]) -> Void { NKE_WebContentsBase.NotImplemented() }
    func beginFrameSubscription(callback: NKScriptValue) -> Void { NKE_WebContentsBase.NotImplemented() }
    func endFrameSubscription() -> Void { NKE_WebContentsBase.NotImplemented() }
    func savePage(fullPath: String, saveType: String, callback: NKScriptValue) -> Void { NKE_WebContentsBase.NotImplemented() }
    var session: NKScriptValue? { get { return nil } }
    var devToolsWebContents: NKE_WebContentProtocol { get } */


    // Event:  'did-frame-finish-load'
    // Event:  'did-get-redirect-request'
    // Event:  'did-get-redirect-request'
    // Event:  'did-start-loading'
    // Event:  'did-stop-loading'
    // Event:  'dom-ready'
    // Event:  'login'
    // Event:  'new-window'
    // Event:  'page-favicon-updated'
    // Event:  'plugin-crashed'
    // Event:  'select-client-certificate'
    // Event:  'will-navigate'
    // Event:  'certificate-error'
    // Event:  'crashed'
    // Event:  'destroyed'
    // Event:  'devtools-closed'
    // Event:  'devtools-focused'
    // Event:  'devtools-opened'
    
}

#endif
