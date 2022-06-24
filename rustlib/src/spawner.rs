use gdnative::api::Node;
use gdnative::prelude::*;

#[inherit(Node)]
#[derive(NativeClass)]
pub struct Spawner;

#[methods]
impl Spawner {
    fn new(_owner: &Node) -> Self {
        Spawner {}
    }
    #[export]
    fn _ready(&mut self, _owner: &Node) {
        godot_print!("Hello world!");
    }

    #[export]
    fn _process(&mut self, _owner: &Node, _delta: f32) {}
}
