//
//  ViewController.swift
//  BeerScroller
//
//  Created by Ben Scheirman on 10/25/17.
//  Copyright © 2017 NSScreencast. All rights reserved.
//

import UIKit

class BeerListViewController: UITableViewController {

    let breweryDBClient = BreweryDBClient()
    
    var totalBeerCount: Int = 0
    var beers: [Beer] = []
    private var currentPage = 1
    private var isFetchingNextPage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Beers"
        
        tableView.prefetchDataSource = self
        tableView.estimatedRowHeight = 56
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(BeerCell.self, forCellReuseIdentifier: String(describing: BeerCell.self))
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshBeers), for: .valueChanged)

        refreshControl?.beginRefreshing()
        loadBeers(refresh: true)
    }
    
    @objc
    private func refreshBeers() {
        currentPage = 1
        loadBeers(refresh: true)
    }
    
    private func loadBeers(refresh: Bool = false) {
        print("Fetching page \(currentPage)")
        isFetchingNextPage = true
        breweryDBClient.fetchBeers(page: currentPage, styleId: 3) { page in
            DispatchQueue.main.async {
                self.totalBeerCount = page.totalResults
                if refresh {
                    self.beers = page.data
                } else {
                    for beer in page.data {
                        if !self.beers.contains(beer) {
                            self.beers.append(beer)
                        }
                    }   
                }
                self.isFetchingNextPage = false
                
                if refresh {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                } else {
                    let startIndex = self.beers.count - page.data.count
                    let endIndex = startIndex + page.data.count - 1
                    let newIndexPaths = (startIndex...endIndex).map { i in
                        return IndexPath(row: i, section: 0)
                    }
                    let visibleIndexPaths = Set(self.tableView.indexPathsForVisibleRows ?? [])
                    let indexPathsNeedingReload = Set(newIndexPaths).intersection(visibleIndexPaths)
                    self.tableView.reloadRows(at: Array(indexPathsNeedingReload), with: .fade)
                }
                
                
            }
        }
    }
    
    private func fetchNextPage() {
        guard !isFetchingNextPage else { return }
        currentPage += 1
        loadBeers()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalBeerCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoadingIndexPath(indexPath) {
            return LoadingCell(style: .default, reuseIdentifier: "loading")
        } else {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BeerCell.self), for: indexPath) as! BeerCell
            let beer = beers[indexPath.row]
            
            cell.beerNameLabel.text = beer.name
            cell.breweryLabel.text = beer.breweries.first?.nameShortDisplay ?? "(unknown)"
            
            if let abv = beer.abv {
                cell.abvLabel.isHidden = false
                cell.abvLabel.text = "\(abv)%"
            } else {
                cell.abvLabel.isHidden = true
            }
            
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    
    private func isLoadingIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.beers.count
    }
}

extension BeerListViewController : UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("Prefetch rows at: \(indexPaths)")
        let needsFetch = indexPaths.contains { $0.row >= self.beers.count }
        if needsFetch {
            fetchNextPage()
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("Cancel prefetch for: \(indexPaths)")
    }
}
