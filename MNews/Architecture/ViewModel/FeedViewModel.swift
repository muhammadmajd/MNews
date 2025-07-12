

import Foundation

class FeedViewModel {
    
    // MARK: - State Management
    enum State {
        case idle           // Default state
        case loadingRefresh // For pull-to-refresh
        case loadingMore    // For pagination
        case reachedEndOfData // For showing the final message
        case error(String)
    }
    
    private(set) var state: State = .idle {
        didSet {
            DispatchQueue.main.async {
                self.onStateChange?(self.state)
            }
        }
    }
    var onStateChange: ((State) -> Void)?
    
    // MARK: - Data Properties
    private(set) var posts: [Post] = []
    
    private let itemsPerPage = 20
    
    // Page number is now computed directly from the post count.
    var currentPage: Int {
        guard !posts.isEmpty else { return 1 }
        return (posts.count - 1) / itemsPerPage + 1
    }
    
    private var nextPage: Int {
        return currentPage + 1
    }
    
    private var isFetching = false
    private var canFetchMore = true

    // MARK: - Initialization
    init() {
        // Load all cached posts when the app starts.
        self.posts = CoreDataManager.shared.fetchLocalPosts()
    }
    
    // MARK: - Data Fetching
    
    func refreshData() {
        guard !isFetching else { return }
        isFetching = true
        state = .loadingRefresh
        
        NetworkManager.shared.fetchPosts(page: 1) { [weak self] result in
            self?.handleFetchResult(result)
        }
        // Delay the network call by 5 seconds
        /* DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
             NetworkManager.shared.fetchPosts(page: 1) { result in
                 self?.handleFetchResult(result)
             }
         }*/
    }
    
    func fetchMoreData() {
        guard !isFetching, canFetchMore else {
            if !canFetchMore { state = .reachedEndOfData }
            return
        }
        isFetching = true
        state = .loadingMore
        
        NetworkManager.shared.fetchPosts(page: nextPage) { [weak self] result in
            self?.handleFetchResult(result)
        }
    }
    
    private func handleFetchResult(_ result: Result<[PostAPIModel], NetworkError>) {
        switch result {
        case .success(let apiPosts):
            if apiPosts.isEmpty {
                self.canFetchMore = false
                self.state = .reachedEndOfData
            } else {
                CoreDataManager.shared.savePosts(from: apiPosts) {
                    self.posts = CoreDataManager.shared.fetchLocalPosts()
                    self.state = .idle
                }
            }
        case .failure(let error):
            self.state = .error(error.localizedDescription)
        }
        
        isFetching = false
    }
    
    // MARK: - User Actions
    func toggleLike(for post: Post) {
        post.isLiked.toggle()
        CoreDataManager.shared.updateLikeStatus(for: post.id, isLiked: post.isLiked)
    }
}
