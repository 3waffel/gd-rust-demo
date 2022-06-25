use gdnative::api::*;
use gdnative::prelude::*;

use crate::bullet::*;
use crate::utils::*;

#[inherit(KinematicBody2D)]
#[derive(NativeClass)]
pub struct Player {
    move_speed: f32,
    input_vector: Vector2,
    bullet_scene_load: Ref<PackedScene>,
    shoot_interval: f32,
    interval_sum: f32,
    can_shoot: bool,
}

impl Default for Player {
    fn default() -> Self {
        Self {
            move_speed: 7.,
            input_vector: Vector2::ZERO,
            bullet_scene_load: PackedScene::new().into_shared(),
            shoot_interval: 0.3,
            interval_sum: 0.,
            can_shoot: true,
        }
    }
}

#[methods]
impl Player {
    fn new(_owner: &KinematicBody2D) -> Self {
        Player::default()
    }
    #[export]
    fn _ready(&mut self, _owner: &KinematicBody2D) {
        let bullet_scene_load = load_scene("res://Scenes/Bullet.tscn");
        match bullet_scene_load {
            Some(_scene) => self.bullet_scene_load = _scene,
            None => godot_print!("Can't load bullet scene."),
        }
    }

    #[export]
    fn _process(&mut self, _owner: &KinematicBody2D, _delta: f32) {
        if !self.can_shoot {
            if self.interval_sum >= self.shoot_interval {
                self.can_shoot = true;
                self.interval_sum = 0.;
            }
            self.interval_sum += _delta;
        }
    }

    #[export]
    fn _physics_process(&mut self, _owner: &KinematicBody2D, _delta: f32) {
        let input = Input::godot_singleton();
        self.input_vector = Vector2::ZERO;
        self.input_vector.x = (Input::is_action_pressed(input, "ui_right", false) as i32
            - Input::is_action_pressed(input, "ui_left", false) as i32)
            as f32;
        self.input_vector.y = (Input::is_action_pressed(input, "ui_down", false) as i32
            - Input::is_action_pressed(input, "ui_up", false) as i32)
            as f32;
        if Input::is_action_pressed(input, "shoot", false) {
            if self.can_shoot {
                self.shoot(_owner, Vector2::UP);
                self.can_shoot = false;
            }
        }

        if self.input_vector != Vector2::ZERO {
            self.input_vector = self.input_vector.normalized();
            _owner.translate(self.input_vector * self.move_speed);
        }
    }

    fn shoot(&self, _owner: &KinematicBody2D, direction: Vector2) {
        let bullet = unsafe { self.bullet_scene_load.assume_safe() };
        let bullet = bullet
            .instance(PackedScene::GEN_EDIT_STATE_DISABLED)
            .expect("Can't instance bullet.");

        let parent = _owner.get_parent().unwrap();
        let parent = unsafe { parent.assume_safe() };
        parent.add_child(bullet, false);

        let bullet = bullet.to_variant();
        let bullet = bullet
            .try_to_object::<Node2D>()
            .expect("Should cast to Node2D");
        let bullet = unsafe { bullet.assume_safe() };

        bullet.set_global_position(_owner.global_position());
    }
}
