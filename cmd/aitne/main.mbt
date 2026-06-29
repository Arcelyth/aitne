///|
pub fn walk_and_compile(
  dir : String,
  show? : Bool = false,
  tmp? : Bool = false,
) -> Unit raise @fs.IOError {
  let entries = try? @fs.read_dir(dir)
  match entries {
    Ok(files) =>
      for file in files {
        if file == "." || file == ".." {
          continue
        }

        let path = dir + "/" + file

        if @fs.is_dir(path) {
          walk_and_compile(path, show~, tmp~)
        } else if path.has_suffix(".mbx") {
          let target = path[0:path.length()] + ".mbt"
          let _ = @mbxc.from_file(path, show~, to=Some(target.to_owned()), tmp~)
        }
      }
    Err(e) => debug(e)
  }
}

///|
fn main {
  let args = @sys.get_cli_args()
  let arg_len = args.length()
  let cmd = if arg_len == 1 { "help" } else { args[1] }

  match cmd {
    "help" => show_main_help()
    "mbxc" => {
      let mut show = false
      let mut tmp = false
      let mut help = false
      let target_dir = "."

      if arg_len == 3 && args[2] == "help" {
        show_mbxc_help()
        return
      }

      for i = 2; i < args.length(); i = i + 1 {
        let arg = args[i]
        match arg {
          "--show" | "-s" => show = true
          "--template" | "-t" => tmp = true
          _ => ()
        }
      }
      let res = try? walk_and_compile(target_dir, show~, tmp~)
      match res {
        Ok(_) => ()
        Err(e) => debug(e)
      }
    }
    "init" => ()
    cmd => show_unknown_command(cmd)
  }
}

///|
fn show_main_help() -> Unit {
  let content =
    #|Usage: aitne [command] [options]
    #| 
    #|command: 
    #|  init                initialize a new project
    #|  mbxc                compile all the MBX file under current dictionary

  println(content)
}

///|
fn show_unknown_command(cmd : String) -> Unit {
  println("Unknown command: \{cmd}, use `aitne help` to show the usage.")
}

///|
fn show_mbxc_help() -> Unit {
  let content =
    #|Usage: aitne mbxc [options]
    #| 
    #|options: 
    #|  --show, -s            output the compile process information
    #|  --template, -t        use template mode [WIP]

  println(content)
}
