///|
test "lexer basic html" {
  let src =
    #|<div>hello</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "hello">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer string handle" {
  let src =
    #|let a = "<div>"
    #|<div>"<div>"</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = \"<div>\"\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "\"<div>\"">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer < handle outside" {
  let src =
    #|if a < b
    #|<div>"<div>"</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "if a < b\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "\"<div>\"">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer < handle inside" {
  let src =
    #|<div>a < b</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "a < b">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer attributes" {
  let src =
    #|<div id="app"></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "id"> }: Str(<StringView: "app">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer event attribute" {
  let src =
    #|<button on:click={() => 1}>+</button>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "button">,
      #|      attrs: <HashMap:
      #|        { { ns: Some(<StringView: "on">), name: <StringView: "click"> }: Expr(<StringView: "() => 1">) }>,
      #|    },
      #|  ),
      #|  RawText(<StringView: "+">),
      #|  TagClose({ tag: <StringView: "button"> }),
      #|]
    ),
  )
}

///|
test "lexer self closing str" {
  let src =
    #|<img src="a.png"/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "img">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "src"> }: Str(<StringView: "a.png">) }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer self closing expr" {
  let src =
    #|<button on:click={() => a}/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "button">,
      #|      attrs: <HashMap:
      #|        { { ns: Some(<StringView: "on">), name: <StringView: "click"> }: Expr(<StringView: "() => a">) }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer code then html" {
  let src =
    #|let a = 1
    #|<div>{() => a}</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = 1\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "() => a">),
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer no brace" {
  let src =
    #|let a = 1
    #|<div>() => a</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = 1\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "() => a">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer nested code block attr" {
  let src =
    #|<div value={{ a: { b: 1 } }}></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "value"> }: Expr(<StringView: "{ a: { b: 1 } }">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "custom component" {
  let src =
    #|<What />
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[TagSelfClose({ tag: <StringView: "What">, attrs: <HashMap: {}> })]
    ),
  )
}

///|
test "lexer mixed attributes" {
  let src =
    #|<div data-count={123}></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "data-count"> }: Expr(<StringView: "123">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer muti string" {
  let src =
    #|let s = 
    #|#|<div> <div>
    #|$|abec <button/>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[RawText(<StringView: "let s = \n#|<div> <div>\n$|abec <button/>">)]
    ),
  )
}

///|
test "lexer css block" {
  let src =
    #|let style = ${
    #|  .btn {
    #|    color: red;
    #|  }
    #|}$
    #|let external = ${ !"./style.css" }$

  let lexer = Lexer::new(src)
  let tokens = try! lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let style = ">),
      #|  CSSBlock(<StringView: "\n  .btn {\n    color: red;\n  }\n">),
      #|  RawText(<StringView: "\nlet external = ">),
      #|  CSSBlock(<StringView: " !\"./style.css\" ">),
      #|]
    ),
  )
}

///|
test "lexer css block with comments and strings" {
  let src =
    #|${
    #|  /* CSS comment */
    #|  .title::after {
    #|    content: "hello }$ world"; // string with fake closing tag
    #|  }
    #|}$

  let lexer = Lexer::new(src)
  let tokens = try! lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  CSSBlock(
      #|    <StringView:
      #|      "\n  /* CSS comment */\n  .title::after {\n    content: \"hello }$ world\"; // string with fake closing tag\n  }\n">,
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer nested tag in attribute expression" {
  // <Apple eat={() => {<li>{()=>name.get()}</li>}}/>
  let src =
    #|<Apple eat={() => {<li>{()=>name.get()}</li>}}/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "Apple">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "eat"> }: Expr(<StringView: "() => {<li>{()=>name.get()}</li>}">) }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer nested tag in children expression" {
  // <div>{() => {<li>{()=>name.get()}</li>}}</div>
  let src =
    #|<div>{() => {<li>{()=>name.get()}</li>}}</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "() => ">),
      #|  BraceOpen,
      #|  TagOpen({ tag: <StringView: "li">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "()=>name.get()">),
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "li"> }),
      #|  BraceClose,
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer deeply nested tag in attribute" {
  // <Outer data={() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}}/>
  let src =
    #|<Outer data={() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}}/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "Outer">,
      #|      attrs: <HashMap:
      #|        {
      #|          { ns: None, name: <StringView: "data"> }: Expr(
      #|            <StringView:
      #|              "() => {<Middle label={() => {<Inner>{()=>name.get()}</Inner>}}/>}">,
      #|          ),
      #|        }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer nested tag with method call" {
  // <div>{items.map(() => {<li>{()=>name.get()}</li>})}</div>
  let src =
    #|<div>{items.map(() => {<li>{()=>name.get()}</li>})}</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "items.map(() => ">),
      #|  BraceOpen,
      #|  TagOpen({ tag: <StringView: "li">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "()=>name.get()">),
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "li"> }),
      #|  BraceClose,
      #|  RawText(<StringView: ")">),
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}
