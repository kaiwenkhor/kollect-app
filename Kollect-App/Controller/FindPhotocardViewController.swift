//
//  AddPhotocardViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 28/04/2024.
//

import UIKit

class FindPhotocardViewController: UIViewController {

    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var albumTextField: UITextField!
    @IBOutlet weak var memberTextField: UITextField!
    
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Let text field select Objects (Artist, Album, Idol)
    }
    
    @IBAction func findPhotocard(_ sender: Any) {
        guard let artist = artistTextField.text, let album = albumTextField.text, let member = memberTextField.text else {
            return
        }
        
        if artist.isEmpty || album.isEmpty {
            var errorMsg = "Please ensure all fields are filled:"
            if artist.isEmpty {
                errorMsg += "\n- Must provide an email"
            }
            if album.isEmpty {
                errorMsg += "\n- Must provide a password"
            }
            displayMessage(title: "Incomplete Form", message: errorMsg)
            return
        }
        
        // Find photocard(s)
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
