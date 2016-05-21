import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var myButton: TransitioningButton!
    @IBOutlet var successSwitch: UISwitch!
    @IBOutlet var enabledSwitch: UISwitch!
    @IBOutlet var restartButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myButton.firstLabel.text = "Submit"
        myButton.secondLabel.text = "Success"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        myButton.buttonState = .Begin
    }
    
    @IBAction func buttonTouchUpInside(sender: TransitioningButton) {
        enableControls(false)
        sender.buttonState = .Loading
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) { 
            if self.successSwitch.on {
                sender.secondLabel.text = "Success"
                sender.buttonState = .FinishWithSuccess
            } else {
                sender.secondLabel.text = "Something went wrong"
                sender.buttonState = .FinishWithFailure
            }
            
            self.enableControls(true)
        }
    }
    
    private func enableControls(enabled: Bool) {
        successSwitch.enabled = enabled
        enabledSwitch.enabled = enabled
        restartButton.enabled = enabled
    }
    
    @IBAction func enabledSwitchChanged(sender: UISwitch) {
        myButton.enabled = sender.on
    }
    
    @IBAction func restartPressed(sender: AnyObject) {
        myButton.buttonState = .Begin
    }
}

