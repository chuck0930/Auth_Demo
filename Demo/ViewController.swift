//
//  ViewController.swift
//  Demo
//
//  Created by Chuck on 2021/10/07.
//

import UIKit
class ViewController: UIViewController {

    @IBOutlet var prepareAuthButton:UIButton!
    @IBOutlet var prepareSignButton:UIButton!
    @IBOutlet var getResultButton:UIButton!
    @IBOutlet var resultTextView:UITextView!
    @IBOutlet var redirectURISwitch:UISwitch!
    
    var requestId:String?
    let clientId = "1002-b6urctvxekbjx4hkfhvoimtwn28maft9.apps.wemixnetwork.com"
    let sampleQuery = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhY2Nlc3NUb2tlbiI6ImV5SmhiR2NpT2lKSVV6STFOaUlzSW5SNWNDSTZJa3BYVkNKOS5leUoxYzJWeWFXUWlPaUpxYjJWNWQyTWlMQ0poWkdSeVpYTnpJam9pTUhnMVpqSmhNVEUxWTJNek5URTJOV1poWlRVeE1UWmxaR1UwWkRjNE1UaGtZelpqWldWbE1tUTBJaXdpZFhWcFpDSTZJaUlzSW1WNGNDSTZNVFl6TXpZNE5EYzVOaXdpYVdGMElqb3hOak16TlRrNE16azJMQ0p6ZFdJaU9pSTRabU01WkdFelppMWlaakl5TFRRMVlXTXRZakZpTXkxa1pXTmlOVEZtTmpkaE9UQWlmUS5JdDFLbWFQWnc3eDlqYThHREJOMTVPQl9HeDViZUtnYnN1c25NSkhXX1NFIiwiYWRkcmVzcyI6IjB4NWYyYTExNWNjMzUxNjVmYWU1MTE2ZWRlNGQ3ODE4ZGM2Y2VlZTJkNCIsImhhc2hEYXRhIjpbeyJoYXNoIjoiMHg5MjAwMjUwZDE2NTEyMDNhNDhhMzlkZjdlYzkwNzEwMjAwNjU1ZTViMGMxZWI2ZGM5OGExZGYyZDZmNjY5ZmQxIn1dLCJ0eXBlIjpbMV19.Ttn5fZ5WqSoMkhvxvRjGeBxIBHQ3SnjOG66rVa71oIk=";
    let redirectURI = "wemix1002-b6urctvxekbjx4hkfhvoimtwn28maft9://walletDemo.com"
    var useRedirect:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func copyToClipboard(_ sender:UIButton) {
        UIPasteboard.general.string = resultTextView.text
    }
    
    @IBAction func switctOnChange(_ sender:UISwitch) {
        self.useRedirect = sender.isOn
    }
    
    @IBAction func prepareButtonTouched(_ sender:UIButton) {
        
        let type:App2AppAuthType = sender == prepareAuthButton ? .auth : .sign
        let deeplinkAction:String = type == .auth ? "authentication" : "signature"
        let apiProvider = WemixWalletAPIProvider()
        apiProvider.requestPrepareAuth(clientId: clientId, type: type) { Result in
            //
            switch (Result) {
            case .success(let response):
                print(response)
                
                self.requestId = response.requestId
                
                var deeplink = "wemix-wallet://wemixnetwork.com/" + deeplinkAction + "?request_id=" + response.requestId
                
                if type == .sign {
                    deeplink = deeplink + "&query=" + self.sampleQuery;
                }
                
                if self.useRedirect == true {
                    deeplink = deeplink + "&redirect_uri=" + self.redirectURI
                }
                
                
                if let url = URL(string: deeplink) {
                    DispatchQueue.main.async {
                        self.resultTextView.text = "Prepare Success: " + response.requestId + ", expires: " +  String(response.expiresIn);
                        self.getResultButton.isEnabled = true;
                        UIApplication.shared.open(url, options: [:])
                    }
                    
                }
            break
            case .failure(let error):
                print(error)
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let status, _, let data):
                        DispatchQueue.main.async {
                            self.resultTextView.text = "Prepare Error: " + String(status)
                            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                                self.resultTextView.text = self.resultTextView.text + " data: " + dataString
                            }
                        }
                        break
                    default:
                        break
                    }
                }
            break
            }
        }
       
    }
    
    @IBAction func getResultButtonTouched(_ sender:UIButton) {
        let apiProvider = WemixWalletAPIProvider()
        guard let requestId = self.requestId else {
            return
        }
        apiProvider.requestAuthResult(requestId: requestId, clientId: clientId) { Result in
            switch (Result) {
            case .success(let response):
                print(response)
                DispatchQueue.main.async {
                    self.resultTextView.text = self.resultTextView.text + "\nGetResult Success: " + response.status;
                    if (response.status == "confirm") {
                        self.resultTextView.text = self.resultTextView.text + " data: " + response.result!
                    }
                }
                break
            case .failure(let error):
                print(error)
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let status, let response, let data):
                        print(response)
                        DispatchQueue.main.async {
                            self.resultTextView.text = self.resultTextView.text + "\nGetResult Error: " + String(status)
                            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                                self.resultTextView.text = self.resultTextView.text + " data: " + dataString
                            }
                        }
                        break
                    default:
                        break
                    }
                }
                break
            }
        }
    }
}

