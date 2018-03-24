//
//  ListPostViewModel.swift
//  SimpleAppDemo
//
//  Created by Hiem Seyha on 3/20/18.
//  Copyright © 2018 seyha. All rights reserved.
//

import Foundation
import RxSwift
import Action

class ListPostViewModel {
  
  // MARK - Internal Access
  private let bag = DisposeBag()
  fileprivate var pagination = Observable<Pagination?>.just(nil)
  
  // MAKR: - Output
  var posts = Variable<[Post]>([])
  
  // MARK: - Input
  fileprivate let network: NetworkLayerType
  fileprivate let translation: TranslationLayerType
  
  // MARK: - Init
  init(network: NetworkLayerType, translation: TranslationLayerType) {
    self.network = network
    self.translation = translation
    
    loadData()
  }
  
  lazy var detailAction: Action<Post, Swift.Never> = {
    return Action { post in
      let detailViewModel = DetailViewModel(item: [post])
      return SceneCoordinator.transition(to: .detail(viewModel: detailViewModel), type: .push).asObservable()
    }
  }()
  
  func fetchMorePage() {
    
    self.pagination
      .map { return $0?.next_url }
      .filter { $0 != nil }
      .distinctUntilChanged { $0 == $1 }
      .map { value -> URLRequest in
        debugPrint("=============   URLRequest   =================")
        return URLRequest(url: value!)
      }
      .map { [weak self] urlRequest -> Observable<Data?> in
        guard let this = self else { Observable.just(nil) }
        return this.network.response(request: urlRequest)
        
//        guard let postvalue = newpost else { return Observable.just([])}
//        return postvalue
      }
    
      .filter { $0 != nil }
      .map { $0 }
     
//      .map {  [weak self] newpost in
//        guard let result = newpost else { return [] }
//        //            _ = result.map { self?.posts.value.append($0) }
//        self?.posts.value.append(contentsOf: result)
//        //            return (self?.posts.value)!
//    }
//      .map { [weak self] data  in
//
//        guard let result =  self?.responseJSON(with: data) else { return [] }
//        //            _ = result.map { self?.posts.value.append($0) }
//        self?.posts.value.append(contentsOf: result)
//    }
    
  }
  
  
  func loadData() {
    
    ReachabilityManager.shared.isConnected
      .subscribe(onNext: { value in
        if value { request() }
      }).disposed(by: bag)
    
    func request() {
      network.request()
        .asObservable()
        .map { [weak self] data  in
          guard let strongSelf = self else { return [] }
          return strongSelf.responseJSON(with: data)
        }
        .distinctUntilChanged()
        .catchErrorJustReturn([])
        .bind(to: self.posts)
        .disposed(by: bag)
    }
  }
  
}

//MARK: - Helper
extension ListPostViewModel {
  
  fileprivate func responseJSON(with data: Data?) -> [Post] {
    guard let responseData = data else { return [] }
    guard let result: ListPost = self.translation.decode(data: responseData) else { return [] }
    self.pagination = Observable.just(result.pagination)
    return result.data
  }
}


