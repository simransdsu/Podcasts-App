import UIKit
import SDWebImage
import Resolver
import Combine
import ProgressHUD

class PodcastDetailsViewController: UITableViewController
{
    @Injected private var episodesListViewModel: PodcastDetailViewModel
    @Injected private var favoritePodcastsViewModel: FavoritePodcastsViewModel
    
    private let cellId = "\(EpisodeCell.self)"
    private var searchController: UISearchController?
    private var cancellable = Set<AnyCancellable>()
    
    var podcastViewModel: PodcastViewModel! { didSet { navigationItem.title = podcastViewModel?.title } }
    var maximizePlayer: ((EpisodeViewModel?, [EpisodeViewModel]?) -> Void)?
    
    init() { super.init(nibName: nil, bundle: nil) }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        setupSubscriptions()
        navigationItem.largeTitleDisplayMode = .never
    }
}


// MARK:- UI Setup methods
fileprivate extension PodcastDetailsViewController {
    
    
    func setupSubscriptions() {
        
        favoritePodcastsViewModel
            .$favoritePodcasts
            .sink { podcasts in
                info("Favorite podcasts received.")
                DispatchQueue.main.async {
                    
                    self.setupFavoriteNavigationBarItem(podcasts.contains { $0.rssFeedUrl == self.podcastViewModel.rssFeedUrl })
                }
            }.store(in: &cancellable)
    }
    
    
    func setupViewModel() {
        
        guard let podcastViewModel = podcastViewModel else { return }
        Task {
            try await episodesListViewModel.fetchEpisodes(forPodcast: podcastViewModel)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func setupTableView() {
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
        let nib = UINib(nibName: "\(EpisodeCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    func setupSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        navigationItem.searchController = searchController
    }
    
    
    func setupFavoriteNavigationBarItem(_ isFavorite: Bool) {
        if isFavorite {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "bookmark.fill"), style: .plain, target: self, action: #selector(self.handleUnFavorite))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "bookmark"), style: .plain, target: self, action: #selector(self.handleSaveToFavorites))
        }
    }
}


// MARK:- Action handlers
fileprivate extension PodcastDetailsViewController {
    
    @objc func handleSaveToFavorites() {
        Task {
            try await favoritePodcastsViewModel.favoritePodcast(podcastViewModel)
        }
        
    }
    
    @objc func handleUnFavorite() {
        Task {
            try await favoritePodcastsViewModel.unfavoritePodcast(podcastViewModel)
        }
    }
}



// MARK:- TableView methods
extension PodcastDetailsViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 110.0 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesListViewModel.episodesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episodeViewModel = self.episodesListViewModel.episode(atIndex: indexPath.row)
        cell.configure(withViewModel: episodeViewModel, podcastImageURL: podcastViewModel.image)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = self.episodesListViewModel.episode(atIndex: indexPath.row)
        episode.imageUrl = podcastViewModel?.image
        self.view.window?.endEditing(true)
    
        maximizePlayer?(episode, episodesListViewModel.episodesList)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodesListViewModel.episodesList.isEmpty ? 200 : 0
    }
}

// MARK:- Searchbar methods
extension PodcastDetailsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        episodesListViewModel.search(forValue: searchText)
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        episodesListViewModel.finishSearch()
    }
}
