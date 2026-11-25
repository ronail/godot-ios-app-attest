// Godot iOS plugin exposing Apple App Attest (DCAppAttestService) as the
// `AppAttest` engine singleton. Results arrive as signals on the main thread.
#pragma once

#include "core/object/class_db.h"

class AppAttest : public Object {
	GDCLASS(AppAttest, Object);

protected:
	static void _bind_methods();

public:
	static AppAttest *instance;

	/// True on iOS 14+ devices that support App Attest (false on simulators).
	bool is_supported();
	/// Generates a Secure Enclave key. Emits key_generated(key_id, error).
	void generate_key();
	/// Attests key_id with Apple. client_data_hash must be SHA-256 (32 bytes)
	/// of the server challenge. Emits key_attested(attestation, error).
	void attest_key(const String &p_key_id, const PackedByteArray &p_client_data_hash);
};

void app_attest_init();
void app_attest_deinit();
