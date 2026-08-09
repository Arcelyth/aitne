///|
pub fn from_file(
  path : String,
  show? : Bool = false,
  to? : String? = None,
  not_tmp? : Bool = false,
  output_style : Ref[StringBuilder],
  //  style_root? : Array[String] = [],
) -> String? {
  let content = @fs.read_file_to_string(path) catch {
    e => {
      debug(e)
      return None
    }
  }
  let lexer = Lexer::new(content)
  let tokens = lexer.tokenizer() catch {
    e => {
      debug(e)
      panic()
    }
  }
  if show {
    debug(tokens)
  }
  let parser = Parser::new(tokens)

  let asts = try! parser.parse()
  if show {
    debug(asts)
  }

  let gen = if not_tmp {
    let codegen = CodeGen::new(path~)
    let res = codegen.generate(asts)
    output_style.val.write_string(codegen.output_style())
    res
  } else {
    let codegen = CodeGenTmp::new(asts)
    codegen.generate()
  }
  match to {
    Some(target) => {
      @fs.write_string_to_file(target, gen) catch {
        e => {
          debug(e)
          return None
        }
      }
      Some(gen)
    }
    None => Some(gen)
  }
}
