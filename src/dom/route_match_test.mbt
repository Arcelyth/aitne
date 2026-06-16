///|
test "match /users/123" {
  let route = NestedRoute::new("/users", "users").child(
    NestedRoute::new("/:id", "profile"),
  )
  let (res, remain) = route.match_nested("/users/123")

  assert_eq(remain, "")

  match res {
    Some((_, m)) => {
      assert_eq(m.matched, "/users")

      match m.child {
        Some(child) => {
          assert_eq(child.matched, "/123")

          let p = child.params

          assert_eq(p.length(), 1)
          assert_eq(p[0].0, "id")
          assert_eq(p[0].1, "123")
        }
        None => panic()
      }
    }
    None => panic()
  }
}

///|
test "match static route" {
  let route = NestedRoute::new("/about", "about")

  let (res, remain) = route.match_nested("/about")

  assert_eq(remain, "")

  match res {
    Some((_, m)) => {
      assert_eq(m.matched, "/about")
      assert_eq(m.params.length(), 0)
    }
    None => panic()
  }
}

///|
test "not match" {
  let route = NestedRoute::new("/users", "users")

  let (res, remain) = route.match_nested("/posts")

  assert_eq(remain, "/posts")

  match res {
    None => ()
    _ => panic()
  }
}

///|
test "nested route" {
  let route = NestedRoute::new("/users", "users").child(
    NestedRoute::new("/:id", "profile").child(
      NestedRoute::new("/messages", "messages"),
    ),
  )

  let (res, remain) = route.match_nested("/users/123/messages")

  assert_eq(remain, "")

  match res {
    Some((_, root)) => {
      assert_eq(root.matched, "/users")

      match root.child {
        Some(profile) => {
          assert_eq(profile.params[0].1, "123")

          match profile.child {
            Some(msg) => assert_eq(msg.matched, "/messages")
            None => panic()
          }
        }
        None => panic()
      }
    }
    None => panic()
  }
}

///|
test "params" {
  let route = NestedRoute::new("/users/:id/posts/:post", "page")

  let (res, _) = route.match_nested("/users/123/posts/456")

  match res {
    Some((_, m)) => {
      assert_eq(m.params.length(), 2)

      assert_eq(m.params[0].0, "id")
      assert_eq(m.params[0].1, "123")

      assert_eq(m.params[1].0, "post")
      assert_eq(m.params[1].1, "456")
    }
    None => panic()
  }
}
