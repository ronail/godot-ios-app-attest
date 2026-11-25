#import <DeviceCheck/DeviceCheck.h>

#include "app_attest.h"
#include "core/config/engine.h"

AppAttest *AppAttest::instance = nullptr;

static String to_str(NSString *s) {
	return s ? String::utf8([s UTF8String]) : String();
}

void AppAttest::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_supported"), &AppAttest::is_supported);
	ClassDB::bind_method(D_METHOD("generate_key"), &AppAttest::generate_key);
	ClassDB::bind_method(D_METHOD("attest_key", "key_id", "client_data_hash"), &AppAttest::attest_key);
	ADD_SIGNAL(MethodInfo("key_generated", PropertyInfo(Variant::STRING, "key_id"), PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("key_attested", PropertyInfo(Variant::PACKED_BYTE_ARRAY, "attestation"), PropertyInfo(Variant::STRING, "error")));
}

bool AppAttest::is_supported() {
	if (@available(iOS 14.0, *)) {
		return DCAppAttestService.sharedService.isSupported;
	}
	return false;
}

void AppAttest::generate_key() {
	if (!is_supported()) {
		call_deferred("emit_signal", "key_generated", String(), String("unsupported"));
		return;
	}
	if (@available(iOS 14.0, *)) {
		[DCAppAttestService.sharedService generateKeyWithCompletionHandler:^(NSString *key_id, NSError *error) {
			// Completion runs on a background queue; hop to the main thread.
			instance->call_deferred("emit_signal", "key_generated", to_str(key_id), to_str(error.localizedDescription));
		}];
	}
}

void AppAttest::attest_key(const String &p_key_id, const PackedByteArray &p_client_data_hash) {
	if (!is_supported() || p_client_data_hash.size() != 32) {
		call_deferred("emit_signal", "key_attested", PackedByteArray(), String(is_supported() ? "client_data_hash must be 32 bytes" : "unsupported"));
		return;
	}
	if (@available(iOS 14.0, *)) {
		NSString *key_id = [NSString stringWithUTF8String:p_key_id.utf8().get_data()];
		NSData *hash = [NSData dataWithBytes:p_client_data_hash.ptr() length:p_client_data_hash.size()];
		[DCAppAttestService.sharedService attestKey:key_id clientDataHash:hash completionHandler:^(NSData *attestation, NSError *error) {
			PackedByteArray out;
			if (attestation) {
				out.resize(attestation.length);
				memcpy(out.ptrw(), attestation.bytes, attestation.length);
			}
			instance->call_deferred("emit_signal", "key_attested", out, to_str(error.localizedDescription));
		}];
	}
}

void app_attest_init() {
	AppAttest::instance = memnew(AppAttest);
	Engine::get_singleton()->add_singleton(Engine::Singleton("AppAttest", AppAttest::instance));
}

void app_attest_deinit() {
	if (AppAttest::instance) {
		memdelete(AppAttest::instance);
		AppAttest::instance = nullptr;
	}
}
