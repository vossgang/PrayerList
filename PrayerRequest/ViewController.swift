//
//  ViewController.swift
//  PrayerRequest
//
//  Created by Matthew Voss on 9/10/22.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PrayerRequest")
//    let dailyPredicate = NSPredicate(format: "interval = %@", Tabs.Daily.rawValue)
//    let weeklyPredicate = NSPredicate(format: "interval = %@", Tabs.Weekly.rawValue)
//    let monthlyPredicate = NSPredicate(format: "interval = %@", Tabs.Monthly.rawValue)
//    let yearlyPredicate = NSPredicate(format: "interval = %@", Tabs.Yearly.rawValue)

    
    lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    
    var requests: [NSManagedObject] = []
    var prayerRequests: [PrayerRequest] {
        return requests as? [PrayerRequest] ?? [PrayerRequest]()
    }
    var barItems = [UITabBarItem]()
    var rev: RequestEntryView?

    var _currentTabValue: Int { return UserDefaults.standard.integer(forKey: "_currentTabValue") }
    var currentTab: Tabs {
        get {
            return Tabs(rawValue: Int32(_currentTabValue)) ?? .About
        }
        set {
            print("setting value to: \(currentTab)")
            UserDefaults.standard.set(newValue.rawValue, forKey: "_currentTabValue")
        }
    }
        
    lazy var selectionBar: UITabBar = { [unowned self] in
        let bar = UITabBar()
        bar.delegate = self
        bar.itemPositioning = .centered
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    lazy var tabView: TabView = { [unowned self] in
        let tab = TabView()
        tab.translatesAutoresizingMaskIntoConstraints = false
        tab.delegate = self
        return tab
    }()
    
    lazy var addRequest: UIButton = {
        let add = UIButton()
        add.backgroundColor = .white
        add.layer.borderWidth = 3
        add.layer.borderColor = UIColor.blue.cgColor
        add.setTitle("➕", for: .normal)
        add.translatesAutoresizingMaskIntoConstraints = false
        add.layer.cornerRadius = 8
        add.addTarget(self, action: #selector(didPressRequestButton(_:)), for: .primaryActionTriggered)
        return add
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(viewWasSwipped(_:)))
        swipeLeft.direction = [.left]
        view.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(viewWasSwipped(_:)))
        swipeRight.direction = [.right]
        view.addGestureRecognizer(swipeRight)
        
        setupContext()
        view.addSubview(selectionBar)

        
        
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
                                     searchBar.heightAnchor.constraint(equalToConstant: 40)])
        
        
        
        // set up selection bar
        var selectedItem: UITabBarItem?
        barItems = [UITabBarItem]()

        Tabs.allCases.forEach { tab in
            guard tab != .Search else { return }
            let tabItem = UITabBarItem(title: tab.text, image: nil, tag: Int(tab.rawValue))
            tabItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -7.5)

            if tab.rawValue == currentTab.rawValue {
                selectedItem = tabItem
            }
            
            barItems.append(tabItem)
        }
        
        view.addSubview(tabView)
        NSLayoutConstraint.activate([tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     tabView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                                     tabView.bottomAnchor.constraint(equalTo: selectionBar.topAnchor)])
        tabView.setupTable()

        selectionBar.setItems(barItems, animated: true)
        selectionBar.selectedItem = selectedItem
        
        NSLayoutConstraint.activate([selectionBar.widthAnchor.constraint(equalTo: view.widthAnchor),
                                     selectionBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.075),
                                     selectionBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        // set up request button
        view.addSubview(addRequest)
        NSLayoutConstraint.activate([addRequest.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
                                     addRequest.bottomAnchor.constraint(equalTo: selectionBar.topAnchor, constant: -5),
                                     addRequest.heightAnchor.constraint(equalToConstant: 40),
                                     addRequest.widthAnchor.constraint(equalToConstant: 40)])
                
        // select current tab
        showCurrentSelection()
    }
    
    func setupContext() {
          guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
          let managedContext = appDelegate.persistentContainer.viewContext
          
          do {
              requests = try managedContext.fetch(fetchRequest)
          } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
          }
    }
    
    @objc func viewWasSwipped(_ sender:UISwipeGestureRecognizer) {
        guard sender.state == .ended else { return }

        switch sender.direction {
        case .left: currentTab = currentTab.nextTab
        case .right: currentTab = currentTab.previousTab
        default: print("default")
        }

        showCurrentSelection()
    }
    
    func showCurrentSelection() {
        barItems.forEach { item in
            if item.tag == currentTab.rawValue {
                selectionBar.selectedItem = item
            }
        }
        
        tabView.updateTab(type: currentTab)
        tabView.reloadData()
        addRequest.alpha = currentTab == .About ? 0.0 : 1.0
    }
    
    @objc func didPressRequestButton(_ sender: UIButton) {
        let rev = RequestEntryView()
        rev.translatesAutoresizingMaskIntoConstraints = false
        rev.delegate = self
        let selectedTab = currentTab == .Today ? .Daily : currentTab
        rev.currentTab = selectedTab
        
        view.addSubview(rev)
        
        NSLayoutConstraint.activate([
            rev.topAnchor.constraint(equalTo: view.topAnchor),
            rev.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rev.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rev.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
            
        rev.setup()
    }
    
    
    func stress() {
        Tabs.allCases.forEach { tab in
            guard ![.About, .Today, .Search].contains(tab) else { return }
            for index in 1...(tab.rawValue*3) {
                save(title: "\(tab.text) \(index)", detail: "detial text \(tab.text)", interval: tab.rawValue, tag: nextTagFor(interval: tab.rawValue), last: nil, answered: false)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

extension ViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        currentTab = Tabs(rawValue: Int32(item.tag)) ?? currentTab
        showCurrentSelection()
    }
}

extension ViewController: RequestDelegate {
    func delete(request: PrayerRequest) {
        
        let alert = UIAlertController(title: "Confirm Delete", message: "Delete Prayer Request?", preferredStyle: .alert)
        let no = UIAlertAction(title: "no", style: .default)
        let yes = UIAlertAction(title: "yes", style: .destructive) { [weak self] action in
            self?.rev?.removeFromSuperview()

            self?.finishDelete(request: request)
        }
        
        alert.addAction(no)
        alert.addAction(yes)
        present(alert, animated: true)
    }
    
    func saveUpdated(request: PrayerRequest) {
        do {
            try save()
        } catch {
            showCurrentSelection()
            return
        }
        showCurrentSelection()
    }
    
    func showDetilViewFor(request: PrayerRequest) {
        dismissSearchKeyboard()
        let rev = RequestEntryView()
        rev.translatesAutoresizingMaskIntoConstraints = false
        rev.delegate = self
        
        
        
        let selectedTab = [.Today, .Search].contains(currentTab) ? .Daily : currentTab
        rev.currentTab = selectedTab
        
        view.addSubview(rev)
        
        NSLayoutConstraint.activate([
            rev.topAnchor.constraint(equalTo: view.topAnchor),
            rev.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rev.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rev.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
            
        rev.setup()
        rev.updateFor(request: request)
        self.rev = rev
    }
    func save(title: String?, detail: String?, interval: Int32, tag: Int32, last: Date?, answered: Bool?) {
        guard let title = title, title != "" else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
  
        let entity = NSEntityDescription.entity(forEntityName: "PrayerRequest", in: managedContext)!
        let prayerRequest = NSManagedObject(entity: entity, insertInto: managedContext) as? PrayerRequest
        
  
        prayerRequest?.titleText = title
        if let detail = detail {
            prayerRequest?.detailText = detail
        }
        if let last = last {
            prayerRequest?.last = last
        }
        if let answered = answered {
            prayerRequest?.answered = answered
        }
        
        prayerRequest?.interval = interval
        prayerRequest?.tag = tag

        do {
            try managedContext.save()
            requests = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        showCurrentSelection()
    }
    
    func fetch() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        do {
            requests = try managedContext.fetch(fetchRequest)
        } catch {
            print("nope")
        }
    }
    
    func itemsFor(interval: Int32) -> [PrayerRequest] {
        if currentTab == .Search {
            return prayerRequests
        }
        
        // today
        let today = Date()
        let dow = today.dayNumberOfWeek
        let dom = today.dayNumberOfMonth
        let doy = today.dayNumberOfYear
        
        // today view
        if interval == 0 {
            var todaysRequests = [PrayerRequest]()
            todaysRequests.append(contentsOf: prayerRequests.filter { request in
                return request.interval == Tabs.Daily.rawValue
            })
            
            // weekly
            var weeklyRequests = prayerRequests.filter { request in
                return  request.interval == Tabs.Weekly.rawValue
            }
            if weeklyRequests.count > 0 {
                let weeklyTarget: Int32 = weeklyRequests.count < Int(Tabs.Weekly.rawValue) ? (doy % Int32(weeklyRequests.count) + 1) : dow
                weeklyRequests = weeklyRequests.filter({ request in
                    return request.tag == weeklyTarget
                })
                todaysRequests.append(contentsOf: weeklyRequests)
            }
            
            // monthly
            var monthlyRequests = prayerRequests.filter { request in
                return request.interval == Tabs.Monthly.rawValue
            }
            if monthlyRequests.count > 0 {
                let monthlyTarget: Int32 = monthlyRequests.count < Int(Tabs.Monthly.rawValue) ? (doy % Int32(monthlyRequests.count) + 1) : dom
                monthlyRequests = monthlyRequests.filter({ request in
                    return request.tag == monthlyTarget
                })
                todaysRequests.append(contentsOf: monthlyRequests)
            }

            // yearly
            var yearlyRequests = prayerRequests.filter { request in
                return request.interval == Tabs.Yearly.rawValue
            }
            if yearlyRequests.count > 0 {
                let yearlyTarget: Int32 = yearlyRequests.count < Int(Tabs.Yearly.rawValue) ? (doy % Int32(yearlyRequests.count) + 1) : doy
                yearlyRequests = yearlyRequests.filter({ request in
                    return request.tag == yearlyTarget
                })
                todaysRequests.append(contentsOf: yearlyRequests)
            }
            
            todaysRequests = todaysRequests.filter({ request in
                return request.answered != true
            })
            
            return todaysRequests
        }
        
        // static views
        var final = prayerRequests.filter { request in
            return request.interval == interval
        }
        
        final = final.sorted(by: { !$0.answered && $1.answered } )
        
        
        return final
    }
    
    func nextTagFor(interval: Int32) -> Int32 {
        return (Int32(itemsFor(interval: interval).count) % interval) + 1
    }
    
    func markAsPrayedFor(request: PrayerRequest?, withDate: Date?) -> PrayerRequest? {
        guard let request = request else { return nil }
        request.last = withDate
                
        try? save()
        return request
    }
    
    private func finishDelete(request: PrayerRequest) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(request)
        try? save()
        showCurrentSelection()
    }
    
    func save() throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        if managedContext.hasChanges {
            do { try managedContext.save() }
            catch { throw ContextError.CouldNotSave }
        } else {
            throw ContextError.NothingToSave
        }
    }
}

enum ContextError: Error {
    case NothingToSave
    case CouldNotSave
}

extension Date {
    var dayNumberOfWeek: Int32 {
        return Int32(Calendar.current.ordinality(of: .day, in: .weekOfYear, for: self) ?? 1)
    }
    
    var dayNumberOfMonth: Int32 {
        return Int32(Calendar.current.ordinality(of: .day, in: .month, for: self) ?? 1)
    }
    
    var dayNumberOfYear: Int32 {
        return Int32(Calendar.current.ordinality(of: .day, in: .year, for: self) ?? 1)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        currentTab = .Search
        showCurrentSelection()
        return true
    }
    
    
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        currentTab = .Today
        dismissSearchKeyboard()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            currentTab = .Today
            dismissSearchKeyboard()
        }
        searchFor(text: searchText)
    }
    
    
    
    func searchFor(text: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext

        if text != "" {
            let textPredicate = NSPredicate(format: "titleText CONTAINS %@ OR detailText CONTAINS %@", text, text)
            fetchRequest.predicate = textPredicate
        } else {
            fetchRequest.predicate = nil
        }
        
    
        do {
            requests = try managedContext.fetch(fetchRequest)
            
        } catch {
            print("keep trying")
        }
        showCurrentSelection()
        print(requests.count)
    }
    
    func dismissSearchKeyboard() {
        searchBar.resignFirstResponder()
        showCurrentSelection()
    }
}
