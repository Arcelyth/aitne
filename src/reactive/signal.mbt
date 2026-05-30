let next_effect_id : Ref[Int] = { val: 0 }

let current_effect : Ref[Option[Subscriber]] = { val: None }

struct Subscriber {
  id : Int
  run : () -> Unit
}

pub struct Signal[T] {
  mut value: T
  subs: Array[Subscriber]
}

pub fn[T] Signal::new(value: T) -> Signal[T] {
  { value, subs: [] }
}

pub fn[T] Signal::set(self: Signal[T], new_val: T) -> Unit {
  self.value = new_val
  let copys = self.subs.copy()
  for sub in copys {
    (sub.run)()
  }
}

pub fn[T] Signal::get(self : Signal[T]) -> T {
  match current_effect.val {
    Some(active_sub) => {
      let mut exists = false
      for sub in self.subs {
        if sub.id == active_sub.id {
          exists = true
          break
        }
      }
      if exists == false {
        self.subs.push(active_sub)
      }
    }
    None => ()
  }
  self.value
}

pub fn[T] Signal::update(self : Signal[T], f : (T) -> T) -> Unit {
  self.set(f(self.value))
}

pub fn create_effect(f : () -> Unit) -> Unit {
  let id = next_effect_id.val
  next_effect_id.val = id + 1
  let sub_ref : Ref[Option[Subscriber]] = { val: None }

  let wrapper = fn() {
    let prev = current_effect.val
    current_effect.val = sub_ref.val
    f()
    current_effect.val = prev
  }

  sub_ref.val = Some({ id, run: wrapper })
  wrapper()
}

pub struct Memo[T] {
  inner : Signal[T]
}

pub fn[T] Memo::new(compute : () -> T) -> Memo[T] {
  let sig = Signal::new(compute())
  create_effect(fn() {
    sig.set(compute())
  })
  { inner: sig }
}

pub fn[T] Memo::get(self : Memo[T]) -> T {
  self.inner.get()
}
