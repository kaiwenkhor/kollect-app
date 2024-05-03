//
//  AddPhotocardViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 28/04/2024.
//

import UIKit

class FindPhotocardViewController: UIViewController, SelectArtistDelegate, SelectAlbumDelegate, SelectMemberDelegate {

    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var albumTextField: UITextField!
    @IBOutlet weak var memberTextField: UITextField!
    @IBOutlet weak var findPhotocardButton: UIButton!
    
    var selectedArtist = Artist()
    var selectedAlbum = Album()
    var selectedMember = Idol()
    var listenerType: ListenerType = .user
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Let text field select Objects (Artist, Album, Idol)
        albumTextField.isEnabled = false
        memberTextField.isEnabled = false
        findPhotocardButton.isEnabled = false
    }
        
    @IBAction func selectArtist(_ sender: Any) {
        performSegue(withIdentifier: "allArtistsSegue", sender: self)
    }
    
    @IBAction func selectAlbum(_ sender: Any) {
        // If artist not selected, ask user to select artist first
        guard let artist = artistTextField.text else {
            return
        }
        
        if artist.isEmpty {
            var errorMsg = "Please select an artist before selecting an album"
            displayMessage(title: "Incomplete form", message: errorMsg)
            return
        }
        
        performSegue(withIdentifier: "allAlbumsSegue", sender: self)
    }
    
    @IBAction func selectMember(_ sender: Any) {
        guard let artist = artistTextField.text, let album = albumTextField.text else {
            return
        }
        
        if artist.isEmpty || album.isEmpty {
            var errorMsg = "Please ensure all fields are filled:\n"
            if artist.isEmpty {
                errorMsg += "- Must select an artist\n"
            }
            if album.isEmpty {
                errorMsg += "- Must select an album\n"
            }
            displayMessage(title: "Incomplete form", message: errorMsg)
            return
        }
        
        performSegue(withIdentifier: "allMembersSegue", sender: self)
    }
    
    @IBAction func findPhotocard(_ sender: Any) {
        // Can search when:
        // - all three fields are selected,
        // - or only artist,
        // - or only artist and album.
        guard let artist = artistTextField.text, let album = albumTextField.text, let member = memberTextField.text else {
            return
        }
        
        if artist.isEmpty {
            var errorMsg = "Please select an artist"
            displayMessage(title: "Incomplete form", message: errorMsg)
        }
        
        // Find photocard(s)
        // Perform search
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "allArtistsSegue" {
            let destination = segue.destination as! AllArtistsTableViewController
            destination.artistDelegate = self
        } else if segue.identifier == "allAlbumsSegue" {
            let destination = segue.destination as! AllAlbumsTableViewController
            destination.albumDelegate = self
            destination.allAlbums = selectedArtist.albums
        } else if segue.identifier == "allMembersSegue" {
            let destination = segue.destination as! AllMembersTableViewController
            destination.memberDelegate = self
            destination.allMembers = selectedArtist.members
        }
    }
    
    // MARK: - SelectArtistDelegate
    
    func selectArtist(_ artist: Artist) -> Bool {
        selectedArtist = artist
        artistTextField.text = artist.name
        
        albumTextField.text = ""
        memberTextField.text = ""
        
        albumTextField.isEnabled = true
        memberTextField.isEnabled = false
        findPhotocardButton.isEnabled = true
        
        return true
    }
    
    // MARK: - SelectAlbumDelegate
    
    func selectAlbum(_ album: Album) -> Bool {
        selectedAlbum = album
        albumTextField.text = album.name
        
        memberTextField.text = ""
        
        memberTextField.isEnabled = true
        
        return true
    }
    
    // MARK: - SelectMemberDelegate
    
    func selectMember(_ member: Idol) -> Bool {
        selectedMember = member
        memberTextField.text = member.name
        
        return true
    }

}
