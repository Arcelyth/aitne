fn create_counter() -> Ref[Int] {
  @ref.new(0)
}

test "memo_basic_caching_and_lazy" {
  let evaluate_count = create_counter()
  let (s, _)= create_signal(10)

  let double_memo = Memo::new(fn(_prev) {
    evaluate_count.val = evaluate_count.val + 1
    s.get() * 2
  })

  assert_eq(evaluate_count.val, 0)

  assert_eq(double_memo.get(), 20)
  assert_eq(evaluate_count.val, 1)

  assert_eq(double_memo.get(), 20)
  assert_eq(double_memo.get(), 20)
  assert_eq(evaluate_count.val, 1)
}

test "memo_upstream_update" {
  let evaluate_count = create_counter()
  let (s, set_s)= create_signal(5)

  let plus_ten_memo = Memo::new(fn(_prev) {
    evaluate_count.val = evaluate_count.val + 1
    s.get() + 10
  })

  assert_eq(plus_ten_memo.get(), 15)

  set_s.set(20)
  assert_eq(evaluate_count.val, 1)

  assert_eq(plus_ten_memo.get(), 30)
  assert_eq(evaluate_count.val, 2)
}

test "memo_diamond_dependency_glitch_free" {
  let run_b = create_counter()
  let run_c = create_counter()
  let run_d = create_counter()

  let (s, set_s)= create_signal(1)

  let memo_b = Memo::new(fn(_prev) {
    run_b.val = run_b.val + 1
    s.get() + 10 // A + 10
  })

  let memo_c = Memo::new(fn(_prev) {
    run_c.val = run_c.val + 1
    s.get() * 2  // A * 2
  })

  let memo_d = Memo::new(fn(_prev) {
    run_d.val = run_d.val + 1
    memo_b.get() + memo_c.get() // B + C
  })

  // A=1 -> B=11, C=2 -> D = 11 + 2 = 13
  assert_eq(memo_d.get(), 13)
  assert_eq(run_b.val, 1)
  assert_eq(run_c.val, 1)
  assert_eq(run_d.val, 1)

  set_s.set(2) 
  // A=2 -> B=12, C=4 -> D = 12 + 4 = 16
  assert_eq(memo_d.get(), 16)
  assert_eq(run_b.val, 2)
  assert_eq(run_c.val, 2)
  assert_eq(run_d.val, 2)
}

test "memo_dynamic_branch_switching" {
  let evaluate_count = create_counter()
  let (cond, set_cond)= create_signal(true)
  let (a, set_a) = create_signal(100)
  let (b, set_b) = create_signal(200)

  let dynamic_memo = Memo::new(fn(_prev) {
    evaluate_count.val = evaluate_count.val + 1
    if cond.get() {
      a.get()
    } else {
      b.get()
    }
  })

  assert_eq(dynamic_memo.get(), 100)

  set_b.set(300)
  assert_eq(dynamic_memo.get(), 100)
  assert_eq(evaluate_count.val, 1)

  set_cond.set(false)
  assert_eq(dynamic_memo.get(), 300)
  assert_eq(evaluate_count.val, 2)

  set_a.set(999)
  assert_eq(dynamic_memo.get(), 300) 
  assert_eq(evaluate_count.val, 2)
}
