## 0.0.3

* Adds dartdoc comments across the public API for a better pub.dev documentation score.
* Adds a `telebirr_setup` command to copy local SDK files and patch common host app setup.
* Adds Ethio Telecom developer portal onboarding and contract-status troubleshooting notes.
* Moves the successful setup steps to the top of the README.
* Removes the publishing checklist from the README.
* Replaces the README Mermaid diagram with a pub.dev-friendly SVG image.
* Adds curl examples and explains where developers enter app/backend payment values.
* Moves low-level native setup details to separate docs.

## 0.0.2

* Expands documentation for the package architecture and Telebirr InApp Purchase flow.
* Adds clearer backend responsibility notes for receiveCode, notify_url, and queryOrder.
* Documents what the package configures automatically and what remains app-specific.
* Updates publishing setup for GitHub Actions trusted publishing.

## 0.0.1

* Initial release.
* Adds typed payment request/result models.
* Adds Android MethodChannel and EventChannel integration with ActivityAware lifecycle handling.
* Adds iOS MethodChannel and EventChannel integration with manual EthiopiaPaySDK.framework setup support.
* Documents secure backend-only Fabric Token, createOrder, notify_url, and queryOrder flow.
