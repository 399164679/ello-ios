//
//  DiscoverMoreCategoriesViewController.swift
//  Ello
//
//  Created by Colin Gray on 6/17/2016.
//  Copyright (c) 2016 Ello. All rights reserved.
//

public class DiscoverMoreCategoriesViewController: StreamableViewController {
    var screen: DiscoverMoreCategoriesScreen { return self.view as! DiscoverMoreCategoriesScreen }

    required public init() {
        super.init(nibName: nil, bundle: nil)

        title = InterfaceString.Discover.MoreCategories
        elloNavigationItem.title = title

        let leftItem = UIBarButtonItem.backChevronWithTarget(self, action: #selector(backTapped(_:)))
        elloNavigationItem.leftBarButtonItems = [leftItem]
        elloNavigationItem.fixNavBarItemPadding()

        streamViewController.initialLoadClosure = loadCategories
        streamViewController.streamKind = .MoreCategories
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let screen = DiscoverMoreCategoriesScreen(navigationItem: elloNavigationItem)
        self.view = screen
        viewContainer = screen.streamContainer
    }

    func loadCategories() {
        CategoryService().loadCategories({ [weak self] categories in
            guard let sself = self else { return }

            let filteredCategories = categories.filter { $0.visibleOnSeeMore }
            let sortedCategories = CategoryList(categories: filteredCategories).categories

            sself.streamViewController.showInitialJSONAbles(sortedCategories)
        })
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = true
        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    private func updateInsets() {
        updateInsets(navBar: screen.navigationBar, streamController: streamViewController)
    }

    override public func showNavBars(scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override public func hideNavBars() {
        super.hideNavBars()
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint)
        updateInsets()
    }

}

// MARK: StreamViewDelegate
extension DiscoverMoreCategoriesViewController {
    override public func streamViewStreamCellItems(jsonables: [JSONAble], defaultGenerator generator: StreamCellItemGenerator) -> [StreamCellItem]? {
        var items: [StreamCellItem] = CategoryList.metaCategories().map { StreamCellItem(jsonable: $0, type: .Category) }
        if let categories = jsonables as? [Category] {
            items += categories.map { StreamCellItem(jsonable: $0, type: .Category) }
            items.append(StreamCellItem(type: .SeeAllCategories))
        }
        return items
    }
}
