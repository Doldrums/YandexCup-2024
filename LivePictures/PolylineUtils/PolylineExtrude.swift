import simd

enum StrokeJoin {
    case miter
    case bevel
}

enum StrokeCap {
    case butt
    case square
}

struct StrokeComplex {
    var positions: [SIMD2<Float>]
    var cells: [SIMD3<UInt32>]
}

struct Stroke {
    var miterLimit: Float
    var thickness: Float
    var join: StrokeJoin
    var cap: StrokeCap
    private var normal: SIMD2<Float>?
    private var lastFlip: Float
    private var started: Bool
    
    init(miterLimit: Float = 10, thickness: Float = 1, join: StrokeJoin = .miter, cap: StrokeCap = .butt) {
        self.miterLimit = miterLimit
        self.thickness = thickness
        self.join = join
        self.cap = cap
        self.normal = nil
        self.lastFlip = -1
        self.started = false
    }
    
    func mapThickness(_ point: SIMD2<Float>, i: Int, points: [SIMD2<Float>]) -> Float {
        return thickness
    }
    
    mutating func build(_ points: [SIMD2<Float>]) -> StrokeComplex {
        var complex = StrokeComplex(positions: [], cells: [])
        
        guard points.count > 1 else { return complex }
        
        var total = points.count
        
        lastFlip = -1
        started = false
        normal = nil
        
        var count = 0
        for i in 1..<total {
            let last = points[i-1]
            let cur = points[i]
            let next = i < points.count - 1 ? points[i+1] : nil
            let halfThick = mapThickness(cur, i: i, points: points) / 2
            let amt = seg(&complex, index: count, last: last, cur: cur, next: next, halfThick: halfThick)
            count += amt
        }
        return complex
    }
    
    private mutating func seg(_ complex: inout StrokeComplex, index: Int, last: SIMD2<Float>, cur: SIMD2<Float>, next: SIMD2<Float>?, halfThick: Float) -> Int {
        var count = 0
        let capSquare = cap == .square
        let joinBevel = join == .bevel
        
        let lineA = direction(cur - last)
        
        if normal == nil {
            normal = normalVector(lineA)
        }
        
        if !started {
            started = true
            
            var adjustedLast = last
            if capSquare {
                adjustedLast -= lineA * halfThick
            }
            extrusions(&complex.positions, point: adjustedLast, normal: normal!, scale: halfThick)
        }
        
        complex.cells.append(SIMD3<UInt32>(UInt32(index), UInt32(index+1), UInt32(index+2)))
        
        if let next = next {
            let lineB = direction(next - cur)
            let (tangent, miter, miterLen) = computeMiter(lineA, lineB, halfThick)
            let flip: Float = dot(tangent, normal!) < 0 ? -1 : 1
            
            var bevel = joinBevel
            if !bevel && join == .miter && (miterLen / halfThick > miterLimit) {
                bevel = true
            }
            
            if bevel {
                complex.positions.append(contentsOf: [
                    cur - normal! * halfThick * flip,
                    cur + miter * miterLen * flip
                ])
                
                complex.cells.append(
                    lastFlip != -flip ?
                    SIMD3<UInt32>(UInt32(index), UInt32(index+2), UInt32(index+3)) :
                    SIMD3<UInt32>(UInt32(index+2), UInt32(index+1), UInt32(index+3))
                )
                
                complex.cells.append(
                    SIMD3<UInt32>(UInt32(index+2), UInt32(index+3), UInt32(index+4))
                )
                
                normal = normalVector(lineB)
                complex.positions.append(cur - normal! * halfThick * flip)
                count += 3
            } else {
                extrusions(&complex.positions, point: cur, normal: miter, scale: miterLen)
                complex.cells.append(
                    lastFlip == 1 ?
                    SIMD3<UInt32>(UInt32(index), UInt32(index+2), UInt32(index+3)) :
                    SIMD3<UInt32>(UInt32(index+2), UInt32(index+1), UInt32(index+3))
                )
                
                normal = miter
                count += 2
            }
            lastFlip = flip
        } else {
            normal = normalVector(lineA)
            var adjustedCur = cur
            if capSquare {
                adjustedCur += lineA * halfThick
            }
            extrusions(&complex.positions, point: adjustedCur, normal: normal!, scale: halfThick)
            complex.cells.append(
                lastFlip == 1 ?
                SIMD3<UInt32>(UInt32(index), UInt32(index+2), UInt32(index+3)) :
                SIMD3<UInt32>(UInt32(index+2), UInt32(index+1), UInt32(index+3))
            )
            
            count += 2
        }
        return count
    }
    
    private func extrusions(_ positions: inout [SIMD2<Float>], point: SIMD2<Float>, normal: SIMD2<Float>, scale: Float) {
        positions.append(point - normal * scale)
        positions.append(point + normal * scale)
    }
    
    private func direction(_ vector: SIMD2<Float>) -> SIMD2<Float> {
        return simd_normalize(vector)
    }
    
    private func normalVector(_ vector: SIMD2<Float>) -> SIMD2<Float> {
        return SIMD2<Float>(-vector.y, vector.x)
    }
    
    private func computeMiter(_ lineA: SIMD2<Float>, _ lineB: SIMD2<Float>, _ halfThick: Float) -> (SIMD2<Float>, SIMD2<Float>, Float) {
        let tangent = simd_normalize(lineA + lineB)
        
        let miter = SIMD2<Float>(-tangent.y, tangent.x)
        let tmp = SIMD2<Float>(-lineA.y, lineA.x)
        
        let length = halfThick / dot(miter, tmp)
        
        return (tangent, miter, length)
    }
}
