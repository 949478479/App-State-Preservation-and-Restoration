//
//  Contacts+CoreDataProperties.swift
//  State Restoration Demo
//
//  Created by 从今以后 on 16/2/10.
//  Copyright © 2016年 从今以后. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Contacts {

    @NSManaged var name: String
    @NSManaged var tel: String

}
