 
import UIKit
import Lottie

class FeedViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel = FeedViewModel()
    
    // --- UI Components ---
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 150
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        return tv
    }()
    
    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loading")
        view.configuration.renderingEngine = .mainThread
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.isHidden = true
        return view
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        rc.tintColor = Theme.secondaryText
        return rc
    }()
    
    // The footer view that will be "stuck" to the bottom of the screen
    private let footerView: FooterView = {
        let view = FooterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        tableView.reloadData()
        updateFooterText(for: viewModel.state)
        viewModel.refreshData()
    }
    
    // MARK: - Setup (This is where the main fixes are)
    
    private func setupUI() {
        title = "Social MNews"
        view.backgroundColor = Theme.background
           
        let appearance = UINavigationBarAppearance()
        //appearance.configureWithOpaquebackground()
        appearance.backgroundColor = Theme.surface
        appearance.titleTextAttributes = [.foregroundColor: Theme.primaryText]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.accent

        // --- View Hierarchy Setup ---
        // Add all views as siblings to the main view.
        view.addSubview(tableView)
        view.addSubview(footerView) // The footer is a sibling of the table view
        view.addSubview(animationView)

        // --- TableView Configuration ---
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
   
        // --- AutoLayout Constraints Setup ---
        NSLayoutConstraint.activate([
            // 1. Pin TableView to top and sides
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 2. Pin TableView's BOTTOM to the TOP of the sticky footer
            tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            
            // 3. Pin the sticky footer to the bottom and sides of the screen's safe area
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 4. Give the footer an explicit height
            footerView.heightAnchor.constraint(equalToConstant: 44),
            
            // 5. Center the loading animation on top of everything
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupBindings() {
        viewModel.onStateChange = { [weak self] state in
            self?.updateUI(for: state)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateUI(for state: FeedViewModel.State) {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        if !animationView.isHidden {
            animationView.stop()
            animationView.isHidden = true
        }

        updateFooterText(for: state)
        
        switch state {
        case .idle, .reachedEndOfData:
            tableView.reloadData()
        case .loadingRefresh:
            if viewModel.posts.isEmpty {
                animationView.isHidden = false
                animationView.play()
            }
        default:
            break
        }
    }
    
    private func updateFooterText(for state: FeedViewModel.State) {
        switch state {
        case .loadingMore:
            footerView.label.text = "Loading Page \(viewModel.currentPage + 1)..."
        case .reachedEndOfData:
            footerView.label.text = "You've reached the end! 🎉"
        case .loadingRefresh:
            footerView.label.text = "Refreshing..."
        default:
            footerView.label.text = "Page \(viewModel.currentPage)"
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

// MARK: - UITableViewDataSource & Delegate (No changes needed)
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            fatalError("Failed to dequeue cell")
        }
        
        let post = viewModel.posts[indexPath.row]
        cell.configure(with: post)
        
        cell.onLikeButtonTapped = { [weak self] in
            self?.viewModel.toggleLike(for: post)
            self?.tableView.reloadRows(at: [indexPath], with: .fade)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPost = viewModel.posts[indexPath.row]
        let detailVC = PostDetailViewController(post: selectedPost)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.posts.count - 5 {
            viewModel.fetchMoreData()
        }
    }
}
