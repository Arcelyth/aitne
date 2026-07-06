///|
using @hashmap {type HashMap}

///|
using @hashset {type HashSet}

///|
/// A reactive, keyed dynamic list.
///
/// Renders each item in the collection, diffing by key across
/// updates so that DOM nodes are reused / moved rather than
/// re-created from scratch.  Anchored between two comment
/// markers so that the surrounding DOM structure is never
/// disturbed.
pub struct ForNode[T, K] {
  each : () -> Array[T]
  key : (T) -> K
  render : (T) -> &View
}

///|
/// Create a keyed dynamic list node.
pub fn[T, K : Hash + Eq] for_node(
  each : () -> Array[T],
  key : (T) -> K,
  render : (T) -> &View,
) -> &View {
  ForNode::{ each, key, render }
}

///|
pub impl[T, K : Hash + Eq] Render for ForNode[T, K] with fn build(self) -> RenderState {
  let start = @ffi.dom_create_comment("for-start")
  let end = @ffi.dom_create_comment("for-end")

  // Extract fields so closures can capture them.
  let each = self.each
  let key_fn = self.key
  let render_fn = self.render

  // Track rendered nodes per key so we can reuse them.
  let cache : Ref[HashMap[K, Array[@ffi.Node]]] = @ref.new(HashMap([]))
  // Whether the initial render has already happened.
  let mounted : Ref[Bool] = @ref.new(false)
  // Parent and end-anchor refs set during init / reconciliation.
  let parent_ref : Ref[@ffi.Node?] = @ref.new(None)
  let end_ref : Ref[@ffi.Node] = @ref.new(end)

  let do_reconcile = fn(_) {
    let items = each()
    guard mounted.val else { return }
    let parent = match parent_ref.val {
      Some(p) => p
      None => return
    }
    let old_cache = cache.val

    // Build new cache and track which old nodes were reused.
    let new_cache : HashMap[K, Array[@ffi.Node]] = HashMap([])
    let used_old_keys : HashSet[K] = HashSet([])

    for item in items {
      let k = key_fn(item)
      match old_cache.get(k) {
        Some(old_nodes) => {
          used_old_keys.add(k)
          new_cache[k] = old_nodes

          // Make sure they are positioned correctly
          if old_nodes.length() > 0 {
            let first = old_nodes[0]
            let first_parent = @ffi.dom_parent(first)
            if !@ffi.dom_is_null(first_parent) &&
              @ffi.prim_node_eq(first_parent, parent) {
              @ffi.dom_insert_before(parent, first, end_ref.val)
            } else {
              @ffi.dom_insert_before(parent, first, end_ref.val)
            }
          }
        }
        None => {
          let child_view = render_fn(item)
          let child_state = child_view.build()
          child_state.mount(parent, end_ref.val)
          let nodes = child_state.elements()
          new_cache[k] = nodes
        }
      }
    }

    // Remove old nodes that are no longer in the data.
    for old_k in old_cache.keys() {
      guard !used_old_keys.contains(old_k) else { continue }
      match old_cache.get(old_k) {
        Some(old_nodes) =>
          for n in old_nodes {
            let n_parent = @ffi.dom_parent(n)
            if !@ffi.dom_is_null(n_parent) &&
              @ffi.prim_node_eq(n_parent, parent) {
              @ffi.dom_remove(n)
            }
          }
        None => ()
      }
    }

    cache.val = new_cache
  }

  // Create the reconciliation effect.
  // First run is a no-op (init handles initial render).
  let _ = @reactive.Effect::new(do_reconcile)

  let init = fn(parent : @ffi.Node) {
    parent_ref.val = Some(parent)

    let items = each()
    let init_cache : HashMap[K, Array[@ffi.Node]] = HashMap([])

    for item in items {
      let k = key_fn(item)
      let child_view = render_fn(item)
      let child_state = child_view.build()
      child_state.mount(parent, end_ref.val)
      let nodes = child_state.elements()
      init_cache[k] = nodes
    }

    cache.val = init_cache
    mounted.val = true
  }

  RenderState::MultiBlock(MultiBlockState::{
    start_anchor: start,
    end_anchor: end,
    init: Some(init),
    cleanup: None,
  })
}

///|
pub impl[T, K : Hash + Eq] Render for ForNode[T, K] with fn rebuild(
  _self,
  _state : Ref[RenderState],
) -> Unit {
  // ForNode is reactive — updates happen through the effect,
  // not through rebuild.
}

///|
pub impl[T, K : Hash + Eq] RenderHtml for ForNode[T, K] with fn html_len(self) -> Int {
  let mut len = 0
  let items = (self.each)()
  for item in items {
    len += (self.render)(item).html_len()
  }
  len
}

///|
pub impl[T, K : Hash + Eq] RenderHtml for ForNode[T, K] with fn to_html_with_buf(
  self,
  buf,
  pos,
) -> Unit {
  let items = (self.each)()
  for item in items {
    (self.render)(item).to_html_with_buf(buf, pos)
  }
}

///|
/// ForNode (dynamic list) implements View.
pub impl[T, K : Hash + Eq] View for ForNode[T, K] with fn style(self, _s) -> &View {
  self
}
