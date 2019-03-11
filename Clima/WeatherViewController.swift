//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    var unit: [String] = ["Celsius", "Fahrenheit"]
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var unitButtonOutlet: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        unitLabel.text = unit[0]
        unitButtonOutlet.isOn = true
    }
    
    @IBAction func unitButton(_ sender: UISwitch) {
        if unitLabel.text == unit[0] {
            unitLabel.text = unit[1]
            convertCtoF()
        }
        else {
            unitLabel.text = unit[0]
            convertFtoC()
        }
    }
    
    func convertCtoF() {
        let fahrenheit = (Int(temperatureLabel.text!)! * 9/5) + 32
        temperatureLabel.text = String(fahrenheit)
    }
    
    func convertFtoC() {
        let celsius = (Int(temperatureLabel.text!)! - 32) * 5/9
        temperatureLabel.text = String(celsius)
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            }
            else {
                print("Error: \(response.result.error)")
                self.cityLabel.text = "Connection Issues"
            }
        }
    }

    //MARK: - JSON Parsing
    /***************************************************************/
   
    //Write the updateWeatherData method here:
    func updateWeatherData(json: JSON) {
        if let temp = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(temp - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
        }
        else {
            cityLabel.text = "Weather Unavailable"
        }
    }

    //MARK: - UI Updates
    /***************************************************************/
    
    //Write the updateUIWithWeatherData method here:
    func updateUIWithWeatherData() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        unitLabel.text = unit[0]
    }
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            let latitude: String = String(location.coordinate.latitude)
            let longitude: String = String(location.coordinate.longitude)
            
            let params: [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
    }

    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredCityName(city: String) {
        let params: [String : String] = ["q": city, "appid": APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }

    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
}
