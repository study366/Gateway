//
//  WebViewController.swift
//
//
//  Created by Gaspar Gyorgy on 27/03/16.
//  Copyright © 2016 George Gaspar. All rights reserved.
//

import CoreData
import UIKit

@available(iOS 9.0, *)
class WebViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet var close: UIButton!
    @IBOutlet var webView: UIWebView!
    // var mutableData: NSMutableData!

    deinit {
        webView = nil
        print(#function, "\(self)")
    }

    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.scrollView.bounces = true
        webView.scalesPageToFit = true

        let ciphertext = cipherText.getCipherText(deviceId)
        let requestURL = URL(string: serverURL + "/example/index.html")
        let request = URLRequest.requestWithURL(requestURL!, method: "GET", queryParameters: nil, bodyParameters: nil, headers: ["M-Device": ciphertext], cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20, isCacheable: nil, contentType: "", bodyToPost: nil)

        webView.loadRequest(request)
        view.addSubview(webView)
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
    }

    func reloadPage(_: AnyObject) {
        webView.reload()
    }

    func webViewDidStartLoad(_: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        NSLog("WebView started loading...")
    }

    func webViewDidFinishLoad(_: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        NSLog("WebView finished loading...")
    }

    func webView(_: UIWebView, shouldStartLoadWith request: URLRequest, navigationType _: UIWebView.NavigationType) -> Bool {
        // We have to also close the webview, without user-interaction.
        if request.url!.relativePath == "/example/tabularasa.jsp" {
            webView = nil
            dismiss(animated: true, completion: nil)
        }

        return true
    }

    @IBAction func close(_: UIButton) {
        webView = nil
        dismiss(animated: true, completion: {
            print(self)
        })
    }

    func webView(_: UIWebView, didFailLoadWithError _: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        /*
         let alertView:UIAlertView = UIAlertView()

         alertView.title = "Error!"
         alertView.message = "Connection Failure: \(error!.localizedDescription)"
         alertView.delegate = self
         alertView.addButtonWithTitle("OK")
         alertView.show()
         */
        NSLog("There was a problem loading the web page!")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
