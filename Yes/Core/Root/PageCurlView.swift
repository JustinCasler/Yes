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
    var pages: [UIViewController]  // this can still be a let or var

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.isDoubleSided = false
        pageVC.dataSource = context.coordinator
        pageVC.delegate   = context.coordinator

        // use the *coordinator’s* controllers, not `self.pages` directly
        pageVC.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: .forward,
            animated: false,
            completion: nil
        )
        return pageVC
    }

    func updateUIViewController(
        _ uiViewController: UIPageViewController,
        context: Context
    ) {
        // 1) If going back to page 0 and we’re already on it, bail:
        if currentPage == 0,
           let visible = uiViewController.viewControllers?.first,
           visible is UIHostingController<HomeView> {
            return
        }

        // 2) Only update if it’s a different controller instance:
        guard let visible = uiViewController.viewControllers?.first,
              visible !== context.coordinator.controllers[currentPage]
        else { return }

        let direction: UIPageViewController.NavigationDirection =
            (currentPage == 0) ? .reverse : .forward

        uiViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: direction,
            animated: true,
            completion: nil
        )
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlView
        let controllers: [UIViewController]

        init(_ pageCurlView: PageCurlView) {
            self.parent      = pageCurlView
            // Capture the pages *once* here
            self.controllers = pageCurlView.pages
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerBefore vc: UIViewController
        ) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: vc), idx > 0 else { return nil }
            return controllers[idx - 1]
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerAfter vc: UIViewController
        ) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: vc),
                  idx < controllers.count - 1
            else { return nil }
            return controllers[idx + 1]
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visible = pvc.viewControllers?.first,
               let idx = controllers.firstIndex(of: visible) {
                parent.currentPage = idx
            }
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            spineLocationFor orientation: UIInterfaceOrientation
        ) -> UIPageViewController.SpineLocation {
            pvc.isDoubleSided = false
            if let current = pvc.viewControllers?.first {
                pvc.setViewControllers([current], direction: .forward, animated: false)
            }
            return .min
        }
    }
}
