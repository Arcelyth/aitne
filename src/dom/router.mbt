///|
using @reactive {use_context}

///|
pub(all) struct RouterContext {
  base : String?
  current_url : RwSignal[Url]
  location : Location
  set_is_routing : ((Bool) -> Unit)?
}

///|
let global_router_context : Ref[RouterContext?] = @ref.new(None)

///|
pub fn provide_router_context(ctx : RouterContext) -> Unit {
  global_router_context.val = Some(ctx)
}

///|
pub fn use_router_context() -> RouterContext? {
  global_router_context.val
}

///|
pub struct RouterChildren[Ch](() -> Ch)

///|
pub fn[Ch : View] router(
  children : RouterChildren[Ch],
  base : String?,
  set_is_routing : ((Bool) -> Unit)?,
) -> &View {
  let location = BrowserUrl::new()

  location.init(base)
  provide_context(location)
  let cur_url = location.url
  // Useless in CSR
  let _redirect_hook = (loc : String) => {
    match Owner::current() {
      Some(o) => o.with_(() => location.redirect(loc))
      _ => ()
    }
  }

  let loc = Location::new(cur_url)

  // TODO: redirection hook
  provide_context(RouterContext::{
    base,
    current_url: location.url,
    location: loc,
    set_is_routing,
  })

  println("[Debug] router")
  children()
}

///|
pub fn[V] route(path : String, view : V) -> NestedRoute[V] {
  NestedRoute::new(path, view)
}

///|
pub fn[V] parent_route(
  path : String,
  view : V,
  children : NestedRoute[V],
) -> NestedRoute[V] {
  NestedRoute::new(path, view).child(children)
}

///|
pub fn[V : View] routes(
  fallback : () -> V,
  children : NestedRoute[V],
) -> RouterChildren[&View] {
  () => {
    println("[Debug] routes")
    let _loc : BrowserUrl? = use_context()
    let rctx : RouterContext? = use_context()
    let ctx = match rctx {
      Some(c) => c
      None => {
        println("[Error] routes must be used in router function")
        panic()
      }
    }
    let outer_owner = match Owner::current() {
      Some(o) => o
      None => {
        println("[Error] found no outer Owner")
        panic()
      }
    }

    ctx.current_url.track()
    let _ = outer_owner.with_(() => ctx.current_url.get_untracked())

    NestedRouteView::{
      location: ctx.location,
      routes: children,
      outer_owner,
      current_url: ctx.current_url,
      base: ctx.base,
      fallback,
      set_is_routing: ctx.set_is_routing,
    }
  }
}

///|
pub(all) struct NestedRouteView[V] {
  location : Location
  routes : NestedRoute[V]
  outer_owner : Owner
  current_url : RwSignal[Url]
  base : String?
  fallback : () -> V
  set_is_routing : ((Bool) -> Unit)?
}

///|
/// Walk the match chain to find the deepest (most specific) matching route.
/// The deepest match corresponds to the most specific route view.
fn[V] deepest_match(matched : NestedMatch[V]) -> NestedMatch[V] {
  match matched.child {
    Some(child) => deepest_match(child)
    None => matched
  }
}

///|
pub impl[V : View] Render for NestedRouteView[V] with fn build(self) -> RenderState {
  let url = self.current_url.get_untracked()

  let path = url.path

  let (match_result, _) = self.routes.match_nested(path)

  let rendered = match match_result {
    None => Some((self.fallback)().build())
    Some((_, matched)) => {
      let view = deepest_match(matched).view_fn

      Some(view.build())
    }
  }

  RenderState::Router(RouterState::{
    start_anchor: dom_create_comment("router-start"),
    end_anchor: dom_create_comment("router-end"),
    path,
    rendered,
  })
}

///|
pub impl[V : View] Render for NestedRouteView[V] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  match state.val {
    RenderState::Router(router) => {
      let url = self.current_url.get_untracked()

      let new_path = url.path

      if router.path == new_path {
        return
      }

      router.path = new_path

      let (match_result, _) = self.routes.match_nested(new_path)

      let new_view = match match_result {
        None => (self.fallback)()
        Some((_, matched)) => deepest_match(matched).view_fn
      }

      let parent = dom_parent(router.start_anchor)

      if dom_is_null(parent) {
        return
      }

      match router.rendered {
        Some(old) => old.unmount()
        None => ()
      }

      let new_state = new_view.build()

      new_state.mount(parent, router.end_anchor)

      router.rendered = Some(new_state)
    }
    _ => ()
  }
}

///|
pub impl[V : View] RenderHtml for NestedRouteView[V] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[V : View] RenderHtml for NestedRouteView[V] with fn to_html_with_buf(
  _self,
  _buf,
  _pos,
) -> Unit {
  // Router is client-side only now; no SSR output
}

///|
pub impl[V : View] View for NestedRouteView[V] with fn style(self, _s) -> &View {
  self
}

///|
pub impl TypeName for RouterContext with fn get_ty() -> String {
  "RouterContext"
}
