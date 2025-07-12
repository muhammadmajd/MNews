/*
 
 State: An enum to communicate the current status to the FeedViewController. This is cleaner than using multiple boolean flags.
 posts: The array that will back our UITableView. It's private(set) so only the ViewModel can modify it.
 onStateChange: A closure that the ViewController will subscribe to, allowing it to react to state changes (e.g., show a spinner, reload data).
 fetchData: The core logic. It calls the network, saves to CoreData on success, then fetches the entire list from CoreData. This ensures our UI is always showing the persisted data. If the network fails, it attempts to load from CoreData for offline support.
 toggleLike: Handles the business logic for liking a post by calling the CoreData manager.
 */
import Foundation

class FeedViewModel {
    
    // Enum to represent the state of the view
    enum State {
            case initial
            case loading // For initial load or pull-to-refresh
            case loadingMore // For pagination
            case loaded
            case error(String)
        }
        
        // ... (posts, onStateChange properties remain the same) ...
        private(set) var posts: [Post] = []
        
        private(set) var state: State = .initial {
            didSet {
                // Ensure UI updates are on the main thread
                DispatchQueue.main.async {
                    self.onStateChange?(self.state)
                }
            }
        }
        var onStateChange: ((State) -> Void)?
        
        //private var currentPage = 1
        private(set) var currentPage = 1
        private var isFetching = false // Crucial flag to prevent multiple requests
        private var canFetchMore = true // Becomes false when the API returns an empty list

        // MARK: - Data Fetching
        
        func fetchInitialData() {
            // This is only called once from viewDidLoad
            guard !isFetching else { return }
            state = .loading
            fetchData(isRefresh: false)
        }
        
        func refreshData() {
            // This is called from pull-to-refresh
            guard !isFetching else { return }
            state = .loading
            fetchData(isRefresh: true)
        }
        
        func fetchMoreData() {
            // This is called when scrolling near the bottom
            guard !isFetching, canFetchMore else { return }
            state = .loadingMore
            fetchData(isRefresh: false)
        }

        private func fetchData(isRefresh: Bool) {
            isFetching = true
            
            if isRefresh {
                currentPage = 1
                canFetchMore = true
            }
            
            NetworkManager.shared.fetchPosts(page: currentPage) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let apiPosts):
                    // If the API returns fewer posts than the limit, or 0, we've reached the end
                    if apiPosts.isEmpty {
                        self.canFetchMore = false
                    }
                    
                    CoreDataManager.shared.savePosts(from: apiPosts)
                    
                    // If it was a refresh, clear the old data
                    if isRefresh {
                        self.posts = []
                    }
                    
                    // Fetch the consolidated list from CoreData.
                    // This ensures our UI is always showing the persisted data.
                    let allLocalPosts = CoreDataManager.shared.fetchLocalPosts()
                    self.posts = allLocalPosts
                    
                    self.state = .loaded
                    self.currentPage += 1
                    
                case .failure(let error):
                    // On failure, try to load from offline storage
                    let localPosts = CoreDataManager.shared.fetchLocalPosts()
                    if !localPosts.isEmpty {
                        self.posts = localPosts
                        self.state = .loaded
                    } else {
                        self.state = .error(error.localizedDescription)
                    }
                }
                
                // IMPORTANT: Set isFetching to false inside the completion block
                self.isFetching = false
            }
        }
    // MARK: - User Actions
    
    func toggleLike(for post: Post) {
        let newLikedStatus = !post.isLiked
        CoreDataManager.shared.updateLikeStatus(for: post.id, isLiked: newLikedStatus)
        // Manually update the local model to reflect the change immediately
        post.isLiked = newLikedStatus
    }
}
