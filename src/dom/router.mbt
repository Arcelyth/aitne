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

