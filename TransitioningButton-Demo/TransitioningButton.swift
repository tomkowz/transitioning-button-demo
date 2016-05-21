import UIKit

class TransitioningButton: UIControl {
    
    enum State {
        case Begin
        case Loading
        case FinishWithSuccess
        case FinishWithFailure
    }
    
    @IBInspectable var normalBackgroundColor: UIColor?
    @IBInspectable var pressedBackgroundColor: UIColor?
    @IBInspectable var disabledBackgroundColor: UIColor?
    @IBInspectable var disabledTextColor: UIColor?
    @IBInspectable var successBackgroundColor: UIColor?
    @IBInspectable var successTextColor: UIColor?
    @IBInspectable var failureBackgroundColor: UIColor?
    @IBInspectable var failureTextColor: UIColor?
    
    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var secondLabel: UILabel!
    
    @IBOutlet private var containerBegin: UIView!
    @IBOutlet private var containerLoading: UIView!
    @IBOutlet private var containerFinish: UIView!
    
    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var widthConstriant: NSLayoutConstraint!

    var buttonState: State = .Begin {
        didSet {
            updateAfterButtonStateChanged(self.buttonState)
        }
    }
    
    override var enabled: Bool {
        didSet {
            configureAppearance()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    private func configure() {
        configureActions()
        configureDefaultAppearance()
        configureAppearance()
        configureObservers()
        updateAfterButtonStateChanged(buttonState)
    }
    
    func configureDefaultAppearance() {
        clipsToBounds = true
        self.layer.cornerRadius = self.bounds.height / 2.0
    }
    
    private func configureActions() {
        self.addTarget(self, action: #selector(touchUpInside), forControlEvents: .TouchUpInside)
        self.addTarget(self, action: #selector(touchUpOutside), forControlEvents: .TouchUpOutside)
        self.addTarget(self, action: #selector(touchDown), forControlEvents: .TouchDown)
    }
    
    private func configureObservers() {
        firstLabel.addObserver(self, forKeyPath: "text", options: [.New], context: nil)
        secondLabel.addObserver(self, forKeyPath: "text", options: [.New], context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?,
                                         ofObject object: AnyObject?,
                                                  change: [String : AnyObject]?,
                                                  context: UnsafeMutablePointer<Void>) {
        if (keyPath == "text") {
            if let lbl = object as? UILabel {
                lbl.sizeToFit()
            }
        } else {
            super.observeValueForKeyPath("text", ofObject: object, change: change, context: context)
        }
    }
    
    private func configureAppearance() {
        if enabled {
            updateAppearanceToNormal()
        } else {
            updateAppearanceToDisabled()
        }
    }
    
    private func offsetForState(state: State) -> CGFloat {
        let height = self.bounds.height
        switch state {
        case .Begin: return 0
        case .Loading: return height
        case .FinishWithFailure, .FinishWithSuccess: return 2 * height
        }
    }
    
    private func containerViewForState(state: State) -> UIView {
        switch state {
        case .Begin: return containerBegin
        case .Loading: return containerLoading
        case .FinishWithFailure, .FinishWithSuccess: return containerFinish
        }
    }
    
    override func updateConstraints() {
        updateAfterButtonStateChanged(self.buttonState)
        super.updateConstraints()
    }
    
    private func updateAfterButtonStateChanged(state: State) {
        // Get container view that will be presented for new state
        let containerView = containerViewForState(state)
        
        /*
         As the content might change in the same autolayout pass as this animation
         We have to make sure that UI is ready to be presented.
         
         This is especially important when you're about to present short or long
         text in case when previous text was oposite, meaning, you had short
        text and not it is long or vice-versa.
    
        Without doing this additional pass you'd see that text is moving up
        and left or right, depending whether new text it is longer or shorter.
         */
        let loopUntil = NSDate(timeIntervalSinceNow: 0)
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: loopUntil)
        
        // Calculate point to where scroll view should offset its content
        let scrollToY = offsetForState(state)

        // Decide whether button should react on touches...
        userInteractionEnabled = state == .Begin
        
        // Set new width for new state
        self.widthConstriant.constant =
            max(self.bounds.height, containerView.subviews.first!.bounds.width +
                (self.bounds.height / 2.0))
        
        // And animate the change...
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.topConstraint.constant = -scrollToY;
            self.layoutIfNeeded()
            
            // Update style of the control
            if state == .Begin {
                if self.enabled {
                    self.updateAppearanceToNormal()
                } else {
                    self.updateAppearanceToDisabled()
                }
                
            } else if state == .FinishWithSuccess {
                self.updateAppearanceToSuccess()
            } else if state == .FinishWithFailure {
                self.updateAppearanceToFailure()
            }
            
            }, completion: { _ in
                // If an operation performed by this control failed, it will
                // show the control in the .Begin state.
                if state == .FinishWithFailure {
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    dispatch_after(time, dispatch_get_main_queue(), {
                        let transition = CATransition()
                        transition.type = kCATransitionFade
                        transition.duration = 0.3
                        
                        self.layer.addAnimation(transition, forKey: kCATransition)
                        
                        self.updateAfterButtonStateChanged(.Begin)
                    })
                }
        })
    }
}

private extension TransitioningButton {
    @objc private func touchUpInside() {
        pushOut()
    }
    
    @objc private func touchUpOutside() {
        pushOut()
    }
    
    @objc private func touchDown() {
        pushIn()
    }
    
    private func pushIn() {
        let pushAnimation = CABasicAnimation(keyPath: "transform.scale")
        pushAnimation.duration = 0.1
        pushAnimation.fromValue = 1
        pushAnimation.toValue = 0.95
        pushAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        pushAnimation.removedOnCompletion = false
        pushAnimation.fillMode = kCAFillModeForwards
        self.layer.addAnimation(pushAnimation, forKey: nil)
        
        updateAppearanceToPressed()
    }
    
    private func pushOut() {
        updateAppearanceToNormal()
        
        let pushAnimation = CABasicAnimation(keyPath: "transform.scale")
        pushAnimation.duration = 0.1
        pushAnimation.fromValue = 0.95
        pushAnimation.toValue = 1
        pushAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        pushAnimation.removedOnCompletion = false
        pushAnimation.fillMode = kCAFillModeForwards
        self.layer.addAnimation(pushAnimation, forKey: nil)
    }
}

private extension TransitioningButton {
    
    func updateAppearanceToNormal() {
        backgroundColor = normalBackgroundColor
        firstLabel.textColor = pressedBackgroundColor
        secondLabel.textColor = pressedBackgroundColor
    }
    
    func updateAppearanceToPressed() {
        backgroundColor = pressedBackgroundColor
        firstLabel.textColor = normalBackgroundColor
        secondLabel.textColor = normalBackgroundColor
    }
    
    func updateAppearanceToDisabled() {
        backgroundColor = disabledBackgroundColor
        firstLabel.textColor = disabledTextColor
        secondLabel.textColor = disabledTextColor
    }
    
    func updateAppearanceToSuccess() {
        backgroundColor = successBackgroundColor
        firstLabel.textColor = successTextColor
        secondLabel.textColor = successTextColor
    }
    
    func updateAppearanceToFailure() {
        backgroundColor = failureBackgroundColor
        firstLabel.textColor = failureTextColor
        secondLabel.textColor = failureTextColor
    }
}
