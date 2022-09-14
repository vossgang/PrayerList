//
//  TabView.swift
//  PrayerRequest
//
//  Created by Matthew Voss on 9/10/22.
//

import Foundation
import UIKit
import CoreData


enum Tabs: Int32, CaseIterable {
    case Search = -1
    case Today = 0
    case Daily = 1
    case Weekly = 7
    case Monthly = 30
    case Yearly = 365
    case About = 1000
    
    var text: String {
        switch self {
        case .Search: return "Search"
        case .Today: return "Today"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        case .Monthly: return "Monthly"
        case .Yearly: return "Yearly"
        case .About: return "About"
        }
    }
    
    var previousTab: Tabs {
        switch self {
        case .Search: return .Search
        case .Today: return .About
        case .Daily: return .Today
        case .Weekly: return .Daily
        case .Monthly: return .Weekly
        case .Yearly: return .Monthly
        case .About: return .Yearly
        }
    }
    
    var nextTab: Tabs {
        switch self {
        case .Search: return .Search
        case .Today: return .Daily
        case .Daily: return .Weekly
        case .Weekly: return .Monthly
        case .Monthly: return .Yearly
        case .Yearly: return .About
        case .About: return .Today
        }
    }
    
}

protocol RequestDelegate: AnyObject {
    func save(title: String?, detail: String?, interval: Int32, tag: Int32, last: Date?, answered: Bool?)
    func itemsFor(interval: Int32) -> [PrayerRequest]
    func nextTagFor(interval: Int32) -> Int32
    func markAsPrayedFor(request: PrayerRequest?, withDate: Date?) -> PrayerRequest?
    func showDetilViewFor(request: PrayerRequest)
    func saveUpdated(request: PrayerRequest)
    func delete(request: PrayerRequest)
}


class TabView: UIView {
    weak var delegate: RequestDelegate? {
        didSet {
            reloadData()
        }
    }
    
    var requests: [PrayerRequest] {
        return delegate?.itemsFor(interval: Int32(tab.rawValue)) ?? []
    }

    lazy var tableView: UITableView = { [unowned self] in
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(RequestCell.self, forCellReuseIdentifier: RequestCell.identifier)
        table.dataSource = self
        table.sectionHeaderTopPadding = 0
        table.delegate = self
        return table
    }()
    
    private(set) var tab: Tabs = .About
    
    func updateTab(type: Tabs) {
        tab = type
        tableView.isHidden = tab == .About
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func setupTable() {
        addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
                                     tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: trailingAnchor)])
    }
    
    func scrollTo(request: PrayerRequest) {
        for (index, erequest) in requests.enumerated() {
            if erequest == request {
                tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            }
        }
    }
}

extension TabView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("request \(requests.count)")
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: RequestCell.identifier, for: indexPath) as? RequestCell {
            let request = requests[indexPath.row]
            cell.set(delegate: delegate, forRequest: request)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let request = requests[indexPath.row]
        delegate?.showDetilViewFor(request: request)
    }
}

class RequestCell: UITableViewCell {
    static let identifier = "RequestCell"
    
    private weak var delegate: RequestDelegate?
    private var request: PrayerRequest?
    
    func set(delegate: RequestDelegate?, forRequest: PrayerRequest) {
        self.delegate = delegate
        request = forRequest
        textLabel?.text = forRequest.titleText
        
        textLabel?.textColor = .black
        composeLayout()
        
        backgroundColor = forRequest.answered ? .black.withAlphaComponent(0.1) : .clear
    }
    
    func composeLayout() {
        contentView.addSubview(completedBox)
        
        NSLayoutConstraint.activate([
            completedBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            completedBox.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),
            completedBox.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),
            completedBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
        ])
        update()
    }
    
    lazy var label: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    lazy var completedBox: UIButton = { [unowned self] in
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 2
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleCompleted(_:)), for: .primaryActionTriggered)
        return button
    }()
    
    @objc func toggleCompleted(_ sender: UIButton) {
        var date:Date? = Date()
        
        if request?.last?.isToday == true {
            date = nil
        }
        
        request = delegate?.markAsPrayedFor(request: request, withDate: date)
        update()
    }
    
    func update() {        
        let title = request?.last?.isToday == true ? "✔️" : ""
        
        completedBox.setTitle(title, for: .normal)
    }
}
