 
import UIKit

class PostDetailViewController: UIViewController {

    // MARK: - Properties
    
    private let post: Post
    
    

    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 40 // Larger avatar for the detail view
        iv.backgroundColor = .lightGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true // IMPORTANT: Enable interaction on the image view
        return iv
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0 // Allow multiple lines
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0 // Allow multiple lines
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initializer
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureData()
        setupAvatarTapGesture()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = Theme.background // Use theme background
        navigationItem.largeTitleDisplayMode = .never // Use a standard title bar

        
        userLabel.textColor = Theme.accent
        titleLabel.textColor = Theme.primaryText
        bodyLabel.textColor = Theme.secondaryText
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(userLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // ContentView constraints (to define scrollable area)
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor), // Crucial for vertical scrolling

            // Avatar constraints
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // User Label constraints
            userLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            userLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            userLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Title Label constraints
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Body Label constraints
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // This makes the contentView grow with the bodyLabel
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func configureData() {
        title = "Post Details" // Navigation bar title
        
        titleLabel.text = post.title?.capitalized
        bodyLabel.text = post.body
        userLabel.text = "User ID: \(post.userId)"
        
        // Load the same avatar image
        let avatarURL = URL(string: "https://picsum.photos/id/\(post.userId)/200/200")!
        avatarImageView.loadImage(from: avatarURL) // Assumes you have the extension from PostTableViewCell
    }
    
    // MARK: - Gestures (New Section)
     
     private func setupAvatarTapGesture() {
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarImageTapped))
         avatarImageView.addGestureRecognizer(tapGesture)
     }
     
     @objc private func avatarImageTapped() {
         // Ensure we have an image to show
         guard let image = avatarImageView.image else { return }
         
         // 1. Create the preview controller
         let previewVC = ImagePreviewViewController(image: image)
         
         // 2. Present it modally
         present(previewVC, animated: true, completion: nil)
     }
}
