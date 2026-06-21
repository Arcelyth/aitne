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
pub fn RouterContext::resolve_path(
  self : RouterContext,
  path : String,
  from : String?,
) -> String {
  let base = match self.base {
    Some(b) => b
    _ => ""
  }
  resolve_path(base, path, from)
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
pub struct RouterChildren(ViewFn)

///|
pub fn router(
  children : RouterChildren,
  base? : String? = None,
  set_is_routing? : ((Bool) -> Unit)? = None,
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

  children()
}

///|
pub fn[Ch] route(path : String, view : ViewFn) -> NestedRoute[Ch] {
  NestedRoute::new(path, view)
}

///|
type ViewFn = () -> &View

///|
pub fn[Ch] parent_route(
  path : String,
  view : () -> &View,
  children : Ch,
) -> NestedRoute[Ch] {
  NestedRoute::new(path, view).child(children)
}

///|
pub fn[Ch : MatchNestedRoutes] routes(
  fallback : ViewFn,
  children : Ch,
) -> RouterChildren {
  RouterChildren(() => {
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

    let routes = RouteDefs::{ base: ctx.base, children }
    debug(routes)
    NestedRouteView::{
      location: ctx.location,
      routes,
      outer_owner: Ref(outer_owner),
      current_url: ctx.current_url,
      base: ctx.base,
      fallback,
      set_is_routing: ctx.set_is_routing,
    }
  })
}

///|
pub(all) struct NestedRouteView[D] {
  location : Location
  routes : RouteDefs[D]
  outer_owner : Ref[Owner]
  current_url : RwSignal[Url]
  base : String?
  fallback : ViewFn
  set_is_routing : ((Bool) -> Unit)?
}

///|
pub impl[D] Debug for NestedRouteView[D] with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("location"),
    to_repr(self.location),
    @debug.Repr::string("outer_owner"),
    to_repr(self.outer_owner),
    @debug.Repr::string("base"),
    to_repr(self.base),
  ])
}

///|
pub impl[D : MatchNestedRoutes] Render for NestedRouteView[D] with fn build(
  self,
) -> RenderState {
  let current_url = self.current_url
  let routes = self.routes
  let base = self.base
  let fallback = self.fallback
  let outer_owner = self.outer_owner

  let url = current_url.get_untracked()
  let path = url.path

  let outlets = Ref([])
  let loaders = Ref([])
  let new_match = routes.match_route(path)

  let rendered = match new_match {
    None => fallback().build()
    Some(matched) => {
      matched.build(url, base, loaders, outlets, outer_owner)
      top_level_outlet(outlets, outer_owner.val)().build()
    }
  }

  let state_ref : Ref[RenderState] = Ref(
    RenderState::Router(RouterState::{
      path: Ref(path),
      current_url,
      outlets,
      view: Ref(rendered),
      outer_owner,
    }),
  )

  @reactive.create_effect(fn() {
    current_url.track()
    let url = current_url.get_untracked()
    let new_path = url.path

    match state_ref.val {
      RenderState::Router(router) => {
        if router.path.val == new_path {
          for outlet in router.outlets.val {
            outlet.url.set(url)
          }
          return
        }

        // Path changed
        router.path.val = new_path

        let dom_pos : (Node, Node?)? = match router.view.val.elements().get(0) {
          Some(first_el) => {
            let parent = dom_parent(first_el)
            if dom_is_null(parent) {
              Option::None
            } else {
              Some((parent, dom_next_sibling(first_el)))
            }
          }
          None => Option::None
        }

        let new_match = routes.match_route(new_path)

        let new_view = match new_match {
          None => fallback().build()
          Some(matched) => {
            let _ = matched.rebuild(url, base, 0, router.outlets, outer_owner)

            // Rebuild the top-level outlet view
            top_level_outlet(router.outlets, outer_owner.val)().build()
          }
        }

        // Swap old view with new in the DOM
        router.view.val.unmount()
        match dom_pos {
          Some((parent, next)) =>
            match next {
              Some(ref_node) => new_view.mount(parent, ref_node)
              None => new_view.mount(parent, dom_null_node())
            }
          None => ()
        }

        router.view.val = new_view
        if new_match is None {
          router.outlets.val = []
        }
      }
      _ => ()
    }
  })

  state_ref.val
}

///|
pub impl[D : MatchNestedRoutes] Render for NestedRouteView[D] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  println("[Debug] nested_route_view build")
  match state.val {
    RenderState::Router(router) => {
      let url = self.current_url.get_untracked()

      if url.path == router.path.val {
        for outlet in router.outlets.val {
          outlet.url.set(url)
        }
        return
      }

      router.path.val = url.path

      let dom_pos : (Node, Node?)? = match router.view.val.elements().get(0) {
        Some(first_el) => {
          let parent = dom_parent(first_el)
          if dom_is_null(parent) {
            Option::None
          } else {
            Some((parent, dom_next_sibling(first_el)))
          }
        }
        None => Option::None
      }

      let new_match = self.routes.match_route(url.path)

      let new_view = match new_match {
        None => (self.fallback)().build()
        Some(matched) => {
          let _ = matched.rebuild(
            url,
            self.base,
            0,
            router.outlets,
            self.outer_owner,
          )

          top_level_outlet(router.outlets, self.outer_owner.val)().build()
        }
      }

      router.view.val.unmount()
      match dom_pos {
        Some((parent, next)) =>
          match next {
            Some(ref_node) => new_view.mount(parent, ref_node)
            None => new_view.mount(parent, dom_null_node())
          }
        None => ()
      }

      router.view.val = new_view
      if new_match is None {
        router.outlets.val = []
      }
    }
    _ => ()
  }
}

///|
pub impl[D : MatchNestedRoutes] RenderHtml for NestedRouteView[D] with fn html_len(
  _self,
) -> Int {
  0
}

///|
pub impl[D : MatchNestedRoutes] RenderHtml for NestedRouteView[D] with fn to_html_with_buf(
  _self,
  _buf,
  _pos,
) -> Unit {
  // Router is client-side only now; no SSR output
}

///|
pub impl[D : MatchNestedRoutes] View for NestedRouteView[D] with fn style(
  self,
  _s,
) -> &View {
  self
}

///|
pub impl TypeName for RouterContext with fn get_ty() -> String {
  "RouterContext"
}

///|
pub(all) struct RouteContext {
  mut id : UInt
  url : RwSignal[Url]
  params : RwSignal[Params]
  matched : RwSignal[String]
  base : String?
  view_fn : Ref[(Owner) -> &View]
  owner : Ref[Owner?]
  mut preload_owner : Owner
  mut child : RouteContext?
  trigger : Trigger
}

///|
pub impl TypeName for RouteContext with fn get_ty() -> String {
  "RouteContext"
}

///|
fn top_level_outlet(
  outlets : Ref[Array[RouteContext]],
  outer_owner : Owner,
) -> () -> &View {
  println("[Debug] top_level_outlet")
  let outlet = match outlets.val.get(0) {
    Some(o) => o
    None => {
      println("[Error] Found 0 outlets")
      panic()
    }
  }

  outer_owner.with_(() => {
    provide_context(outlet.child)
    () => {
      outlet.trigger.track()
      let view_fn = outlet.view_fn.val
      view_fn(outer_owner.child())
    }
  })
}

///|
pub struct OutletView {
  child : RouteContext?
  outer_owner : Owner
}

///|
pub impl View for OutletView with fn style(self, _i) -> &View {
  self
}

///|
pub impl Render for OutletView with fn build(self) -> RenderState {
  match self.child {
    Some(c) => {
      c.trigger.track()
      let view_fn = c.view_fn.val
      view_fn(self.outer_owner.child()).build()
    }
    None => RenderState::None
  }
}

///|
pub impl Render for OutletView with fn rebuild(self, state : Ref[RenderState]) -> Unit {
  match self.child {
    Some(c) => {
      c.trigger.track()
      let view_fn = c.view_fn.val
      let new_view = view_fn(self.outer_owner.child())

      new_view.rebuild(state)
    }
    None => ()
  }
}

///|
pub impl RenderHtml for OutletView with fn html_len(_self) -> Int {
  0
}

///|
pub impl RenderHtml for OutletView with fn to_html_with_buf(_self, _buf, _pos) -> Unit {
  // Router is client-side only now; no SSR output
}

///|
pub fn outlet() -> &View {
  let cctx : RouteContext?? = use_context()
  let child = match cctx {
    Some(c) => c
    _ => {
      println("[Error] Used without provided RouteContext.")
      panic()
    }
  }
  let oo = Owner::current()
  let outer_owner = match oo {
    Some(o) => o
    None => {
      println("[Error] Cannot find owner.")
      panic()
    }
  }

  OutletView::{ child, outer_owner }
}
