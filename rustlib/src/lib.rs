mod spawner;
use gdnative::prelude::*;

fn init(handle: InitHandle) {
    handle.add_class::<spawner::Spawner>();
}

godot_init!(init);
