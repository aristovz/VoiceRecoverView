//
//  VoicePlayView.swift
//  VoiceRecoverView
//
//  Created by Pavel Aristov on 20.02.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import UIKit
import FontAwesome_swift
import AVFoundation

protocol VoicePlayViewDelegate: class {
    func didSendRecover(at: URL)
}

class VoicePlayView: UIView {
    
    @IBOutlet weak var cancelButtonOutlet: UIButton!
    @IBOutlet weak var sendButtonOutlet: UIButton!
    
    @IBOutlet weak var playButtonOutlet: UIButton!
    
    @IBOutlet weak var peaksView: PeaksView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    weak var delegate: VoicePlayViewDelegate? = nil
    
    var recorder: Recording!
    
    var duration: TimeInterval! {
        didSet {
            didChangePlayerCurrentTime(currentTime: duration)
        }
    }
    
    override func awakeFromNib() {
        setFAIcons()
    }
    
    func setFAIcons() {
        cancelButtonOutlet.setImage(UIImage.fontAwesomeIcon(name: .times, textColor: .lightGray, size: CGSize(width: 24, height: 24)), for: .normal)
        sendButtonOutlet.setImage(UIImage.fontAwesomeIcon(name: .arrowUp, textColor: .lightGray, size: CGSize(width: 24, height: 24)), for: .normal)
        
        setPlayIcon(icon: .playCircle)
    }
    
    func setupUI(recorder: Recording, decibels: [Float]) {
        print(#function)
        
        self.recorder = recorder
        recorder.delegate = self
        
        self.duration = Double(CMTimeGetSeconds(AVURLAsset(url: recorder.url).duration)) - 0.33
        
        peaksView.decibels = decibels
        peaksView.recorder = recorder
        peaksView.delegate = self
    }
    
    func setPlayIcon(icon: FontAwesome) {
        playButtonOutlet.setImage(UIImage.fontAwesomeIcon(name: icon, textColor: .groupTableViewBackground, size: CGSize(width: 30, height: 30)), for: .normal)
    }
    
    func showView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1
        })
    }
    
    func hideView() {
        recorder.stop()
        UIView.animate(withDuration: 0.2, animations: {
            self.superview?.alpha = 0
        }) { _ in
            self.superview?.removeFromSuperview()
        }
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if recorder.state == .Play {
            recorder.pause()
            setPlayIcon(icon: .playCircle)
        } else {
            do {
                try recorder.play()
                setPlayIcon(icon: .pauseCircle)
            }
            catch { print(error) }
        }
    }
    
    @IBAction func sendButtonAction(_ sender: UIButton) {
        delegate?.didSendRecover(at: recorder.url)
        hideView()
    }
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        hideView()
    }
}

extension VoicePlayView: RecorderDelegate {
    func didChangePlayerCurrentTime(currentTime: TimeInterval) {
        
        peaksView.progress = currentTime / duration
        
        let time = Darwin.round(currentTime)
        
        let minutes = time / 60
        let seconds = time.truncatingRemainder(dividingBy: 60)
        
        timeLabel.text = "\(Int(minutes)):\(seconds < 10 ? "0" : "")\(Int(seconds))"
        
    }
    
    func didStopPlaying() {
        setPlayIcon(icon: .playCircle)
    }
}

extension VoicePlayView: PeaksViewDelegate {
    class func instanceFromNib(to containerView: UIView, show: Bool = true) -> VoicePlayView {
        let view = UINib(nibName: "VoicePlayView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! VoicePlayView
        
        view.alpha = 0
        containerView.addSubview(view)
        
        if show { view.showView() }
        
        return view
    }
}
