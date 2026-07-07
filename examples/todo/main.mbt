///|
fn main {
  let app = todo_app()
  let _ = @dom.mount_to_body(() => app)
}
