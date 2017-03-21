//
//  MyURLProtocol.swift
//  NSURLProtocolExample
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.//

import UIKit
import SwiftyJSON
import CoreData
import Foundation
import Kanna


var requestCount = 0
var pattern_ = "https://([^/]+)(/example/tabularasa.jsp.*?)(/$|$)"
var pattern_rs = "https://([^/]+)(/example/tabularasa.jsp.*?JSESSIONID=)"

class MyURLProtocol: URLProtocol {

    var connection: NSURLConnection!
    var mutableData: NSMutableData!
    var response: URLResponse!
    var httpresponse: HTTPURLResponse!
    var newRequest:NSMutableURLRequest!
    
    override class func canInit(with request: URLRequest) -> Bool {
    
        if URLProtocol.property(forKey: "MyURLProtocolHandledKey", in: request) != nil {
            return false
        }
        
        if URLProtocol.property(forKey: "MyRedirectHandledKey", in: request) != nil {
            return false
        }
        
        print("Request #\(requestCount+=1): URL = \(request.url!.absoluteString)")
        NSLog("Relative path ==> %@", request.url!.relativePath)


        return true
        
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ aRequest: URLRequest,to bRequest: URLRequest) -> Bool {
            return super.requestIsCacheEquivalent(aRequest, to:bRequest)
    }
    
    override func startLoading() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        if AFNetworkReachabilityManager.shared().isReachable {
            NSLog("AFNetwork is reachable...")
            
            // 1
            let possibleCachedResponse = self.cachedResponseForCurrentRequest()
            
            if let cachedResponse = possibleCachedResponse {
                
                NSLog("Serving response from Cache. url == %@", self.request.url!.absoluteString)
                
                // 2
                let data = cachedResponse.value(forKey: "data") as! Data
                let mimeType = cachedResponse.value(forKey: "mimeType") as! String
                let encoding = cachedResponse.value(forKey: "encoding") as? String?
                
                // 3
                let response = URLResponse(url: self.request.url!, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: encoding!)
                
                // 4
                self.client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client!.urlProtocol(self, didLoad: data)
                self.client!.urlProtocolDidFinishLoading(self)
                
                
                
            } else {
                
                // 5
                NSLog("Serving response from NSURLConnection. url == %@", self.request.url!.absoluteString)
                
                
                if request.url!.relativePath == "/login/HelloWorld" {
                    
                    newRequest = (self.request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
                    URLProtocol.setProperty(true, forKey: "MyURLProtocolHandledKey", in: newRequest)
                    /* We set the headerfield and value that the Apache webserver will accept */
                    
                    let ciphertext = cipherText!.getCipherText(deviceId)
                    newRequest.setValue(ciphertext, forHTTPHeaderField: "M-Device")
                    
                    newRequest.setValue("M", forHTTPHeaderField: "M")
                    self.connection = NSURLConnection(request: newRequest as URLRequest, delegate: self)
                    
                }
                
                if request.url!.relativePath != "/example/tabularasa.jsp" && request.url!.relativePath != "/login/HelloWorld"{
                    
                    newRequest = (self.request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
                    URLProtocol.setProperty(true, forKey: "MyURLProtocolHandledKey", in: newRequest)
                    /* We set the headerfield and value that the Apache webserver will accept */
                    
                    newRequest.setValue("M", forHTTPHeaderField: "M")
                    self.connection = NSURLConnection(request: newRequest as URLRequest, delegate: self)
                    
                }
                
            }
            
        } else {
            
            NSLog("AFNetwork failed to respond......")
            
            // 1
            let possibleCachedResponse = self.cachedResponseForCurrentRequest()
            
            if let cachedResponse = possibleCachedResponse {
                
                NSLog("Serving response from Cache. url == %@", self.request.url!.absoluteString)
                
                // 2
                let data = cachedResponse.value(forKey: "data") as! Data
                let mimeType = cachedResponse.value(forKey: "mimeType") as! String
                let encoding = cachedResponse.value(forKey: "encoding") as? String?
                
                // 3
                let response = URLResponse(url: self.request.url!, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: encoding!)
                
                // 4
                self.client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client!.urlProtocol(self, didLoad: data)
                self.client!.urlProtocolDidFinishLoading(self)
                
            } else {
                
                let failedResponse = HTTPURLResponse(url: self.request.url!, statusCode: 0, httpVersion: nil, headerFields: nil)
                
                self.client?.urlProtocol(self, didReceive: failedResponse!, cacheStoragePolicy: .notAllowed)
                
                self.client?.urlProtocolDidFinishLoading(self)
                
                var errorOnLogin:RequestManager?
                
                errorOnLogin = RequestManager(url: "https://milo.crabdance.com/login/HelloWorld", errors: "No internet connection!")
                errorOnLogin!.getResponse { _ in }
                
            }
            
        }
    }
    
    override func stopLoading() {
        if self.connection != nil {
            self.connection.cancel()
        }
        self.connection = nil
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

    }
    
    
    func connection(_ connection: NSURLConnection!, willSendRequest request: URLRequest, redirectResponse response: URLResponse?) -> URLRequest? {
        
        let prefs:UserDefaults = UserDefaults.standard
        var xtoken = prefs.value(forKey: "X-Token")

        if let httpResponse = response as? HTTPURLResponse {
        
        if httpResponse.statusCode == 302 {

                let newRequest = (self.request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
                URLProtocol.setProperty(true, forKey: "MyRedirectHandledKey", in: newRequest)
           //   self.client?.URLProtocol(self, wasRedirectedToRequest: newRequest, redirectResponse: response!)
                
                let jsonHeaders:NSDictionary = httpResponse.allHeaderFields as NSDictionary
                
                xtoken = jsonHeaders.value(forKey: "X-Token") as! NSString
                NSLog("X-Token: ", xtoken as! NSString);

                prefs.setValue(xtoken, forKey: "X-Token")
                //NSLog("Sending Request from %@ to %@", response!.url!, request.url!);
                
            
                let match = RegEx()
                let url = request.url!.absoluteString
                var requestLogin:RequestManager?
                
                if match.containsMatch(pattern_, inString: url) {
                    
                    let adminUrl = match.replaceMatches(pattern_rs, inString: url, withString:"https://milo.crabdance.com/login/admin?JSESSIONID=")
                    let sessionID = match.replaceMatches(pattern_rs, inString: url, withString:"")
                    
                    prefs.setValue(sessionID, forKey: "JSESSIONID")
                    NSLog("SessionId ==> %@", sessionID!)

                    requestLogin = RequestManager(url: adminUrl!, errors: "")
                    
                    requestLogin?.getResponse {
                        (json: JSON, error: NSError?) in
                        
                        print(json)
                        
                    }
                }
                
              //  NSLog("Url to be redirected ==> %@", request.URL!.absoluteString)
                
            }
            

        }
        
      //  self.client!.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response!)
        return request
        
    }
    
    func connection(_ connection: NSURLConnection!, didReceiveResponse response: URLResponse!) {
        self.client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        self.response = response
        self.mutableData = NSMutableData()
        self.httpresponse = response as? HTTPURLResponse!

        
    }
    
    func connection(_ connection: NSURLConnection!, didReceiveData data: Data!) {
        
        self.client!.urlProtocol(self, didLoad: data)
        self.mutableData.append(data)
        
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection!) {
        self.client!.urlProtocolDidFinishLoading(self)
        self.saveCachedResponse()
    }
    
    // It sends a call to RequestManager to present an alert view about the error
    func connection(_ connection: NSURLConnection!, didFailWithError error: NSError!) {
        self.client!.urlProtocol(self, didFailWithError: error)

        if (newRequest != nil) {
        var errorOnLogin:RequestManager?
        
        errorOnLogin = RequestManager(url: "https://milo.crabdance.com/login/HelloWorld", errors: "Connection error!")
        errorOnLogin?.getResponse { _ in }
        
        
        }
        
    }
    
    func saveCachedResponse () {
      //  NSLog("Saving cached response url == %@", self.request.URL!.absoluteString)
        
        // 1
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        // Create a private NSManagedObjectContext with private queue concurrency type and use it to access CoreData whenever operating on a background thread.
        let context = delegate.managedObjectContext
       
        //let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        //privateMOC.parentContext = context
        
        // 2
        let cachedResponse = NSEntityDescription.insertNewObject(forEntityName: "CachedURLResponse", into: context) as NSManagedObject
        
        if let httpResponse = response as? HTTPURLResponse {
        
            switch(httpResponse.statusCode) {
            case 200:
               
                if request.url!.relativePath != "/login/HelloWorld" {
                    
                cachedResponse.setValue(self.mutableData, forKey: "data")
                cachedResponse.setValue(self.request.url!.absoluteString, forKey: "url")
                cachedResponse.setValue(Date(), forKey: "timestamp")
                cachedResponse.setValue(self.response.mimeType, forKey: "mimeType")
                cachedResponse.setValue(self.response.textEncodingName, forKey: "encoding")
                cachedResponse.setValue(self.httpresponse.statusCode, forKey: "statusCode")
                    
                    
                    if request.url!.relativePath == "/example/jsR/app.js" {

                    let urldata:Data = self.mutableData as Data
                    let convertedString = NSString(data: urldata, encoding: String.Encoding.utf8.rawValue)
                    
                        let newString:NSString = convertedString!.replacingOccurrences(of: "(uuid)", with: "("+("\"\((deviceId))\"")+")") as NSString
                        let newurldata:Data = newString.data(using: String.Encoding.ascii.rawValue)!
                        self.mutableData.append(newurldata)
                        cachedResponse.setValue(self.mutableData, forKey: "data")
                        
                    }
        
                }
                
            case 502:
                
                if request.url!.relativePath == "/login/HelloWorld" {
                    let prefs:UserDefaults = UserDefaults.standard
                    prefs.set(0, forKey: "ISWEBLOGGEDIN")
                    
                    var errorOnLogin:RequestManager?
                    
                        let data: Data = self.mutableData as Data
                        
                        if let jsonData:NSDictionary = (try? JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers )) as? Dictionary<String, AnyObject> as NSDictionary? {
                            
                            let errmsg = jsonData["Session creation"] as! String
                            errorOnLogin = RequestManager(url: "https://milo.crabdance.com/login/HelloWorld", errors: errmsg)
                            errorOnLogin?.getResponse { _ in }
                        
                    }


                }
                
            case 503:

                if request.url!.relativePath == "/login/HelloWorld" {
                    let prefs:UserDefaults = UserDefaults.standard
                    prefs.set(0, forKey: "ISWEBLOGGEDIN")
                    
                    var errorOnLogin:RequestManager?
                    
                    let data: Data = self.mutableData as Data
                    
                    if let result = (NSString(data: data, encoding: String.Encoding.ascii.rawValue)) as? String {
                        
                        if let doc = Kanna.HTML(html: result, encoding: String.Encoding.ascii) {
                            errorOnLogin = RequestManager(url: "https://milo.crabdance.com/login/HelloWorld", errors: doc.title!)
                            errorOnLogin?.getResponse { _ in }
                            
                        }

                    }
    
                }
                
            default:
                
                NSLog("Url was redirected.")

            }
            
        }
    
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        
        }
        
    }
    
    // FIXMES: app.js is modified and stored in cache like this, however, it won't take effect untill app restart, because still the original app.js is loaded. 
    func cachedResponseForCurrentRequest() -> NSManagedObject? {
        // 1
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext
        
        // 2
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "CachedURLResponse", in: context)
        fetchRequest.entity = entity
        
        // 3
        let predicate = NSPredicate(format:"url == %@", self.request.url!.absoluteString)
        fetchRequest.predicate = predicate
        
        
        // 4
        let possibleResult = try?context.fetch(fetchRequest) as! Array<NSManagedObject>
        /*
        let fetchRequests = NSFetchRequest(entityName: "CachedURLResponse")
        let results = try?context.executeFetchRequest(fetchRequests) as! [CachedURLResponse]
        
        for managedObject in results! {
            if let url = managedObject.valueForKey("url"), statusCode = managedObject.valueForKey("statusCode") {
                print("\(url) \(statusCode)")
            }
        }*/
        
        // 5
        if let result = possibleResult {
            if !result.isEmpty {
             //   NSLog("Serving response from cache; url == %@", self.request.URL!.absoluteString)

              return result[0]
            
                }
            }
        
        return nil
    }

}
