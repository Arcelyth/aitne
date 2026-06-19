///|
test "params_basic_operations" {
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

///|
test "from_search_basic_parsing" {
  let p = Params::from_search("?a=1&b=2&c=")
  assert_eq(p.get("a"), Some("1"))
  assert_eq(p.get("b"), Some("2"))
  assert_eq(p.get("c"), Some(""))
}

///|
test "from_search_duplicate_keys_behavior" {
  let p = Params::from_search("?a=1&a=2&b=3")
  assert_eq(p.get("a"), Some("2"))
  assert_eq(p.get("b"), Some("3"))
}

///|
test "to_params should group values by duplicate keys" {
  let empty_input : Array[(String, String)] = []
  let Params(empty_res) = to_params(empty_input)
  inspect(empty_res.length(), content="0")

  let input = [
    ("id", "123"),
    ("tag", "rust"),
    ("id", "456"),
    ("tag", "moonbit"),
    ("page", "1"),
  ]

  let Params(res) = to_params(input)

  inspect(res.length(), content="3")

  inspect(res[0].0, content="id")
  inspect(res[0].1, content="[123, 456]")

  inspect(res[1].0, content="tag")
  inspect(res[1].1, content="[rust, moonbit]")

  inspect(res[2].0, content="page")
  inspect(res[2].1, content="[1]")
}
