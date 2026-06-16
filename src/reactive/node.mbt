///|
pub(open) trait ReactiveNode {
  fn mark_stale(Self) -> Unit
  fn mark_pending(Self) -> Unit
  fn mark_all_pending(Self) -> Unit
  fn update_value(Self) -> Bool
}

///|
pub(all) enum ReactiveNodeState {
  Clean
  Pending
  Stale
} derive(Eq, Debug)
