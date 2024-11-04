import MetalKit

struct Frame: Identifiable {
    private(set) var id = UUID()

    private(set) var operations: [Operation]
    private var redoOperations: [Operation]
    
    init() {
        self.operations = []
        self.redoOperations = []
    }
    
    var canRedo: Bool {
        redoOperations.count > 0
    }
    
    var canUndo: Bool {
        operations.count > 0
    }
    
    mutating func undo() {
        guard canUndo else { return }
        
        redoOperations.append(operations.popLast()!)
    }
    
    mutating func redo() {
        guard canRedo else { return }
        
        operations.append(redoOperations.popLast()!)
    }
    
    mutating func addOperation(_ operation: Operation) {
        redoOperations = []
        operations.append(operation)
    }
}
