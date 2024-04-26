//
//  LogInViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 23/04/2024.
//

import UIKit
import FirebaseAuth

class LogInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var authController = Auth.auth()
    var authHandle: AuthStateDidChangeListenerHandle?
    weak var databaseController: DatabaseProtocol?
    
    @IBAction func logIn(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        
        if email.isEmpty || password.isEmpty {
            var errorMsg = "Please ensure all fields are filled:"
            if email.isEmpty {
                errorMsg += "\n- Must provide an email"
            }
            if password.isEmpty {
                errorMsg += "\n- Must provide a password"
            }
            displayMessage(title: "Incomplete Form", message: errorMsg)
            return
        }
        
        Task {
            await databaseController?.logInAccount(email: email, password: password)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func signUp(_ sender: Any) {
        performSegue(withIdentifier: "signUpFromMenuSegue", sender: self)
        emailTextField.text?.removeAll()
        passwordTextField.text?.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authHandle = authController.addStateDidChangeListener { (auth, user) in
            // Identify user
            user?.isAnonymous == true ? print("Anonymous user \(String(describing: user?.uid))") : print("User \(String(describing: user?.uid))")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        authController.removeStateDidChangeListener(authHandle!)
    }

}
