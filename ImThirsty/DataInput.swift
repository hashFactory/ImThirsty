//
//  DataInput.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 20/09/2019.
//  Copyright © 2019 Tristan Charpentier. All rights reserved.
//

import Foundation

class DataInput {
    
    typealias DataPoint = (lat: Double, long: Double, timetable: String, dist: Double, heading: Double)
    typealias Coordinates = (horaire: String, lat: Double, long: Double)
    
    // Offline
    var myToiletDoubles = Array<Double>()
    var myWaterDoubles = Array<Double>()
    var allToiletCoordinates:[Coordinates] = []
    var allWaterCoordinates:[Coordinates] = []
    var allHoraires = Array<String>()
    
    // OverpassAPI
    let rawURL: String = "https://z.overpass-api.de/api/interpreter"
    var resultCount: Int = 0
    var wantedResults: Int = 0
    var radius: Int = 200
    var amenities: [Amenity] = []
    var amenityString: String = ""
    
    var lat: Double = 0
    var long: Double = 0
    var heading: Double = 0
    
    func readWaterFile(name: String) {
        
        if let path = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                let fileData = try String(contentsOfFile: path, encoding: .utf8)
                myWaterDoubles = fileData.components(separatedBy: .newlines).compactMap(Double.init)
            } catch {
                print(error)
            }
        }
        
        processWater()
    }
    
    func readToiletFile(name: String) {
        
        print("read file")
        
        if let path = Bundle.main.path(forResource: (name + "_horaires"), ofType: "txt") {
            do {
                let fileData = try String(contentsOfFile: path, encoding: .utf8)
                allHoraires = fileData.components(separatedBy: .newlines)
                print(allHoraires)
                print("worked")
            } catch {
                print("didn't work")
                print(error)
            }
        }
        
        if let path = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                let fileData = try String(contentsOfFile: path, encoding: .utf8)
                myToiletDoubles = fileData.components(separatedBy: .newlines).compactMap(Double.init)
            } catch {
                print(error)
            }
        }
        
        processToilet()
    }
    
    func processWater() {
        for i in 0..<(myWaterDoubles.count / 2) {
            allWaterCoordinates.append(("", myWaterDoubles[i * 2], myWaterDoubles[i * 2 + 1]))
        }
    }
    
    func processToilet() {
        for i in 0..<(myToiletDoubles.count / 2) {
            //print(allHoraires.count)
            allToiletCoordinates.append((allHoraires[i], myToiletDoubles[i * 2], myToiletDoubles[i * 2 + 1]))
        }
    
    }
    
    func toRadians(value: Double) -> Double {
        return value * .pi / 180.0
    }
    
    func hyp(a: Double, b: Double) -> Double {
        return sqrt(a * a + b * b)
    }
    
    func getHeading(lat1: Double, long1: Double, lat2: Double, long2: Double, currentHeading: Double) -> Double {
        
        let startLat = toRadians(value: lat2)
        let startLong = toRadians(value: long2)
        let finalLat = toRadians(value: lat1)
        let finalLong = toRadians(value: long1)
        
        let y = sin(finalLong - startLong) * cos(finalLat)
        let x = cos(startLat) * sin(finalLat) - sin(startLat) * cos(finalLat) * cos(finalLong - startLong)
        let bearing = (atan2(y, x) * (180.0 / .pi) + 360.0 - currentHeading).truncatingRemainder(dividingBy: 360.0)
        
        return bearing
    }

    func getRealDistance(lat1: Double, long1: Double, lat2: Double, long2: Double) -> Double {
        
        // Haversine formula
        let earthRadius = 6371000.0 // Meters
        let phi1 = toRadians(value: lat1)
        let phi2 = toRadians(value: long1)
        
        let deltaPhi = toRadians(value: lat2 - lat1)
        let deltaLambda = toRadians(value: long2 - long1)
        
        let a = sin(deltaPhi / 2.0) * sin(deltaPhi / 2.0) + cos(phi1) * cos(phi2) * sin(deltaLambda / 2.0) * sin(deltaLambda / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        
        return earthRadius * c
    }
    
    func getNewMax(topNums: [DataPoint]) -> (Int, Double) {
        //print(topNums)
        var maxValue: (index: Int, dist: Double) = (0, 0)
        
        for i in 0..<topNums.count {
            if topNums[i].dist > maxValue.dist {
                maxValue = (i, topNums[i].dist)
            }
        }
        
        return maxValue
    }
    
    // Finds the top #num quickly for further processing later on
    func quickFind(lat: Double, long: Double, heading: Double, num: Int, coordinates: [Coordinates]) -> [DataPoint] {
        var topNums: [DataPoint] = []
        var maxValue: (index: Int, dist: Double) = (0, Double.infinity)
        
        for _ in 1...num {
            topNums.append((0, 0, "", Double.infinity, 0))
        }
        
        coordinates.forEach { coords in
            let distance = hyp(a: coords.lat - lat, b: coords.long - long)
            
            if distance < maxValue.dist {
                topNums[maxValue.index] = (coords.lat, coords.long, coords.horaire, distance, 0)
                maxValue = getNewMax(topNums: topNums)
            }
        }
        
        for i in 0..<num {
            topNums[i].dist = getRealDistance(lat1: topNums[i].lat, long1: topNums[i].long, lat2: lat, long2: long)
            topNums[i].heading = getHeading(lat1: topNums[i].lat, long1: topNums[i].long, lat2: lat, long2: long, currentHeading: heading)
        }
        
        topNums.sort(by: {$0.dist < $1.dist})
        //print(topNums)
        
        return topNums
    }
    
    func generateBody(amenity: String, radius: Int, lat: Double, long: Double) -> Data {
        // returns the body of the POST request we want to submit to overpass turbo
        let body = "[out:json][timeout:25];(node[\"amenity\"=\"" + amenity + "\"](around: " + String(radius) + ", " + String(lat) + ", " + String(long) + "););out body;"
        return Data(body.utf8)
    }
    
    func dispatchRequests(view: ViewController, amenity: String, lat: Double, long: Double) {
        let decoder: JSONDecoder = JSONDecoder()
        
        if let url = URL(string: self.rawURL) {
            // prepare request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = generateBody(amenity: amenity, radius: radius, lat: lat, long: long)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            print("Called " + amenity + ", radius=" + String(radius) + ", lat=" + String(lat) + ", long: " + String(long) + ", and have " + String(amenities.count) + " results so far.")
            
            // make HTTP request
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                semaphore.signal()
                // check if we didn't get a response
                if error != nil {
                    print("THE API CALL FAILED")
                }
                // once we have the data, sed to function
                if let data = data as Data? {
                    print(data)
                    let resData: Response = try! decoder.decode(Response.self, from: data)
                    print(resData)
                    
                    OS_dispatch_queue_serial.main.async {
                        // parse received json and update our array
                        self.amenities = resData.elements
                        self.resultCount = self.amenities.count
                        
                        let result = self.quickFind(lat: self.lat, long: self.long, heading: self.heading, num: self.wantedResults, coordinates: self.resultsToCoordinates())
                        
                        view.updateTable(res: result)
                        self.radius *= 3
                        if (self.resultCount < self.wantedResults) {
                            self.dispatchRequests(view: view, amenity: amenity, lat: lat, long: long)
                        }
                    }
                }
            } )
            
            task.resume()
            semaphore.wait()
        }
    }
    
    func update(lat: Double, long: Double, heading: Double) {
        self.lat = lat
        self.long = long
        self.heading = heading
    }
    
    func resultsToCoordinates() -> [Coordinates] {
        var coords: [Coordinates] = []
        
        for i in 0..<self.amenities.count {
            coords.append((self.amenities[i].tags["amenity"] ?? "", self.amenities[i].lat, self.amenities[i].lon))
        }
        
        if (coords.count > 0 && coords[0].horaire.localizedStandardContains("rinking")) {
            self.allWaterCoordinates = coords
        } else if (coords.count > 0 && coords[0].horaire.localizedStandardContains("oilet")) {
            self.allToiletCoordinates = coords
        } else {
            print("Wrong amenity requested: \"" + self.amenityString + "\"")
        }
        
        return coords
    }
    
    func fetchAmenities(view: ViewController, amenity: String, lat: Double, long: Double, results: Int) {
        // init vars we need
        self.amenities = []
        self.radius = 200
        self.resultCount = 0
        
        self.wantedResults = results
        self.amenityString = amenity
        
        self.dispatchRequests(view: view, amenity: amenity, lat: lat, long: long)
    }
}
