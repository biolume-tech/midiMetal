//
//  MIDIController.swift
//  midiMetal
//
//  Created by Raul on 3/1/24.
//

import Foundation

// Import the CoreMIDI framework, which provides an interface to the MIDI (Musical Instrument Digital Interface) system, enabling communication with MIDI devices.
import CoreMIDI

// Declare a protocol named MIDIMessageDelegate. Protocols in Swift define a blueprint of methods, properties, and other requirements that suit a particular task or piece of functionality. This particular protocol is designed for objects that will handle MIDI messages. The 'AnyObject' restriction means only class types can adopt this protocol, enabling weak references to the delegate to avoid retain cycles.
protocol MIDIMessageDelegate: AnyObject {
    // Define a method in the protocol that any delegate conforming to this protocol must implement. This method is intended to be called when a MIDI message is received, carrying details of the MIDI channel, control change (CC) number, and its value. Each parameter is a UInt8, reflecting the byte-based nature of MIDI messages.
    func didReceiveMIDIMessage(channel: UInt8, ccNumber: UInt8, value: UInt8)
}

// Define a class named MIDIController. Classes in Swift are general-purpose, flexible constructs that become the building blocks of your program’s code. This class is designed to manage MIDI interactions, such as receiving MIDI messages from devices.
class MIDIController {
    // Define a variable midiClient of type MIDIClientRef, initialized to 0. MIDIClientRef is a type alias for an integer that represents a reference to a CoreMIDI client object, which is an application's access point to the MIDI system.
    var midiClient: MIDIClientRef = 0
    // Define a variable midiInPort of type MIDIPortRef, also initialized to 0. MIDIPortRef is a type alias for an integer that represents a reference to a MIDI port, used here to specify an input port through which MIDI messages are received.
    var midiInPort: MIDIPortRef = 0
    // Declare a weak, optional delegate variable of the type MIDIMessageDelegate?. The weak keyword prevents strong reference cycles, and the optional allows the delegate to be nil. This delegate will be notified of incoming MIDI messages.
    weak var delegate: MIDIMessageDelegate?

    // Define the initializer for the MIDIController class. Initializers in Swift are called to create a new instance of a class.
    init() {
        // Call the setupMIDI method within the initializer to configure MIDI communication when an instance of MIDIController is created.
        setupMIDI()
    }
    
    // Define a private method named setupMIDI. Marking this method as private restricts its visibility to the scope of this class, encapsulating the MIDI setup logic.
    private func setupMIDI() {
        // Create a MIDI client with a specific name ('MetalMIDIClient'). The MIDIClientCreate function takes four parameters: the name of the client, a pointer to a callback function for notifying the client of changes in the MIDI setup (unused here, hence nil), a context pointer for the callback (also nil here), and a reference to the MIDIClientRef variable where the newly created client reference will be stored.
        let statusClient = MIDIClientCreate("MetalMIDIClient" as CFString, nil, nil, &midiClient)
        // Check if the MIDI client was successfully created by comparing the statusClient variable to noErr. The guard statement is used to exit early if the client creation failed.
        guard statusClient == noErr else { return }
        
        // Create a MIDI input port for the client. The MIDIInputPortCreate function is called with the client reference, a name for the port ('MetalMIDIIn'), a callback function (midiInputCallback) where incoming MIDI messages will be delivered, a context pointer passed to the callback (a reference to 'self' here, to allow the callback to access this instance of MIDIController), and a reference to the MIDIPortRef variable where the newly created port reference will be stored.
        let statusPort = MIDIInputPortCreate(midiClient, "MetalMIDIIn" as CFString, midiInputCallback, Unmanaged.passUnretained(self).toOpaque(), &midiInPort)
        // Check if the MIDI input port was successfully created by comparing the statusPort to noErr, using a guard statement to exit early if port creation failed.
        guard statusPort == noErr else { return }
        
        // Iterate through all MIDI sources (devices that can send MIDI messages) available in the system. MIDIGetNumberOfSources() returns the number of sources, and a for loop is used to go through each source by its index.
        (0..<MIDIGetNumberOfSources()).forEach { index in
            // Retrieve a reference to the MIDI source at the given index. MIDIGetSource(index) returns the MIDIEndpointRef for the source, which uniquely identifies a MIDI endpoint.
            let source = MIDIGetSource(index)
            // Check if the source reference is valid (non-zero). If not valid, skip the rest of this iteration.
            guard source != 0 else { return }
            // Connect the previously created input port to this MIDI source, enabling the application to receive messages from the source. MIDIPortConnectSource takes the input port reference, the source endpoint reference, and a context pointer (nil in this case since it's not used).
            MIDIPortConnectSource(midiInPort, source, nil)
        }
    }
}

// Define the midiInputCallback function, which is called by the CoreMIDI system when MIDI messages are received through the input port. The function signature matches what CoreMIDI expects for input port callbacks, with parameters for the packet list (containing MIDI messages), and two context pointers.
func midiInputCallback(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) {
    // Dereference the packetList pointer to access the MIDIPacketList structure it points to. This structure contains an array of MIDI packets.
    let packetList = packetList.pointee
    // Access the first MIDI packet in the list. MIDIPacketList uses a direct array access method to store packets.
    var packet = packetList.packet
    // Iterate over each packet in the list. The numPackets field of MIDIPacketList tells us how many packets are in the list.
    for _ in 0..<packetList.numPackets {
        // Use Swift's Mirror reflection to iterate over the packet's data bytes. This approach is a bit unconventional but works to access the bytes in a Swift-friendly way.
        let bytes = Mirror(reflecting: packet.data).children
        // Map the reflected children to an array of UInt8, which are the actual MIDI message bytes.
        let data = bytes.map { $0.value as! UInt8 }
        // Extract the MIDI status byte from the first byte of the message. This byte contains both the type of MIDI message and the channel number.
        let status = data[0]
        // Isolate the channel number from the status byte. MIDI channels are 0-15, but they are encoded in the lower 4 bits of the status byte, so we use bitwise AND with 0x0F.
        let channel = status & 0x0F
        
        // Use DispatchQueue to schedule the delegate call on the main thread. This is important for thread safety, especially in UI applications where updates must be performed on the main thread.
        DispatchQueue.main.async {
            // Use Unmanaged to convert the readProcRefCon pointer back to a MIDIController instance. This is necessary because the callback mechanism in C cannot directly handle Swift objects.
            let midiController = Unmanaged<MIDIController>.fromOpaque(readProcRefCon!).takeUnretainedValue()
            // Call the delegate's didReceiveMIDIMessage method, passing the channel, CC number, and value extracted from the MIDI message.
            midiController.delegate?.didReceiveMIDIMessage(channel: channel, ccNumber: data[1], value: data[2])
        }
        // Move to the next packet in the list for the next iteration. MIDIPacketNext is a C function that calculates the address of the next MIDIPacket.
        packet = MIDIPacketNext(&packet).pointee
    }
}
