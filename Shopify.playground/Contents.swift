//: Playground - noun: a place where people can play

import Foundation
import PlaygroundSupport

// Let asynchronous code run
PlaygroundPage.current.needsIndefiniteExecution = true;
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

class OrdersTotalCounter {
    private let secretToken: String
    private let requestUrl: String
    private let ordersPerPage = 50
    private var amoutnOfPages = 0
    public let baseApiUrl = "https://shopicruit.myshopify.com/admin"
    public var total: Double = 0.0
    let session = URLSession.shared

    
    
    init(secretToken: String) {
        print("Init")
        self.secretToken = secretToken
        self.requestUrl = "\(baseApiUrl)/orders.json?access_token=\(secretToken)"
    }
    
    
    func fetchTotal() {
        
        let countUrl  = URL(string:"\(baseApiUrl)/orders/count.json?access_token=\(secretToken)")!
        var pagesCount = 0
        
        let task = session.dataTask(with: countUrl) { (data, response, error) in
            
            guard error == nil else {
                print("Error: Counter url returned error");
                print(error)
                return
            }
            
            guard let responseData = data else {
                print("Error: requested url returned empty data");
                return
            }
            
            do {
                
                guard let countJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    print("Error: Can't parse json response.")
                    return
                }
                
                
                guard let parsedCount = countJSON["count"] as? Int else {
                    print("Error: Can't parse json response.")
                    return
                }
                
                pagesCount = self.getPagesCount(count: parsedCount)
                
                self.fetchOrders(count: pagesCount)
                
            } catch {
                print("Error: Can't parse json response.")
            }
            
        }
        
        task.resume()
        
    }
    
    
    private func fetchOrders(count: Int) {
        print("Page count: \(count)")
        let queue = DispatchQueue(label: "com.orest.hazda")
        
        // Creates group to know whe all of the requests are done, and data was saved to total
        let group = DispatchGroup()
        for page in 1 ... count {
            fetchOrdersByPage(page: page, group: group)
            
        }
        
        group.notify(queue: queue) { [weak self] in
            
            guard let this = self else {
                print("OrdersTotalCounter doesn't exist")
                return
            }
            
            
            print(String(format: "Total: %.2f", this.total))
        }
    }
    
    private func fetchOrdersByPage(page: Int, group: DispatchGroup) {
        
        var pageUrl = URLComponents(string: requestUrl)!
        group.enter()
        
        pageUrl.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "access_token", value: self.secretToken),
            
        ]
        
        
        let task =  session.dataTask(with: pageUrl.url!) { (data, response, error) in
            
            guard error == nil else {
                print("Error: Page url returned error");
                print(error)
                return
            }
            
            guard let responseData = data else {
                print("Error: requested url returned empty data");
                return
            }
            
            do {
                
                guard let ordersJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    print("Error: Can't parse json response.")
                    return
                }
                
                
                if let orders = ordersJSON["orders"] as? [Any] {
                    
                    let sum = self.calculateSum(items: orders)
                    
                    self.total += sum
                    
                    print("SUM PER PAGE \(page): \(sum)")
                    
                }
                
                
                
                
            } catch {
                print("Error: Can't parse json response.")
            }
            group.leave()
            
        }
        
        task.resume()
        
    }
    
    // MARK: - Helpers
    
    func getPagesCount(count: Int) -> Int {
        var pages = 0.0
        
        if count > 0 {
            pages = Double(count) / Double(self.ordersPerPage)
        }
        
        return Int(ceil(pages))
    }
    
    func calculateSum(items: [Any]) -> Double {
        var sum: Double = 0.0
        
        for item in items {
            if let orderObject = item as? [String: Any] {
                if let price = orderObject["total_price_usd"] as? String {
                    sum += Double(price)!
                }
            }
        }
        
        return sum
    }

}

let counter = OrdersTotalCounter(secretToken: "c32313df0d0ef512ca64d5b336a0d7c6")
counter.fetchTotal()
