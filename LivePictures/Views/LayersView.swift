import SwiftUI

struct LayersView: View {
    var frames: [Frame]
    var frameRatio: CGFloat
    
    @Binding var currentFrame: Int
    @Binding var isVisible: Bool
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(frames.enumerated()), id: \.element.id) { offset, frame in
                    Button(action: {
                        currentFrame = offset
                        isVisible = false
                    }) {
                        MetalView(frame: frame)
                            .background {
                                Image(.canvasTexture)
                                    .resizable()
                            }
                            .clipShape(
                                RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                            )
                            .if(currentFrame == offset) {
                                $0.overlay {
                                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                                        .stroke(lineWidth: 5)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .aspectRatio(frameRatio, contentMode: .fit)
                    }
                }
            }
            .padding(16)
        }
    }
}
