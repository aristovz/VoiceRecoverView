//
//  Recorder.swift
//  VoiceRecoverView
//
//  Created by Pavel Aristov on 20.02.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import AVFoundation
import QuartzCore

@objc public protocol RecorderDelegate: AVAudioRecorderDelegate {
    @objc optional func audioMeterDidUpdate(dB: Float)
    @objc optional func didChangeRecordCurrentTime(currentTime: TimeInterval)
    @objc optional func didChangePlayerCurrentTime(currentTime: TimeInterval)
    @objc optional func didStopRecord()
    @objc optional func didStopPlaying()
}

public class Recording : NSObject {
    
    @objc public enum State: Int {
        case None, Record, Play, Pause
    }
    
    static var directory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    static var voiceRecordName = "recording.m4a"
    
    public weak var delegate: RecorderDelegate?
    public private(set) var url: URL
    public private(set) var state: State = .None
    
    public var bitRate = 192000
    public var sampleRate = 44100.0
    public var channels = 1
    public var metering = true
    
    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var link: CADisplayLink?
    
    private var recordTimer = Timer()
    private var playerTimer = Timer()
    
    var recordCurrentTime: TimeInterval? {
        return recorder?.currentTime
    }
    
    var playerCurrentTime: TimeInterval? {
        return player?.currentTime
    }
    
    var duration: TimeInterval {
        return Double(CMTimeGetSeconds(AVURLAsset(url: url).duration)) - 0.33
    }
    
    // MARK: - Initializers
    public init(to: String) {
        url = URL(fileURLWithPath: Recording.directory).appendingPathComponent(to)
        super.init()
    }
    
    // MARK: - Initializers
    public init(url: URL) {
        self.url = url
        super.init()
    }
    
    // MARK: - Record
    public func prepare() throws {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: bitRate,
            AVNumberOfChannelsKey: channels,
            AVSampleRateKey: sampleRate
            ] as [String : Any]
        
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.prepareToRecord()
        recorder?.delegate = delegate
        recorder?.isMeteringEnabled = metering
    }
    
    public func record() throws {
        if recorder == nil {
            try prepare()
        }
        
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try session.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        
        recorder?.record()
        state = .Record
        recordTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateRecordTimer), userInfo: nil, repeats: true)
        
        if metering {
            startMetering()
        }
    }
    
    // MARK: - Playback
    public func play() throws {
        try session.setCategory(AVAudioSessionCategoryPlayback)
        
        if state != .Pause {
            player = try AVAudioPlayer(contentsOf: url)
        }
        
        player?.play()
        state = .Play
        
        playerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updatePlayerTimer), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        switch state {
        case .Play:
            player?.pause()
            playerTimer.invalidate()
        default:
            break
        }
        
        state = .Pause
    }
    
    public func stop() {
        switch state {
        case .Play:
            player?.stop()
            player = nil
            playerTimer.invalidate()
            delegate?.didStopPlaying?()
        case .Record:
            recorder?.stop()
            recorder = nil
            recordTimer.invalidate()
            delegate?.didStopRecord?()
            stopMetering()
        default:
            break
        }
        
        state = .None
    }
    
    public func setProgress(progress: Double) {
        guard let player = player, player.currentTime > 0 else { return }
        
        player.currentTime = player.duration * progress
        delegate?.didChangePlayerCurrentTime?(currentTime: player.currentTime)
    }
    
    @objc func updateRecordTimer() {
        guard let recorder = recorder else { return }
        
        delegate?.didChangeRecordCurrentTime?(currentTime: recorder.currentTime)
    }
    
    @objc func updatePlayerTimer() {
        guard let player = player else { return }
        guard player.currentTime > 0 else {
            stop()
            return
        }
        
        delegate?.didChangePlayerCurrentTime?(currentTime: player.currentTime)
    }
    
    // MARK: - Metering
    @objc func updateMeter() {
        guard let recorder = recorder else { return }
        
        recorder.updateMeters()
        
        let dB = recorder.averagePower(forChannel: 0)
        
        delegate?.audioMeterDidUpdate?(dB: dB)
    }
    
    private func startMetering() {
        link = CADisplayLink(target: self, selector: #selector(updateMeter))
        link?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    private func stopMetering() {
        link?.invalidate()
        link = nil
    }
}
