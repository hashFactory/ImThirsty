//
//  DataInput.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 20/09/2019.
//  Copyright © 2019 Tristan Charpentier. All rights reserved.
//

import Foundation

class DataInput {
    
    typealias DataPoint = (lat: Double, long: Double, dist: Double, heading: Double)
    
    var myDoubles = Array<Double>()
    var allCoordinates:[(lat: Double, long: Double)] = []
    
    func readFile(name: String) {
        
        if let path = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                let fileData = try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: " ", with: "", options: String.CompareOptions.literal, range: nil)
                myDoubles = fileData.components(separatedBy: .newlines).compactMap(Double.init)
                print(myDoubles[1387])
            } catch {
                print(error)
            }
            
            process()
        }
    }
    
    func process() {
        
        for i in 0..<(myDoubles.count / 2) {
            allCoordinates.append((myDoubles[i * 2], myDoubles[i * 2 + 1]))
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
    func quickFind(lat: Double, long: Double, heading: Double, num: Int) -> [DataPoint] {
        
        var topNums: [DataPoint] = []
        var maxValue: (index: Int, dist: Double) = (0, Double.infinity)
        
        for _ in 1...num {
            topNums.append((0, 0, Double.infinity, 0))
        }
        
        allCoordinates.forEach { coords in
            
            let distance = hyp(a: coords.lat - lat, b: coords.long - long)
            
            if distance < maxValue.dist {
                topNums[maxValue.index] = (coords.lat, coords.long, distance, 0)
                
                maxValue = getNewMax(topNums: topNums)
            }
        }
        
        for i in 0..<num {
            topNums[i].dist = getRealDistance(lat1: topNums[i].lat, long1: topNums[i].long, lat2: lat, long2: long)
            topNums[i].heading = getHeading(lat1: topNums[i].lat, long1: topNums[i].long, lat2: lat, long2: long, currentHeading: heading)
        }
        
        topNums.sort(by: {$0.dist < $1.dist})
        
        print(topNums)
        
        return topNums
    }
}
