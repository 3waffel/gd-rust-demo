mod bullet;
mod scene_translator;
mod enemy;
mod player;
mod spawner;
mod viewport_manager;
pub mod utils;
use gdnative::prelude::*;

fn init(handle: InitHandle) {
    handle.add_class::<spawner::Spawner>();
    handle.add_class::<scene_translator::SceneTranslator>();
    handle.add_class::<bullet::Bullet>();
    handle.add_class::<viewport_manager::ViewportManager>();
    handle.add_class::<enemy::Enemy>();
    handle.add_class::<player::Player>();
}

godot_init!(init);
