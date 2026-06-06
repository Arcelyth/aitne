fn main {
  let str = match @mbxc.from_file("./examples/counter_mbx/counter.mbx", show=true) {
    Some(c) => c
    None => "error"
  }

  println(str)
  
//  @dom.mount_to_body(app)
}
