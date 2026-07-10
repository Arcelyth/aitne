///|
pub(all) struct Keyed[T, V] {
  items : () -> Iter[T]
  key_fn : (T) -> String
  view_fn : (Int, T) -> ((Int) -> Unit, V)
}

///|
pub impl[T, V : Render] Render for Keyed[T, V] with fn build(self) -> RenderState {
  let items = (self.items)()
  let keys = Ref(@utils.IndexSet::new())
  let rendered_items = []
  items.eachi((idx, item) => {
    let _ = keys.val.insert((self.key_fn)(item))
    let (set_idx, view) = (self.view_fn)(idx, item)
    rendered_items.push(Some((set_idx, view.build())))
  })
  RenderState::KeyedState(KeyedState::{
    parent: None,
    marker: @ffi.dom_create_comment("for-start"),
    keys,
    rendered_items,
  })
}

///|
pub impl[T, V : Render] Render for Keyed[T, V] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  match state.val {
    RenderState::KeyedState({ parent, marker, keys, rendered_items }) => {
      let new_items = (self.items)()
      let new_keys = @utils.IndexSet::new()
      let items = []

      new_items.each(i => {
        let _ = new_keys.insert((self.key_fn)(i))
        items.push(Some(i))
      })

      let cmds = diff(keys.val, new_keys)
      apply_diff(parent, marker, cmds, rendered_items, self.view_fn, items)
      keys.val = new_keys
    }
    _ => ()
  }
}

///|
pub impl[T, V : Render] View for Keyed[T, V] with fn style(_s, _d) {

}

///|
pub impl[T, V : Render] RenderHtml for Keyed[T, V] with fn html_len(_self) -> Int {
  // TODO
  0
}

///|
pub impl[T, V : Render] RenderHtml for Keyed[T, V] with fn to_html_with_buf(
  _self,
  _buf,
  _position,
) -> Unit {
  // TODO
  ()
}

///|
pub enum DiffOpAddMode {
  Normal
  Append
} derive(Eq)

///|
pub struct DiffOpAdd {
  at : Int
  mode : DiffOpAddMode
}

///|
pub struct DiffOpRemove {
  at : Int
}

///|
pub struct DiffOpMove {
  from : Int
  to : Int
  mut len : Int
  move_in_dom : Bool
}

///|
pub struct Diff {
  removed : Array[DiffOpRemove]
  moved : Array[DiffOpMove]
  added : Array[DiffOpAdd]
  items_to_move : Int
  clear : Bool
}

///|
pub fn diff(
  from : @utils.IndexSet[String],
  to : @utils.IndexSet[String],
) -> Diff {
  if from.is_empty() && to.is_empty() {
    return { removed: [], moved: [], added: [], items_to_move: 0, clear: false }
  }

  if to.is_empty() {
    return { removed: [], moved: [], added: [], items_to_move: 0, clear: true }
  }

  if from.is_empty() {
    let added = []
    for i = 0; i < to.length(); i = i + 1 {
      added.push({ at: i, mode: Append })
    }
    return { removed: [], moved: [], added, items_to_move: 0, clear: false }
  }

  let removed : Array[DiffOpRemove] = []
  let moved : Array[DiffOpMove] = []
  let added : Array[DiffOpAdd] = []

  let max_len = if from.length() > to.length() {
    from.length()
  } else {
    to.length()
  }

  for index = 0; index < max_len; index = index + 1 {
    let from_item = from.get(index)
    let to_item = to.get(index)

    if from_item != to_item {
      match from_item {
        Some(key) => if !to.contains(key) { removed.push({ at: index }) }
        None => ()
      }

      match to_item {
        Some(key) =>
          if !from.contains(key) {
            added.push({ at: index, mode: Normal })
          }
        None => ()
      }

      match from_item {
        Some(key) =>
          match to.get_index(key) {
            Some(to_index) => {
              let moves_forward_by = to_index - index
              let move_in_dom = moves_forward_by !=
                added.length() - removed.length()
              moved.push({ from: index, to: to_index, len: 1, move_in_dom })
            }
            None => ()
          }
        None => ()
      }
    }
  }

  let grouped_moved : Array[DiffOpMove] = []
  if moved.length() > 0 {
    let mut current_move = moved[0]
    for i = 1; i < moved.length(); i = i + 1 {
      let next_move = moved[i]
      if next_move.from == current_move.from + current_move.len &&
        next_move.to == current_move.to + current_move.len &&
        next_move.move_in_dom == current_move.move_in_dom {
        current_move.len = current_move.len + next_move.len
      } else {
        grouped_moved.push(current_move)
        current_move = next_move
      }
    }
    grouped_moved.push(current_move)
  }

  let mut items_to_move = 0
  for m in grouped_moved {
    items_to_move = items_to_move + m.len
  }

  { removed, moved: grouped_moved, added, items_to_move, clear: false }
}

///|
pub fn[T, V : Render] apply_diff(
  parent : @ffi.Element?,
  marker : @ffi.Node,
  diff : Diff,
  children : Array[((Int) -> Unit, RenderState)?],
  view_fn : (Int, T) -> ((Int) -> Unit, V),
  items : Array[T?],
) -> Unit {
  if diff.clear {
    for child in children {
      match child {
        Some((_, state)) => state.unmount()
        None => ()
      }
    }
    children.clear()
    if diff.added.is_empty() {
      return
    }
  }

  for op in diff.removed {
    if op.at < children.length() {
      match children[op.at] {
        Some((_, state)) => {
          state.unmount()
          children[op.at] = None
        }
        None => ()
      }
    }
  }

  let move_cmds : Array[DiffOpMove] = []
  for group in diff.moved {
    for j = 0; j < group.len; j = j + 1 {
      move_cmds.push({
        from: group.from + j,
        to: group.to + j,
        len: 1,
        move_in_dom: group.move_in_dom,
      })
    }
  }

  let moved_children : Array[((Int) -> Unit, RenderState)?] = []
  for op in move_cmds {
    if op.from < children.length() {
      let child = children[op.from]
      children[op.from] = None
      moved_children.push(child)
    } else {
      moved_children.push(None)
    }
  }

  let new_len = children.length() + diff.added.length()
  while children.length() < new_len {
    children.push(None)
  }

  let get_next_mounted = fn(start_idx) {
    let mut res : RenderState? = None
    for i = start_idx + 1; i < children.length(); i = i + 1 {
      match children[i] {
        Some((_, state)) => {
          res = Some(state)
          break
        }
        None => ()
      }
    }
    res
  }

  for i = 0; i < move_cmds.length(); i = i + 1 {
    let op = move_cmds[i]
    if !op.move_in_dom {
      match moved_children[i] {
        Some((set_index, state)) => {
          set_index(op.to)
          children[op.to] = Some((set_index, state))
        }
        None => ()
      }
    }
  }

  for i = 0; i < move_cmds.length(); i = i + 1 {
    let op = move_cmds[i]
    if op.move_in_dom {
      match moved_children[i] {
        Some((set_index, state)) => {
          match parent {
            Some(p) =>
              match get_next_mounted(op.to) {
                Some(target_state) => {
                  let _ = target_state.insert_before(state)
                }
                None => state.mount(@ffi.el_as_node(p), marker)
              }
            None => ()
          }
          set_index(op.to)
          children[op.to] = Some((set_index, state))
        }
        None => ()
      }
    }
  }

  for add in diff.added {
    if add.at < items.length() {
      match items[add.at] {
        Some(item) => {
          let (set_index, view) = view_fn(add.at, item)
          let state = view.build()

          match parent {
            Some(p) =>
              match add.mode {
                Normal =>
                  match get_next_mounted(add.at) {
                    Some(target_state) => {
                      let _ = target_state.insert_before(state)
                    }
                    None => state.mount(@ffi.el_as_node(p), marker)
                  }
                Append => state.mount(@ffi.el_as_node(p), marker)
              }
            None => ()
          }
          children[add.at] = Some((set_index, state))
        }
        None => ()
      }
    }
  }

  let mut k = 0
  while k < children.length() {
    match children[k] {
      None => {
        let _ = children.remove(k)
      }
      Some(_) => k = k + 1
    }
  }
}

///|
pub struct KeyedState {
  mut parent : @ffi.Element?
  marker : @ffi.Node
  mut keys : Ref[@utils.IndexSet[String]]
  rendered_items : Array[((Int) -> Unit, RenderState)?]
}
