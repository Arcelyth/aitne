///|
test "provide and use context" {
  let owner = Owner::new()

  owner.provide_context("hello")

  assert_eq(owner.use_context(), Some("hello"))
}

///|
test "child inherits parent context" {
  let root = Owner::new()
  let child = root.child()

  root.provide_context("root")
  assert_eq(child.use_context(), Some("root"))
}

///|
test "parent cannot access child context" {
  let root = Owner::new()
  let child = root.child()

  child.provide_context("child")

  assert_eq(root.use_context(), None)
}

///|
test "context in closure" {
  let root = Owner::new()
  let child = root.child()

  let f = () => assert_eq(child.use_context(), Some("child"))

  root.provide_context("child")

  assert_eq(root.use_context(), Some("child"))
  f()
}

///|
test "nearest context wins" {
  let root = Owner::new()
  let child = root.child()

  root.provide_context("root")
  child.provide_context("child")

  assert_eq(child.use_context(), Some("child"))
  assert_eq(root.use_context(), Some("root"))
}

///|
test "take context removes it" {
  let owner = Owner::new()

  owner.provide_context("hello")

  assert_eq(owner.take_context(), Some("hello"))

  assert_eq(owner.use_context(), None)
}

///|
test "take context from parent" {
  let root = Owner::new()
  let child = root.child()

  root.provide_context("root")

  assert_eq(child.take_context(), Some("root"))

  assert_eq(root.use_context(), None)
}

///|
test "bidirectional finds child context" {
  let root = Owner::new()
  let child = root.child()

  child.provide_context("child")

  assert_eq(root.use_context_bidirectional(), Some("child"))
}

///|
test "bidirectional bfs" {
  let root = Owner::new()

  let child1 = root.child()
  let child2 = root.child()

  let grandchild = child2.child()

  grandchild.provide_context("target")

  assert_eq(root.use_context_bidirectional(), Some("target"))
}
