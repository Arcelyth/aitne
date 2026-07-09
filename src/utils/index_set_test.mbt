///|
test "IndexSet basic operations" {
  let set = IndexSet::new()

  debug_inspect(set.length(), content="0")

  assert_true(set.insert("a"))
  assert_true(set.insert("b"))
  assert_true(set.insert("c"))

  debug_inspect(set.length(), content="3")

  assert_false(set.insert("b"))

  debug_inspect(set.contains("a"), content="true")
  debug_inspect(set.contains("x"), content="false")

  debug_inspect(set.get_index("a"), content="Some(0)")
  debug_inspect(set.get_index("b"), content="Some(1)")
  debug_inspect(set.get_index("c"), content="Some(2)")

  debug_inspect(set.get(0), content="Some(\"a\")")
  debug_inspect(set.get(1), content="Some(\"b\")")
  debug_inspect(set.get(2), content="Some(\"c\")")
}
