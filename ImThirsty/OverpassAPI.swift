//
//  overpass_api.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 20/02/2021.
//  Copyright © 2021 Tristan Charpentier. All rights reserved.
//

import Foundation

struct Amenity: Codable {
    let type: String
    let id: Int
    let lat: Double
    let lon: Double
    let tags: Dictionary<String, String>
}

struct Response: Codable {
    let version: Double
    let generator: String
    let osm3s: Dictionary<String, String>
    let elements: Array<Amenity>?
}

class OverpassApi {
    
    var rawURL: String = "https://z.overpass-api.de/api/interpreter"
    
    func generateBody(amenity: String, radius: Int, lat: Double, long: Double) -> Data {
        let body = "[out:json][timeout:25];(node[\"amenity\"=\"" + amenity + "\"](around: " + String(radius) + ", " + String(lat) + ", " + String(long) + "););out body;"
        return Data(body.utf8)
    }
    
    func fetchAmenities(amenity: String, lat: Double, long: Double, results: Int32) -> Response? {
        if let url = URL(string: self.rawURL) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = generateBody(amenity: amenity, radius: 400, lat: lat, long: long)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print("THE API CALL FAILED")
                }
                guard let data = data else { return }

                let resData = try! JSONDecoder().decode(Response.self, from: data)
                print(resData)
            }.resume()
        }
        return nil
    }
}
