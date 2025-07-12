//
//  PostTableViewCell.swift
//  SocialFeedApp
//

import UIKit

class PostTableViewCell: UITableViewCell {

    // MARK: - Public Properties
    
    /// A closure that the ViewController can implement to handle the like button tap.
    var onLikeButtonTapped: (() -> Void)?

    // MARK: - Private UI Components
    
    /// The outer container that casts the shadow.
    /// It does NOT clip to bounds, so the shadow is visible.
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surface
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// The inner container that holds the content.
    /// It CLIPS to bounds, ensuring the image and other content adhere to the rounded corners.
    private let innerContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        // The innerContentView will handle clipping, so this isn't strictly necessary but is good practice.
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = .darkGray // A placeholder color while the image loads
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.numberOfLines = 2
        label.textColor = Theme.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.textColor = Theme.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // --- Cell Styling ---
        // Make the cell's own background transparent to see the view controller's background.
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        self.selectionStyle = .none
        
        // --- View Hierarchy ---
        // 1. Add containerView to cell's contentView. It will provide the shadow.
        contentView.addSubview(containerView)
        // 2. Add innerContentView to containerView. It will clip the content to rounded corners.
        containerView.addSubview(innerContentView)
        // 3. Add all visual elements to the innerContentView.
        innerContentView.addSubview(avatarImageView)
        innerContentView.addSubview(titleLabel)
        innerContentView.addSubview(bodyLabel)
        innerContentView.addSubview(likeButton)
        
        // --- Apply Shadow ---
        // Call the extension method directly on the containerView.
        containerView.addShadow(color: .black, alpha: 0.2, y: 5, blur: 15)

        // --- Layout Constraints ---
        NSLayoutConstraint.activate([
            // Pin containerView to the cell's contentView with margins.
            // The margins provide spacing between cells and room for the shadow.
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Pin the innerContentView to fill the containerView completely.
            innerContentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            innerContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            innerContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            innerContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Now, constrain all content relative to the innerContentView.
            avatarImageView.leadingAnchor.constraint(equalTo: innerContentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: innerContentView.topAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -12),

            likeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),

            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor, constant: -16),
            bodyLabel.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cell Configuration
    
    /// Populates the cell with data from a Post object.
    func configure(with post: Post) {
        titleLabel.text = post.title?.capitalized
        bodyLabel.text = post.body

        let avatarURL = URL(string: "https://picsum.photos/id/\(post.userId)/100/100")!
        avatarImageView.loadImage(from: avatarURL)
        
        // Update the like button's appearance based on the post's state.
        let heartImageName = post.isLiked ? "heart.fill" : "heart"
        let heartImage = UIImage(systemName: heartImageName)
        likeButton.setImage(heartImage, for: .normal)
        likeButton.tintColor = post.isLiked ? Theme.accentRed : Theme.secondaryText
    }
    
    // MARK: - Lifecycle Overrides
    
    /// Resets cell content before reuse to prevent displaying stale data.
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        titleLabel.text = nil
        bodyLabel.text = nil
    }
    
    // MARK: - Actions
    
    @objc private func likeButtonTapped() {
        onLikeButtonTapped?()
    }
}
