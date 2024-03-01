//
//  Shaders.metal
//  midiMetal
//
//  Created by Raul on 3/1/24.
//

#include <metal_stdlib>
using namespace metal;


struct Vertex {
    float4 position [[position]]; // Vertex position
    float4 color;                 // Vertex color
};

// Define a struct that matches the Swift Uniforms struct
struct Uniforms {
    float size;      // Scale factor for the size of the triangle
    float4 color;    // Color of the triangle
};

// Updated vertex shader to scale the triangle size
vertex Vertex vertex_main(constant Vertex* vertices [[buffer(0)]],
                          constant Uniforms& uniforms [[buffer(1)]],
                          uint vertexID [[vertex_id]]) {
    Vertex outVert = vertices[vertexID];
    
    // Apply the size scaling to the triangle's vertices
    outVert.position.xy *= uniforms.size;
    
    return outVert;
}

// Updated fragment shader to utilize the uniform color
fragment float4 fragment_main(Vertex vert [[stage_in]],
                              constant Uniforms& uniforms [[buffer(1)]]) {
    // Use the color from the uniforms instead of the vertex color
    return uniforms.color;
}



