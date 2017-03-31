//
//  StatusMenuController.swift
//  Sum41Tour
//
//  Copyright © 2017 Anastasia Grineva
//

import Cocoa

class StatusMenuController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var eventsView: EventsView!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var tableView: NSTableView!
    var eventsMenuItem: NSMenuItem!
    
    fileprivate enum CellIdentifiers {
        static let CityCell = "cityCell"
        static let DateCell = "dateCell"
    }
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    let eventsAPI = EventsAPI()
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // for dark mode
        statusItem.image = icon
        
        // No. of new events near icon
        if(noOfNewEvents > 0) {
            statusItem.title = String(noOfNewEvents)
        }
        
        // Prepare place for the events list
        statusItem.menu = statusMenu
        eventsMenuItem = statusMenu.item(withTitle: "Events")
        eventsMenuItem.view = eventsView
        
        tableView.backgroundColor = .clear
        
        updateEvents(false)
        
        // Update events twice per day
        //let interval: TimeInterval = 60 * 60 * 12
        let interval: TimeInterval = 10
        Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateEventsFromTimer), userInfo: nil, repeats: true)
    }
    
    @IBAction func updateClicked(_ sender: NSMenuItem) {
        print("updateClicked")
        updateEvents(true)
        //self.tableView.reloadData()
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func updateEventsFromTimer() {
        updateEvents(false)
    }
    
    func updateEvents(_ resetNewEvents: Bool) {
        print("updateEvents")
        
        eventsAPI.fetchEvents(resetNewEvents) {
            events in allEvents = events
            // Update UI
            self.eventsView.update(allEvents.count, noOfUKevents: noOfUKevents, noOfNewEvents: noOfNewEvents)
            
            // Update icon text
            if(noOfNewEvents > 0) {
                self.statusItem.title = String(noOfNewEvents)
            }
            else {
                self.statusItem.title = ""
            }
        }
        self.tableView.reloadData()
    }
    
    override func viewDidAppear() {
        super.viewDidLoad()
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (allEvents.count)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier: String = ""
        var text: String = ""
        
        //tableView.backgroundColor = .clear
        
        //guard let item = (data)[row] else { return nil }
        let item = (allEvents)[row]
        
        if tableColumn == tableView.tableColumns[0] {
            text = "\(item.country),  \(item.city)"
            cellIdentifier = CellIdentifiers.CityCell
        }
        else if tableColumn == tableView.tableColumns[1] {
            text = item.date
            cellIdentifier = CellIdentifiers.DateCell
        }
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.textColor = NSColor.white
            
            if(item.isNew) {
                cell.textField?.textColor = NSColor.red
            }
            
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
