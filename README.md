[![codecov](https://codecov.io/gh/CruGlobal/oauth-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/CruGlobal/oauth-ios)

OAuth
=====

This module implements OAuth with a PKCE flow and ASWebAuthenticationSession.  It is configurable for authorizing, fetching access and refresh tokens, and persisting tokens to the device keychain.

- [Publishing New Versions With GitHub Actions](#publishing-new-versions-with-github-actions)
- [Publishing New Versions Manually](#publishing-new-versions-manually)

### Publishing New Versions With GitHub Actions

Publishing new versions with GitHub Actions is easy.

- Ensure you set a new version in OAuth.podspec.  The new version can't already exist as a tag.
- Create a pull request on main and once merged into main GitHub actions will handle tagging the version and pushing to the CruGlobal specs repo.

### Publishing New Versions Manually

Steps to publish new versions for Cocoapods and Swift Package Manager. 

- Edit OAuth.podspec s.version to the newly desired version following Major.Minor.Patch.

- Run command 'pod lib lint OAuth.podspec --private --verbose --sources=https://github.com/CruGlobal/cocoapods-specs.git,https://cdn.cocoapods.org/' to ensure it can deploy without any issues (https://guides.cocoapods.org/making/using-pod-lib-create.html#deploying-your-library).

- Merge the s.version change into the main branch and then tag the main branch with the new version and push the tag to remote (Swift Package Manager relies on tags).  

- Run command 'pod repo push cruglobal-cocoapods-specs --private --verbose --sources=https://github.com/CruGlobal/cocoapods-specs.git,https://cdn.cocoapods.org/' to push to CruGlobal cocoapods specs (https://github.com/CruGlobal/cocoapods-specs).  You can also run command 'pod repo list' to see what repos are currently added and 'pod repo add cruglobal-cocoapods-specs https://github.com/CruGlobal/cocoapods-specs.git' to add repos (https://guides.cocoapods.org/making/private-cocoapods.html).


Cru Global Specs Repo: https://github.com/CruGlobal/cocoapods-specs

Private Cocoapods: https://guides.cocoapods.org/making/private-cocoapods.html
