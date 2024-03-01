# MIDI Controller Written in SwiftUI

the didReceiveMIDIMessage function  <br />
makes it easy to map the midi   <br />
cc value to the desired parameter  <br />
 
in this example a buffer is created  <br />
called "Uniforms" that carries over   <br />
color, and size as data.   <br />
 
this data is updated in SwiftUI by our midi controller  <br />
then passed as a MTLBuffer? to our metal shader which   <br />
reads the data from the buffer  <br />
 
In this example, we render a triangle, mapped to 4 midi knobs (encoders),  <br />
which control the color, and size like so:    <br />

cc 13 = red color channel gain  <br />
cc 14 = green color channel gain  <br />
cc 15 = blue color channel gain  <br />
cc 16 = size of triangle  <br />
