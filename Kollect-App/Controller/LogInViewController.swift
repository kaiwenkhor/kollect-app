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
    var indicator = UIActivityIndicatorView()
    
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
            indicator.startAnimating()
            if let result = await databaseController?.logInAccount(email: email, password: password) {
                indicator.stopAnimating()
                if result == false {
                    displayMessage(title: "Log In Error", message: "Authentication failed")
                } else {
                    navigationController?.popViewController(animated: true)
//                    tabBarController?.selectedIndex = 0
                }
            }
        }
    }
    
    @IBAction func signUp(_ sender: Any) {
//        performSegue(withIdentifier: "signUpFromMenuSegue", sender: self)
        emailTextField.text?.removeAll()
        passwordTextField.text?.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set back button title for Sign Up screen
        navigationItem.backButtonTitle = "Account"
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
    }

}
