use gdnative::api::*;
use gdnative::prelude::*;

#[inherit(Spatial)]
#[derive(NativeClass)]
pub struct SceneTranslator {
    rotate_speed: f64,
}

impl Default for SceneTranslator {
    fn default() -> Self {
        Self { rotate_speed: 0.005 }
    }
}

#[methods]
impl SceneTranslator {
    fn new(_owner: &Spatial) -> Self {
        SceneTranslator::default()
    }
    #[export]
    fn _ready(&mut self, _owner: &Spatial) {}

    #[export]
    fn _process(&mut self, _owner: &Spatial, _delta: f32) {
        _owner.rotate(Vector3::RIGHT, self.rotate_speed);
    }
}
