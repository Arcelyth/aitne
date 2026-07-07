///|
/// Global scheduler used to batch, deduplicate, and flush pending effects.
pub struct Scheduler {
  mut pending : Array[&EffectRunner]
  queued : @hashset.HashSet[UInt]
  mut flushing : Bool
  mut batch_depth : Int
}

///|
/// Global scheduler instance.
pub let scheduler : Ref[Scheduler] = @ref.new(Scheduler::{
  pending: [],
  queued: @hashset.HashSet([]),
  flushing: false,
  batch_depth: 0,
})

///|
/// Schedule an effect for execution.
/// The same effect will only be queued once per flush cycle.
pub fn schedule_effect(effect : &EffectRunner) -> Unit {
  guard !scheduler.val.queued.contains(effect.get_id()) else { return }

  scheduler.val.queued.add(effect.get_id())
  scheduler.val.pending.push(effect)

  guard scheduler.val.batch_depth == 0 && !scheduler.val.flushing else {
    return
  }
  flush_scheduler()
}

///|
/// Flush all pending effects.
/// Effects scheduled during a flush are deferred to the next flush round.
/// `flush_count` is used to prevent infinite loops caused by circular dependencies.
pub fn flush_scheduler() -> Unit {
  guard !scheduler.val.flushing else { return }

  scheduler.val.flushing = true

  let mut flush_count = 0

  while scheduler.val.pending.length() > 0 {
    if flush_count > 1000 {
      panic()
    }
    flush_count = flush_count + 1

    let current_pending = scheduler.val.pending
    scheduler.val.pending = []

    let mut i = 0
    while i < current_pending.length() {
      let effect = current_pending[i]

      scheduler.val.queued.remove(effect.get_id())
      //      Effect::run(effect)
      effect.run_effect()

      i = i + 1
    }
  }

  scheduler.val.flushing = false
}

///|
/// Execute multiple updates as a single batch.
/// Effects are deferred until the outermost batch completes.
pub fn batch(f : () -> Unit) -> Unit {
  scheduler.val.batch_depth = scheduler.val.batch_depth + 1
  f()
  scheduler.val.batch_depth = scheduler.val.batch_depth - 1
  guard scheduler.val.batch_depth == 0 else { return }
  flush_scheduler()
}
