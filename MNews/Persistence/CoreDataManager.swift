// CoreDataManager.swift
/*
 We access the persistentContainer to get the viewContext, which is our scratchpad for Core Data objects.
 savePosts: This is a critical function. To prevent creating duplicate posts every time we refresh, we first fetch all existing post IDs and store them in a Set for fast lookups. We then only create new Post objects if their ID is not in the set.
 fetchLocalPosts: A standard fetch request to get all saved posts, sorted by ID.
 updateLikeStatus: Finds a specific post by its ID and updates its isLiked property.
 */
import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    // Use the persistent container from the AppDelegate
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MNews")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Save posts from the API, avoiding duplicates.
    func savePosts(from apiPosts: [PostAPIModel]) {
        context.perform {
            do {
                // To avoid duplicates, get all existing post IDs
                let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                fetchRequest.propertiesToFetch = ["id"]
                let existingPosts = try self.context.fetch(fetchRequest)
                let existingPostIDs = Set(existingPosts.map { $0.id })

                // Only create new objects for posts that don't already exist
                for apiPost in apiPosts {
                    if !existingPostIDs.contains(Int64(apiPost.id)) {
                        let newPost = Post(context: self.context)
                        newPost.id = Int64(apiPost.id)
                        newPost.userId = Int64(apiPost.userId)
                        newPost.title = apiPost.title
                        newPost.body = apiPost.body
                        newPost.isLiked = false // Default value
                    }
                }
                
                try self.context.save()
            } catch {
                print("Failed to save posts: \(error)")
            }
        }
    }

    // Fetch all posts stored locally.
    func fetchLocalPosts() -> [Post] {
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        // Sort posts by ID to maintain order
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let posts = try context.fetch(fetchRequest)
            return posts
        } catch {
            print("Failed to fetch posts: \(error)")
            return []
        }
    }
    
    // Update the like status for a specific post.
    func updateLikeStatus(for postId: Int64, isLiked: Bool) {
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", postId)
        
        do {
            let posts = try context.fetch(fetchRequest)
            if let postToUpdate = posts.first {
                postToUpdate.isLiked = isLiked
                try context.save()
            }
        } catch {
            print("Failed to update like status: \(error)")
        }
    }
}
