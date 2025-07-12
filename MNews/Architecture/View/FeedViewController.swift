//
//  FeedViewController.swift
//  SocialFeedApp
//

import UIKit
import Lottie // <-- Step 1: Uncomment this line if you decide to use Lottie animations.

class FeedViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel = FeedViewModel()
    
    // --- UI Components ---
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        // Register the custom cell we created earlier
        tv.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 150
        return tv
    }()
    
    // Standard loading indicator (adheres to "no third-party libs" rule)
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    
    // --- Lottie Animation (Optional Bonus) ---
    // Step 2: Comment out the `activityIndicator` above and uncomment this `animationView` below.
    // Make sure you have added the Lottie package and a JSON animation file named "loading" to your project.
    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loading") // Assumes a file named "loading.json" is in your project
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.isHidden = true
        return view
    }()
    
    
    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()
    
    // A spinner for the table view footer to indicate pagination loading
    private let footerSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        // Set a frame, as this will be the view for the table footer
        spinner.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        return spinner
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Kick off the initial data fetch
        viewModel.fetchInitialData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Social MNews"
       // view.backgroundColor = .systemBackground
        view.backgroundColor = Theme.background // Use theme background
           
           // Style the navigation bar for a dark theme
           let appearance = UINavigationBarAppearance()
           appearance.configureWithOpaqueBackground()
           appearance.backgroundColor = Theme.surface
           appearance.titleTextAttributes = [.foregroundColor: Theme.primaryText]
           navigationController?.navigationBar.standardAppearance = appearance
           navigationController?.navigationBar.scrollEdgeAppearance = appearance
           navigationController?.navigationBar.tintColor = Theme.accent // For back button, etc.

           // Style the table view
           tableView.backgroundColor = .clear // Make it transparent to show the view's background
           tableView.separatorStyle = .none // Hides lines between cells for a modern look
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(animationView) // <-- Step 3: Use this line instead of the one above for Lottie.

        // Configure table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinner // Add spinner for pagination
        footerSpinner.hidesWhenStopped = true
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Constraints for the main loading indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // --- Lottie Animation Constraints (Optional Bonus) ---
            // Step 4: Comment out the activityIndicator constraints above and uncomment these below.
             animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
             animationView.widthAnchor.constraint(equalToConstant: 200),
             animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    /// Binds the ViewController's UI to the ViewModel's state.
    /// This is the core of the MVVM pattern.
    private func setupBindings() {
        viewModel.onStateChange = { [weak self] state in
            // The ViewModel now dispatches to the main thread, so we can update UI directly.
            self?.updateUI(for: state)
        }
    }
    
    // MARK: - UI Updates
    
    /// Updates the UI based on the current state from the ViewModel.
    private func updateUI(for state: FeedViewModel.State) {
        // Stop all indicators first to avoid overlapping states
        stopAllIndicators()
        
        switch state {
        case .loading:
            // Show the main loading animation for initial load or pull-to-refresh
            animationView.isHidden = false
            animationView.play()
            
        case .loadingMore:
            // Show the footer spinner for pagination
            footerSpinner.startAnimating()
            
        case .loaded:
            // New data is available, reload the table
            tableView.reloadData()
            
        case .error(let message):
            // Show an error message to the user
            showErrorAlert(message: message)
            
        case .initial:
            break
        }
    }

    private func stopAllIndicators() {
        // This function ensures everything is reset before showing the correct indicator.
        if animationView.isAnimationPlaying {
            animationView.stop()
        }
        animationView.isHidden = true
        
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        
        if footerSpinner.isAnimating {
            footerSpinner.stopAnimating()
        }
    }
    
    // MARK: - Actions & Helpers
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: "Could not load feed. \(message)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            // This should never happen if the cell is registered correctly
            return UITableViewCell()
        }
        
        let post = viewModel.posts[indexPath.row]
        cell.configure(with: post)
        
        // Handle the like button tap via a closure from the cell
        cell.onLikeButtonTapped = { [weak self, weak cell] in
            self?.viewModel.toggleLike(for: post)
            
            // We can either re-configure the cell directly for an instant update...
            if let updatedCell = cell {
                updatedCell.configure(with: post)
            }
            // ...or reload the row for a clean, animated update (often preferred).
             self?.tableView.reloadRows(at: [indexPath], with: .fade)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FeedViewController: UITableViewDelegate {
    
    // This method is called when a user taps a row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row for a cleaner UI effect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 1. Get the post that was tapped from our view model
        let selectedPost = viewModel.posts[indexPath.row]
        
        // 2. Create an instance of our new detail view controller
        let detailVC = PostDetailViewController(post: selectedPost)
        
        // 3. Push it onto the navigation stack
        // This gives us the "back" button for free!
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // (Your existing pagination logic stays here)
        let lastRowIndex = viewModel.posts.count - 1
        if indexPath.row == lastRowIndex - 5 {
            viewModel.fetchMoreData()
        }
    }
}
