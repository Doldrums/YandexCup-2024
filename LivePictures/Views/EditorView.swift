import SwiftUI
import MetalKit

enum Tool {
    case brush
    case pencil
    case erase
    case instruments
    
    var isDrawing: Bool {
        switch self {
        case .brush:
            true
        case .pencil:
            true
        case .erase:
            true
        case .instruments:
            false
        }
    }
    
    var brushType: BrushType {
        switch self {
        case .brush:
            .brush
        case .pencil:
            .pencil
        case .erase:
            .eraser
        case .instruments:
            fatalError("Unreachable state")
        }
    }
}

struct EditorView: View {
    @ObservedObject private var frameManager = FrameManager()
    
    @State private var selectedTool: Tool = .brush
    @State private var selectedColor: CGColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
    @State private var layersSheetShown = false
    
    enum Progress {
        case inactive
        case started
        case changing
    }
    @GestureState private var gestureState: Progress = .inactive
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Button(action: {
                        frameManager.frames[frameManager.currentIndex].undo()
                    }) {
                        Image(.undo)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                            .opacity(frameManager.currentFrame.canUndo ? 1 : 0.5)
                    }
                    .disabled(!frameManager.currentFrame.canUndo)
                    
                    Button(action: {
                        frameManager.frames[frameManager.currentIndex].redo()
                    }) {
                        Image(.redo)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                            .opacity(frameManager.currentFrame.canRedo ? 1 : 0.5)
                    }
                    .disabled(!frameManager.currentFrame.canRedo)
                }
                .disabled(frameManager.isPlaying)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        frameManager.removeCurrentFrame()
                    }) {
                        Image(.bin)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                    }
                    
                    Button(action: {
                        frameManager.newFrame()
                    }) {
                        Image(.filePlus)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                    }
                    
                    Button(action: {
                        layersSheetShown.toggle()
                    }) {
                        Image(.layers)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                    }
                }
                .disabled(frameManager.isPlaying)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        frameManager.pause()
                    }) {
                        Image(.pause)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                            .opacity(frameManager.canPause ? 1 : 0.5)
                    }
                    .disabled(!frameManager.canPause)
                    
                    Button(action: {
                        frameManager.play()
                    }) {
                        Image(.play)
                            .foregroundStyle(
                                Color(UIColor.label)
                            )
                            .opacity(frameManager.canPlay ? 1 : 0.5)
                    }
                    .disabled(!frameManager.canPlay)
                }
            }
            .padding(.horizontal, 16)
            
            ZStack {
                Image(.canvasTexture)
                    .resizable()
                    .clipShape(
                        RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                    )
                
                if let previousFrame = frameManager.previousFrame, !frameManager.isPlaying {
                    MetalView(frame: previousFrame)
                        .opacity(0.5)
                        .clipShape(
                            RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                        )
                }
                
                GeometryReader { geometry in
                    MetalView(frame: frameManager.currentFrame)
                        .clipShape(
                            RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                        )
                        .onAppear {
                            frameManager.setFrameSize(geometry.size)
                        }
                        .if(selectedTool.isDrawing && !frameManager.isPlaying) { view in
                            view.gesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($gestureState) { value, state , _ in
                                        switch (state) {
                                        case .inactive:
                                            state = .started
                                            frameManager.frames[frameManager.currentIndex].addOperation(
                                                DrawingOperation(
                                                    brushType: selectedTool.brushType,
                                                    size: geometry.size,
                                                    color: selectedColor
                                                )
                                            )
                                        default:
                                            state = .changing
                                            
                                            let currentOperation = frameManager.currentFrame.operations.last as? DrawingOperation
                                            
                                            let point = SIMD2(
                                                Float(value.location.x),
                                                Float(value.location.y)
                                            )
                                            currentOperation?.addPoint(point)
                                        }
                                    }
                            )
                        }
                }
            }
            .padding(.all, 16)
            
            HStack(spacing: 16) {
                Button(action: {
                    selectedTool = .brush
                }) {
                    Image(.brush)
                        .foregroundStyle(
                            selectedTool == .brush ? .accentColor : Color(UIColor.label)
                        )
                }
                Button(action: {
                    selectedTool = .pencil
                }) {
                    Image(.pencil)
                        .foregroundStyle(
                            selectedTool == .pencil ? .accentColor : Color(UIColor.label)
                        )
                }
                Button(action: {
                    selectedTool = .erase
                }) {
                    Image(.erase)
                        .foregroundStyle(
                            selectedTool == .erase ? .accentColor : Color(UIColor.label)
                        )
                }
                Button(action: {
                    selectedTool = .instruments
                }) {
                    Image(.instruments)
                        .foregroundStyle(
                            selectedTool == .instruments ? .accentColor : Color(UIColor.label)
                        )
                }
                
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
            }
            .disabled(frameManager.isPlaying)
        }
        .sheet(isPresented: $layersSheetShown) {
            LayersView(
                frames: frameManager.frames,
                frameRatio: frameManager.frameRatio,
                currentFrame: $frameManager.currentIndex,
                isVisible: $layersSheetShown
            )
        }
    }
}

#Preview {
    EditorView()
}
