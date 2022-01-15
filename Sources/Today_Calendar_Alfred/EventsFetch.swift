//
//  File.swift
//  Today_Calendar_Alfred
//
//  Created by Ray Wu on 4/21/21.
//

import Foundation
import EventKit
import AlfredWorkflowScriptFilter

let webexPrefix1 = "https://appleinc.webex.com/appleinc"
let webexPrefix2 = "https://appleinc.webex.com/meet/"

func getWebexLink(text: String) -> String? {
    let allLines = text.components(separatedBy: "\n")
    for l in allLines {
        if l.hasPrefix(webexPrefix1) {
            return l
        } else if l.contains(webexPrefix2) {
            let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: l, options: [], range: NSRange(location: 0, length: l.utf16.count))

            for match in matches {
                guard let range = Range(match.range, in: l) else { continue }
                let url = l[range]
                return String(url)
            }
            
        }
    }
    return nil
}

enum OutputType {
    case webex
    case id
}

func getEvents(_ events: [EKEvent], for outPutType: OutputType) {
    let curCal = Calendar.current
    let todayDay = curCal.component(.day, from: startTime)
    var isSecondDay = false

    
    for e in events {
        guard !e.isAllDay else {
            continue
        }
        
        let eventCurDay = curCal.component(.day, from: e.startDate)
        if eventCurDay > todayDay && !isSecondDay {
            isSecondDay = true
            ScriptFilter.add(Item(title: "=========(Tomorrow)========="))
        }
        
        let item = Item(title: e.title ?? "No Title")
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let eStartTime = formatter.string(from: e.startDate)
        let eEndTime = formatter.string(from: e.endDate)
        
        switch outPutType {
        case .id:
            item.arg(e.eventIdentifier).valid()
            item.subtitle("\(eStartTime) - \(eEndTime)")
        case .webex:
            if e.hasNotes, let webexLink = getWebexLink(text: e.notes!) {
                item.arg("\(webexLink.trimmingCharacters(in: .whitespacesAndNewlines))").valid()
                item.subtitle("\(eStartTime) - \(eEndTime) (webex)")
            } else {
                item.valid(false)
                item.subtitle("\(eStartTime) - \(eEndTime)")
            }
        }
        
        ScriptFilter.add(item)
    }
}

func getEvent(byId eventId: String, inEventStore eventStore: EKEventStore) {
    eventStore.requestAccess(to: .event, completion: { _,_  in
        guard let event = eventStore.event(withIdentifier: eventId) else {
            ScriptFilter.add(Item(title: "There is no event with such id: \(eventId)"))
            return
        }
        
        ScriptFilter.add(Item(title: event.title ?? "No Title").subtitle("Title"))
        ScriptFilter.add(Item(title: event.calendar.title).subtitle("Calendar"))
        if let location = event.location {
            ScriptFilter.add(Item(title: location).subtitle("Location"))
        }
        switch event.status {
        case .canceled:
            ScriptFilter.add(Item(title: "canceled").subtitle("Status"))
        case .tentative:
            ScriptFilter.add(Item(title: "tentative").subtitle("Status"))
        case .confirmed:
            ScriptFilter.add(Item(title: "confirmed").subtitle("Status"))
        default:
            ScriptFilter.add(Item(title: "none").subtitle("Status"))
        }
        ScriptFilter.add(Item(title: "=========(Attendees)========="))
        ScriptFilter.add(Item(title: event.organizer?.name ?? "No name").subtitle("Organizor"))
        if let participants = event.attendees {
            for p in participants {
                guard p != event.organizer else {
                    continue
                }
                
                if p.isCurrentUser {
                    ScriptFilter.add(Item(title: "Awesome Me"))
                } else if p.participantType == .person {
                    switch p.participantStatus {
                    case .declined:
                        ScriptFilter.add(Item(title: p.name ?? "No name").subtitle("declined"))
                    case .tentative:
                        ScriptFilter.add(Item(title: p.name ?? "No name").subtitle("maybe"))
                    default:
                        ScriptFilter.add(Item(title: p.name ?? "No name").subtitle("attend"))
                    }
                }
            }
        }
    })
    
    Thread.sleep(forTimeInterval: 0.5)
}
