#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;

use serde::Serialize;
use rocket_contrib::json::Json;
use rand::prelude::*;
use base64;
use uuid::Uuid;
use std::sync::Mutex;
use std::collections::HashMap;
use rocket::State;

struct SharedState {
    challenges: Mutex<HashMap<Uuid, String>>
}

#[get("/")]
fn index() -> &'static str {
    "Hello, world!"
}

#[derive(Serialize)]
struct ChallengeResponse {
    c: String,
    id: Uuid
}

impl Default for ChallengeResponse {
    fn default() -> Self {
        let mut c = vec![0u8; 1024];
        rand::thread_rng().fill_bytes(&mut c);
        ChallengeResponse {
            c: base64::encode(c),
            id: Uuid::new_v4()
        }
    }
}

#[get("/challenge")]
fn get_challenge(challenges: State<SharedState>) -> Json<ChallengeResponse> {
    let c = ChallengeResponse::default();
    let mut lock = challenges.challenges.lock().expect("Lock challenges");
    lock.insert(c.id.clone(), c.c.clone());
    Json(c)
}

#[get("/challenges")]
fn get_challenges(challenges: State<SharedState>) -> Json<Vec<ChallengeResponse>> {
    let mut v = Vec::new();
    let lock = challenges.challenges.lock().expect("Lock challenges");
    for (id, c) in lock.iter() {
        let entry = ChallengeResponse {id: id.clone(), c: c.clone() };
        v.push(entry);
    }
    Json(v)
}

fn main() {
    rocket::ignite()
        .mount("/", routes![index, get_challenge, get_challenges])
        .manage(SharedState { challenges: Mutex::new(HashMap::new()) } )
        .launch();
}

