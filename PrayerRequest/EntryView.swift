//
//  Entryswift
//  PrayerRequest
//
//  Created by Matthew Voss on 9/10/22.
//

import Foundation
import UIKit
import CoreData


class RequestEntryView: UIView {
    static let defaultTitle = "Title"
    static let defaultDetail = "Detail Text"
    
    lazy var centerView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.layer.cornerRadius = 10
        cv.backgroundColor = UIColor(white: 0.875, alpha: 1)
        return cv
    }()
    
    weak var delegate: RequestDelegate?
    var prayerRequest: PrayerRequest?
    lazy var optionsView: UIView  = {
        let ov = UIView()
        ov.translatesAutoresizingMaskIntoConstraints = false
        ov.layer.cornerRadius = 10
        return ov
    }()
    
    lazy var bottomContainer: UIView = {
        let bc = UIView()
        bc.translatesAutoresizingMaskIntoConstraints = false
        return bc
    }()
    
    var currentTab = Tabs.Daily
    lazy var selectionBar: UITabBar = { [unowned self] in
        let bar = UITabBar()
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.layer.cornerRadius = 10
        bar.itemPositioning = .centered
        bar.clipsToBounds = true
        return bar
    }()
    
    lazy var deleteButton: UIButton = {
        let delete = UIButton()
        delete.translatesAutoresizingMaskIntoConstraints = false
        delete.setImage(UIImage(systemName: "trash"), for: .normal)
        delete.addTarget(self, action: #selector(deletePressed(_:)), for: .primaryActionTriggered)
        return delete
    }()
    
    lazy var titleTextEntry: UITextView = {
        let text = UITextView()
        text.isUserInteractionEnabled = true
        text.delegate = self
        text.translatesAutoresizingMaskIntoConstraints = false
        text.returnKeyType = .next
        text.text = Self.defaultTitle
        text.layer.cornerRadius = 10
        return text
    }()
    
    lazy var completedBox: LabelBox = { [unowned self] in
        let box = LabelBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.layer.cornerRadius = 5
        box.backgroundColor = .white
        box.setupWith(text: "Prayed for today")
        return box
    }()
    
    lazy var answeredBox: LabelBox = { [unowned self] in
        let box = LabelBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.layer.cornerRadius = 5
        box.backgroundColor = .white
        box.setupWith(text: "Answered")
        return box
    }()
    
    lazy var detailTextEntry: UITextView = {
        let text = UITextView()
        text.isUserInteractionEnabled = true
        text.delegate = self
        text.translatesAutoresizingMaskIntoConstraints = false
        text.text = Self.defaultDetail
        text.layer.cornerRadius = 10
        return text
    }()
    
    var centerViewConstraint = NSLayoutConstraint()
    var centerViewKeyboardConstraint = NSLayoutConstraint()

    func setup() {
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.alpha = 0.3
        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        NSLayoutConstraint.activate([blur.topAnchor.constraint(equalTo: topAnchor),
                                     blur.bottomAnchor.constraint(equalTo: bottomAnchor),
                                     blur.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     blur.trailingAnchor.constraint(equalTo: trailingAnchor)])
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAway(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
            
        addSubview(centerView)
        centerViewConstraint = centerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerViewKeyboardConstraint = centerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([centerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
                                     centerView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
                                     centerView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     centerViewConstraint])

        // set up selection bar
        centerView.addSubview(bottomContainer)
        NSLayoutConstraint.activate([bottomContainer.widthAnchor.constraint(equalTo: centerView.widthAnchor, multiplier: 0.95),
                                     bottomContainer.heightAnchor.constraint(equalTo: centerView.heightAnchor, multiplier: 0.075),
                                     bottomContainer.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
                                     bottomContainer.bottomAnchor.constraint(equalTo: centerView.bottomAnchor, constant: -5)])
        
        bottomContainer.addSubview(selectionBar)
        NSLayoutConstraint.activate([selectionBar.widthAnchor.constraint(equalTo: bottomContainer.widthAnchor, multiplier: 0.9),
                                     selectionBar.heightAnchor.constraint(equalTo: bottomContainer.heightAnchor),
                                     selectionBar.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
                                     selectionBar.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor)])
        
        
        bottomContainer.addSubview(deleteButton)
        NSLayoutConstraint.activate([deleteButton.widthAnchor.constraint(equalTo: bottomContainer.widthAnchor, multiplier: 0.075),
                                     deleteButton.heightAnchor.constraint(equalTo: bottomContainer.heightAnchor),
                                     deleteButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
                                     deleteButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor)])
        
        var tabs = [UITabBarItem]()
        var selectedTab: UITabBarItem?
        for item in Tabs.allCases {
            guard ![.About, .Today, .Search].contains(item) else { continue }
            let tab = UITabBarItem(title: item.text, image: nil, tag: Int(item.rawValue))
            tab.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -7.5)
            if tab.tag == currentTab.rawValue {
                selectedTab = tab
            }
            tabs.append(tab)
        }
        selectionBar.setItems(tabs, animated: true)
        selectionBar.selectedItem = selectedTab
        
        // set up text entry view
        centerView.addSubview(detailTextEntry)
        centerView.addSubview(titleTextEntry)
        centerView.addSubview(optionsView)

        NSLayoutConstraint.activate([detailTextEntry.widthAnchor.constraint(equalTo: centerView.widthAnchor, multiplier: 0.95),
                                     detailTextEntry.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
                                     detailTextEntry.topAnchor.constraint(equalTo: titleTextEntry.bottomAnchor, constant: 10),
                                     detailTextEntry.bottomAnchor.constraint(equalTo: optionsView.topAnchor, constant: -5)])
        
        NSLayoutConstraint.activate([titleTextEntry.topAnchor.constraint(equalTo: centerView.topAnchor, constant: 5),
                                     titleTextEntry.widthAnchor.constraint(equalTo: centerView.widthAnchor, multiplier: 0.95),
                                     titleTextEntry.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
                                     titleTextEntry.heightAnchor.constraint(equalTo: centerView.heightAnchor, multiplier: 0.1)])
        
        NSLayoutConstraint.activate([optionsView.widthAnchor.constraint(equalTo: centerView.widthAnchor, multiplier: 0.95),
                                     optionsView.heightAnchor.constraint(equalTo: centerView.heightAnchor, multiplier: 0.075),
                                     optionsView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: -5),
                                     optionsView.centerXAnchor.constraint(equalTo: centerView.centerXAnchor)])
        
        
        optionsView.addSubview(completedBox)
        optionsView.addSubview(answeredBox)
        NSLayoutConstraint.activate([completedBox.widthAnchor.constraint(equalTo: optionsView.widthAnchor, multiplier: 0.4875),
                                     completedBox.heightAnchor.constraint(equalTo: optionsView.heightAnchor, multiplier: 0.95),
                                     completedBox.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor),
                                     completedBox.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor)])
        
        NSLayoutConstraint.activate([answeredBox.widthAnchor.constraint(equalTo: optionsView.widthAnchor, multiplier: 0.4875),
                                     answeredBox.heightAnchor.constraint(equalTo: optionsView.heightAnchor, multiplier: 0.95),
                                     answeredBox.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor),
                                     answeredBox.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor)])
    }
    
    func updateFor(request: PrayerRequest) {
        prayerRequest = request
        currentTab = Tabs(rawValue: request.interval) ?? currentTab
        titleTextEntry.text = request.titleText
        detailTextEntry.text = request.detailText
        completedBox.updateCheck(request.last?.isToday ?? false)
        answeredBox.updateCheck(request.answered)
    }
    
    @objc func tapAway(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        if centerViewKeyboardConstraint.isActive {
            detailTextEntry.resignFirstResponder()
            titleTextEntry.resignFirstResponder()
            return
        }
        
        dismissPressed(nil)
    }
    
    @objc func deletePressed(_ sender: UIButton) {
        if let prayerRequest = prayerRequest {
            delegate?.delete(request: prayerRequest)
        } else {
            self.removeFromSuperview()
        }
    }
    
    @objc func dismissPressed(_ sender: UIButton?) {
        
        if let prayerRequest = prayerRequest {
            // only update the request if there are changes
            if prayerRequest.titleText != titleTextEntry.text {
                prayerRequest.titleText = titleTextEntry.text
            }
            if prayerRequest.detailText != detailTextEntry.text {
                prayerRequest.detailText = detailTextEntry.text
            }
            if prayerRequest.interval != currentTab.rawValue {
                prayerRequest.interval = currentTab.rawValue
                // if the interval changed, then also update the tag to ensure it will actually show at some point
                prayerRequest.tag = delegate?.nextTagFor(interval: currentTab.rawValue) ?? 1
            }
            
            if let last = prayerRequest.last {
                if (completedBox.isChecked && !last.isToday) || (!completedBox.isChecked && last.isToday) {
                    prayerRequest.last = completedBox.isChecked ? Date() : nil
                }
            } else if completedBox.isChecked {
                    prayerRequest.last = Date()
            }
            
            if prayerRequest.answered != answeredBox.isChecked {
                prayerRequest.answered = answeredBox.isChecked
            }
            
            delegate?.saveUpdated(request: prayerRequest)
        } else {
            let tag = delegate?.nextTagFor(interval: currentTab.rawValue) ?? 1
            let last = completedBox.isChecked ? Date() : nil
            let answered = answeredBox.isChecked
            let title = titleTextEntry.text == Self.defaultTitle ? "" : titleTextEntry.text
            let detail = detailTextEntry.text == Self.defaultDetail ? "" : detailTextEntry.text

            delegate?.save(title: title, detail: detail, interval: Int32(currentTab.rawValue), tag: tag, last: last, answered: answered)
        }
        self.removeFromSuperview()
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        NSLayoutConstraint.deactivate([centerViewConstraint])

        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            centerViewKeyboardConstraint.constant = -(keyboardSize.height + 5)
        }
        NSLayoutConstraint.activate([centerViewKeyboardConstraint])
        centerView.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        NSLayoutConstraint.deactivate([centerViewKeyboardConstraint])
        NSLayoutConstraint.activate([centerViewConstraint])
        centerView.layoutIfNeeded()
    }
}

extension RequestEntryView: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        currentTab = Tabs(rawValue: Int32(item.tag)) ?? currentTab
    }
}

extension RequestEntryView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.text == Self.defaultTitle || textView.text == Self.defaultDetail {
            textView.text = ""
        }
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == titleTextEntry && text == "\n" {
            if textView.text != "" {
                textView.resignFirstResponder()
                detailTextEntry.becomeFirstResponder()
            }
            return false
        }
        
        return true
    }
}

extension RequestEntryView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: gestureRecognizer.view)
        return !centerView.frame.contains(point)
    }
}


class LabelBox: UIView {
    
    lazy var label: UILabel = { [unowned self] in
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.layer.cornerRadius = 5
        l.backgroundColor = .clear
        return l
    }()
    
    
    lazy var checkBox: UIButton = { [unowned self] in
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 2
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleChekcBox(_:)), for: .primaryActionTriggered)
        return button
    }()
    
    var isChecked: Bool {
        return checkBox.currentTitle?.contains("✔️") == true
    }
    
    func updateCheck(_ checked: Bool) {
        if checked {
            checkBox.setTitle("✔️", for: .normal)
        } else {
            checkBox.setTitle("", for: .normal)
        }
    }
    
    @objc func toggleChekcBox(_ sender: UIButton) {
        updateCheck(!isChecked)
    }
    
    func setupWith(text: String) {
        
        addSubview(checkBox)
        addSubview(label)
        label.text = text

        NSLayoutConstraint.activate([checkBox.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9),
                                     checkBox.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9),
                                     checkBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
                                     checkBox.centerYAnchor.constraint(equalTo: centerYAnchor)])
        
        NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
                                     label.trailingAnchor.constraint(equalTo: checkBox.leadingAnchor, constant: 10),
                                     label.heightAnchor.constraint(equalTo: checkBox.heightAnchor),
                                     label.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}
