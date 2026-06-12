test {
  let p = Params::empty()
  p.add("id", "123")
  p.add("name", "alice")

  assert_eq(p.get("id"), Some("123"))
  assert_eq(p.get("name"), Some("alice"))
  assert_eq(p.contains("id"), true)
  assert_eq(p.contains("age"), false)

  let all = p.get_all("id")
  assert_eq(all.length(), 1)
  assert_eq(all[0], "123")
}

test {
  let p = Params::from_search("?a=1&b=2&c=")
  assert_eq(p.get("a"), Some("1"))
  assert_eq(p.get("b"), Some("2"))
  assert_eq(p.get("c"), Some(""))
}

test {
  let m1 = match_path("", ["contacts"], 0)
  assert_eq(m1.matched, true)
  assert_eq(m1.consumed, 0)

  let m2 = match_path("contacts", ["contacts"], 0)
  assert_eq(m2.matched, true)
  assert_eq(m2.consumed, 1)

  let m3 = match_path(":id", ["bob"], 0)
  assert_eq(m3.matched, true)
  assert_eq(m3.consumed, 1)
  assert_eq(m3.params.get("id"), Some("bob"))

  let m4 = match_path("*", ["a", "b", "c"], 0)
  assert_eq(m4.matched, true)
  assert_eq(m4.consumed, 3)
  assert_eq(m4.params.get("*"), Some("a/b/c"))
}

test {
  let routes = [
    Route::parent("", fn(outlet) {
      outlet
    }, [
      Route::new("", fn() {
        Html::Text("root")
      }),
      Route::new(":id", fn() {
        let params = use_params()
        let id = match params.get("id") {
          Some(v) => v
          None => ""
        }
        Html::Text(id)
      }),
    ])
  ]

  let segments1 = split_path("/")
  let r1 = match_routes(routes, segments1, 0, Params::empty(), Html::Text("outlet"))
  match r1 {
    Some(x) => {
      assert_eq(x.params.get("id"), None)
    }
    None => panic()
  }

  let segments2 = split_path("/bob")
  let r2 = match_routes(routes, segments2, 0, Params::empty(), Html::Text("outlet"))
  match r2 {
    Some(x) => {
      assert_eq(x.params.get("id"), Some("bob"))
    }
    None => panic()
  }
}
