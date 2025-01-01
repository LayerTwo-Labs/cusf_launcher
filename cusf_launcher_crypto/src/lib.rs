use bitcoin_hashes::{hmac, ripemd160, sha512, Hash as _, HashEngine};
use godot::{builtin::PackedByteArray, prelude::{gdextension, godot_api, ExtensionLibrary, GodotClass}};

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}

#[derive(GodotClass)]
#[class(init)]
struct Ripemd160;

#[godot_api]
impl Ripemd160 {
    #[func]
    fn digest(msg: PackedByteArray) -> PackedByteArray {
        let digest = ripemd160::Hash::hash(msg.as_slice());
        digest.to_byte_array().into()
    }
}

#[derive(GodotClass)]
#[class(init)]
struct HmacSha512;

#[godot_api]
impl HmacSha512 {
    #[func]
    fn hmac(key: PackedByteArray, msg: PackedByteArray) -> PackedByteArray {
        let mut engine = hmac::HmacEngine::<sha512::Hash>::new(key.as_slice());
        engine.input(msg.as_slice());
        let hmac = hmac::Hmac::<sha512::Hash>::from_engine(engine);
        hmac.to_byte_array().into()
    }
}