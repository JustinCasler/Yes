//
//  PageCurlView.swift
//  Yes
//
//  Created by justin casler on 2/18/25.
//

import SwiftUI

// MARK: - PageCurlView: UIViewControllerRepresentable wrapping UIPageViewController
struct PageCurlView: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    var pages: [UIViewController]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        // Disable double-sided mode to avoid showing a blank backside.
        pageVC.isDoubleSided = false
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        
        // Set the initial page (HomeView).
        pageVC.setViewControllers([pages[currentPage]], direction: .forward, animated: false, completion: nil)
        return pageVC
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // Only update if the visible controller isn’t already the desired one.
        if let currentVC = uiViewController.viewControllers?.first, currentVC != pages[currentPage] {
            let direction: UIPageViewController.NavigationDirection = (currentPage == 0) ? .reverse : .forward
            uiViewController.setViewControllers([pages[currentPage]], direction: direction, animated: true, completion: nil)
        }
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlView
        
        init(_ pageCurlView: PageCurlView) {
            self.parent = pageCurlView
        }
        
        // Return the previous view controller only if available.
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController), index > 0 else { return nil }
            return parent.pages[index - 1]
        }
        
        // Return the next view controller only if available.
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController), index < parent.pages.count - 1 else { return nil }
            return parent.pages[index + 1]
        }
        
        // Update the current page when the transition finishes.
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let visibleVC = pageViewController.viewControllers?.first, let index = parent.pages.firstIndex(of: visibleVC) {
                parent.currentPage = index
            }
        }
        
        // For page curl transitions, provide the spine location and ensure only one view controller is visible.
        func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
            pageViewController.isDoubleSided = false
            if let currentVC = pageViewController.viewControllers?.first {
                pageViewController.setViewControllers([currentVC], direction: .forward, animated: false, completion: nil)
            }
            return .min
        }
    }
}
