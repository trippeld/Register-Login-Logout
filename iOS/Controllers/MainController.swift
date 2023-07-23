//
//  MainController.swift
//  Wip
//
//  Created by Daniel Douglas Dyrseth on 09/10/2017.
//  Copyright © 2017 Lightpear. All rights reserved.
//

import UIKit

let keychain = KeychainSwift()
let cellId = "cellId"

class MainController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    func checkIfLoggedIn() {
        guard let jwt = keychain.get("rnbwjwt") else {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
            return
        }
        guard let url = URL(string: "http://localhost:3000/users/profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(jwt, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, _, _) in
            guard let data = data else { return }
            if String(data: data, encoding: .utf8) == "Unauthorized" {
                    self.reLogIn()
            }
        }
        task.resume()
    }
    
    func reLogIn() {
        guard let username = keychain.get("rnbwusername"), let password = keychain.get("rnbwpswd") else {
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
        let task = session.dataTask(with: request) { (data, error, _) in
            guard let data = data else { return }
            do {
                let jsonwt = try JSONDecoder().decode(JWT.self, from: data)
                if jsonwt.success == true {
                    keychain.set(jsonwt.token, forKey: "rnbwjwt")
                } else {
                    DispatchQueue.main.async {
                        self.handleLogout()
                    }
                }
            } catch {}
        }
        task.resume()
    }
    
    @objc func handleLogout() {
        keychain.clear()
        let loginController = LoginController()
        present(loginController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        checkIfLoggedIn()
        super.viewDidLoad()
        setupNavigationBarItems()
        
        collectionView?.backgroundColor = .white

        collectionView?.register(PostCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 36, bottom: 0, right: -28)

        //navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target:self, action: #selector(handleLogout))
    }
    
    private func setupNavigationBarItems() {
        navigationItem.title = "popp"
        
        let postButton = UIButton(type: .system)
        postButton.setImage(#imageLiteral(resourceName: "post-it-blue").withRenderingMode(.alwaysOriginal), for: .normal)
        postButton.layer.cornerRadius = 7
        postButton.layer.masksToBounds = true
        
        let profileButton = UIButton(type: .system)
        profileButton.setImage(#imageLiteral(resourceName: "defaultprofilepic").withRenderingMode(.alwaysOriginal), for: .normal)
        profileButton.layer.cornerRadius = 7
        profileButton.layer.masksToBounds = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: postButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: profileButton)
        
        navigationController?.navigationBar.addSubview(postButton)
        navigationController?.navigationBar.addSubview(profileButton)
        
        postButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        postButton.heightAnchor.constraint(equalTo: postButton.widthAnchor).isActive = true
        
        profileButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileButton.heightAnchor.constraint(equalTo: profileButton.widthAnchor).isActive = true
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let postCell = PostCell()
        
        let approximateWidthOfContent = view.frame.width-36
        let size = CGSize(width: approximateWidthOfContent, height: 500)
        let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)]
        
        let estimatedFrame = NSString(string: postCell.postTitle.text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        return CGSize(width: view.frame.width-8, height: view.frame.width+32+estimatedFrame.height)
    }
    
}

class PostCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 18
        
        setupViews()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSMutableAttributedString(string: keychain.get("rnbwusername")!, attributes: stroke(font: UIFont.boldSystemFont(ofSize: 18), strokeWidth: 1, insideColor: .white, strokeColor: .black))
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let profilePicView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 7
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "defaultprofilepic")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let postTitle: UITextView = {
        let textView = UITextView()
        textView.text = "This is what's up!"
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.backgroundColor = nil
        textView.isEditable = false
        textView.sizeToFit()
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "post-it-blue")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let rankLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSMutableAttributedString(string: "#1", attributes: stroke(font: UIFont.boldSystemFont(ofSize: 28), strokeWidth: 1, insideColor: UIColor(r: 255, g: 215, b: 0), strokeColor: .black))
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "989"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let upvoteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "thumbsupdis"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let downvoteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "thumbsdowndis"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let repostButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "repost"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func setupViews() {
        backgroundColor = UIColor(r: 30, g: 145, b: 255)
        
        addSubview(rankLabel)
        addSubview(upvoteButton)
        addSubview(scoreLabel)
        addSubview(downvoteButton)
        addSubview(profilePicView)
        addSubview(usernameLabel)
        addSubview(postTitle)
        addSubview(postImageView)
        addSubview(repostButton)
        
        rankLabel.centerYAnchor.constraint(equalTo: postTitle.centerYAnchor).isActive = true
        rankLabel.centerXAnchor.constraint(equalTo: scoreLabel.centerXAnchor).isActive = true
        
        upvoteButton.bottomAnchor.constraint(equalTo: scoreLabel.topAnchor, constant: -6).isActive = true
        upvoteButton.centerXAnchor.constraint(equalTo: scoreLabel.centerXAnchor).isActive = true
        upvoteButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        upvoteButton.heightAnchor.constraint(equalTo: upvoteButton.widthAnchor).isActive = true
        
        scoreLabel.centerYAnchor.constraint(equalTo: postImageView.centerYAnchor).isActive = true
        scoreLabel.centerXAnchor.constraint(equalTo: self.leftAnchor, constant: -18).isActive = true
        
        downvoteButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 6).isActive = true
        downvoteButton.centerXAnchor.constraint(equalTo: scoreLabel.centerXAnchor).isActive = true
        downvoteButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        downvoteButton.heightAnchor.constraint(equalTo: downvoteButton.widthAnchor).isActive = true
        
        repostButton.centerXAnchor.constraint(equalTo: scoreLabel.centerXAnchor).isActive = true
        repostButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        repostButton.heightAnchor.constraint(equalTo: repostButton.widthAnchor).isActive = true
        repostButton.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
        
        profilePicView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        profilePicView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        profilePicView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profilePicView.widthAnchor.constraint(equalTo: profilePicView.heightAnchor).isActive = true
        
        usernameLabel.centerYAnchor.constraint(equalTo: profilePicView.centerYAnchor).isActive = true
        usernameLabel.leftAnchor.constraint(equalTo: profilePicView.rightAnchor, constant: 10).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -28).isActive = true
        
        postTitle.topAnchor.constraint(equalTo: profilePicView.bottomAnchor).isActive = true
        postTitle.leftAnchor.constraint(equalTo: profilePicView.leftAnchor, constant: -5).isActive = true
        postTitle.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -28).isActive = true
        
        postImageView.topAnchor.constraint(equalTo: postTitle.bottomAnchor).isActive = true
        postImageView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -28).isActive = true
        postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor).isActive = true
    }
    
}

public func stroke(font: UIFont, strokeWidth: Float, insideColor: UIColor, strokeColor: UIColor) -> [NSAttributedStringKey: Any]{
    return [
        NSAttributedStringKey.strokeColor : strokeColor,
        NSAttributedStringKey.foregroundColor : insideColor,
        NSAttributedStringKey.strokeWidth : -strokeWidth,
        NSAttributedStringKey.font : font
    ]
}

extension UIViewController {
    func reachabilityAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Ok", style: .default) { (action) in
            alert.dismiss(animated: false, completion: nil)
        }
        alert.addAction(action1)
        present(alert, animated: false) {
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(alert.dismiss)))
        }
        let fiveSecs = DispatchTime.now() + 5
        DispatchQueue.main.asyncAfter(deadline: fiveSecs) {
            alert.dismiss(animated: false, completion: nil) }
    }
}
