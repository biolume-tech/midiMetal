//
//  Renderer.swift
//  midiMetal
//
//  Created by Raul on 3/1/24.
//

import Foundation
import MetalKit
import simd
import CoreMIDI


class Renderer: NSObject, MIDIMessageDelegate {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    var dimensionsBuffer: MTLBuffer?
    var vertexBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var midiController: MIDIController?
    
    // Add properties to store the current size and color
    var currentSize: Float = 1.0
    var currentColor: SIMD4<Float> = SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
    
    struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
    }
    
    struct Uniforms {
        var size: Float
        var color: SIMD4<Float>
    }
    
    
    init(metalView: MTKView) {
        super.init()
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        setupShadersAndPipelineState(metalView: metalView)
        setupVertexBuffer()
        setupUniformsBuffer()
        updateUniforms(size: currentSize, color: currentColor)

        // Initialize MIDIController and set this Renderer as the delegate
        midiController = MIDIController()
        midiController?.delegate = self
        
        metalView.delegate = self
    }
    
    // This function is called whenever a MIDI message is received. MIDI messages are used for communication
    // between musical instruments and computer software. In this context, they're repurposed to control visual elements.
    func didReceiveMIDIMessage(channel: UInt8, ccNumber: UInt8, value: UInt8) {
        // MIDI values range from 0 to 127. This line normalizes the MIDI value to a floating-point range [0.0, 1.0],
        // making it suitable for use in calculations that expect values in this range, such as color intensity or size scaling.
        let normalizedValue = Float(value) / 127.0
        
        // The control change (CC) number determines what aspect of the visual element the MIDI message is meant to control.
        // Each if-else block checks for a specific CC number and updates the corresponding aspect accordingly.
        
        if ccNumber == 13 {
            // CC number 13 is designated to control the red component of the color.
            // currentColor.x corresponds to the red component in the RGBA color model when using SIMD4<Float>.
            // This line updates the red component to the normalized MIDI value, affecting the color's red intensity.
            currentColor.x = normalizedValue
        } else if ccNumber == 14 {
            // Similarly, CC number 14 controls the green component of the color.
            // currentColor.y is updated, which affects the green intensity of the color.
            currentColor.y = normalizedValue
        } else if ccNumber == 15 {
            // CC number 15 controls the blue component.
            // Updating currentColor.z affects the blue intensity, modifying the overall color.
            currentColor.z = normalizedValue
        } else if ccNumber == 16 {
            // CC number 16 is used to control the size of the visual element.
            // The size is represented as a floating-point value, and updating currentSize adjusts the element's scale.
            // This demonstrates a versatile use of MIDI messages, extending beyond color adjustments to include size scaling.
            currentSize = normalizedValue
        }
        
        // After determining which aspect to update based on the CC number and applying the normalized value,
        // the uniforms are updated with the current size and color. This step is crucial as it applies the changes
        // to the visual element, ensuring that the latest adjustments are reflected in the rendered output.
        // The updateUniforms function likely updates a buffer or similar data structure that the rendering pipeline uses
        // to draw the visual elements with the specified size and color.
        updateUniforms(size: currentSize, color: currentColor)
    }


    
    func updateUniforms(size: Float, color: SIMD4<Float>) {
        var uniforms = Uniforms(size: size, color: color)
        uniformsBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
    }
    
    
    
    
    func setupVertexBuffer() {
        let vertices: [Vertex] = [
            Vertex(position: SIMD4<Float>(0, 1, 0, 1), color: SIMD4<Float>(1, 0, 0, 1)), // Top vertex
            Vertex(position: SIMD4<Float>(-1, -1, 0, 1), color: SIMD4<Float>(0, 1, 0, 1)), // Bottom left vertex
            Vertex(position: SIMD4<Float>(1, -1, 0, 1), color: SIMD4<Float>(0, 0, 1, 1))  // Bottom right vertex
        ]
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
    }
    
    func setupUniformsBuffer() {
        uniformsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])
    }

    
    
    private func setupShadersAndPipelineState(metalView: MTKView) {
        Renderer.library = Renderer.device.makeDefaultLibrary()
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let descriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let vertexBuffer = vertexBuffer,
              let uniformsBuffer = uniformsBuffer else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1) // Bind uniform buffer
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}
