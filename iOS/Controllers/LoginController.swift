//
//  LoginController.swift
//  Wip
//
//  Created by Daniel Douglas Dyrseth on 09/10/2017.
//  Copyright © 2017 Lightpear. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 30, g: 145, b: 255)
        button.setTitle("Log In", for: UIControlState())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 3
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(loginRegisterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc func loginRegisterButtonTapped() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            if usernameTextField.text?.isEmpty == false {
                handleLogin()
            }
        } else {
            validateRegister()
        }
    }
    
    func validateRegister() {
        if usernameTextField.text?.isEmpty == true {
            usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username required", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
        } else if usernameTextField.text?.isValidUsername() == false {
            usernameTextField.text = ""
            usernameTextField.attributedPlaceholder = NSAttributedString(string: "2-12 characters, only letters and numbers", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
        }
        
        if emailTextField.text?.isEmpty == true {
            emailTextField.attributedPlaceholder = NSAttributedString(string: "Email address required", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
        } else if emailTextField.text?.isValidEmail() == false {
            emailTextField.text = ""
            emailTextField.attributedPlaceholder = NSAttributedString(string: "Invalid email address", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
        }
        
        if passwordTextField.text?.isEmpty == true {
            passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password required", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
        } else if emailTextField.text?.isValidEmail() == true, usernameTextField.text?.isValidUsername() == true  {
            handleRegister()
        }
    }
    
    let keychain = KeychainSwift()
    
    func handleLogin() {
        guard let username = usernameTextField.text, let password = passwordTextField.text else {
            return
        }
        guard let url = URL(string: "http://localhost:3000/users/authenticate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authUser = Authenticate(username: username, password: password)
        do {
            let jsonBody = try JSONEncoder().encode(authUser)
            request.httpBody = jsonBody
        } catch {}
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, _, _) in
            guard let data = data else {
                if ReachabilityTest.isConnectedToNetwork() {
                    DispatchQueue.main.async {
                        self.reachabilityAlert(title: "Something went wrong.", message: "Please try again later.")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.reachabilityAlert(title: "No internet-connection.", message: "")
                    }
                }
                return
            }
            do {
                let jsonwt = try JSONDecoder().decode(JWT.self, from: data)
                if jsonwt.success == true {
                    self.keychain.set(jsonwt.token, forKey: "rnbwjwt")
                    self.keychain.set(authUser.username, forKey: "rnbwusername")
                    self.keychain.set(authUser.password, forKey: "rnbwpswd")
                    DispatchQueue.main.async {
                        UIApplication.shared.statusBarStyle = .lightContent
                    }
                    self.dismiss(animated: false, completion: nil)
                }
            } catch {}
            do {
                let dataRes = try JSONDecoder().decode(Response.self, from: data)
                if dataRes.msg == "User not found" {
                    DispatchQueue.main.async {
                        self.usernameTextField.attributedPlaceholder = NSAttributedString(string: "\"\(self.usernameTextField.text!)\" not found", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
                        self.passwordTextField.placeholder = "Password"
                        self.usernameTextField.text = ""
                    }
                } else if dataRes.msg == "Wrong password" {
                    DispatchQueue.main.async {
                        self.passwordTextField.text = ""
                        self.passwordTextField.attributedPlaceholder = NSAttributedString(string: "Wrong password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
                    }
                }
            } catch {}
        }
        task.resume()
    }
    
    func handleRegister() {
        guard let username = usernameTextField.text, let email = emailTextField.text?.lowercased(), let password = passwordTextField.text else { return }
        guard let url = URL(string: "http://localhost:3000/users/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let addUser = Register(username: username, email: email, password: password)
        do {
            let jsonBody = try JSONEncoder().encode(addUser)
            request.httpBody = jsonBody
        } catch{}
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, _, _) in
            guard let data = data else {
                if ReachabilityTest.isConnectedToNetwork() {
                    DispatchQueue.main.async {
                    self.reachabilityAlert(title: "Something went wrong.", message: "Please try again later.")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.reachabilityAlert(title: "No internet-connection.", message: "")
                    }
                }
                return
            }
            do {
                let dataRes = try JSONDecoder().decode(Response.self, from: data)
                if dataRes.success == true {
                    DispatchQueue.main.async {
                        self.handleLogin()
                    }
                } else {
                    if dataRes.msg == "Email taken" {
                        DispatchQueue.main.async {
                            self.emailTextField.text = ""
                            self.emailTextField.attributedPlaceholder = NSAttributedString(string: "Email address already in use", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
                        }
                    }
                    if dataRes.msg == "Username taken" {
                        DispatchQueue.main.async {
                            self.usernameTextField.attributedPlaceholder = NSAttributedString(string: "\"\(self.usernameTextField.text!)\" is taken", attributes: [NSAttributedStringKey.foregroundColor: UIColor.orange])
                            self.usernameTextField.text = ""
                        }
                    }
                }
            } catch {}
        }
        task.resume()
    }
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()
    
    let usernameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.adjustsFontSizeToFitWidth = true
        return tf
    }()
    
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isSecureTextEntry = true
        return tf
    }()
    
    let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 250, g: 250, b: 250)
        button.setTitle("Forgot username/password", for: UIControlState())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(r: 255, g: 135, b: 135), for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        return button
        
    }()
    
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "rainbow-logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Signup"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.subviews[0].tintColor = UIColor(r: 30, g: 145, b: 255)
        sc.subviews[1].tintColor = UIColor(r: 40, g: 190, b: 40)
        sc.layer.cornerRadius = 3
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    
    @objc func handleLoginRegisterChange() {
        usernameTextField.placeholder = "Username"
        emailTextField.placeholder = "Email"
        passwordTextField.placeholder = "Password"
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            loginRegisterButton.setTitle("Log In", for: UIControlState())
            loginRegisterButton.backgroundColor = UIColor(r: 30, g: 145, b: 255)
        } else {
            loginRegisterButton.setTitle("Sign Up", for: UIControlState())
            loginRegisterButton.backgroundColor = UIColor(r: 40, g: 190, b: 40)
        }
        
        // Change height of inputsContainerView
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 1 ? 150 : 100
        
        // Change height of emailTextField
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 1 ? 1/3 : 0)
        emailTextFieldHeightAnchor?.isActive = true
        
        // Change height of usernameTextField
        usernameTextFieldHeightAnchor?.isActive = false
        usernameTextFieldHeightAnchor = usernameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 1 ? 1/3 : 1/2)
        usernameTextFieldHeightAnchor?.isActive = true
        
        // Change height of passwordTextField
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 1 ? 1/3 : 1/2)
        passwordTextFieldHeightAnchor?.isActive = true
    }
    
    override func viewDidLoad() {
        UIApplication.shared.statusBarStyle = .default
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 250, g: 250, b: 250)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(forgotPasswordButton)
        view.addSubview(logoImageView)
        view.addSubview(loginRegisterSegmentedControl)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupForgotPasswordButton()
        setupLogoImageView()
        setupLoginRegisterSegmentedControl()
    }
    
    func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    func setupLogoImageView() {
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -18).isActive = true
        logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        logoImageView.widthAnchor.constraint(equalTo: loginRegisterSegmentedControl.widthAnchor, multiplier: 4/5).isActive = true
    }
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var usernameTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    func setupInputsContainerView() {
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 100)
        inputsContainerViewHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(usernameTextField)
        inputsContainerView.addSubview(usernameSeparatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeparatorView)
        inputsContainerView.addSubview(passwordTextField)
        
        usernameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        usernameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        usernameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        
        usernameTextFieldHeightAnchor = usernameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)
        usernameTextFieldHeightAnchor?.isActive = true
        
        usernameSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        usernameSeparatorView.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor).isActive = true
        usernameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        usernameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 0)
        emailTextFieldHeightAnchor?.isActive = true
        
        emailSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        passwordTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)
        passwordTextFieldHeightAnchor?.isActive = true
    }
    
    func setupLoginRegisterButton() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupForgotPasswordButton() {
        forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        forgotPasswordButton.topAnchor.constraint(equalTo: loginRegisterButton.bottomAnchor, constant: 40).isActive = true
        forgotPasswordButton.widthAnchor.constraint(equalTo: loginRegisterButton.widthAnchor, multiplier: 3/5).isActive = true
        forgotPasswordButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
}

extension String {
    func isValidEmail() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf8.count)) != nil
    }
}

extension String {
    func isValidUsername() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9a-zA-Z]{2,12}$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf8.count)) != nil
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
