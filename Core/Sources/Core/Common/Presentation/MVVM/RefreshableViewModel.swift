//
//  RefreshableViewModel.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

open class RefreshableViewModel: NSObject, UIScrollViewDelegate {
    
    public var refreshControl = UIRefreshControl()
    
    private func prepareRefreshControl() {
        refreshControl.attributedTitle = NSAttributedString(string: "BasicStrings.pullToRefresh.localized")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    public override init() {
        super.init()
        prepareRefreshControl()
    }
    
    @objc private func refresh() {
        refreshView()
    }
    
    open func refreshView() {
        fatalError("No implementation is provided for refresh view")
    }
    
    public func endRefreshing() {
        refreshControl.endRefreshing()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
        if !UIApplication.shared.isTabBarHidden {
            bottomOffset += UIApplication.shared.tabBarHeight
        }
        bottomOffset = max(bottomOffset, 0)
        
        if scrollView.contentOffset.y > bottomOffset {
            scrollView.contentOffset.y = bottomOffset
        }
    }
}
