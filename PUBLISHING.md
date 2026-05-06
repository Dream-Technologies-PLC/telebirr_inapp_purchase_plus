# Publishing

## GitHub

Create the public repository:

```sh
gh auth login
gh repo create ebakebede/telebirr_inapp_purchase_plus --public --source=. --remote=origin --push
```

If the repository already exists:

```sh
git remote add origin git@github.com:ebakebede/telebirr_inapp_purchase_plus.git
git push -u origin main
```

## pub.dev

Run locally first:

```sh
flutter pub get
flutter analyze
flutter test
dart pub publish --dry-run
```

Then publish:

```sh
dart pub publish
```

For GitHub Actions publishing, configure trusted publishing for this package on
pub.dev and use the `Publish to pub.dev` workflow.

## Before A Release

- Remove all merchant credentials from examples and docs.
- Do not commit private keys.
- Do not commit Telebirr SDK binaries unless you have redistribution rights.
- Verify a real Android or iOS device payment in testbed.
