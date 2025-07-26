//
//  AnimatedLabel.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

/// **NOTE:**
/// This component is completely generated with Claude, no doubt there are improvements
/// This was just done from simplicity for this example to showcase a simple text animation
/// Realisically there are a lot of optimisations and better ways of handling this to ensure a smoother result
/// Feel free to take this as a starting position when animating words or use SwfitUI text transition etc
/// This is just showcasing that you can control this part with custom animations

import UIKit

class AnimatedUILabel: UIView {
    
    // MARK: - Properties
    private var wordLabels: [UILabel] = []
    private var previousWords: [String] = []
    private var currentSize: CGSize = .zero
    
    var text: String = "" {
        didSet {
            animateTextChange()
        }
    }
    
    var font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            updateFont()
        }
    }
    
    var textColor: UIColor = .label {
        didSet {
            updateTextColor()
        }
    }
    
    var animationDuration: TimeInterval = 0.15
    var wordSpacing: CGFloat = 4.0
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        isUserInteractionEnabled = false
        clipsToBounds = false
    }
    
    // MARK: - Animation Logic
    private func animateTextChange() {
        let oldWords = previousWords
        let newWords = text.split(separator: " ").map { String($0) }
        
        // Calculate the new size before animating
        let newSize = calculateSize(for: newWords)
        
        // If this is the first time, set size immediately
        if currentSize == .zero {
            currentSize = newSize
            invalidateIntrinsicContentSize()
        }
        
        // Create a mapping of which old labels can be reused
        var reusableLabels: [String: UILabel] = [:]
        var labelsToFadeOut: [UILabel] = []
        
        // Categorize existing labels
        for (index, label) in wordLabels.enumerated() {
            if index < oldWords.count {
                let oldWord = oldWords[index]
                if let _ = newWords.firstIndex(of: oldWord) {
                    // This word exists in the new text, can be reused
                    reusableLabels[oldWord] = label
                } else {
                    // This word doesn't exist in new text, fade it out
                    labelsToFadeOut.append(label)
                }
            }
        }
        
        // Fade out labels that are no longer needed
        for label in labelsToFadeOut {
            UIView.animate(withDuration: animationDuration * 0.5,
                          animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
        
        // Clear the labels array and rebuild with new words
        wordLabels.removeAll()
        
        // Create/position new word labels
        var xPosition: CGFloat = 0
        
        for (index, word) in newWords.enumerated() {
            if let existingLabel = reusableLabels[word] {
                // Reuse existing label and animate to new position
                wordLabels.append(existingLabel)
                
                UIView.animate(withDuration: animationDuration,
                              delay: 0,
                              usingSpringWithDamping: 0.8,
                              initialSpringVelocity: 0,
                              options: [.curveEaseOut],
                              animations: {
                    existingLabel.frame.origin.x = xPosition
                })
                
                // Remove from reusable pool so it won't be used again
                reusableLabels.removeValue(forKey: word)
            } else {
                // Create new label
                let label = UILabel()
                label.text = word
                label.font = font
                label.textColor = textColor
                label.sizeToFit()
                
                // Start with fade out state
                label.alpha = 0
                
                // Add to view and position without animation
                UIView.performWithoutAnimation {
                    addSubview(label)
                    label.frame.origin.x = xPosition
                    label.frame.origin.y = 0
                    layoutIfNeeded() // Force layout to apply immediately
                }
                
                wordLabels.append(label)
                
                // Animate in with only fade, no position change
                UIView.animate(withDuration: animationDuration,
                              delay: 0,
                              usingSpringWithDamping: 0.8,
                              initialSpringVelocity: 0,
                              options: [.curveEaseOut],
                              animations: {
                    label.alpha = 1
                })
            }
            
            xPosition += calculateWordWidth(word) + wordSpacing
        }
        
        self.currentSize = newSize
        UIView.animate(withDuration: self.animationDuration) {
            self.invalidateIntrinsicContentSize()
            self.superview?.layoutIfNeeded()
        }
        
        previousWords = newWords
    }
    
    // MARK: - Size Calculation
    private func calculateSize(for words: [String]) -> CGSize {
        guard !words.isEmpty else { return .zero }
        
        let totalWidth = words.enumerated().reduce(0.0) { result, element in
            let (index, word) = element
            let wordWidth = calculateWordWidth(word)
            let spacing = index < words.count - 1 ? wordSpacing : 0
            return result + wordWidth + spacing
        }
        
        let height = font.lineHeight
        return CGSize(width: totalWidth, height: height)
    }
    
    private func calculateWordWidth(_ word: String) -> CGFloat {
        let label = UILabel()
        label.text = word
        label.font = font
        label.sizeToFit()
        return label.frame.width
    }
    
    // MARK: - Property Updates
    private func updateFont() {
        wordLabels.forEach { $0.font = font }
        // Recalculate size with new font
        currentSize = calculateSize(for: previousWords)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    
    private func updateTextColor() {
        wordLabels.forEach { $0.textColor = textColor }
    }
    
    // MARK: - Layout
    override var intrinsicContentSize: CGSize {
        return currentSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure labels are positioned correctly after layout changes
        var xPosition: CGFloat = 0
        for (index, label) in wordLabels.enumerated() {
            label.frame.origin.x = xPosition
            xPosition += label.frame.width + (index < wordLabels.count - 1 ? wordSpacing : 0)
        }
    }
}
