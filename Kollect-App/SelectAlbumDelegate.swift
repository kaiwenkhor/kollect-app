//
//  SelectAlbumDelegate.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import Foundation

protocol SelectAlbumDelegate: AnyObject {
    func selectAlbum(_ album: Album) -> Bool
}
