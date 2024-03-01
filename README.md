# MIDI Controller Written in SwiftUI

the didReceiveMIDIMessage function
makes it easy to map the midi 
cc value to the desired parameter
 
in this example a buffer is created
called "Uniforms" that carries over 
color, and size as data. 
 
this data is updated in SwiftUI by our midi controller
then passed as a MTLBuffer? to our metal shader which 
reads the data from the buffer

In this example, we render a triangle, mapped to 4 midi knobs (encoders),
which control the color, and size like so:  

cc 13 = red color channel gain
cc 14 = green color channel gain
cc 15 = blue color channel gain
cc 16 = size of triangle
