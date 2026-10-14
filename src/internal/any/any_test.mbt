///|
test "integer boxing, type metadata, and checked conversions" {
  let value = @any.of(42)
  assert_eq((value.to() : Int32), 42)
  assert_eq((value.try_to() : Int32?), Some(42))
  assert_eq((value.try_to() : Bool?), None)
  assert_eq(value.type_name(), "Int")
  assert_eq(value.type_info().name(), "Int")
  assert_true(physical_equal(value.type_id(), value.type_info().id()))
  assert_eq((value.unsafe_coerce() : Int32), 42)
  try {
    let _ : Bool = value.to()
    fail("expected a type mismatch")
  } catch {
    @any.TypeMismatch(expect~, actual~) => {
      assert_eq(expect.name(), "Bool")
      assert_eq(actual.name(), "Int")
    }
    error => raise error
  }
}

///|
test "mapping only invokes matching callbacks and propagates errors" {
  let value = @any.of(2)
  let calls = Ref(0)
  let untouched = value.map((flag : Bool) => {
    calls.val += 1
    if flag {
      1
    } else {
      0
    }
  })
  assert_eq(calls.val, 0)
  assert_eq((untouched.to() : Int32), 2)
  assert_eq((value.map((n : Int32) => n + 1).to() : Int32), 3)
  let raised = try {
    let _ = value.map(fn(_ : Int32) -> Int32 raise Failure {
      fail("callback failure")
    })
    false
  } catch {
    Failure(_) => true
  }
  assert_true(raised)
  assert_eq((value.to() : Int32), 2)
}

///|
test "boxing Any is idempotent" {
  let first = @any.of(42)
  let second = @any.of(first)
  let extracted : @any.Any = second.to()
  assert_eq((second.to() : Int32), 42)
  assert_eq((extracted.to() : Int32), 42)
  let optional : @any.Any? = first.try_to()
  assert_eq((optional.unwrap().to() : Int32), 42)
}
