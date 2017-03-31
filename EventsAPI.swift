//
//  EventsAPI.swift
//  Sum41Tour
//
//  Copyright © 2017 Anastasia Grineva.
//

import Foundation

struct Event: CustomStringConvertible {
    var country: String
    var city: String
    var date: String
    var isNew: Bool
    
    var description: String {
        return "\(country), \(city), \(date)"
    }
    
    func match(string:String) -> Bool {
        return country.contains(string)
    }
    
    init() {
        self.city = ""
        self.country = ""
        self.date = ""
        self.isNew = false
    }
    
    init(city: String, country: String, date: String) {
        self.city = city
        self.country = country
        self.date = date
        self.isNew = false
    }
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

var allEvents = [Event]()
var noOfUKevents : Int = 0
var noOfNewEvents : Int = 0

let file = ".Sum41events" // Used to store previously loaded events

class EventsAPI {
    let BASE_URL = "https://rest.bandsintown.com/artists/"
    let BAND_NAME = "Sum 41"
    
    func fetchEvents(_ resetNewEvents: Bool, success: @escaping ([Event]) -> Void) {
        let session = URLSession.shared
        // url-escape the band name string
        let escapedBandName = BAND_NAME.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = URL(string: "\(BASE_URL)\(escapedBandName)/events?app_id=\(escapedBandName)")
        
        let task = session.dataTask(with: url!) { data, response, err in
            // check for a hard error
            if let error = err {
                NSLog("Events api error: \(error)")
            }
            
            // check the response code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // all good!
                    if let events = self.eventsFromJSONData(data!, resetNewEvents: resetNewEvents) {
                        success(events)
                    }
                default:
                    NSLog("Events api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func eventsFromJSONData(_ data: Data, resetNewEvents: Bool) -> [Event]? {
        do {
            allEvents.removeAll()
            noOfUKevents = 0
            noOfNewEvents = 0
            
            // Filter out countries that the user cannot visit
            let notValidCountries = ["Japan","Canada", "United States"]
            var validEvents = [[String:Any]]()
            
            // Parse JSON and save only valid countries for the further actions
            if let jsonObject = try JSONSerialization.jsonObject(with:data, options: []) as? [[String:Any]] {
                for item in jsonObject {
                    if let venue = item["venue"] as? [String: Any] {
                        if let country = venue["country"] as? String {
                            // Filter entries by comparing countries
                            if(!notValidCountries.contains(country)) {
                                if(country == "United Kingdom") {
                                    noOfUKevents += 1
                                }
                                else {
                                    validEvents.append(item)
                                }
                            }
                        }
                    }
                }
            }
            let eventsCount = validEvents.count
        
            // Starting reading & writing log of events
            let fileManager = FileManager.default
            var fileContentToWrite : String = ""
            
            // The log file will be saved to the user's documents directory
            if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let path = dir.appendingPathComponent(file)
                
                // Check if file with saved events exists
                if fileManager.fileExists(atPath: path.path) {
                }
                else {
                    // Create an empty file
                    print("File not found")
                    try "".write(to: path, atomically: false, encoding: String.Encoding.utf8)
                }
                
                do {
                    // Read the file contents
                    var savedEvents = [[String]]()
                    do {
                        let fileContent = try String(contentsOf: path, encoding: String.Encoding.utf8)
                        
                        for line in fileContent.components(separatedBy: "\n") {
                            var entry = line.components(separatedBy: ", ")
                            savedEvents.append([entry[2], entry[3]])
                        }
                    }
                    catch let error as NSError {
                        print("Failed reading from URL: \(file), Error: " + error.localizedDescription)
                    }
                    
                    let savedEventsCount = savedEvents.count
                    
                    // Get only necessary information and save entries as "Event" objects
                    for event in validEvents {
                        
                        guard let venue = event["venue"] as? [String: Any] else {
                            NSLog("Venue parsing error"); throw SerializationError.missing("venue")}
                        
                        guard let country = venue["country"] as? String else {
                            NSLog("Country parsing error"); throw SerializationError.missing("country")}
                        
                        
                        guard let city = venue["city"] as? String else {
                            NSLog("City parsing error"); throw SerializationError.missing("city")}
                        
                        guard let datetime = event["datetime"] as? String else {
                            NSLog("Datetime parsing error"); throw SerializationError.missing("datetime")}
                        
                        // format date to "06 Jun"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        let date = dateFormatter.date(from: datetime)!
                        dateFormatter.dateFormat = "dd MMM"
                        let dateString = dateFormatter.string(from:date)
                        
                        // save parsed data to a new Event object
                        var parsedEvent = Event(city: city, country: country, date: dateString)
                        
                        if(eventsCount > savedEventsCount) {
                            // Events-API sent more events than saved, so, there are new events
                            if(!savedEvents.contains {$0.contains(dateString)}) {
                                // check if the current event is new by comparing dates from the events log
                                noOfNewEvents += 1
                                parsedEvent.isNew = true
                            }
                        }
                        else {
                            if(!resetNewEvents) {
                                // Auto-update called -
                                // we don't want to mark the event as old,
                                // even if it's already saved to log
                                // overwise the user can miss this info
                                if(savedEvents.contains {$0 == [dateString, "true"]}) {
                                    noOfNewEvents += 1
                                    parsedEvent.isNew = true
                                }
                            }
                        }
                        
                        // Prepare log data
                        fileContentToWrite += "\(country), \(city), \(dateString), \(parsedEvent.isNew)\n"
                        
                        // add the prepared event to the return array
                        allEvents.append(parsedEvent)
                    }
                    
                    // Remove last "\n" and update log with events
                    fileContentToWrite = String(fileContentToWrite.characters.dropLast(1))
                    do {
                        try fileContentToWrite.write(to: path, atomically: false, encoding: String.Encoding.utf8)
                    }
                    catch let error as NSError {
                        print("Failed writing to URL: \(path), Error: " + error.localizedDescription)
                    }
                }
                catch {
                    print("Error in reading file: \(error)")
                    return nil
                }
            }
        }
        catch {
            print("JSON parsing failed: \(error)")
            return nil
        }
        return allEvents
    }
}
