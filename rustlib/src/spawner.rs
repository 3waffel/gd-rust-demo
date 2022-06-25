use gdnative::api::Node;
use gdnative::prelude::*;

pub enum AttackType {
    Trivial,
    Circle,
}

struct SpawnTask {
    spawn_interval: f32,
    spawn_number: u32,
}

impl Default for SpawnTask {
    fn default() -> Self {
        Self {
            spawn_interval: 5.,
            spawn_number: 3,
        }
    }
}

impl SpawnTask {
    fn activate(&self) {}
}

#[inherit(Node)]
#[derive(NativeClass)]
pub struct Spawner {
    tasks: Vec<SpawnTask>,
}

impl Default for Spawner {
    fn default() -> Self {
        Self {
            tasks: Vec::<SpawnTask>::new(),
        }
    }
}

#[methods]
impl Spawner {
    fn new(_owner: &Node) -> Self {
        Spawner::default()
    }
    #[export]
    fn _ready(&mut self, _owner: &Node) {}

    #[export]
    fn _process(&mut self, _owner: &Node, _delta: f32) {}

    fn spawn(&self, _owner: &Node, attack_type: AttackType) {
        match attack_type {
            AttackType::Trivial => {}
            AttackType::Circle => {}
        }
    }

    fn add_task(&mut self, task: SpawnTask) {
        self.tasks.push(task);
    }
}
