import UIKit

var game:Game! = nil
var vc:ViewController! = nil

class ViewController: UIViewController {
    
    @IBOutlet var gameView: GameView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        game = Game()
        
        let segmentedTapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGestureSegment(_:)))
        segmentedControl.addGestureRecognizer(segmentedTapGesture)
    }
    
    @IBAction func onTapGestureSegment(_ tapGesture: UITapGestureRecognizer) {
        let point = tapGesture.location(in: segmentedControl)
        let segmentSize = segmentedControl.bounds.size.width / CGFloat(segmentedControl.numberOfSegments)
        let touchedSegment = Int(point.x / segmentSize)

        segmentedControl.selectedSegmentIndex = touchedSegment
        game.levelChange(segmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func showAnswer(_ sender: UIButton)      { game.showAnswer() }

    override var prefersStatusBarHidden : Bool { return true;  }
}


