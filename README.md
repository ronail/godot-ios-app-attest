# godot-ios-app-attest

Apple [App Attest](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
for Godot 4 iOS exports. About 60 lines of Objective-C++, one singleton, two signals.

It only does the device side: make a Secure Enclave key and get Apple's
attestation for it. **Your server must verify the attestation** (certificate
chain to Apple's App Attest root, nonce, app ID, counter). Without that, this
plugin proves nothing.

## Install

1. Build: `GODOT=/path/to/godot-source ./build.sh` (needs Xcode).
2. Copy `build/app_attest.xcframework` and `AppAttest.gdip` into `res://ios/plugins/`.
3. Export settings (iOS) → Plugins → tick **AppAttest**.
4. Add the App Attest entitlement (`com.apple.developer.devicecheck.appattest-environment` =
   `production`) to your provisioning profile / entitlements.

## Use

```gdscript
func attest(challenge: PackedByteArray) -> void:
	if not Engine.has_singleton("AppAttest"):
		return  # not iOS
	var aa := Engine.get_singleton("AppAttest")
	if not aa.is_supported():
		return  # simulator or old device: fall back to your weaker path

	aa.generate_key()
	var key: Array = await aa.key_generated          # [key_id, error]
	if key[1] != "":
		push_error(key[1]); return

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(challenge)
	aa.attest_key(key[0], ctx.finish())
	var res: Array = await aa.key_attested           # [attestation, error]
	if res[1] == "":
		send_to_server(key[0], Marshalls.raw_to_base64(res[0]))
```

Store `key_id` (e.g. Keychain or `user://`); generate a new key only if it is lost.

## API

| Member | Notes |
|---|---|
| `is_supported() -> bool` | iOS 14+, real device |
| `generate_key()` | emits `key_generated(key_id: String, error: String)` |
| `attest_key(key_id: String, client_data_hash: PackedByteArray)` | hash must be 32 bytes; emits `key_attested(attestation: PackedByteArray, error: String)` |

`error` is `""` on success. Signals fire on the main thread.

Not included: per-request assertions (`generateAssertion`). Open an issue if you need them.

## License

MIT
