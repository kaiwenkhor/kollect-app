//
//  AboutViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 08/06/2024.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var acknowledgementTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "About"
        
        setupTextView()
        acknowledgementTextView.isEditable = false
        acknowledgementTextView.isSelectable = true
        acknowledgementTextView.isScrollEnabled = true
    }
    
    
    func setupTextView() {
        let acknowledgmentText = """
        Acknowledgements:\n\n\nThis application makes use of the following third party libraries:\n\n\nThis app uses Firebase services, including Firebase Authentication, Cloud Firestore, and Firebase Cloud Messaging, provided by Google. Learn more at [https://firebase.google.com].\n\n\nKpop Comebacks API: [https://github.com/heismauri/kpop-comebacks-api]
        """

        let attributedString = NSMutableAttributedString(string: acknowledgmentText)

        // Create a range for the link text
        let linkRange = (acknowledgmentText as NSString).range(of: "https://firebase.google.com")
        let linkRange2 = (acknowledgmentText as NSString).range(of: "https://github.com/heismauri/kpop-comebacks-api")

        // Set the link attributes
        attributedString.addAttribute(.link, value: "https://firebase.google.com", range: linkRange)
        attributedString.addAttribute(.link, value: "https://github.com/heismauri/kpop-comebacks-api", range: linkRange2)

        // Set the attributed string to the UITextView
        acknowledgementTextView.attributedText = attributedString
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
