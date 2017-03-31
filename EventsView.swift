//
//  EventsView.swift
//  Sum41Tour
//
//  Copyright © 2017 Anastasia Grineva
//

import Cocoa

class EventsView: NSView {
    @IBOutlet weak var cityTextField: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func update(_ eventsCount: Int, noOfUKevents: Int, noOfNewEvents: Int) {
        // do UI updates on the main thread
        DispatchQueue.main.async {
            let eventsEnding = (eventsCount > 1 ? "s" : "")
            let UKevents = (noOfUKevents > 0 ? "(+ \(noOfUKevents) in the UK)" : "")
            let newEvents = (noOfNewEvents > 0 ? "- \(noOfNewEvents) NEW" : "")
            self.cityTextField.stringValue = "\(String(eventsCount)) gig\(eventsEnding) \(UKevents) \(newEvents)"
        }
    }
}
