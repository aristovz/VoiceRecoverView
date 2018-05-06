//
//  peaksView.swift
//  VoiceRecoverView
//
//  Created by Pavel Aristov on 21.02.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import UIKit

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Strideable where Self.Stride: SignedInteger {
    
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

protocol PeaksViewDelegate: class {
    func panGestureDidEnd(_ peaksView: PeaksView, progress: Double)
}

extension PeaksViewDelegate {
    func panGestureDidEnd(_ peaksView: PeaksView, progress: Double) { }
}

class PeaksView: UIView {
    
    var recorder: Recording? = nil
    var player: MusicPlayer? = nil
    weak var delegate: PeaksViewDelegate? = nil
    
    // Минимальная высота пика в px
    static var minHeight: CGFloat = 1
    
    // Пик при идеальной тишине
    static var silence: CGFloat = 35
    
    // Расстояние между пиками в px
    static var space: CGFloat = 1
    
    // Ширина пика в px
    static var width: CGFloat = 2
    
    var decibels: [Float] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var progress: Double = -1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var fillColor = UIColor.white
    var emptyColor = UIColor.gray
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    override func draw(_ rect: CGRect) {
        
        guard decibels.count > 0 else { return }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setShouldAntialias(false)
        
        // Минимальная высота пика в px
        let minHeight: CGFloat = PeaksView.minHeight
        
        // Пик при идеальной тишине
        let silence: CGFloat = PeaksView.silence
        
        // Расстояние между пиками в px
        let space: CGFloat = PeaksView.space
        
        // Ширина пика в px
        let width: CGFloat = PeaksView.width
        
        // Кол-во пиков
        let n = Int(self.frame.width / (width + space))
        
        let h = decibels.count / n
        var currentPosition = CGPoint(x: 0, y: 0)
        
        for k in 0..<n {
            let pos = Int(k * h)
            var avg: Float = 0
            var div: Float = 0
            for i in pos..<pos+h {
                avg += decibels[i]
                div += 1
            }
            
            let x = CGFloat(avg / div)
            let height = (1 - (x / silence).clamped(to: 0...1)) * (self.frame.height / 2 - minHeight) + minHeight
            currentPosition.y = (self.frame.height - 2 * height) / 2
            
            let path = UIBezierPath(roundedRect: CGRect(x: currentPosition.x, y: currentPosition.y, width: width, height: 2 * height), cornerRadius: width / CGFloat(2))
            
            if progress.isNormal && k <= Int(Double(n) * progress.clamped(to: 0...1)) {
                fillColor.setFill()
            } else {
                emptyColor.setFill()
            }
            
            path.fill()
            
            currentPosition.x += width + space
        }
    }
    
    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        
        if let player = player {
            guard player.state == .Play || player.state == .Pause else { return }
            
            if sender.state == .began {
                player.pause()
            } else if sender.state == .ended {
                do { try player.play() }
                catch { print(error) }
            }
            
            let location = sender.location(in: self).x
            let progress = Double(location / self.frame.width).clamped(to: 0...1)
            
            player.setProgress(progress: progress)
            delegate?.panGestureDidEnd(self, progress: progress)
        } else if let recorder = recorder {
            guard recorder.state == .Play || recorder.state == .Pause else { return }
            
            if sender.state == .began {
                recorder.pause()
            } else if sender.state == .ended {
                do { try recorder.play() }
                catch { print(error) }
            }
            
            let location = sender.location(in: self).x
            let progress = Double(location / self.frame.width).clamped(to: 0...1)
            
            recorder.setProgress(progress: progress)
            delegate?.panGestureDidEnd(self, progress: progress)
        }
    }
}
