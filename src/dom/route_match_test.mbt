///|
test "match /users/123" {
  let route = NestedRoute::new("/users", () => "users").child(
    NestedRoute::new("/:id", () => "profile"),
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
  let route = NestedRoute::new("/about", () => "about")

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
  let route = NestedRoute::new("/users", () => "users")

  let (res, remain) = route.match_nested("/posts")

  assert_eq(remain, "/posts")

  match res {
    None => ()
    _ => panic()
  }
}

///|
test "nested route" {
  let route = NestedRoute::new("/users", () => "users").child(
    NestedRoute::new("/:id", () => "profile").child(
      NestedRoute::new("/messages", () => "messages"),
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
  let route = NestedRoute::new("/users/:id/posts/:post", () => "page")

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

///|
test "has_scheme" {
  inspect(has_scheme("http://github.com"), content="true")
  inspect(has_scheme("https://moonbitlang.com"), content="true")
  inspect(has_scheme("mailto:test@example.com"), content="true")
  inspect(has_scheme("tel:10086"), content="true")
  inspect(has_scheme("//cdn.example.com"), content="true")

  inspect(has_scheme("/local/path"), content="false")
  inspect(has_scheme("relative/path"), content="false")
}

///|
test "normalize" {
  inspect(normalize("/foo/bar/", false), content="/foo/bar/")
  inspect(normalize("foo/bar//", false), content="/foo/bar/")
  inspect(normalize("///foo///bar", false), content="/foo///bar")
  inspect(normalize("", false), content="")

  inspect(normalize("?query=true", false), content="?query=true")
  inspect(normalize("#hash-tag", false), content="#hash-tag")
}

///|
test "resolve_path" {
  inspect(
    resolve_path("/base", "https://moonbitlang.com", None),
    content="https://moonbitlang.com",
  )
  inspect(
    resolve_path("/base", "mailto:a@b.com", Some("/base/current")),
    content="mailto:a@b.com",
  )

  inspect(resolve_path("/base", "about", None), content="/base/about")
  inspect(resolve_path("/base", "/about", None), content="/base/about")

  inspect(
    resolve_path("/base", "settings", Some("/base/user")),
    content="/base/user/settings",
  )

  inspect(
    resolve_path("/base", "settings", Some("/other")),
    content="/base/other/settings",
  )

  inspect(
    resolve_path("/base", "/dashboard", Some("/base/user")),
    content="/base/dashboard",
  )

  inspect(resolve_path("/base", "?query=1", None), content="/base?query=1")
  inspect(
    resolve_path("/base", "#section-2", Some("/base/about")),
    content="/base/about#section-2",
  )
}

///|
test "normalize_path_tests" {
  inspect(normalize_path(""), content="")

  inspect(normalize_path("/a/b/c"), content="/a/b/c")

  inspect(normalize_path("/a/b/../c"), content="/a/c")

  inspect(normalize_path("/a/./b/../../c"), content="/c")

  inspect(normalize_path("/a/b/c/.."), content="/a/b")

  inspect(normalize_path("/../.."), content="/")

  inspect(normalize_path("/a/../../b"), content="/b")

  inspect(normalize_path("/a/b/../c?query=1#hash"), content="/a/c")

  inspect(normalize_path("/?only_query=true"), content="/")

  inspect(normalize_path("a/b/../c"), content="/a/c")
  inspect(normalize_path("//a//b/.."), content="//a")
}
