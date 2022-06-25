#![allow(dead_code)]

use gdnative::api::*;
use gdnative::prelude::*;

pub fn load_scene(path: &str) -> Option<Ref<PackedScene, Shared>> {
    let scene = ResourceLoader::godot_singleton().load(path, "PackedScene", false)?;
    let scene = unsafe { scene.assume_unique().into_shared()};
    scene.cast::<PackedScene>()
}