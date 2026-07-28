///|
using @hashmap {type HashMap}

///|
test "parse valid mbx node with attributes and dynamic expression" {
  let div_attrs = HashMap([])
  div_attrs.set(
    TokenAttr::{ ns: None, name: "eat" },
    AttrValue::Expr("() => omg()"),
  )

  let tokens = [
    // <div eat={() => omg()}> {() => <div/>} </div>
    Token::TagOpen({ tag: "div", attrs: div_attrs }),
    Token::RawText(" "),
    Token::BraceOpen,
    Token::RawText("() => "),
    Token::TagSelfClose({ tag: "div", attrs: HashMap([]) }),
    Token::BraceClose,
    Token::RawText(" "),
    Token::TagClose({ tag: "div" }),
  ]

  let parser = Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    <HashMap:
      #|      { { ns: None, name: <StringView: "eat"> }: Expr(<StringView: "() => omg()">) }>,
      #|    [
      #|      RawText(<StringView: " ">),
      #|      DynamicCode(
      #|        [
      #|          PureCode(<StringView: "() => ">),
      #|          ElementNode(<StringView: "div">, <HashMap: {}>, []),
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

  let lexer = Lexer::new(src)
  let tokens = try! lexer.tokenizer()

  let parser = Parser::new(tokens)
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
    Token::TagOpen({ tag: "div", attrs: HashMap([]) }),
    Token::BraceOpen,
    Token::RawText("() => "),
    Token::BraceOpen,
    Token::TagOpen({ tag: "li", attrs: HashMap([]) }),
    Token::BraceOpen,
    Token::RawText("()=>name.get()"),
    Token::BraceClose,
    Token::TagClose({ tag: "li" }),
    Token::BraceClose,
    Token::BraceClose,
    Token::TagClose({ tag: "div" }),
  ]

  let parser = Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    <HashMap: {}>,
      #|    [
      #|      DynamicCode(
      #|        [
      #|          PureCode(<StringView: "() => {">),
      #|          ElementNode(
      #|            <StringView: "li">,
      #|            <HashMap: {}>,
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
  let attrs = HashMap([])
  attrs.set(
    TokenAttr::{ ns: None, name: "data" },
    AttrValue::Expr(
      "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}",
    ),
  )

  let tokens = [
    // <Outer data={() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}}/>
    Token::TagSelfClose({ tag: "Outer", attrs }),
  ]

  let parser = Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "Outer">,
      #|    <HashMap:
      #|      {
      #|        { ns: None, name: <StringView: "data"> }: Expr(
      #|          <StringView:
      #|            "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}">,
      #|        ),
      #|      }>,
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
    Token::TagOpen({ tag: "div", attrs: HashMap([]) }),
    Token::BraceOpen,
    Token::RawText("a"),
    Token::BraceClose,
    Token::BraceOpen,
    Token::RawText("b"),
    Token::BraceClose,
    Token::TagClose({ tag: "div" }),
  ]

  let parser = Parser::new(tokens)
  let result = parser.parse()

  debug_inspect(
    result,
    content=(
      #|[
      #|  ElementNode(
      #|    <StringView: "div">,
      #|    <HashMap: {}>,
      #|    [
      #|      DynamicCode([PureCode(<StringView: "a">)]),
      #|      DynamicCode([PureCode(<StringView: "b">)]),
      #|    ],
      #|  ),
      #|]
    ),
  )
}
