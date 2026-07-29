//
//  ShareViewController.swift
//  SynoShareExtension
//

import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let rootView = ShareExtensionView(
      extensionItems: extensionContext?.inputItems as? [NSExtensionItem] ?? [],
      onFinish: { [weak self] in
        self?.extensionContext?.completeRequest(returningItems: nil)
      },
      onCancel: { [weak self] in
        self?.extensionContext?.cancelRequest(
          withError: NSError(domain: "com.synoteam.Syno.SynoShareExtension", code: 0)
        )
      }
    )

    let hosting = UIHostingController(rootView: rootView)
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    hosting.didMove(toParent: self)
  }
}
