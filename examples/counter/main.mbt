fn main {
  let app = counter_component(0)
  
  @dom.mount_to_body(app)
}
