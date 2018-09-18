import UIKit

class FavoritePodcastCell : UICollectionViewCell
{
   
    override
    init(frame: CGRect)
    {
        super.init(frame: frame)
        stylizeUI()
        layoutUI()
    }
    
    required
    init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Setups
    fileprivate
    func stylizeUI()
    {
        nameLabel.text = "Podcast name"
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        artistNameLabel.text = "Artist Name"
        artistNameLabel.font = UIFont.systemFont(ofSize: 13)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    }
    
    fileprivate
    func layoutUI()
    {
        let stackView = UIStackView(arrangedSubviews: [imageView, nameLabel, artistNameLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        
        addSubview(stackView)
        
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    
    func setupCell(podcast: Podcast)
    {
        guard let imageUrl = URL(string: podcast.artworkUrl600 ?? "") else { return }
        imageView.sd_setImage(with: imageUrl)
        nameLabel.text = podcast.trackName
        artistNameLabel.text = podcast.artistName
    }
    
    // MARK:- UI properties
    let imageView = UIImageView(image: UIImage(named: "appicon"))
    let nameLabel = UILabel()
    let artistNameLabel = UILabel()
}