//
//  Preloader.swift
//  Ello
//
//  Created by Sean on 4/25/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import PINRemoteImage

public struct Preloader {

    // public so that we can swap out a fake in specs
    public var manager = PINRemoteImageManager.sharedImageManager()

    public init(){}

    public func preloadImages(jsonables: [JSONAble]) {

        for jsonable in jsonables {

            // activities avatar
            if  let activity = jsonable as? Activity,
                let authorable = activity.subject as? Authorable,
                let author = authorable.author,
                let avatarURL = author.avatarURL()
            {
                preloadUrl(avatarURL)
            }

            // post / comment avatars
            else if let authorable = jsonable as? Authorable,
                    let author = authorable.author,
                    let avatarURL = author.avatarURL()
            {
                preloadUrl(avatarURL)
            }

            // user's posts avatars
            else if let user = jsonable as? User,
                    let posts = user.posts
            {
                if let userAvatarURL = user.avatarURL() {
                    preloadUrl(userAvatarURL)
                }

                for post in posts {
                    if  let author = post.author,
                        let avatarURL = author.avatarURL()
                        {
                            preloadUrl(avatarURL)
                        }
                }
            }

            // activity image regions
            if  let activity = jsonable as? Activity,
                let post = activity.subject as? Post
            {
                preloadImagesinPost(post)
            }

            // post image regions
            else if let post = jsonable as? Post {
                preloadImagesinPost(post)
            }

            // comment image regions
            else if let comment = jsonable as? ElloComment {
                preloadImagesInRegions(comment.content)
            }

            // user's posts image regions
            else if let user = jsonable as? User,
                    let posts = user.posts
            {
                for post in posts {
                    preloadImagesinPost(post)
                }
            }

            // categories
            else if let category = jsonable as? Category,
                url = category.tileURL
            {
                preloadUrl(url)
            }

            // TODO: account for discovery when the api includes assets in the discovery
            // responses
        }
    }

    private func preloadUserAvatar(post: Post, streamKind: StreamKind) {
        if let content = post.content {
            for region in content {
                if let imageRegion = region as? ImageRegion,
                    let asset = imageRegion.asset,
                    let attachment = asset.oneColumnAttachment
                {
                    preloadUrl(attachment.url)
                }
            }
        }
    }

    private func preloadImagesinPost(post: Post) {
        if let content = post.content {
            preloadImagesInRegions(content)
        }
    }

    private func preloadImagesInRegions(regions: [Regionable]) {
        for region in regions {
            if  let imageRegion = region as? ImageRegion,
                let asset = imageRegion.asset,
                let attachment = asset.oneColumnAttachment
            {
                preloadUrl(attachment.url)
            }
        }
    }

    private func preloadUrl(url: NSURL) {
        if !url.hasGifExtension {
            manager.prefetchImageWithURL(url, options: PINRemoteImageManagerDownloadOptions.DownloadOptionsNone)
        }
    }
}
