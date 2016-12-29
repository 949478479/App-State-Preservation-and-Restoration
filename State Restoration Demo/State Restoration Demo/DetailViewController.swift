//
//  DetailViewController.swift
//  State Restoration Demo
//
//  Created by 从今以后 on 16/2/10.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UITableViewController {

	var contacts: Contacts?
	var managedObjectContext: NSManagedObjectContext!

	@IBOutlet private weak var nameField: UITextField!
	@IBOutlet private weak var telField: UITextField!
	@IBOutlet private weak var doneButton: UIBarButtonItem!

	override func viewDidLoad() {
		super.viewDidLoad()

		// 传入了联系人则根据其信息填充文本框
		if let contacts = contacts {
			nameField.text = contacts.name
			telField.text = contacts.tel
			// 此时该控制器是以 push 的形式呈现的，移除导航栏左侧的 cancel 按钮
			navigationItem.leftBarButtonItems?.removeLast()
		}
		// 未传入联系人说明是要新建联系人，此时文本框为空，先禁用 done 按钮
		else {
			doneButton.enabled = false
		}
    }
}

private typealias Action = DetailViewController
private extension Action {

	@IBAction func done(sender: UIBarButtonItem) {

		guard let name = nameField.text, tel = telField.text else {
			return
		}

		// 传入了联系人则修改其信息
		if let contacts = contacts {
			contacts.name = name
			contacts.tel = tel
			navigationController?.popViewControllerAnimated(true)
		}
		// 为传入联系人说明是要新建联系人
		else {
			let contacts = NSEntityDescription.insertNewObjectForEntityForName(String(Contacts),
				inManagedObjectContext: managedObjectContext) as! Contacts
			contacts.name = name
			contacts.tel = tel
			do {
				try managedObjectContext.save()
			} catch {
				print(error)
			}
			dismissViewControllerAnimated(true, completion: nil)
		}
	}

	@IBAction func editingChanged(sender: AnyObject) {
		doneButton.enabled = (nameField.hasText() && telField.hasText())
	}
}

private typealias Restoration = DetailViewController
extension Restoration {

	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)

		// 为了让 UITextField 能够支持状态恢复，父视图 tableView 也需要设置恢复标识符
		// UITextField 只会保存文本选中范围，文本内容需手动保存
		if let name = nameField.text, tel = telField.text {
			coder.encodeObject(name, forKey: "name")
			coder.encodeObject(tel, forKey: "tel")
		}

		// 保存当前联系人的 URL，而不是联系人对象本身
		if let contacts = contacts {
			let url = contacts.objectID.URIRepresentation()
			coder.encodeObject(url, forKey: "objectIDURL")
		}
	}

	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)

		// 根据先前保存的 URI 来重新获取对应的数据对象
		if let
			url = coder.decodeObjectForKey("objectIDURL") as? NSURL,
			objectID = managedObjectContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url),
			contacts = try? managedObjectContext.existingObjectWithID(objectID) as? Contacts {
			self.contacts = contacts
		}

		// 恢复先前保存的文本框内容
		if let
			name = coder.decodeObjectForKey("name") as? String,
			tel = coder.decodeObjectForKey("tel") as? String {
			nameField.text = name
			telField.text = tel
		}
	}

	// 此方法会在恢复过程完成后调用
	override func applicationFinishedRestoringState() {
		super.applicationFinishedRestoringState()
		doneButton.enabled = (nameField.hasText() && telField.hasText())
	}
}
