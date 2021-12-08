/// Copyright (c) 2020 Razeware LLC
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
import ReSwift
import Combine

public typealias TransformClosure<StateT: Any, SelectedStateT: Equatable> = (ReSwift.Subscription<StateT>) -> ReSwift.Subscription<SelectedStateT>
public typealias ScopedTransformClosure<StateT: Any, SelectedStateT: Equatable> = (ReSwift.Subscription<StateT>) -> ReSwift.Subscription<ScopedState<SelectedStateT>>

extension Store where State: Equatable {

  public func publisher() -> AnyPublisher<State, Never> {
    return StatePublisher(store: self).eraseToAnyPublisher()
  }

  public func publisher<SelectedStateT>(transform: @escaping TransformClosure<State, SelectedStateT>) -> AnyPublisher<SelectedStateT, Never> {
    return FilteredStatePublisher(store: self,
                                  transform: transform).eraseToAnyPublisher()
  }

  public func publisher<SelectedStateT>(transform: @escaping ScopedTransformClosure<State, SelectedStateT>) -> AnyPublisher<SelectedStateT, Never> {
    return FilteredStatePublisher(store: self,
                                  scopedTransfofm: transform).eraseToAnyPublisher()
  }

  struct StatePublisher: Combine.Publisher {
    typealias Output = State
    typealias Failure = Never

    let store: Store<State>

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input  {
      let subscription = StateSubscription(subscriber: subscriber, store: store)
      subscriber.receive(subscription: subscription)
    }
  }

  struct FilteredStatePublisher<SelectedStateT: Equatable>: Combine.Publisher {
    typealias Output = SelectedStateT
    typealias Failure = Never

    let store: Store<State>
    let transform: TransformClosure<State, SelectedStateT>?
    let scopedTransform: ScopedTransformClosure<State, SelectedStateT>?

    init(store: Store<State>,
         transform: @escaping TransformClosure<State, SelectedStateT>) {
      self.store = store
      self.transform = transform
      self.scopedTransform = nil
    }

    init(store: Store<State>,
         scopedTransfofm: @escaping ScopedTransformClosure<State, SelectedStateT>) {
      self.store = store
      self.transform = nil
      self.scopedTransform = scopedTransfofm
    }

    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
      if let transform = self.transform  {
        let subscription = FilteredStateSubscription(subscriber: subscriber,
                                                     store: store,
                                                     transform: transform)
        subscriber.receive(subscription: subscription)
      } else if let scopedTransform = self.scopedTransform {
        let subscription = ScopedFilteredStateSubscription(subscriber: subscriber,
                                                           store: store,
                                                           scopedTransform: scopedTransform)
        subscriber.receive(subscription: subscription)
      }
    }
  }
}

private final class StateSubscription<S: Subscriber, StateT: Any>: Combine.Subscription, StoreSubscriber where S.Input == StateT {
  var requested: Subscribers.Demand = .none
  var subscriber: S?

  let store: Store<StateT>
  var subscribed = false

  init(subscriber: S, store: Store<StateT>) {
    self.subscriber = subscriber
    self.store = store
  }

  func cancel() {
    store.unsubscribe(self)
    subscriber = nil
  }

  func request(_ demand: Subscribers.Demand) {
    requested += demand

    if !subscribed, requested > .none {
      // Subscribe to ReSwift store
      store.subscribe(self)
      subscribed = true
    }
  }

  // ReSwift calls this method on state changes
  func newState(state: StateT) {
    guard requested > .none else {
      return
    }
    requested -= .max(1)

    // Forward ReSwift update to subscriber
    _ = subscriber?.receive(state)
  }
}

private final class FilteredStateSubscription
  <S: Subscriber, StateT: Any, SelectedStateT: Equatable>:
  Combine.Subscription, StoreSubscriber where S.Input == SelectedStateT {

  var requested: Subscribers.Demand = .none
  var subscriber: S?

  let store: Store<StateT>
  var subscribed = false
  let transform: TransformClosure<StateT, SelectedStateT>

  init(subscriber: S,
       store: Store<StateT>,
       transform: @escaping TransformClosure<StateT, SelectedStateT>) {
    self.subscriber = subscriber
    self.store = store
    self.transform = transform
  }

  func cancel() {
    store.unsubscribe(self)
    subscriber = nil
  }

  func request(_ demand: Subscribers.Demand) {
    requested += demand

    if !subscribed, requested > .none {
      // Subscribe to ReSwift store
      store.subscribe(self, transform: self.transform)
      subscribed = true
    }
  }

  // ReSwift calls this method on state changes
  func newState(state: SelectedStateT) {
    guard requested > .none else {
      return
    }
    requested -= .max(1)

    _ = subscriber?.receive(state)
  }
}

private final class ScopedFilteredStateSubscription<S: Subscriber, StateT: Any, SelectedStateT: Equatable>: Combine.Subscription, StoreSubscriber where S.Input == SelectedStateT {
  var requested: Subscribers.Demand = .none
  var subscriber: S?

  let store: Store<StateT>
  var subscribed = false
  let scopedTransform: ScopedTransformClosure<StateT, SelectedStateT>

  init(subscriber: S,
       store: Store<StateT>,
       scopedTransform: @escaping ScopedTransformClosure<StateT, SelectedStateT>) {
    self.subscriber = subscriber
    self.store = store
    self.scopedTransform = scopedTransform
  }

  func cancel() {
    store.unsubscribe(self)
    subscriber = nil
  }

  func request(_ demand: Subscribers.Demand) {
    requested += demand

    if !subscribed, requested > .none {
      // Subscribe to ReSwift store
      store.subscribe(self, transform: scopedTransform)
      subscribed = true
    }
  }

  // ReSwift calls this method on state changes
  func newState(state: ScopedState<SelectedStateT>) {
    guard requested > .none else {
      return
    }
    requested -= .max(1)

    switch state {
    case let .inScope(inScopeState):
      _ = subscriber?.receive(inScopeState)
    case .outOfScope:
      _ = subscriber?.receive(completion: .finished)
    }
  }
}
