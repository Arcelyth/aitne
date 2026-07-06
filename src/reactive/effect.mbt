///|
let effect_id_counter : Ref[UInt] = @ref.new(0)

///|
fn next_effect_id() -> UInt {
  let id = effect_id_counter.val
  effect_id_counter.val = id + 1
  id
}

///|
pub struct EffectInner[T] {
  id : UInt
  mut stale : Bool
  cb : (T?) -> T
  mut sources : HashSet[ASource]
  mut schedule : (() -> Unit)?
}

///|
pub fn[T] EffectInner::new(cb : (T?) -> T) -> EffectInner[T] {
  EffectInner::{
    id: next_effect_id(),
    stale: false,
    cb,
    sources: HashSet([]),
    schedule: None,
  }
}

///|
pub impl[T] ReactiveNode for Ref[EffectInner[T]] with fn mark_stale(self) {
  self.val.stale = true
  match self.val.schedule {
    Some(run) => run()
    None => ()
  }
}

///|
#inline
pub impl[T] ReactiveNode for Ref[EffectInner[T]] with fn mark_pending(_self) {

}

///|
pub impl[T] ReactiveNode for Ref[EffectInner[T]] with fn mark_all_pending(self) {
  ReactiveNode::mark_stale(self)
}

///|
#inline
pub impl[T] ReactiveNode for Ref[EffectInner[T]] with fn update_value(self) {
  if self.val.stale {
    self.val.stale = false
    return true
  }
  self.val.sources.iter().any(s => s.update_value())
}

///|
pub impl[T] Subscriber for Ref[EffectInner[T]] with fn add_source(
  self,
  source : ASource,
) -> Unit {
  self.val.sources.add(source)
}

///|
pub impl[T] ToASubscriber for Ref[EffectInner[T]] with fn to_asubscriber(self) {
  { id: self.val.id, sub: Some(self as &Subscriber) }
}

///|
pub impl[T] Subscriber for Ref[EffectInner[T]] with fn clean_sources(
  self,
  subscriber : ASubscriber,
) -> Unit {
  for source in self.val.sources {
    source.remove_sub(subscriber)
  }
  self.val.sources = HashSet([])
}

///|
pub struct RenderEffect[T] {
  mut value : T?
  inner : Ref[EffectInner[T]]
  owner : Ref[Owner]
}

///|
pub fn[T] RenderEffect::new(fun : (T?) -> T) -> Ref[RenderEffect[T]] {
  RenderEffect::new_with_value(fun, None)
}

///|
pub fn[T] RenderEffect::new_with_value(
  fun : (T?) -> T,
  init_val : T?,
) -> Ref[RenderEffect[T]] {
  let owner = Owner::new()
  let inner = Ref(EffectInner::new(fun))
  let sub = ToASubscriber::to_asubscriber(inner)
  let value = Some(
    owner.with_(() => Observer::with_replace(Some(sub), () => fun(init_val))),
  )
  let e = RenderEffect::{ value, inner, owner: Ref(owner) }
  let ref_e = Ref(e)

  inner.val.schedule = Some(() => schedule_effect(ref_e as &EffectRunner))
  ref_e
}

///|
pub fn[T] RenderEffect::new_isomorphic(fun : (T?) -> T) -> Ref[RenderEffect[T]] {
  let owner = Owner::new()
  let inner = Ref(EffectInner::new(fun))
  let sub = ToASubscriber::to_asubscriber(inner)
  let value = Some(
    owner.with_(() => Observer::with_replace(Some(sub), () => fun(None))),
  )

  let e = RenderEffect::{ value, inner, owner: Ref(owner) }
  let ref_e = Ref(e)

  inner.val.schedule = Some(() => schedule_effect(ref_e as &EffectRunner))
  ref_e
}

///|
#inline
pub fn[T] RenderEffect::take_value(self : RenderEffect[T]) -> T? {
  let v = self.value
  self.value = None
  v
}

///|
pub fn[T] RenderEffect::run(effect : RenderEffect[T]) -> Unit {
  let inner = effect.inner

  inner.val.stale = false

  let sub : ASubscriber = { id: inner.val.id, sub: Some(inner as &Subscriber) }

  let subscriber_trait = inner as &Subscriber
  subscriber_trait.clean_sources(sub)
  effect.owner.val.with_cleanup(() => {
    Observer::with_replace(Some(sub), fn() {
      let next_value = (inner.val.cb)(effect.value)

      effect.value = Some(next_value)
    })
  })
}

///|
pub fn[T] Effect::run(effect : Effect[T]) -> Unit {
  let e = effect
  let inner = e.inner

  inner.val.stale = false

  let sub : ASubscriber = { id: inner.val.id, sub: Some(inner as &Subscriber) }

  let subscriber_trait = inner as &Subscriber
  subscriber_trait.clean_sources(sub)
  e.owner.val.with_cleanup(() => {
    Observer::with_replace(Some(sub), fn() { let _ = (inner.val.cb)(None) })
  })
}

///|
pub struct Effect[T] {
  inner : Ref[EffectInner[T]]
  owner : Ref[Owner]
}

///|
pub fn[T] Effect::new(cb : (T?) -> T) -> Effect[T] {
  let inner = Ref(EffectInner::new(cb))
  let owner = Ref(Owner::new())
  let e = Effect::{ inner, owner }
  let ref_e = Ref(e)
  inner.val.schedule = Some(() => schedule_effect(ref_e as &EffectRunner))
  schedule_effect(ref_e as &EffectRunner)
  e
}

///|
pub trait EffectRunner {
  fn get_id(Self) -> UInt
  fn run_effect(Self) -> Unit
}

///|
pub impl[T : EffectRunner] EffectRunner for Ref[T] with fn get_id(self) -> UInt {
  self.val.get_id()
}

///|
pub impl[T : EffectRunner] EffectRunner for Ref[T] with fn run_effect(self) -> Unit {
  self.val.run_effect()
}

///|
pub impl[T] EffectRunner for Effect[T] with fn get_id(self) -> UInt {
  self.inner.val.id
}

///|
pub impl[T] EffectRunner for Effect[T] with fn run_effect(self) -> Unit {
  Effect::run(self)
}

///|
pub impl[T] EffectRunner for RenderEffect[T] with fn get_id(self) -> UInt {
  self.inner.val.id
}

///|
pub impl[T] EffectRunner for RenderEffect[T] with fn run_effect(self) -> Unit {
  RenderEffect::run(self)
}
