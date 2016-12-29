//
//  ContactsViewController.swift
//  State Restoration Demo
//
//  Created by 从今以后 on 16/2/10.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit
import CoreData

class ContactsViewController: UITableViewController {

	var managedObjectContext: NSManagedObjectContext!

	private lazy var fetchedResultsController: NSFetchedResultsController = {

		let fetchRequest = NSFetchRequest(entityName: String(Contacts))
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

		let fetchedResultsController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: self.managedObjectContext,
			sectionNameKeyPath: nil,
			cacheName: String(Contacts))
		fetchedResultsController.delegate = self

		do {
			try fetchedResultsController.performFetch()
		} catch  {
			print(error)
		}

		return fetchedResultsController
	}()
}

private typealias Navigation = ContactsViewController
extension Navigation {

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		switch segue.identifier {
		case "ShowDetail"?:

			let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)!
			let contacts = fetchedResultsController.objectAtIndexPath(indexPath) as! Contacts
			let detailVC = segue.destinationViewController as! DetailViewController
			detailVC.managedObjectContext = managedObjectContext
			detailVC.contacts = contacts

		case "AddContacts"?:

			let destinationVC = segue.destinationViewController as! UINavigationController
			let detailVC = destinationVC.childViewControllers[0] as! DetailViewController
			detailVC.managedObjectContext = managedObjectContext

		default: break
		}
	}

	@IBAction func unwindForSegue(unwindSegue: UIStoryboardSegue) {}
}

private typealias DataSource = ContactsViewController
extension DataSource {

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.fetchedObjects?.count ?? 0
	}

	override func tableView(tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

			let cell = tableView.dequeueReusableCellWithIdentifier(String(Contacts),
				forIndexPath: indexPath)
			configureCell(cell, indexPath: indexPath)
			return cell
	}

	override func tableView(tableView: UITableView,
		commitEditingStyle editingStyle: UITableViewCellEditingStyle,
		forRowAtIndexPath indexPath: NSIndexPath) {

			if editingStyle == .Delete {
				let contacts = fetchedResultsController.objectAtIndexPath(indexPath) as! Contacts
				managedObjectContext.deleteObject(contacts)
				do {
					try managedObjectContext.save()
				} catch {
					print(error)
				}
			}
	}

	private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
		let contacts = fetchedResultsController.objectAtIndexPath(indexPath) as! Contacts
		cell.textLabel?.text = contacts.name
		cell.detailTextLabel?.text = contacts.tel
	}
}

// 为数据源实现该协议能让状态恢复系统更好地适应数据的变化
private typealias DataSourceModelAssociation = ContactsViewController
extension DataSourceModelAssociation: UIDataSourceModelAssociation {

	func modelIdentifierForElementAtIndexPath(idx: NSIndexPath, inView view: UIView) -> String? {
		// 将每行数据由索引映射到 URI
		let contacts = fetchedResultsController.objectAtIndexPath(idx) as! Contacts
		return contacts.objectID.URIRepresentation().absoluteString
	}

	func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		// 根据 URI 字符串获取对应行的数据
		if let
			url = NSURL(string: identifier),
			objectID = managedObjectContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url),
			object = try? managedObjectContext.existingObjectWithID(objectID) {
			let idx = fetchedResultsController.indexPathForObject(object)
			return idx
		}
		// 如果在状态保存且应用退出后将选中行从数据库中删除就会执行这句
		return nil
	}
}

private typealias FetchedResultsControllerDelegate = ContactsViewController
extension FetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate {

	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		tableView.beginUpdates()
	}

	func controller(controller: NSFetchedResultsController,
		didChangeObject anObject: AnyObject,
		atIndexPath indexPath: NSIndexPath?,
		forChangeType type: NSFetchedResultsChangeType,
		newIndexPath: NSIndexPath?) {

		switch type {
		case .Insert:
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
		case .Update:
			if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
				configureCell(cell, indexPath: indexPath!)
			}
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
		}
	}

	func controller(controller: NSFetchedResultsController,
		didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
		atIndex sectionIndex: Int,
		forChangeType type: NSFetchedResultsChangeType) {

		if type == .Insert {
			tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
		} else if type == .Delete {
			tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
		}
	}

	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		tableView.endUpdates()
	}
}
