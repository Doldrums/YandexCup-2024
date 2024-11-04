import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var frame: Frame
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(frame)
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.preferredFramesPerSecond = 60
        mtkView.device = MetalBackend.shared.device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.isOpaque = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.layer.isOpaque = false
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.frame = frame
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var frame: Frame
        
        private let mtlCommandQueue: MTLCommandQueue
        private let mtlRenderPipelineState: MTLRenderPipelineState
        
        init(_ frame: Frame) {
            self.frame = frame
            self.mtlCommandQueue = MetalBackend.shared.makeCommandQueue()
            self.mtlRenderPipelineState = MetalBackend.shared.makeRenderPipelineState()

            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {
                return
            }
            
            let commandBuffer = mtlCommandQueue.makeCommandBuffer()
            
            let renderPass = view.currentRenderPassDescriptor
            renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
            renderPass?.colorAttachments[0].loadAction = .clear
            renderPass?.colorAttachments[0].storeAction = .store
            
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(
                descriptor: renderPass!
            )

            for operation in frame.operations {
                operation.encodeOperation(into: commandEncoder!)
            }
            
            commandEncoder?.endEncoding()
            
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}

#Preview {
    MetalView(
        frame: Frame()
    )
}
