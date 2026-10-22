///|
test "parse valid mbx node with attributes and dynamic expression" {
  let div_attrs = []
  div_attrs.push(
    (
      @mbxc.TokenAttr::{ ns: None, name: "eat", },
      @mbxc.AttrValue::Expr("() => omg()"),
    ),
  )

  let tokens = [
    // <div eat={() => omg()}> {() => <div/>} </div>
    @mbxc.Token::TagOpen({ tag: "div", attrs: div_attrs, }),
    @mbxc.Token::RawText(" "),
    @mbxc.Token::BraceOpen,
    @mbxc.Token::RawText("() => "),
    @mbxc.Token::TagSelfClose({ tag: "div", attrs: [], }),
    @mbxc.Token::BraceClose,
    @mbxc.Token::RawText(" "),
    @mbxc.Token::TagClose({ tag: "div", }),
  ]

  let parser = @mbxc.Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    [
      #|      (
      #|        { ns: None, name: <StringView: "eat"> },
      #|        Expr(<StringView: "() => omg()">),
      #|      ),
      #|    ],
      #|    [
      #|      RawText(<StringView: " ">),
      #|      DynamicCode(
      #|        [
      #|          PureCode(<StringView: "() => ">),
      #|          ElementNode(<StringView: "div">, [], []),
      #|        ],
      #|      ),
      #|      RawText(<StringView: " ">),
      #|    ],
      #|  ),
      #|]
    ),
  )
}

///|
test "parse style block" {
  let src =
    #|let style = ${
    #|  .btn {
    #|    color: red;
    #|  }
    #|}$
    #|let external = ${ !"./style.css" }$

  let lexer = @mbxc.Lexer::new(src)
  let tokens = try! lexer.tokenizer()

  let parser = @mbxc.Parser::new(tokens)
  let result = try! parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  PureCode(<StringView: "let style = ">),
      #|  StyleNode(<StringView: "\n  .btn {\n    color: red;\n  }\n">),
      #|  PureCode(<StringView: "\nlet external = ">),
      #|  StyleNode(<StringView: " !\"./style.css\" ">),
      #|]
    ),
  )
}

///|
test "parse nested tag in children" {
  let tokens = [
    // <div>{() => {<li>{()=>name.get()}</li>}}</div>
    @mbxc.Token::TagOpen({ tag: "div", attrs: [], }),
    @mbxc.Token::BraceOpen,
    @mbxc.Token::RawText("() => "),
    @mbxc.Token::BraceOpen,
    @mbxc.Token::TagOpen({ tag: "li", attrs: [], }),
    @mbxc.Token::BraceOpen,
    @mbxc.Token::RawText("()=>name.get()"),
    @mbxc.Token::BraceClose,
    @mbxc.Token::TagClose({ tag: "li", }),
    @mbxc.Token::BraceClose,
    @mbxc.Token::BraceClose,
    @mbxc.Token::TagClose({ tag: "div", }),
  ]

  let parser = @mbxc.Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    [],
      #|    [
      #|      DynamicCode(
      #|        [
      #|          PureCode(<StringView: "() => {">),
      #|          ElementNode(
      #|            <StringView: "li">,
      #|            [],
      #|            [DynamicCode([PureCode(<StringView: "()=>name.get()">)])],
      #|          ),
      #|          PureCode(<StringView: "}">),
      #|        ],
      #|      ),
      #|    ],
      #|  ),
      #|]
    ),
  )
}

///|
test "parse deeply nested tag" {
  let attrs = []
  attrs.push(
    (
      @mbxc.TokenAttr::{ ns: None, name: "data", },
      @mbxc.AttrValue::Expr(
        "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}",
      ),
    ),
  )

  let tokens = [
    // <Outer data={() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}}/>
    @mbxc.Token::TagSelfClose({ tag: "Outer", attrs, }),
  ]

  let parser = @mbxc.Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "Outer">,
      #|    [
      #|      (
      #|        { ns: None, name: <StringView: "data"> },
      #|        Expr(
      #|          <StringView:
      #|            "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}">,
      #|        ),
      #|      ),
      #|    ],
      #|    [],
      #|  ),
      #|]
    ),
  )
}

///|
test "parse sibling brace expressions" {
  let tokens = [
    // <div>{a}{b}</div>
    @mbxc.Token::TagOpen({ tag: "div", attrs: [], }),
    @mbxc.Token::BraceOpen,
    @mbxc.Token::RawText("a"),
    @mbxc.Token::BraceClose,
    @mbxc.Token::BraceOpen,
    @mbxc.Token::RawText("b"),
    @mbxc.Token::BraceClose,
    @mbxc.Token::TagClose({ tag: "div", }),
  ]

  let parser = @mbxc.Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    [],
      #|    [
      #|      DynamicCode([PureCode(<StringView: "a">)]),
      #|      DynamicCode([PureCode(<StringView: "b">)]),
      #|    ],
      #|  ),
      #|]
    ),
  )
}
