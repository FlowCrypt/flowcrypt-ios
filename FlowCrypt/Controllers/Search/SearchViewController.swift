//
//  SearchViewController.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 3/18/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
import FlowCryptCommon
import FlowCryptUI
import UIKit

class SearchViewController: InboxViewController {

    private var searchTask: DispatchWorkItem?
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSearchUI()
        self.setupSearch()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }

    private func setupSearchUI() {
        view.backgroundColor = .backgroundColor
        view.accessibilityIdentifier = "aid-search-view-controller"

        title = "search_title".localized
        state = .searchStart
        setupTableNode()
    }

    private func setupSearch() {
        searchController.do {
            $0.delegate = self
            $0.searchResultsUpdater = self
            $0.hidesNavigationBarDuringPresentation = false
            $0.searchBar.tintColor = .white
            $0.searchBar.setImage(UIImage(systemName: "magnifyingglass")?.tinted(.white), for: .search, state: .normal)
            $0.searchBar.setImage(UIImage(systemName: "xmark")?.tinted(.white), for: .clear, state: .normal)
            $0.searchBar.delegate = self
            $0.searchBar.searchTextField.textColor = .white
        }
        update(searchController: searchController)
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }

    private func update(searchController: UISearchController) {
        searchController.searchBar.searchTextField.attributedPlaceholder = "search_placeholder"
            .localized
            .attributed(
                .regular(14),
                color: UIColor.white.withAlphaComponent(0.7),
                alignment: .left
            )
        searchController.searchBar.searchTextField.textColor = .white
        searchController.searchBar.searchTextField.accessibilityIdentifier = "aid-search-all-emails-field"
    }
}

// MARK: - UISearchControlelr Delegate
extension SearchViewController: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarSearchButtonClicked(_: UISearchBar) {
        guard let searchText = searchText(for: searchController.searchBar) else { return }
        searchTask?.cancel()
        search(for: searchText)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }

        update(searchController: searchController)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.text = searchedExpression
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive,
              let searchText = searchText(for: searchController.searchBar)
        else {
            searchTask?.cancel()
            return
        }

        guard searchedExpression != searchText else {
            return
        }

        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.search(for: searchText)
        }
        searchTask = task

        let throttleTime = 1.0
        DispatchQueue.main.asyncAfter(
            deadline: .now() + throttleTime,
            execute: task
        )
    }

    private func searchText(for searchBar: UISearchBar) -> String? {
        guard let text = searchBar.text else { return nil }
        if text.isEmpty {
            state = .searchStart
            tableNode.reloadData()
            return nil
        }
        return text
    }

    private func search(for searchText: String) {
        searchedExpression = searchText
        fetchAndRenderEmails(nil)
    }
}
