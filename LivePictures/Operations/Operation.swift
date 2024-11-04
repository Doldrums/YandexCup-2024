import MetalKit

protocol Operation {
    func encodeOperation(into encoder: MTLRenderCommandEncoder)
}
