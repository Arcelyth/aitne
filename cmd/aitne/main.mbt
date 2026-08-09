///|
fn compile_mbx_file(
  path : String,
  show : Bool,
  not_tmp : Bool,
  out_dir : String?,
  style_buffer : Ref[StringBuilder],
) -> Unit {
  if path.has_suffix(".mbx") {
    let target = match out_dir {
      Some(dir) => {
        let mut last_slash = -1
        for i = 0; i < path.length(); i = i + 1 {
          if path[i] == '/' || path[i] == '\\' {
            last_slash = i
          }
        }
        let filename = if last_slash == -1 {
          path
        } else {
          path[last_slash:path.length()].to_owned()
        }
        dir + filename + ".mbt"
      }
      None => path + ".mbt"
    }
    let _ = @mbxc.from_file(
      path,
      show~,
      to=Some(target),
      not_tmp~,
      style_buffer,
    )
  }
}

///|
pub fn walk_and_compile(
  dir : String,
  show? : Bool = false,
  not_tmp? : Bool = false,
  out_dir : String?,
  style_buffer : Ref[StringBuilder],
  style_root : Array[String],
) -> Unit raise @fs.IOError {
  let files = @fs.read_dir(dir) catch {
    e => {
      debug(e)
      return
    }
  }
  for file in files {
    if file == "." || file == ".." {
      continue
    }
    let path = dir + "/" + file
    if @fs.is_dir(path) {
      walk_and_compile(path, show~, not_tmp~, out_dir, style_buffer, style_root)
    } else if path.has_suffix(".mbx") {
      compile_mbx_file(path, show, not_tmp, out_dir, style_buffer)
    }
  }
}

///|
#cfg(target="native")
async fn main {
  let args = @sys.get_cli_args()
  let arg_len = args.length()
  let cmd = if arg_len == 1 { "help" } else { args[1] }

  let mut target_file : String? = None
  let mut step = 1

  match cmd {
    "help" => show_main_help()
    "mbxc" => {
      let mut style_root = []
      let content = match get_config(target_file) {
        Some(c) => c
        None => return
      }
      try {
        let cfg = @eirene.load_config(content)
        style_root = cfg.build.style_root
      } catch {
        err => debug("Config Error: \{to_repr(err)}")
      }
      let mut show = false
      let mut not_tmp = false
      let mut _help = false
      let target_dir = "."
      let mut out_dir : String? = None
      let mut style_dir = "./dist"
      let style_buffer = StringBuilder::new()

      if arg_len == 3 && args[2] == "help" {
        show_mbxc_help()
        return
      }

      for i = 2; i < args.length(); i = i + step {
        step = 1
        let arg = args[i]
        match arg {
          "--show" | "-s" => show = true
          "--no-template" | "-n" => not_tmp = true
          "--out-dir" | "-o" =>
            if i + 1 < args.length() {
              out_dir = Some(args[i + 1])
              step = 2
            } else {
              println("Error: Missing path for --out-dir/-o option")
              return
            }
          "--style-dir" =>
            if i + 1 < args.length() {
              style_dir = args[i + 1]
              step = 2
            } else {
              println("Error: Missing path for --style-dir option")
              return
            }
          "--file" | "-f" =>
            if i + 1 < args.length() {
              target_file = Some(args[i + 1])
              step = 2
            } else {
              println("Error: Missing file path for --file/-f option")
              return
            }
          _ => ()
        }
      }

      match out_dir {
        Some(dir) =>
          if !@fs.path_exists(dir) {
            @fs.create_dir(dir) catch {
              _ => {
                println("Error: Failed to create output directory '\{dir}'")
                return
              }
            }
          }
        None => ()
      }

      match target_file {
        Some(file) =>
          compile_mbx_file(file, show, not_tmp, out_dir, Ref(style_buffer))
        None =>
          walk_and_compile(
            target_dir,
            show~,
            not_tmp~,
            out_dir,
            Ref(style_buffer),
            style_root,
          ) catch {
            e => debug(e)
          }
      }

      if !@fs.path_exists(style_dir) {
        @fs.create_dir(style_dir) catch {
          _ => ()
        }
      }
      let css_path = if style_dir.has_suffix("/") || style_dir.has_suffix("\\") {
        style_dir + "style.css"
      } else {
        style_dir + "/style.css"
      }
      @fs.write_string_to_file(css_path, style_buffer.to_string()) catch {
        _ => println("Error: Failed to write style file '\{css_path}'")
      }
    }
    "run" => {
      if arg_len == 3 && args[2] == "help" {
        show_run_help()
        return
      }

      for i = 2; i < args.length(); i = i + step {
        step = 1
        let arg = args[i]
        match arg {
          "--file" | "-f" =>
            if i + 1 < args.length() {
              target_file = Some(args[i + 1])
              step = 2
            } else {
              println("Error: Missing file path for --file/-f option")
              return
            }
          _ => ()
        }
      }

      let content = match get_config(target_file) {
        Some(c) => c
        None => return
      }

      try {
        let cfg = @eirene.load_config(content)
        @eirene.start_server(cfg) catch {
          err => debug("Server Error: \{to_repr(err)}")
        }
      } catch {
        err => debug("Config Error: \{to_repr(err)}")
      }
    }
    "init" => {
      let mut project_name : String? = None
      let mut template : String? = None
      if arg_len == 3 && args[2] == "help" {
        show_init_help()
        return
      }

      if arg_len == 3 && (args[2] == "--list" || args[2] == "-l") {
        list_templates_local()
        return
      } else if arg_len == 3 && (args[2] == "--list-remote" || args[2] == "-lr") {
        list_templates_remote()
        return
      }

      if arg_len >= 3 {
        project_name = Some(args[2])
      } else {
        println("Error: Please enter project's name")
        return
      }

      for i = 3; i < args.length(); i = i + step {
        step = 1
        let arg = args[i]
        match arg {
          "--template" | "-t" =>
            if i + 1 < args.length() {
              template = Some(args[i + 1])
              step = 2
            } else {
              println("Error: Missing template name")
              return
            }
          _ => ()
        }
      }

      let tmpl_name = match template {
        Some(t) => t
        None => "starter"
      }
      let p_name = match project_name {
        Some(n) => n
        None => {
          println("Error: Project name is none, this should be unreachable")
          return
        }
      }

      println(
        "Setup: Initializing project `\{p_name}` using template `\{tmpl_name}`...",
      )
      let _repo_url = "https://github.com/aitne-dev/template-\{tmpl_name}.git"
      init_project(p_name, tmpl_name)
    }
    "build" => handle_build()
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
    #|  run                 run current project locally
    #|  build               build aitne project

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
    #|  --show, -s              output the compile process information
    #|  --no-template, -n       not generate template code
    #|  --out-dir, -o <path>    the output path
    #|  --style-dir <path>      the style's path
    #|  --file, -f <file>       compile a specific MBX file

  println(content)
}

///|
fn show_run_help() -> Unit {
  let content =
    #|Usage: aitne run [options]
    #| 
    #|options: 
    #|  --file, -f <file>       specify an eirene.toml file

  println(content)
}

///|
fn show_init_help() -> Unit {
  let content =
    #|Usage: aitne init <project_name> [options]
    #| 
    #|options: 
    #|  --template, -t <name>     specity a template [default: starter]
    #|  --list, -l                list all the usable templates
    #|  --list-remote, -lr        list all the usable templates from github

  println(content)
}

///|
fn get_config(target_file : String?) -> String? {
  match target_file {
    Some(file) =>
      Some(
        @fs.read_file_to_string(file) catch {
          _ => {
            println("Failed to read file \{file}")
            return None
          }
        },
      )
    None =>
      if @fs.path_exists("./eirene.toml") {
        Some(
          @fs.read_file_to_string("./eirene.toml") catch {
            _ => {
              println("Failed to read file ./eirene.toml")
              return None
            }
          },
        )
      } else {
        println("Error: Cannot find 'eirene.toml' at the current folder")
        return None
      }
  }
}
