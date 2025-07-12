
import UIKit

class ImagePreviewViewController: UIViewController {

    // MARK: - Properties
    
    private let image: UIImage?

    // MARK: - UI Components
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true // Enable user interaction to detect taps
        return iv
    }()
    
    // A semi-transparent background view
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializer
    
    init(image: UIImage?) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        
        // This is key for the custom "pop-up" presentation
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve // A simple fade-in/fade-out animation
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .clear // Make the view's own background transparent
        
        // Add the background first, then the image view on top
        view.addSubview(backgroundView)
        view.addSubview(imageView)
        
        imageView.image = self.image
        
        NSLayoutConstraint.activate([
            // Background view should fill the entire screen
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Image view should be centered and constrained by the safe area margins
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
    
    private func setupGestures() {
        // Add a tap gesture to dismiss the view controller
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissViewController))
        view.addGestureRecognizer(tapGesture) // Add to the main view to catch taps on the background
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
