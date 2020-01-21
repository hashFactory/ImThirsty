//
//  ViewController.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 18/09/2019.
//  Copyright © 2019 Tristan Charpentier. All rights reserved.


import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var timer = Timer()
    var data = DataInput();
    
    var results = [DataInput.DataPoint]()
    var previousHeadings = [Double]()
    
    var currentLat = 0.0
    var currentLong = 0.0
    
    /*private func loadResults() {
        
        // guard let result1 =
    }*/
    
    @IBOutlet weak var myLocationDisplay: UITextView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let aColor = UIColor(named: "BackgroundColor")
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) {
            self.view.backgroundColor = aColor
        }
        
        self.refreshButton.addTarget(self, action: Selector(("refreshLocation")), for: .touchUpInside)
        
        self.locationManager.requestWhenInUseAuthorization()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        data.readFile(name: "toilets");
        
        if CLLocationManager.locationServicesEnabled() {
            // locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.delegate = self
            locationManager.startUpdatingHeading()
            
            scheduledTimerWithTimeInterval()
            // self.view.addSubview(label)
            
        }
        
        myLocationDisplay.textContainer.maximumNumberOfLines = 10
        myLocationDisplay.textContainer.lineBreakMode = .byTruncatingTail
        
        refreshLocation()
    }
    
    // TODO: Create the same but for location
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        let locationString = "Latitude:\t\t\(currentLat)°N\nLongitude:\t\(currentLong)°E\nBearing:\t\t\(newHeading.magneticHeading)°"
        
        myLocationDisplay.text = locationString
        
        for index in 0..<results.count {
            results[index].heading = data.getHeading(lat1: results[index].lat, long1: results[index].long, lat2: currentLat, long2: currentLong, currentHeading: newHeading.magneticHeading)
        }
        
        print("Updated heading but not location")
        
        self.tableView.reloadData()
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        //timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: Selector(("refreshLocation")), userInfo: nil, repeats: true)
        self.timer = Timer(timeInterval: 2, target: self, selector: #selector(refreshLocation), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer, forMode: .common)
    }
    
    @objc func refreshLocation() {

        guard let locationLatLong = locationManager.location else {
            return
        }
        
        guard let locationHeading = locationManager.heading else {
            return
        }
        
        print("Updated both")
        
        let locationString = "Latitude:\t\t\(locationLatLong.coordinate.latitude)°N\nLongitude:\t\(locationLatLong.coordinate.longitude)°E\nBearing:\t\t\(locationHeading.magneticHeading)°"
        
        myLocationDisplay.text = locationString
        
        self.currentLat = locationLatLong.coordinate.latitude
        self.currentLong = locationLatLong.coordinate.longitude
        
        results = data.quickFind(lat: locationLatLong.coordinate.latitude, long: locationLatLong.coordinate.longitude, heading: locationHeading.magneticHeading, num: 10)
        
        self.tableView.reloadData()
        
        print("Horizontal: \(locationLatLong.horizontalAccuracy)\nVertical: \(locationLatLong.verticalAccuracy)")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "ResultTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ResultTableViewCell else {
            fatalError("Couldn't instantiate cell")
        }
        
        let result = results[indexPath.row]
        var savedPrevious: Double = 0.0
        
        if previousHeadings.count < results.count {
            self.previousHeadings.append(self.results[indexPath.row].heading)
        }
        else {
            savedPrevious = self.previousHeadings[indexPath.row]
            self.previousHeadings[indexPath.row] = self.results[indexPath.row].heading
        }
        
        cell.distanceLabel.text = String(Int(round(result.dist))) + "m (" + result.timetable + ")"
        
        // TODO: ************ Implement image generation
        
        if savedPrevious != self.results[indexPath.row].heading {
            //print("Drew new arrow")
            cell.distanceDirection.image = UIImage(named: "arrowSmall")
            cell.distanceDirection.transform = .identity
            
            cell.distanceDirection.transform = CGAffineTransform(rotationAngle: CGFloat(self.data.toRadians(value:  self.results[indexPath.row].heading)))
        }
        
        /*
        cell.distanceDirection.transform = .identity
        cell.distanceDirection.transform = CGAffineTransform(rotationAngle: CGFloat(data.toRadians(value: savedPrevious)))
        
        UIView.animate(withDuration: 0.1) {
            cell.distanceDirection.transform = CGAffineTransform(rotationAngle: CGFloat(self.data.toRadians(value:  self.results[indexPath.row].heading)))
        }*/
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print(String("comgooglemaps://?center=" + String(self.results[indexPath.row].lat) + "," + String(self.results[indexPath.row].long) + "&zoom=14"))
        let urlString = String("http://maps.google.com/?daddr=" + String(self.results[indexPath.row].lat) + "," + String(self.results[indexPath.row].long))
        
        if let url = URL(string: urlString)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    

}

