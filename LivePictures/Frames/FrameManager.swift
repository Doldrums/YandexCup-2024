import SwiftUI

class FrameManager: ObservableObject {
    @Published var frames: [Frame] = [Frame()]
    @Published var currentIndex: Int = 0
    
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    
    private(set) var frameRatio: CGFloat = 1
    
    func setFrameSize(_ size: CGSize) {
        frameRatio = size.width / size.height
    }
    
    func play() {
        guard canPlay else { return }
        
        self.currentIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentIndex = (self.currentIndex + 1) % self.frames.count
            }
        }
        self.isPlaying = true
    }
    
    func pause() {
        guard canPause else { return }
        
        timer?.invalidate()
        timer = nil
        self.isPlaying = false
    }
    
    var canPlay: Bool {
        !isPlaying && frames.count > 1
    }
    
    var canPause: Bool {
        isPlaying
    }
    
    var currentFrame: Frame {
        frames[currentIndex]
    }
    
    var previousFrame: Frame? {
        guard currentIndex - 1 >= 0 else {
            return nil
        }
        
        return frames[currentIndex - 1]
    }

    func newFrame() {
        let frame = Frame()
        
        frames.append(frame)
        currentIndex = frames.count - 1
    }

    
    func removeCurrentFrame() {
        frames.removeAll { $0.id == currentFrame.id }
        
        if frames.count == 0 {
            frames.append(Frame())
            currentIndex = 0
        } else {   
            currentIndex = frames.count - 1
        }
    }
}
