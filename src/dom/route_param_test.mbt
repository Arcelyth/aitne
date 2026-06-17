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
