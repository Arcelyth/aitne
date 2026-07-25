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
