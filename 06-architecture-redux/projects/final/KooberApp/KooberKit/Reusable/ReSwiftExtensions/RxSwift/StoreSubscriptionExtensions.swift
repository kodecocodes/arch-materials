/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import RxSwift
import ReSwift

extension Store where State: Equatable {

  public func makeObservable() -> Observable<State> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<State>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxy<State>(rxObserver)
      self.subscribe(subscriberRxProxy)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }

  public func makeObservable<SelectedState>(transform: @escaping (Subscription<State>) -> Subscription<SelectedState>) -> Observable<SelectedState> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<SelectedState>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxy<SelectedState>(rxObserver)
      self.subscribe(subscriberRxProxy, transform: transform)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }

  public func makeObservable<SelectedState: Equatable>(transform: @escaping (Subscription<State>) -> Subscription<SelectedState>) -> Observable<SelectedState> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<SelectedState>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxy<SelectedState>(rxObserver)
      self.subscribe(subscriberRxProxy, transform: transform)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }

  public func makeObservable<SelectedState: Equatable>(transform: @escaping (Subscription<State>) -> Subscription<ScopedState<SelectedState>>) -> Observable<SelectedState> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<SelectedState>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxyScoped<SelectedState>(rxObserver)
      self.subscribe(subscriberRxProxy, transform: transform)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }
}

extension Store {

  public func makeObservable() -> Observable<State> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<State>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxy<State>(rxObserver)
      self.subscribe(subscriberRxProxy)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }

  public func makeObservable<SelectedState>(transform: @escaping (Subscription<State>) -> Subscription<SelectedState>) -> Observable<SelectedState> {
    // Make onRxSubscribe closure.
    let onRxSubscribe = { [weak self] (rxObserver: AnyObserver<SelectedState>) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      let subscriberRxProxy = StoreSubscriberRxProxy<SelectedState>(rxObserver)
      self.subscribe(subscriberRxProxy, transform: transform)

      let disposable = self.makeUnsubscribeDisposable(subscriber: subscriberRxProxy)
      return disposable
    }

    // Make and return observable.
    return Observable.create(onRxSubscribe)
  }

  private func makeUnsubscribeDisposable<S: StoreSubscriber>(subscriber: S) -> Disposable {
    return Disposables.create { [weak self] in
      self?.unsubscribe(subscriber)
    }
  }
}
