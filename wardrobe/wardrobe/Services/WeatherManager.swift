//
//  WeatherManager.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/24/25.
//

import Foundation
import CoreLocation

@MainActor
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var temperature: Int?
    @Published var condition: String?
    @Published var recommendation: String?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager = CLLocationManager()
    private let apiKey = Config.openWeatherAPIKey // Replace with your actual API key
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func fetchWeather() async {
        isLoading = true
        
        // Request location permission
        locationManager.requestWhenInUseAuthorization()
        
        // Wait a bit for location
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let location = locationManager.location else {
            // Default to Palo Alto if location unavailable
            await fetchWeatherForLocation(latitude: 37.4419, longitude: -122.1430)
            return
        }
        
        await fetchWeatherForLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    // Replace the fetchWeatherForLocation method in WeatherManager.swift

    private func fetchWeatherForLocation(latitude: Double, longitude: Double) async {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=imperial"
        
        print("🔵 Fetching weather from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("🔴 Invalid URL")
            setFallbackWeather()
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("🔵 HTTP Status: \(httpResponse.statusCode)")
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔵 Raw response: \(jsonString)")
            }
            
            // Try to decode
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            
            // Update published properties
            self.temperature = Int(weatherResponse.main.temp)
            self.condition = weatherResponse.weather.first?.main ?? "Unknown"
            self.recommendation = getRecommendation(for: Int(weatherResponse.main.temp))
            
            print("✅ Weather loaded: \(temperature ?? 0)°F, \(condition ?? "")")
            
            isLoading = false
        } catch let DecodingError.keyNotFound(key, context) {
            print("🔴 Missing key '\(key.stringValue)' in response")
            print("🔴 Context: \(context.debugDescription)")
            setFallbackWeather()
        } catch {
            print("🔴 Weather error: \(error)")
            setFallbackWeather()
        }
    }
    
    private func setFallbackWeather() {
        self.temperature = 65
        self.condition = "Partly Cloudy"
        self.recommendation = "Light layers"
        isLoading = false
    }
    
    private func getRecommendation(for temp: Int) -> String {
        switch temp {
        case ..<40:
            return "Bundle up with layers"
        case 40..<55:
            return "Jacket recommended"
        case 55..<65:
            return "Light layers"
        case 65..<75:
            return "Perfect for anything"
        case 75..<85:
            return "Keep it light"
        default:
            return "Stay cool"
        }
    }
    
    func getWeatherIcon() -> String {
        guard let condition = condition else { return "cloud.sun.fill" }
        
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "snowflake"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    func getWeatherColor() -> (red: Double, green: Double, blue: Double) {
        guard let condition = condition else { return (255, 165, 0) }
        
        switch condition.lowercased() {
        case "clear":
            return (255, 165, 0) // Orange
        case "clouds":
            return (128, 128, 128) // Gray
        case "rain", "drizzle":
            return (70, 130, 180) // Steel blue
        case "thunderstorm":
            return (75, 0, 130) // Indigo
        case "snow":
            return (135, 206, 235) // Sky blue
        default:
            return (255, 165, 0) // Orange
        }
    }
    
    // CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            Task {
                await fetchWeather()
            }
        }
    }
}

// MARK: - Weather Response Models

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherCondition]
}

struct MainWeather: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
}

struct WeatherCondition: Codable {
    let main: String
    let description: String
    let icon: String
}
