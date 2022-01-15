import EventKit
import Foundation
import AlfredWorkflowScriptFilter



var store = EKEventStore()

let args = CommandLine.arguments

guard args.count >= 2 else {
    _exit(1)
}

//Authorization
if args[1] == "auth" {
    requestAccess(store: store)
    _exit(1)
}

if EKEventStore.authorizationStatus(for:.event) != .authorized {
    ScriptFilter.add(Item(title: "Please use \".grantpermission\" to grant Calendar permission"))
    print(ScriptFilter.output())
    _exit(1)
}
//End of Authorization

let startTime = Date()
guard let endTime = Calendar.current.date(byAdding: .hour, value: 24, to: startTime) else {
    _exit(1)
}

let cals = store.calendars(for: .event)
let todayPredicate = store.predicateForEvents(withStart: startTime, end: endTime, calendars: cals)
let events = store.events(matching: todayPredicate)

guard events.count > 0 else {
    ScriptFilter.add(Item(title: "There is no event in next 24 hrs"))
    print(ScriptFilter.output())
    _exit(0)
}

//Show full
if args[1] == "id" {
    getEvents(events, for: .id)
} else if args[1] == "webex" {
    getEvents(events, for: .webex)
} else if args.count > 2 && args[1] == "detail" {
    getEvent(byId: args[2], inEventStore: store)
}

print(ScriptFilter.output())
