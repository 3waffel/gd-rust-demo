use gdnative::api::*;
use gdnative::prelude::*;

#[inherit(Node2D)]
#[derive(NativeClass)]
pub struct Enemy {
    health: f32,
    live_time: f64,
    live_timer: Ref<Node>,
}

impl Default for Enemy {
    fn default() -> Self {
        Self {
            health: 100.,
            live_time: 10.,
            live_timer: Node::new().into_shared(),
        }
    }
}

#[methods]
impl Enemy {
    fn new(_owner: &Node2D) -> Self {
        Enemy::default()
    }
    #[export]
    fn _ready(&mut self, _owner: TRef<Node2D>) {
        self.live_timer = _owner
            .get_node("Timer")
            .expect("Timer node does not exist.");
        let timer = unsafe { self.live_timer.assume_safe() };
        let timer = timer.cast::<Timer>().unwrap();
        timer
            .connect(
                "timeout",
                _owner,
                "queue_free",
                VariantArray::new_shared(),
                0,
            )
            .unwrap();
        timer.start(self.live_time);
    }

    #[export]
    fn _process(&mut self, _owner: &Node2D, _delta: f32) {
        if self.health <= 0. {
            _owner.queue_free();
        }
    }
}
