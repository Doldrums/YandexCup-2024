import Foundation
import MetalKit

enum BrushType {
    case pencil
    case brush
    case eraser
    
    var brushThickness: Float {
        switch (self) {
        case .brush:
            8
        case .pencil:
            2
        case .eraser:
            10
        }
    }
}

class DrawingOperation: Operation {
    var brushType: BrushType
    var color: SIMD4<Float>
    
    private static let pipelineState = MetalBackend.shared.makePencilPipelineState()
    
    private var points: [SIMD2<Float>] = []
    private var stroke: Stroke
    
    private var size: CGSize
    private var triangulated: StrokeComplex
    
    init(brushType: BrushType, size: CGSize, color: CGColor) {
        self.brushType = brushType
        self.stroke = Stroke(
            miterLimit: 10,
            thickness: brushType.brushThickness,
            join: .bevel,
            cap: .butt
        )
        self.size = size
        
        let components = color.components!.map { Float($0) }
        self.color = brushType == .eraser ?
            SIMD4<Float>(0, 0, 0, 0) :
            SIMD4<Float>(components[0], components[1], components[2], components[3])
        
        self.triangulated = StrokeComplex(positions: [], cells: [])
    }
    
    func addPoint(_ point: SIMD2<Float>) {
        if let last = self.points.last, distance(last, point) < 10 {
            return
        }
        self.points.append(point)
        
        self.triangulated = stroke.build(points)
        self.triangulated.positions = self.triangulated.positions.map {
            SIMD2(
                ($0.x / Float(size.width) - 0.5) * 2.0,
                ($0.y / Float(size.height) - 0.5) * -2.0
            )
        }
    }
    
    func encodeOperation(into encoder: MTLRenderCommandEncoder) {
        if self.triangulated.positions.isEmpty {
            return
        }
        
        let vertexData = triangulated.positions.flatMap { [$0.x, $0.y] }
        let vertexBuffer = MetalBackend.shared.device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        
        let indexData = triangulated.cells.flatMap { [$0.x, $0.y, $0.z] }
        let indexBuffer = MetalBackend.shared.device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<UInt32>.size, options: [])
        
        
        let colorBuffer = MetalBackend.shared.device.makeBuffer(bytes: &color, length: MemoryLayout<SIMD4<Float>>.size, options: [])

        encoder.setRenderPipelineState(DrawingOperation.pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)

        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: triangulated.cells.count * 3,
            indexType: .uint32,
            indexBuffer: indexBuffer!,
            indexBufferOffset: 0
        )
    }
}
