//
//  pkgs.swift
//  PureKFD
//
//  Created by Lrdsnow on 8/21/23.
//

import Foundation
import SwiftUI

struct AppDetailView: View {
    let pkg: Package?
    let MisakaPkg: Content?
    let repo: Repo?
    let MisakaRepo: Repository?
    let picassoRepo: Bool
    @State private var contentIcon: UIImage? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    func picasso(pkg: Package, repo: Repo) {
        if let pkgURL = URL(string: (repo.url!.appendingPathComponent(pkg.path).absoluteString)) {
            if let iconURL = URL(string: (repo.url!.appendingPathComponent(pkg.icon).absoluteString)) {
                downloadAndExtractJSONFiles(from: pkgURL, icon: iconURL) { success in
                    if success {
                        alertTitle = "Success"
                        alertMessage = "Package \"\(pkg.name)\" was successfully downloaded and installed."
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to download and install package"
                    }
                    showAlert = true
                }
            }
        }
    }
    
    func misaka(pkg: Content, repo: Repository) {
        if let pkgURL = URL(string: pkg.Releases![0].Package) {
            if let iconURL = URL(string: pkg.Icon ?? "") {
                downloadPackage(from: pkgURL, icon: iconURL, pkg: pkg) { success in
                    if success {
                        alertTitle = "Success"
                        alertMessage = "Package \"\(pkg.Name)\" was successfully downloaded and installed."
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to download and install package"
                    }
                    showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 16) {
                    if let icon = contentIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pkg?.name ?? MisakaPkg?.Name ?? "Not Found")
                            .font(.title).bold()
                            .foregroundColor(.purple)
                        Text(pkg?.author ?? MisakaPkg?.Author?.Label ?? MisakaRepo?.RepositoryAuthor ?? "Unknown Author")
                            .font(.subheadline)
                            .foregroundColor(.purple.opacity(0.7))
                        if picassoRepo {
                            if isPackageInstalled(pkg: pkg!, repo: repo!) {
                                Text("Installed")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                                    .background(Color.purple.opacity(0.7))
                                    .cornerRadius(50)
                            } else {
                                Button(action: {
                                    picasso(pkg: pkg!, repo: repo!)
                                }) {
                                    Text("Install")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                        .background(Color.purple)
                                        .cornerRadius(50)
                                }
                            }
                        } else {
                                Button(action: {
                                    misaka(pkg: MisakaPkg!, repo: MisakaRepo!)
                                }) {
                                    Text("Install")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                        .background(Color.purple)
                                        .cornerRadius(50)
                                }
                            }
                        }
                    }
                    //.padding() // Add padding only to the VStack if needed
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    .onAppear {
                        if picassoRepo {
                            if let iconURL = URL(string: (repo?.url!.appendingPathComponent(pkg!.icon).absoluteString)!) {
                                fetchImage(from: iconURL) { result in
                                    switch result {
                                    case .success(let image):
                                        DispatchQueue.main.async {
                                            contentIcon = image // Update the fetched image
                                        }
                                    case .failure(let error):
                                        print("Error fetching image: \(error)")
                                    }
                                }
                            }
                        } else {
                            if let iconURL = URL(string: MisakaPkg!.Icon ?? "NoIcon") {
                                if iconURL != URL(string: "NoIcon") {
                                    fetchImage(from: iconURL) { result in
                                        switch result {
                                        case .success(let image):
                                            DispatchQueue.main.async {
                                                contentIcon = image // Update the fetched image
                                            }
                                        case .failure(let error):
                                            print("Error fetching image: \(error)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Text("Description").bold().padding(.vertical, 5).font(.title2).foregroundColor(.purple)
                Text(pkg?.description ?? MisakaPkg?.Caption ?? "No description found for this package").foregroundColor(.purple)
            }
        }
}

func convertToRepos(from repositories: [Repository]) -> [Repo] {
    var repoList: [Repo] = []
    
    for repository in repositories {
        if let url = repository.RepositoryURL {
            let repo = Repo(
                name: repository.RepositoryName,
                description: repository.RepositoryDescription,
                icon: repository.RepositoryIcon,
                packages: repository.RepositoryContents.map { content in
                    Package(
                        name: content.Name,
                        bundleid: content.PackageID ?? "",
                        author: content.Author?.Label ?? repository.RepositoryAuthor,
                        description: content.Caption,
                        version: content.PackageID ?? "",
                        icon: content.Icon ?? "",
                        path: "",
                        MisakaReleases: content.Releases,
                        MinIOSVersion: content.MinIOSVersion,
                        MaxIOSVersion: content.MaxIOSVersion,
                        type: "misaka"
                    )
                },
                url: url,
                type: "misaka"
            )
            repoList.append(repo)
        }
    }
    
    return repoList
}

func translatePackageToContent(package: Package) -> Content {
    var content = Content(
        Name: package.name,
        Description: package.description,
        Caption: nil,
        Icon: package.icon,
        Author: Author(Label: package.author, Links: nil),
        Releases: package.MisakaReleases, // You need to populate this array based on package.repo and package.version
        PackageID: package.id.uuidString,
        MinIOSVersion: nil, 
        MaxIOSVersion: nil
    )
    
    return content
}

func convertToRepositories(from repo: Repo) -> Repository? {
    if let url = repo.url {
        let repository = Repository(
            RepositoryName: repo.name,
            RepositoryDescription: repo.description,
            RepositoryAuthor: "",
            RepositoryIcon: repo.icon,
            RepositoryWebsite: "",
            RepositoryURL: url,
            RepositoryContents: repo.packages.map { package in
                Content(
                    Name: package.name,
                    Description: package.description,
                    Caption: package.description,
                    Icon: package.icon,
                    Author: Author(Label: package.author, Links: nil),
                    Releases: package.MisakaReleases,
                    PackageID: package.bundleid,
                    MinIOSVersion: package.MinIOSVersion,
                    MaxIOSVersion: package.MaxIOSVersion
                )
            }
        )
        return repository
    }
    return nil
}

struct PackageDetailView: View {
    let package: Package
    @State private var contentIcon: UIImage? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 16) {
                    if let icon = contentIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.purple)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(package.name)
                            .font(.title).bold()
                            .foregroundColor(.purple)
                        Text(package.author)
                            .font(.subheadline)
                            .foregroundColor(.purple.opacity(0.7))
                        Button(action: {
                            if package.type == "misaka" {
                                misaka(pkg: translatePackageToContent(package: package), repo: convertToRepositories(from: package.repo!)!)
                            } else {
                                picasso(pkg: package, repo: package.repo!)
                            }
                        }) {
                            Text("Install")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                                .background(Color.purple)
                                .cornerRadius(50)
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    .onAppear {
                        if package.type == "misaka" {
                            if let iconURL = URL(string: package.icon) {
                                fetchImage(from: iconURL) { result in
                                    switch result {
                                    case .success(let image):
                                        DispatchQueue.main.async {
                                            contentIcon = image
                                        }
                                    case .failure(let error):
                                        print("Error fetching image: \(error)")
                                    }
                                }
                            }
                        } else {
                            if let iconURL = URL(string: (package.repo?.url!.appendingPathComponent(package.icon).absoluteString)!) {
                                fetchImage(from: iconURL) { result in
                                    switch result {
                                    case .success(let image):
                                        DispatchQueue.main.async {
                                            contentIcon = image
                                        }
                                    case .failure(let error):
                                        print("Error fetching image: \(error)")
                                    }
                                }
                            }
                        }
                    }
                }
                Text("Description").bold().padding(.vertical, 5).font(.title2).foregroundColor(.purple)
                Text(package.description ?? "No description found for this package").foregroundColor(.purple)
            }
        }
    }

    func picasso(pkg: Package, repo: Repo) {
        if let pkgURL = URL(string: (repo.url!.appendingPathComponent(pkg.path).absoluteString)) {
            if let iconURL = URL(string: (repo.url!.appendingPathComponent(pkg.icon).absoluteString)) {
                downloadAndExtractJSONFiles(from: pkgURL, icon: iconURL) { success in
                    if success {
                        alertTitle = "Success"
                        alertMessage = "Package \"\(pkg.name)\" was successfully downloaded and installed."
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to download and install package"
                    }
                    showAlert = true
                }
            }
        }
    }
    
    func misaka(pkg: Content, repo: Repository) {
        if let pkgURL = URL(string: pkg.Releases![0].Package) {
            if let iconURL = URL(string: pkg.Icon ?? "") {
                downloadPackage(from: pkgURL, icon: iconURL, pkg: pkg) { success in
                    if success {
                        alertTitle = "Success"
                        alertMessage = "Package \"\(pkg.Name)\" was successfully downloaded and installed."
                    } else {
                        alertTitle = "Error"
                        alertMessage = "Failed to download and install package"
                    }
                    showAlert = true
                }
            }
        }
    }
}
