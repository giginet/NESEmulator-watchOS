import Foundation
import AVFoundation
import PVNES
import PVSupport

class AudioPlayer {
    let engine = AVAudioEngine()
    let emulatorCore: PVNESEmulatorCore
    let playerNode = AVAudioPlayerNode()
    private var ringBuffer: OERingBuffer!
    private var buffer: AVAudioPCMBuffer!
    private var playing: Bool = false
    
    init(emulatorCore: PVNESEmulatorCore) {
        self.emulatorCore = emulatorCore
    }
    
    func start() {
        if playing {
            return
        }
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: emulatorCore.audioSampleRate(),
                                   channels: AVAudioChannelCount(emulatorCore.channelCount()),
                                   interleaved: false)
        
        let audioBufferCount = self.emulatorCore.audioBufferCount()
        for i in 0..<audioBufferCount {
            ringBuffer = self.emulatorCore.ringBuffer(at: i)
        }
        
        let capacity = AVAudioFrameCount(emulatorCore.audioSampleRate())
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity)
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        
        self.playNext(buffer: self.buffer)
        
        try! engine.start()
        playerNode.play()
        playing = true
    }
    
    func stop() {
        if !playing {
            return
        }
        playerNode.stop()
        engine.stop()
        playing = false
    }
    
    func playNext(buffer: AVAudioPCMBuffer) {
        self.updateBuffer()
        playerNode.scheduleBuffer(buffer) {
            self.playNext(buffer: buffer)
        }
    }
    
    private func updateBuffer() {
        var availableBytes: Int32 = 0
        guard let head = TPCircularBufferTail(&ringBuffer.buffer, &availableBytes) else {
            fatalError()
        }
        
        let bytesPerSample: Int = Int(self.emulatorCore.audioBitDepth() / 8)
        let channelCount: Int = Int(self.emulatorCore.channelCount(forBuffer: 0))
        
        let bufferLength = Int(availableBytes) / Int(bytesPerSample)
        let framesAvailable = bufferLength / channelCount
        buffer.frameLength = AVAudioFrameCount(framesAvailable)
        
        let audioBuffer = UnsafeBufferPointer<Int16>(start: head.assumingMemoryBound(to: Int16.self), count: bufferLength)
        for channel in 0..<channelCount {
            let samples = UnsafeMutableBufferPointer<Float32>(start: buffer.floatChannelData?.pointee, count: Int(buffer.frameLength))
            for frame in 0..<framesAvailable {
                samples[frame] = Float32(audioBuffer[frame * channelCount + channel])
            }
        }
        TPCircularBufferConsume(&ringBuffer.buffer, availableBytes)
    }
}
