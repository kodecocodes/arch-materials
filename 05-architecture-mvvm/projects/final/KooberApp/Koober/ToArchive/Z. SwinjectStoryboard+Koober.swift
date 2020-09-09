/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SwinjectStoryboard
import Swinject
import KooberKit

func makeSwinjectContainer(userSession: UserSession) -> Container {
  let container = Container()

  let assembler = Assembler(container: container)
  assembler.apply(assembly: KooberKitAssembly(userSession: userSession))

  // Register services provided by KooberKit

  // Register ImageCache implementation
  container.register(ImageCache.self) { r in
    return ImageCacheKingfisher()
    }.inObjectScope(.container)

  // RequestRideContainerViewController
  container.storyboardInitCompleted(RequestRideContainerViewController.self, initCompleted: { r, c in })

  // SelectPickupAndDropoffViewController
  container.storyboardInitCompleted(SelectPickupAndDropoffViewController.self, initCompleted: { r, c in })

  // MapViewController
  container.storyboardInitCompleted(MapViewController.self, initCompleted: { r, c in
    c.imageCache = r.resolve(ImageCache.self)!
    c.startSelectPickupLocationUseCase = { locationID in
      let useCase = r.resolve(SelectPickupLocationUseCase.self, argument: locationID)!
      useCase.start()
      return useCase
    }
    c.startSelectDropoffLocationUseCase = { locationID in
      let useCase = r.resolve(SelectDropoffLocationUseCase.self, argument: locationID)!
      useCase.start()
      return useCase
    }
  })

  // RideOptionSelectionViewController
  container.storyboardInitCompleted(RideOptionSelectionViewController.self, initCompleted: { r, c in
    c.imageCache = r.resolve(ImageCache.self)!

    // Inject use case factory closures here.
    c.makeRefreshRideOptionSegmentsUseCase = {
      return r.resolve(RefreshRideOptionsUseCase.self)!
    }
    c.makeSelectRideOptionUseCase = { rideOptionID in
      return r.resolve(SelectRideOptionUseCase.self, argument: rideOptionID)!
    }
  })

  return container
}
