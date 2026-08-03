///|
pub struct OwnedView[T] {
  owner : Owner
  view : T
}

///|
pub fn[T] OwnedView::new(view : T) -> OwnedView[T] {
  let owner = match Owner::current() {
    Some(o) => o
    None => {
      println("Failed to get current owner")
      panic()
    }
  }
  OwnedView::{ owner, view }
}

///|
pub fn[T] OwnedView::new_with_owner(owner : Owner, view : T) -> OwnedView[T] {
  OwnedView::{ owner, view }
}

///|
pub struct OwnedViewState {
  state : Ref[RenderState]
  owner : Owner
}

///|
pub fn OwnedViewState::new(
  state : RenderState,
  owner : Owner,
) -> OwnedViewState {
  OwnedViewState::{ owner, state: Ref(state) }
}

///|
pub impl Mountable for OwnedViewState with fn mount(
  self,
  parent : @ffi.Node,
  marker : @ffi.Node,
) -> Unit {
  self.state.val.mount(parent, marker)
}

///|
pub impl Mountable for OwnedViewState with fn unmount(self) -> Unit {
  self.state.val.unmount()
}

///|
pub impl Mountable for OwnedViewState with fn insert_before(
  self,
  child : &Mountable,
) -> Bool {
  self.state.val.insert_before(child)
}

///|
pub impl Mountable for OwnedViewState with fn elements(self) -> Array[@ffi.Node] {
  self.state.val.elements()
}

///|
pub impl[T : Render] Render for OwnedView[T] with fn build(self) -> RenderState {
  let state = self.owner.with_(() => self.view.build())
  RenderState::OwnedViewState(OwnedViewState::new(state, self.owner))
}

///|
pub impl[T : Render] Render for OwnedView[T] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  match state.val {
    RenderState::OwnedViewState(rs) => {
      let { owner, view } = self
      owner.with_(() => view.rebuild(rs.state))
    }
    _ => ()
  }
}

///|
pub impl[T : RenderHtml] RenderHtml for OwnedView[T] with fn html_len(self) -> Int {
  self.view.html_len()
}

///|
pub impl[T : RenderHtml] RenderHtml for OwnedView[T] with fn hydrate(
  self,
  cursor : Cursor,
  position : PositionState,
) -> RenderState {
  let state = self.owner.with_(() => self.view.hydrate(cursor, position))
  RenderState::OwnedViewState(OwnedViewState::new(state, self.owner))
}

///|
pub impl[T : RenderHtml] RenderHtml for OwnedView[T] with fn to_html_with_buf(
  self,
  buf,
  position,
) -> Unit {
  self.owner.with_(() => self.view.to_html_with_buf(buf, position))
}
