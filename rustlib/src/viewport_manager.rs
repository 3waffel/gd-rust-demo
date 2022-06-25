use gdnative::api::*;
use gdnative::prelude::*;

#[inherit(ViewportContainer)]
#[derive(NativeClass)]
pub struct ViewportManager {
    viewport: Ref<Node>,
}

impl Default for ViewportManager {
    fn default() -> Self {
        Self {
            viewport: Node::new().into_shared(),
        }
    }
}

#[methods]
impl ViewportManager {
    fn new(_owner: &ViewportContainer) -> Self {
        ViewportManager::default()
    }
    #[export]
    fn _ready(&mut self, _owner: TRef<ViewportContainer>) {
        self.viewport = _owner
            .get_node("Viewport")
            .expect("Viewport does not exist.");

        let root_viewport = _owner.get_viewport().unwrap();
        let root_viewport = unsafe{ root_viewport.assume_safe()};
        
        _owner.set_size(root_viewport.size(), false);
        root_viewport
            .connect(
                "size_changed",
                _owner,
                "on_viewport_resized",
                VariantArray::new_shared(),
                0,
            )
            .unwrap();
    }

    #[export]
    fn _process(&mut self, _owner: &ViewportContainer, _delta: f32) {}

    #[export]
    fn on_viewport_resized(&self, _owner: &ViewportContainer) {
        let root_viewport = _owner.get_viewport().unwrap();
        let root_viewport = unsafe{ root_viewport.assume_safe()};
        
        _owner.set_size(root_viewport.size(), false);
    }
}
