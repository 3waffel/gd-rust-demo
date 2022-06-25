use gdnative::api::Node2D;
use gdnative::prelude::*;

#[inherit(Node2D)]
#[derive(NativeClass)]
pub struct Bullet {
    live_time: f64,
    live_timer: Ref<Node>,
    move_speed: f32,
    move_type: MoveType,
    move_direction: Vector2,
}

pub enum MoveType {
    Straight,
}

impl Default for Bullet {
    fn default() -> Self {
        Self {
            live_time: 3.,
            live_timer: Node::new().into_shared(),
            move_speed: 10.,
            move_type: MoveType::Straight,
            move_direction: Vector2::UP,
        }
    }
}

#[methods]
impl Bullet {
    fn new(_owner: &Node2D) -> Self {
        Bullet::default()
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
        match self.move_type {
            MoveType::Straight => {
                _owner.translate(self.move_direction * self.move_speed);
            }
        }
    }

    pub fn modify(
        &mut self,
        live_time: f64,
        move_speed: f32,
        move_type: MoveType,
        move_direction: Vector2,
    ) {
        self.live_time = live_time;
        self.move_speed = move_speed;
        self.move_type = move_type;
        self.move_direction = move_direction;
    }
}
