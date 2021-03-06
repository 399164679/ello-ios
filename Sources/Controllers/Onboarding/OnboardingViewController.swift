//
//  OnboardingViewController.swift
//  Ello
//
//  Created by Colin Gray on 5/12/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Crashlytics
import PINRemoteImage

protocol OnboardingStep {
    var onboardingViewController: OnboardingViewController? { get set }
    var onboardingData: OnboardingData? { get set }
    func onboardingWillProceed(_: (OnboardingData?) -> Void)
    func onboardingStepBegin()
}

public class OnboardingData {
    var name: String?
    var bio: String?
    var links: String?
    var coverImage: UIImage?
    var avatarImage: UIImage?
}

private enum OnboardingDirection: CGFloat {
    case Left = -1
    case Right = 1
}

public class OnboardingViewController: BaseElloViewController, HasAppController {
    public struct Size {
        static let buttonContainerHeight = CGFloat(80)
    }

    var parentAppController: AppViewController?
    var isTransitioning = false
    private var visibleViewController: UIViewController?
    private var visibleViewControllerIndex: Int = 0
    private var onboardingViewControllers = [UIViewController]()
    var onboardingData: OnboardingData?

    public private(set) lazy var statusBar: UIView = { return UIView() }()
    public private(set) lazy var controllerContainer: UIView = { return UIView() }()
    public private(set) lazy var buttonContainer: UIView = { return UIView() }()
    public private(set) lazy var skipButton: OnboardingSkipButton = {
        let button = OnboardingSkipButton()
        return button
    }()
    public private(set) lazy var nextButton: OnboardingNextButton = {
        let button = OnboardingNextButton()
        button.setTitle(InterfaceString.Next, forState: .Normal)
        return button
    }()
    public var canGoNext: Bool {
        get { return nextButton.enabled }
        set { if nextButton.enabled != newValue { nextButton.enabled = newValue } }
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        for _ in onboardingViewControllers {
            if let controller = onboardingViewControllers as? ControllerThatMightHaveTheCurrentUser {
                controller.currentUser = currentUser
            }
        }
    }

    required public init() {
        super.init(nibName: nil, bundle: NSBundle(forClass: ProfileInfoViewController.self))
        modalTransitionStyle = .CrossDissolve
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()

        setupButtonContainer()
        setupControllerContainer()
        setupOnboardingControllers()
        setupStatusBar()
    }

}

// MARK: Child View Controller handling
extension OnboardingViewController {
    override public func sizeForChildContentContainer(container: UIContentContainer, withParentContainerSize: CGSize) -> CGSize {
        return controllerContainer.frame.size
    }
}

// MARK: Button Actions
extension OnboardingViewController {

    public func proceedToNextStep() {
        let proceedClosure: (OnboardingData?) -> Void = { data in
            self.onboardingData = data
            self.goToNextStep(data)
        }

        if self.isKindOfClass(CommunitySelectionViewController) {
            Tracker.sharedTracker.completedCommunities()
            Crashlytics.sharedInstance().setObjectValue("OnboardingAwesomePropleSelection", forKey: CrashlyticsKey.StreamName.rawValue)
        }
        else if self.isKindOfClass(AwesomePeopleSelectionViewController) {
            // handled in controller
            Crashlytics.sharedInstance().setObjectValue("OnboardingImportPrompt", forKey: CrashlyticsKey.StreamName.rawValue)
        }
        else if self.isKindOfClass(ImportPromptViewController) {
            Tracker.sharedTracker.completedContactImport()
            Crashlytics.sharedInstance().setObjectValue("OnboardingCoverImageSelection", forKey: CrashlyticsKey.StreamName.rawValue)
        }
        else if self.isKindOfClass(CoverImageSelectionViewController) {
            Tracker.sharedTracker.completedCoverImage()
            Crashlytics.sharedInstance().setObjectValue("OnboardingAvatarImageSelection", forKey: CrashlyticsKey.StreamName.rawValue)
        }
        else if self.isKindOfClass(AvatarImageSelectionViewController) {
            Tracker.sharedTracker.completedAvatar()
            Crashlytics.sharedInstance().setObjectValue("OnboardingProfileInfo", forKey: CrashlyticsKey.StreamName.rawValue)
        }
        else if self.isKindOfClass(ProfileInfoViewController) {
            Tracker.sharedTracker.addedNameBio()
        }

        if let onboardingStep = visibleViewController as? OnboardingStep {
            onboardingStep.onboardingWillProceed(proceedClosure)
        }
        else {
            proceedClosure(self.onboardingData)
        }
    }

    public func skipToNextStep() {

        if self.isKindOfClass(CommunitySelectionViewController) {
            Tracker.sharedTracker.skippedCommunities()
        }
        else if self.isKindOfClass(AwesomePeopleSelectionViewController) {
            // handled in controller
        }
        else if self.isKindOfClass(ImportPromptViewController) {
            Tracker.sharedTracker.skippedContactImport()
        }
        else if self.isKindOfClass(CoverImageSelectionViewController) {
            Tracker.sharedTracker.skippedCoverImage()
        }
        else if self.isKindOfClass(AvatarImageSelectionViewController) {
            Tracker.sharedTracker.skippedAvatar()
        }
        else if self.isKindOfClass(ProfileInfoViewController) {
            Tracker.sharedTracker.skippedNameBio()
        }

        goToNextStep(onboardingData)
    }

}

private extension OnboardingViewController {

    func setupStatusBar() {
        statusBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 20)
        statusBar.backgroundColor = .blackColor()
        statusBar.autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        view.addSubview(statusBar)
    }

    func setupButtonContainer() {
        buttonContainer.frame = view.bounds.fromBottom().growUp(Size.buttonContainerHeight)
        buttonContainer.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        buttonContainer.backgroundColor = .whiteColor()
        view.addSubview(buttonContainer)

        let inset = CGFloat(15)
        skipButton.frame = CGRect(
            x: 0,
            y: 0,
            width: Size.buttonContainerHeight,
            height: Size.buttonContainerHeight
        ).inset(all: inset)
        skipButton.autoresizingMask = [.FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        skipButton.addTarget(self, action: #selector(OnboardingViewController.skipToNextStep), forControlEvents: .TouchUpInside)
        buttonContainer.addSubview(skipButton)

        nextButton.frame = CGRect(
            x: skipButton.frame.maxX,
            y: 0,
            width: buttonContainer.frame.width - skipButton.frame.maxX,
            height: Size.buttonContainerHeight
        ).inset(all: inset)
        nextButton.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin, .FlexibleBottomMargin]
        nextButton.addTarget(self, action: #selector(OnboardingViewController.proceedToNextStep), forControlEvents: .TouchUpInside)
        buttonContainer.addSubview(nextButton)
    }

    func setupControllerContainer() {
        controllerContainer.frame = view.bounds.shrinkUp(buttonContainer.frame.height).shrinkDown(20)
        controllerContainer.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.insertSubview(controllerContainer, belowSubview: buttonContainer)
    }

    func setupOnboardingControllers() {
        onboardingData = OnboardingData()

        if let currentUser = currentUser {
            onboardingData?.name = currentUser.name
            onboardingData?.bio = currentUser.profile?.shortBio
            if let links = currentUser.externalLinksList {
                onboardingData?.links = links.reduce("") { (memo: String, link) in
                    if (memo ?? "").characters.count == 0 {
                        return link["url"] ?? ""
                    }
                    else if let url = link["url"] {
                        return "\(memo), \(url)"
                    }
                    else {
                        return memo
                    }
                }
            }

            if let url = currentUser.avatarURL()
            where url.absoluteString !~ "ello-default"
            {
                PINRemoteImageManager.sharedImageManager().downloadImageWithURL(url) { result in
                    if let image = result.image {
                        self.onboardingData?.avatarImage = image
                    }
                }
            }

            if let url = currentUser.coverImageURL()
            where url.absoluteString !~ "ello-default"
            {
                PINRemoteImageManager.sharedImageManager().downloadImageWithURL(url) { result in
                    if let image = result.image {
                        self.onboardingData?.coverImage = image
                    }
                }
            }
        }

        let communityController = CommunitySelectionViewController()
        communityController.onboardingViewController = self
        communityController.currentUser = currentUser
        addOnboardingViewController(communityController)

        let awesomePeopleController = AwesomePeopleSelectionViewController()
        awesomePeopleController.onboardingViewController = self
        awesomePeopleController.currentUser = currentUser
        addOnboardingViewController(awesomePeopleController)

        let importPromptController = ImportPromptViewController()
        importPromptController.onboardingViewController = self
        importPromptController.currentUser = currentUser
        addOnboardingViewController(importPromptController)

        let headerImageSelectionController = CoverImageSelectionViewController()
        headerImageSelectionController.onboardingViewController = self
        headerImageSelectionController.currentUser = currentUser
        addOnboardingViewController(headerImageSelectionController)

        let avatarImageSelectionController = AvatarImageSelectionViewController()
        avatarImageSelectionController.onboardingViewController = self
        avatarImageSelectionController.currentUser = currentUser
        addOnboardingViewController(avatarImageSelectionController)

        let profileInfoSelectionController = ProfileInfoViewController()
        profileInfoSelectionController.onboardingViewController = self
        profileInfoSelectionController.currentUser = currentUser
        addOnboardingViewController(profileInfoSelectionController)
    }

}

// MARK: Screen transitions
extension OnboardingViewController {

    private func showFirstViewController(viewController: UIViewController) {
        Tracker.sharedTracker.screenAppeared(viewController)

        if var onboardingStep = viewController as? OnboardingStep {
            onboardingStep.onboardingData = onboardingData
        }

        addChildViewController(viewController)
        controllerContainer.addSubview(viewController.view)
        viewController.view.frame = controllerContainer.bounds
        viewController.view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        viewController.didMoveToParentViewController(self)

        visibleViewController = viewController
        visibleViewControllerIndex = 0
        onboardingViewControllers.append(viewController)

        Crashlytics.sharedInstance().setObjectValue("OnboardingCommunities", forKey: CrashlyticsKey.StreamName.rawValue)
    }

    private func addOnboardingViewController(viewController: UIViewController) {
        if visibleViewController == nil {
            showFirstViewController(viewController)
        }
        else {
            onboardingViewControllers.append(viewController)
        }
    }

}

// MARK: Moving through the screens
extension OnboardingViewController {

    public func goToNextStep(data: OnboardingData?) {
        self.visibleViewControllerIndex += 1

        if let nextViewController = onboardingViewControllers.safeValue(visibleViewControllerIndex) {
            goToController(nextViewController, data: data, direction: .Right)
        }
        else {
            done()
        }
    }

    public func goToPreviousStep() {
        self.visibleViewControllerIndex -= 1

        if self.visibleViewControllerIndex == -1 {
            self.visibleViewControllerIndex = 0
            return
        }

        if let prevViewController = onboardingViewControllers.safeValue(visibleViewControllerIndex)
        {
            goToController(prevViewController, data: onboardingData, direction: .Left)
        }
    }

    private func done() {
        parentAppController?.doneOnboarding()
    }

    public func goToController(viewController: UIViewController, data: OnboardingData?) {
        goToController(viewController, data: data, direction: .Right)
        if self.isKindOfClass(ImportFriendsViewController) {
            Crashlytics.sharedInstance().setObjectValue("OnboardingImportFriends", forKey: CrashlyticsKey.StreamName.rawValue)
        }
    }

}

// MARK: Controller transitions
extension OnboardingViewController {

    private func goToController(viewController: UIViewController, data: OnboardingData?, direction: OnboardingDirection) {
        if let visibleViewController = visibleViewController {
            canGoNext = false
            transitionFromViewController(visibleViewController, toViewController: viewController, direction: direction)
        }

        if viewController == onboardingViewControllers.last {
            nextButton.setTitle(InterfaceString.Done, forState: .Normal)
        }
        else {
            nextButton.setTitle(InterfaceString.Next, forState: .Normal)
        }

        if var onboardingStep = viewController as? OnboardingStep {
            onboardingData = data
            onboardingStep.onboardingData = data
            onboardingStep.onboardingStepBegin()
        }
    }

    private func transitionFromViewController(visibleViewController: UIViewController, toViewController nextViewController: UIViewController, direction: OnboardingDirection) {
        if isTransitioning {
            return
        }

        Tracker.sharedTracker.screenAppeared(nextViewController)

        visibleViewController.willMoveToParentViewController(nil)
        addChildViewController(nextViewController)

        nextViewController.view.alpha = 1
        nextViewController.view.frame = CGRect(
                x: direction.rawValue * controllerContainer.frame.width,
                y: 0,
                width: controllerContainer.frame.width,
                height: controllerContainer.frame.height
            )

        isTransitioning = true
        transition(
            from: visibleViewController,
            to: nextViewController,
            duration: 0.4,
            options: .TransitionNone,
            animations: {
                self.controllerContainer.insertSubview(nextViewController.view, aboveSubview: visibleViewController.view)
                visibleViewController.view.frame.origin.x = -direction.rawValue * visibleViewController.view.frame.width
                nextViewController.view.frame.origin.x = 0
            },
            completion: { _ in
                nextViewController.didMoveToParentViewController(self)
                visibleViewController.removeFromParentViewController()
                self.visibleViewController = nextViewController
                self.isTransitioning = false
            })
    }

}
