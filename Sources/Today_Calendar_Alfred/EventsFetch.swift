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
let webexPrefix2 = "https://appleinc.webex.com/"


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
    let todayDate = curCal.component(.day, from: Date())
    var isSecondDay = false

    
    for e in events {
        guard !e.isAllDay else {
            continue
        }
        
        let eventCurDay = curCal.component(.day, from: e.startDate)
        if eventCurDay > todayDate && !isSecondDay {
            isSecondDay = true
            ScriptFilter.add(Item(title: "=========(Tomorrow)=========").icon(Icon(path: "clocks/0_00.png")))
        }
        
        let item = Item(title: e.title ?? "No Title")
        let eHour = curCal.component(.hour, from: e.startDate)%12
        let eMinute = abs(curCal.component(.minute, from: e.startDate) - 30) < 15 ? "30" : "00"
        item.icon(Icon(path: "clocks/\(eHour)_\(eMinute).png"))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let eStartTime = formatter.string(from: e.startDate)
        let eEndTime = formatter.string(from: e.endDate)
        
        switch outPutType {
        case .id:
            item.arg(e.eventIdentifier).valid()
            item.subtitle("\(eStartTime) - \(eEndTime)")
        case .webex:
            if let url = e.url {
                item.arg(url.absoluteString)
                item.subtitle("\(eStartTime) - \(eEndTime) (webex)")
            } else if e.hasNotes, let webexLink = getWebexLink(text: e.notes!) {
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

func getEvent(byId eventId: String, inEventStore eventStore: EKEventStore, _ completionHandler: @escaping () -> ()) {
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
                    let pName = "\(p.name ?? "No name") (\(p.participantRole == .optional ? "optional": "required"))"
                    switch p.participantStatus {
                    case .declined:
                        ScriptFilter.add(Item(title: pName).subtitle("declined"))
                    case .tentative:
                        ScriptFilter.add(Item(title: pName).subtitle("maybe"))
                    default:
                        ScriptFilter.add(Item(title: pName).subtitle("attend"))
                    }
                }
            }
        }
//        completionHandler()
    })
    
    //TODO: - fix completionhandler so that we don't need to rely on this pause
    Thread.sleep(forTimeInterval: 0.5)
}
