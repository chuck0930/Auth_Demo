//
//  WemixWalletAPIProvider.swift
//  Demo
//
//  Created by Chuck on 2021/10/07.
//

import Foundation
struct PrepareReponse: Decodable {
    let requestId: String
    let expiresIn: Double
    
    enum CodingKeys:String, CodingKey {
        case requestId = "request_id"
        case expiresIn = "expires_in"
        
    }
}

struct GetResultReponse: Decodable {
    let requestId: String
    let status: String
    let result: String?
    
    enum CodingKeys:String, CodingKey {
        case requestId = "request_id"
        case status, result
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum AuthBaseURL:String {
    case alpha = "https://alpha-oauth.wemix.co"
    case dev = "https://dev-oauth.wemix.co"
    case stage = "https://stg-oauth.wemixnetwork.com"
    case production = "https://oauth.wemixnetwork.com"
}

enum AuthV2 {
    case prepare(clientId:String, type:App2AppAuthType)
    case getResult(requestId:String, clientId:String)
    
    var method:HTTPMethod {
        switch self {
        case .prepare( _, _):
            return .post
        case .getResult( _, _):
        return .get
        
        }
    }
    
    static let baseURL: String = AuthBaseURL.alpha.rawValue
    var path:String {
        var aPath = ""
        switch (self) {
        case .prepare( _, _):
            aPath = "/api/v2/a2a/prepare"
            break
        case .getResult( _, _):
            aPath = "/api/v2/a2a/result"
        }
        
        return aPath
    }
    
    var params:[URLQueryItem] {
        switch (self) {
        case .prepare( _, _):
            return [];
        case .getResult(let requestId, let clientId):
            return [URLQueryItem(name:"request_id", value: requestId), URLQueryItem(name:"client_id", value: clientId)]
        }
    }
    
    var url:URL {
        var components = URLComponents(string:AuthV2.baseURL + self.path)
        components?.queryItems = self.params
        return (components?.url)!
    }
    
    var request: URLRequest {
        var request = URLRequest(url: self.url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = self.method.rawValue
        
        switch (self) {
        case .prepare(let clientId, let type):
            let json:[String:Any] = ["client_id":clientId, "type":type.rawValue];
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            break
        default:
            break
        }
        return request
    }
}

enum APIError: LocalizedError {
    case unknownError
    case httpError(status:Int, response:HTTPURLResponse, data:Data?)
}

enum App2AppAuthType:String {
    case auth = "auth"
    case sign = "sign"
}

class WemixWalletAPIProvider {
    let session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }

    func requestPrepareAuth(clientId:String,
                            type:App2AppAuthType,
                            completion: @escaping (Result<PrepareReponse, Error>) -> Void) {
        
        let request = AuthV2.prepare(clientId: clientId, type: type).request
        
        let task: URLSessionDataTask = session
            .dataTask(with: request) { data, urlResponse, error in
                guard let response = urlResponse as? HTTPURLResponse else {
                    completion(.failure(APIError.unknownError))
                    return
                }
                
                guard (200...399).contains(response.statusCode) else {
                    completion(.failure(APIError.httpError(status: response.statusCode, response: response, data: data)))
                    return
                }

                if let data = data,
                    let response = try? JSONDecoder().decode(PrepareReponse.self, from: data) {
                    completion(.success(response))
                    return
                }
                completion(.failure(APIError.unknownError))
        }

        task.resume()
    }
    
    func requestAuthResult (requestId:String,
                            clientId:String,
                            completion: @escaping (Result<GetResultReponse, Error>) -> Void) {
     
        let request = AuthV2.getResult(requestId: requestId, clientId: clientId).request
        
        let task: URLSessionDataTask = session
            .dataTask(with: request) { data, urlResponse, error in
                guard let response = urlResponse as? HTTPURLResponse else {
                    completion(.failure(APIError.unknownError))
                    return
                }
                
                guard (200...399).contains(response.statusCode) else {
                    completion(.failure(APIError.httpError(status: response.statusCode, response: response,  data: data)))
                    return
                }

                if let data = data,
                    let response = try? JSONDecoder().decode(GetResultReponse.self, from: data) {
                    completion(.success(response))
                    return
                }
                completion(.failure(APIError.unknownError))
        }

        task.resume()
    }
}
