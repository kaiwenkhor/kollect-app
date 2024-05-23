//
//  SelectMemberDelegate.swift
//  Kollect-App
//
//  Created by Daryl Khor on 03/05/2024.
//

import Foundation

protocol SelectMemberDelegate: AnyObject {
    func selectMember(_ member: Idol) -> Bool
}
