///|
test "generate dynamic code block" {
  let cg = @mbxc.CodeGen::new()

  let ast_dyn_closure : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::DynamicCode([
      @mbxc.MbxAST::PureCode("() => count.get().to_string()"),
    ]),
  ]

  let result_closure = cg.generate(ast_dyn_closure)
  let expected_closure =
    #|@Arcelyth/aitne/src/dom.text_dyn(
    #|        () => count.get().to_string()
    #|      )

  inspect(result_closure, content=expected_closure)
}

///|
test "output style" {
  let cg = @mbxc.CodeGen::new(path="index.mbx")
  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::StyleNode(".btn { color: red; }"),
  ]

  let _ = cg.generate(ast)
  inspect(cg.output_style() != "", content="true")
}

///|
test "generate nested tag in attribute expression" {
  let attrs = []
  attrs.push(
    (
      @mbxc.TokenAttr::{ ns: None, name: "eat", },
      @mbxc.AttrValue::Expr("() => {<li>{()=>name.get()}</li>}"),
    ),
  )

  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("Apple", attrs, []),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|apple(eat=() => {@Arcelyth/aitne/src/dom.li(children=[@Arcelyth/aitne/src/dom.text_dyn(
    #|        ()=>name.get()
    #|      )])})

  inspect(result, content=expected)
}

///|
test "generate nested tag in children" {
  // <div>{() => {<li>{()=>name.get()}</li>}}</div>
  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("div", [], [
      @mbxc.MbxAST::DynamicCode([
        @mbxc.MbxAST::PureCode("() => {"),
        @mbxc.MbxAST::ElementNode("li", [], [
          @mbxc.MbxAST::DynamicCode([@mbxc.MbxAST::PureCode("()=>name.get()")]),
        ]),
        @mbxc.MbxAST::PureCode("}"),
      ]),
    ]),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|@Arcelyth/aitne/src/dom.div(children=[() => {@Arcelyth/aitne/src/dom.li(children=[@Arcelyth/aitne/src/dom.text_dyn(
    #|        ()=>name.get()
    #|      )])}])

  inspect(result, content=expected)
}

///|
test "generate deeply nested tag" {
  let attrs = []
  attrs.push(
    (
      @mbxc.TokenAttr::{ ns: None, name: "data", },
      @mbxc.AttrValue::Expr(
        "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}",
      ),
    ),
  )

  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("Outer", attrs, []),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|outer(data=() => {middle(label=() => {inner(children=[@Arcelyth/aitne/src/dom.text_dyn(
    #|        ()=>name.get()
    #|      )])})})

  inspect(result, content=expected)
}

///|
test "generate nested tag with method call" {
  // <div>{items.map(() => {<li>{()=>name.get()}</li>})}</div>
  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("div", [], [
      @mbxc.MbxAST::DynamicCode([
        @mbxc.MbxAST::PureCode("items.map(() => {"),
        @mbxc.MbxAST::ElementNode("li", [], [
          @mbxc.MbxAST::DynamicCode([@mbxc.MbxAST::PureCode("()=>name.get()")]),
        ]),
        @mbxc.MbxAST::PureCode("})"),
      ]),
    ]),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|@Arcelyth/aitne/src/dom.div(children=[items.map(() => {@Arcelyth/aitne/src/dom.li(children=[@Arcelyth/aitne/src/dom.text_dyn(
    #|        ()=>name.get()
    #|      )])})])

  inspect(result, content=expected)
}

///|
test "generate sibling brace expressions" {
  // <div>{a}{b}</div>
  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("div", [], [
      @mbxc.MbxAST::DynamicCode([@mbxc.MbxAST::PureCode("a")]),
      @mbxc.MbxAST::DynamicCode([@mbxc.MbxAST::PureCode("b")]),
    ]),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|@Arcelyth/aitne/src/dom.div(children=[a, b])

  inspect(result, content=expected)
}

///|
test "generate conditional with nested tags" {
  // <div>{condition ? <span>{()=>x.get()}</span> : <em>static</em>}</div>
  let ast : Array[@mbxc.MbxAST] = [
    @mbxc.MbxAST::ElementNode("div", [], [
      @mbxc.MbxAST::DynamicCode([
        @mbxc.MbxAST::PureCode("condition ? "),
        @mbxc.MbxAST::ElementNode("span", [], [
          @mbxc.MbxAST::DynamicCode([@mbxc.MbxAST::PureCode("()=>x.get()")]),
        ]),
        @mbxc.MbxAST::PureCode(" : "),
        @mbxc.MbxAST::ElementNode("em", [], [@mbxc.MbxAST::RawText("static")]),
      ]),
    ]),
  ]

  let cg = @mbxc.CodeGen::new()
  let result = cg.generate(ast)

  let expected =
    #|@Arcelyth/aitne/src/dom.div(children=[condition ? @Arcelyth/aitne/src/dom.span(children=[@Arcelyth/aitne/src/dom.text_dyn(
    #|        ()=>x.get()
    #|      )]) : @Arcelyth/aitne/src/dom.em(children=["static"])])

  inspect(result, content=expected)
}
