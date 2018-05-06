//
//  VoiceRecoverView.swift
//  VoiceRecoverView
//
//  Created by Pavel Aristov on 19.02.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import UIKit
import FontAwesome_swift
import AVFoundation

protocol VoiceRecoverViewDelegate: class {
    func didSendRecord(at url: URL, duration: Int, peaks: [Float])
}

class VoiceRecoverView: UIView {
    
    @IBOutlet weak var recoverIcon: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cancelContainerView: UIView!
    @IBOutlet weak var timeContainerView: UIView!
    
    @IBOutlet weak var leftArrowIcon: UIImageView!
    @IBOutlet weak var sendIcon: UIImageView!
    
    @IBOutlet weak var sendButtonOutlet: UIButton!
    @IBOutlet weak var cancelButtonOutlet: UIButton!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    fileprivate let shapeLayer = CAShapeLayer()
    private var sendButtonIcon: FontAwesome = .microphone
    private var endAnimation = true
    
    var recorder: Recording!
    var decibels = [Float]()
    
    var mainColor = UIColor.yellowMainColor
    var errorColor = UIColor.errorColor
    
    var alphaOreol: CGFloat = 0.2
    
    var playerView: VoicePlayView? = nil
    weak var delegate: VoiceRecoverViewDelegate? = nil
    
    override func awakeFromNib() {
        
        setFAIcons()
        setupRecorder()
        recoverIconAnimate()
        
        shapeLayer.fillColor = mainColor.withAlphaComponent(alphaOreol).cgColor
        timeContainerView.layer.addSublayer(shapeLayer)
        sendButtonOutlet.layer.zPosition = 1
        sendIcon.layer.zPosition = 1
        
        self.sendButtonOutlet.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.sendButtonOutlet.transform = .identity
        })
        
        do { try recorder.record() }
        catch { print(error) }
    }
    
    func setFAIcons() {
        leftArrowIcon.image = UIImage.fontAwesomeIcon(name: .chevronLeft, textColor: .lightGray, size: leftArrowIcon.frame.size)
        setSendIcon(name: .microphone)
    }
    
    func setSendIcon(name: FontAwesome) {
        sendButtonIcon = name
        sendIcon.image = UIImage.fontAwesomeIcon(name: name, textColor: .white, size: CGSize(width: 30, height: 30))
    }
    
    func setupRecorder() {
        recorder = Recording(to: Recording.voiceRecordName)
        recorder.bitRate = 16000
        recorder.sampleRate = 16000
        recorder.delegate = self
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            do {
                try self.recorder.prepare()
            } catch {
                print(error)
            }
        }
    }
    
    func recoverIconAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.recoverIcon.alpha = 0
        }) { _ in
            UIView.animate(withDuration: 0.25, animations: {
                self.recoverIcon.alpha = 1
            }, completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                    self.recoverIconAnimate()
                })
            })
        }
    }
    
    func translateX(translationX: CGFloat) {
        guard translationX < 0 else {
            return
        }
        
        timeContainerView.transform = CGAffineTransform(translationX: translationX, y: 0)
        
        self.cancelContainerView.alpha = (timeContainerView.frame.minX - self.cancelContainerView.frame.maxX) / 50
        
        UIView.animate(withDuration: 0.2) {
            self.sendButtonOutlet.backgroundColor = self.cancelContainerView.alpha < 1 ? self.errorColor : self.mainColor
            self.shapeLayer.fillColor = (self.cancelContainerView.alpha < 1 ? self.errorColor : self.mainColor).withAlphaComponent(self.alphaOreol).cgColor
        }
        
        if (sendButtonIcon == .microphone && self.cancelContainerView.alpha < 1) ||
            (sendButtonIcon == .trash && self.cancelContainerView.alpha >= 1) {
            changeSendIcon()
        }
    }
    
    func changeSendIcon() {
        guard endAnimation else { return }
        
        endAnimation = false
        UIView.animate(withDuration: 0.1, animations: {
            self.sendIcon.alpha = 0
            self.sendIcon.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }) { _ in
            self.sendButtonIcon = self.cancelContainerView.alpha < 1 ? .trash : .microphone
            self.setSendIcon(name: self.sendButtonIcon)
            self.endAnimation = true
            UIView.animate(withDuration: 0.1, animations: {
                self.sendIcon.alpha = 1
                self.sendIcon.transform = CGAffineTransform.identity
            })
        }
    }
    
    func touchEnded(at location: CGPoint) {
        if self.sendButtonOutlet.frame.contains(location) {
            if let time = recorder.recordCurrentTime, time < 1 {
                hideView(send: false)
            } else {
                print("SEND")
                hideView(send: true)
            }
        } else if self.cancelContainerView.alpha < 1 {
            hideView(send: false)
        } else {
            reset(setIcon: true)
        }
    }
    
    func reset(setIcon: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            UIView.animate(withDuration: 0.2, animations: {
                self.timeContainerView.transform = .identity
                self.cancelContainerView.alpha = 0
                self.cancelButtonOutlet.alpha = 1
            }, completion: { _ in
                if setIcon {
                    self.setSendIcon(name: .arrowUp)
                }
            })
        })
    }
    
    func showView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1
        })
    }
    
    func hideView(send: Bool) {
        recorder.stop()
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
    
            if send { self.delegate?.didSendRecord(at: self.recorder.url, duration: Int(self.recorder.duration), peaks: self.decibels) }
            
            self.removeFromSuperview()
        }
    }
    
    func showRecord() {
        
        if let time = recorder.recordCurrentTime, time < 1 {
            hideView(send: false)
            return
        }

        guard playerView == nil else { return }
        
        recorder.stop()
        UIView.animate(withDuration: 0.2, animations: {
            self.shapeLayer.fillColor = UIColor.clear.cgColor
            self.sendButtonOutlet.alpha = 0
            self.sendIcon.alpha = 0
        }) { _ in
            self.playerView = VoicePlayView.instanceFromNib(to: self)
            self.playerView?.delegate = self
            self.playerView?.setupUI(recorder: self.recorder, decibels: self.decibels)
        }
    }
    
    @IBAction func sendButtonAction(_ sender: UIButton) {
        hideView(send: true)
    }
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        hideView(send: false)
    }
}

extension VoiceRecoverView: RecorderDelegate {
    func didChangeRecordCurrentTime(currentTime: TimeInterval) {
        
        guard Int(currentTime) <= 300 else {
            recorder.stop()
            return
        }
        
        let minutes = currentTime / 60
        let seconds = currentTime.truncatingRemainder(dividingBy: 60)
        
        timeLabel.text = "\(Int(minutes)):\(seconds < 10 ? "0" : "")\(Int(seconds))"
    }
    
    func didStopRecord() { }
    
    func audioMeterDidUpdate(dB: Float) {
        decibels.append(-dB)
        
        let scale = 40 - CGFloat( -dB / 1.3 )
        let circlePath = UIBezierPath(arcCenter: sendButtonOutlet.center, radius: sendButtonOutlet.frame.width / 2 + scale, startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
    }
}

extension VoiceRecoverView: VoicePlayViewDelegate {
    func didSendRecover(at: URL) {
        self.delegate?.didSendRecord(at: at, duration: Int(recorder.duration), peaks: decibels)
    }
    
    class func instanceFromNib(to containerView: UIView, show: Bool = true) -> VoiceRecoverView {
        let view = UINib(nibName: "VoiceRecoverView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! VoiceRecoverView
        view.alpha = 0
        containerView.addSubview(view)
        
        if show { view.showView() }
        
        return view
    }
}
