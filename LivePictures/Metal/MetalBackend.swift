import MetalKit

class MetalBackend {
    static let shared: MetalBackend = MetalBackend()
    
    let device: MTLDevice
    let textureLoader: MTKTextureLoader
    let library: MTLLibrary
    
    let canvasTexture: MTLTexture
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        library = device.makeDefaultLibrary()!
        textureLoader = MTKTextureLoader(device: device)
        canvasTexture = try! textureLoader.newTexture(name: "CanvasTexture", scaleFactor: 1, bundle: .main)
    }
    
    func makeCommandQueue() -> MTLCommandQueue {
        return device.makeCommandQueue()!
    }
    
    func makeRenderPipelineState() -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "displayTexture")
        
        return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func makePencilPipelineState() -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor()
        pipelineDescriptor.vertexDescriptor?.attributes[0].format = .float2
        pipelineDescriptor.vertexDescriptor?.attributes[0].offset = 0
        pipelineDescriptor.vertexDescriptor?.attributes[0].bufferIndex = 0
        pipelineDescriptor.vertexDescriptor?.layouts[0].stride = MemoryLayout<Float>.size * 2
        pipelineDescriptor.vertexDescriptor?.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "pencilVertex")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "pencilFragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}
