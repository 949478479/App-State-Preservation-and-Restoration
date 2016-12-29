//
//  AppDelegate.swift
//  State Restoration Demo
//
//  Created by 从今以后 on 16/2/9.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	private(set) lazy var managedObjectContext: NSManagedObjectContext = {
		let coordinator = self.persistentStoreCoordinator
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()

	func application(application: UIApplication,
		willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

			let userDefaults = NSUserDefaults.standardUserDefaults()
			if userDefaults.boolForKey("initialized") == false {
				for idx in 0..<100 {
					let contacts = NSEntityDescription.insertNewObjectForEntityForName(String(Contacts),
						inManagedObjectContext: managedObjectContext) as! Contacts
					contacts.name = "contacts_\(idx)"
					contacts.tel = String(1_000_000 + arc4random_uniform(8_999_999))
				}
				saveContext()
				userDefaults.setBool(true, forKey: "initialized")
			}

			let navController = window?.rootViewController?.childViewControllers[0] as! UINavigationController
			let contactsVC = navController.childViewControllers[0] as! ContactsViewController
			contactsVC.managedObjectContext = managedObjectContext

			// 如果去掉这句将导致表视图的选中行恢复后又消失，以及弹出的模态视图会在父视图出现后才延迟弹出等问题
			window?.makeKeyAndVisible()

			return true
	}

	func applicationDidEnterBackground(application: UIApplication) {
		saveContext()
	}

	func applicationWillTerminate(application: UIApplication) {
		saveContext()
	}
}

private typealias Restoration = AppDelegate
extension Restoration {

	func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		// 在启动时不要显示上次退出时的截图
		application.ignoreSnapshotOnNextApplicationLaunch()
		return true
	}

	func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		// 比较状态保存时和恢复时的应用版本，当版本相同时才恢复状态
		let savedBundleVersion = coder
			.decodeObjectForKey(UIApplicationStateRestorationBundleVersionKey) as! String
		let currentBundleVersion = NSBundle.mainBundle()
			.objectForInfoDictionaryKey("CFBundleVersion") as! String
		return savedBundleVersion == currentBundleVersion
	}

	func application(application: UIApplication,
		viewControllerWithRestorationIdentifierPath identifierComponents: [AnyObject],
		coder: NSCoder) -> UIViewController? {

			// 恢复标识符数组的最后一个元素即是当前需要恢复的视图控制器的恢复标识符
			// 一般情况下，使用类名作为恢复标识符比较方便管理
			guard let identifier = identifierComponents.last as? String
				where identifier == String(DetailViewController) else { return nil }

			// 该视图控制器最初是由故事版加载的，因此可以根据自动保存的故事版信息获取相应故事版来创建它
			let storyboard = coder.decodeObjectForKey(UIStateRestorationViewControllerStoryboardKey)
				as! UIStoryboard
			// 该视图控制器的恢复标识符沿用了故事版标识符，两个标识符是一样的
			let detailVC = storyboard.instantiateViewControllerWithIdentifier(identifier)
				as! DetailViewController
			// 状态恢复时不会触发 prepareForSegue(_:sender:) 方法，因此需要为该视图控制器传递必要的数据
			detailVC.managedObjectContext = managedObjectContext

			return detailVC
	}
}

private typealias CoreDataStack = AppDelegate
private extension CoreDataStack {

	var applicationDocumentsDirectory: NSURL {
		let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
		return NSURL(fileURLWithPath: path)
	}

	var managedObjectModel: NSManagedObjectModel {
		let modelURL = NSBundle.mainBundle().URLForResource("State_Restoration_Demo",
			withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
	}

	var persistentStoreCoordinator: NSPersistentStoreCoordinator {

		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let url = applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")

		do {
			try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
				configuration: nil, URL: url, options: nil)
		} catch {
			print(error)
			abort()
		}

		return coordinator
	}

	func saveContext() {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				print(error)
				abort()
			}
		}
	}
}
