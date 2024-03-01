//
//  MetalView.swift
//  midiMetal
//
//  Created by Raul on 3/1/24.
//

import SwiftUI
import MetalKit

struct MetalView: View {
    
    @State private var metalView = MTKView()
    @State private var renderer: Renderer?
    
    var body: some View {
        MetalViewRepresentable(metalView: $metalView)
            .onAppear {
                metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
                renderer = Renderer(metalView: metalView)
            }
    }
}


#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#endif

struct MetalViewRepresentable: ViewRepresentable {
    
    @Binding var metalView: MTKView
    
    
#if os(macOS)
    
    func makeNSView(context: Context) -> some NSView {
        metalView.preferredFramesPerSecond = 60
        return metalView
    }
    
    func updateNSView(_ uiView: NSViewType, context: Context) {
        updateMetalView()
    }
    
#elseif os(iOS)
    
    func makeUIView(context: Context) -> MTKView {
        metalView.preferredFramesPerSecond = 120
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        updateMetalView()
    }
    
#endif
    func updateMetalView(){
    }
}

