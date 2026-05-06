# Publishing

## GitHub

Create the public repository:

```sh
gh auth login
gh repo create Dream-Technologies-PLC/telebirr_inapp_purchase_plus --public --source=. --remote=origin --push
```

If the repository already exists:

```sh
git remote add origin https://github.com/Dream-Technologies-PLC/telebirr_inapp_purchase_plus.git
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

## GitHub Actions Publishing

First publish version `0.0.1` manually from your machine:

```sh
dart pub login
dart pub publish
```

After the first version exists, enable automated publishing in pub.dev:

1. Open `https://pub.dev/packages/telebirr_inapp_purchase_plus/admin`.
2. Find **Automated publishing**.
3. Choose **Enable publishing from GitHub Actions**.
4. Repository: `Dream-Technologies-PLC/telebirr_inapp_purchase_plus`.
5. Tag pattern: `v{{version}}`.

For the next release:

```sh
git tag v0.0.2
git push origin v0.0.2
```

The GitHub workflow publishes the package when the tag version matches
`pubspec.yaml`.

## Before A Release

- Remove all merchant credentials from examples and docs.
- Do not commit private keys.
- Do not commit Telebirr SDK binaries unless you have redistribution rights.
- Verify a real Android or iOS device payment in testbed.
