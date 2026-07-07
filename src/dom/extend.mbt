///|
/// A reactive, keyed dynamic list.
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

  let each = self.each
  let key_fn = self.key
  let render_fn = self.render

  let cache : Ref[@hashmap.HashMap[K, RenderState]] = @ref.new(HashMap([]))
  let mounted : Ref[Bool] = @ref.new(false)
  let parent_ref : Ref[@ffi.Node?] = @ref.new(None)

  let do_reconcile = fn(_) {
    let items = each()
    guard mounted.val else { return }
    let parent = match parent_ref.val {
      Some(p) => p
      None => return
    }
    let old_cache = cache.val

    let new_cache : @hashmap.HashMap[K, RenderState] = HashMap([])
    let used_old_keys : @hashset.HashSet[K] = HashSet([])

    let mut current_node_opt = dom_next_sibling(start)

    for item in items {
      let k = key_fn(item)
      match old_cache.get(k) {
        Some(old_state) => {
          used_old_keys.add(k)
          new_cache[k] = old_state

          let nodes = old_state.elements()
          for n in nodes {
            let is_match = match current_node_opt {
              Some(cur_n) => @ffi.prim_node_eq(n, cur_n)
              None => false
            }

            if is_match {
              match current_node_opt {
                Some(cur_n) => current_node_opt = dom_next_sibling(cur_n)
                None => ()
              }
            } else {
              match current_node_opt {
                Some(cur_n) => @ffi.dom_insert_before(parent, n, cur_n)
                None => @ffi.dom_append(parent, n)
              }
            }
          }
        }
        None => {
          let child_view = render_fn(item)
          let child_state = child_view.build()
          new_cache[k] = child_state

          match current_node_opt {
            Some(cur_n) => child_state.mount(parent, cur_n)
            None => child_state.mount(parent, end)
          }
        }
      }
    }

    for old_k in old_cache.keys() {
      guard !used_old_keys.contains(old_k) else { continue }
      match old_cache.get(old_k) {
        Some(old_state) => old_state.unmount()
        None => ()
      }
    }

    cache.val = new_cache
  }

  let _ = @reactive.Effect::new(do_reconcile)

  let init = fn(parent : @ffi.Node) {
    parent_ref.val = Some(parent)
    let items = each()
    let init_cache : @hashmap.HashMap[K, RenderState] = HashMap([])

    for item in items {
      let k = key_fn(item)
      let child_view = render_fn(item)
      let child_state = child_view.build()
      child_state.mount(parent, end)
      init_cache[k] = child_state
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
  // ForNode is reactive — updates happen through the effect.
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
pub impl[T, K : Hash + Eq] View for ForNode[T, K] with fn style(self, _s) -> &View {
  self
}
