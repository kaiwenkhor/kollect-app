//
//  SelectArtistDelegate.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import Foundation

protocol SelectArtistDelegate: AnyObject {
    func selectArtist(_ artist: Artist) -> Bool
}
