///|
fn compile_file(path : String, show : Bool, tmp : Bool) -> Unit {
  if path.has_suffix(".mbx") {
    let target = path[0:path.length()] + ".mbt"
    let _ = @mbxc.from_file(path, show~, to=Some(target.to_owned()), tmp~)
  }
}

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
        } else {
          compile_file(path, show, tmp)
        }
      }
    Err(e) => debug(e)
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
      let mut show = false
      let mut tmp = false
      let mut help = false
      let target_dir = "."

      if arg_len == 3 && args[2] == "help" {
        show_mbxc_help()
        return
      }

      for i = 2; i < args.length(); i = i + step {
        step = 1
        let arg = args[i]
        match arg {
          "--show" | "-s" => show = true
          "--template" | "-t" => tmp = true
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

      match target_file {
        Some(file) => compile_file(file, show, tmp)
        None => {
          let res = try? walk_and_compile(target_dir, show~, tmp~)
          match res {
            Ok(_) => ()
            Err(e) => debug(e)
          }
        }
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

      let content = match target_file {
        Some(file) =>
          match (try? @fs.read_file_to_string("file")) {
            Ok(f) => f
            Err(_) => {
              println("Failed to read file \{file}")
              return
            }
          }
        None =>
          if @fs.path_exists("./eirene.toml") {
            match (try? @fs.read_file_to_string("./eirene.toml")) {
              Ok(f) => f
              Err(err) => {
                println("Failed to read file ./eirene.toml")
                return
              }
            }
          } else {
            println("Error: Cannot find 'eirene.toml' at the current folder")
            return
          }
      }

      match (try? @eirene.load_config(content)) {
        Ok(cfg) =>
          match (try? @eirene.start_server(cfg)) {
            Ok(_) => ()
            Err(err) => println("Server Error: \{err}")
          }
        Err(err) => println("Config Error: \{err}")
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
      let repo_url = "https://github.com/aitne-dev/template-\{tmpl_name}.git"
      init_project(p_name, tmpl_name)
    }
    cmd => show_unknown_command(cmd)
  }
}

///|
fn show_main_help() -> Unit {
  let content =
    #|Usage: aitne [command] [options]
    #| 
    #|command: 
    #|  init                initialize a new project [WIP]
    #|  mbxc                compile all the MBX file under current dictionary
    #|  run                 run current project locally

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
    #|  --file, -f <file>     compile a specific MBX file

  println(content)
}

///|
fn show_run_help() -> Unit {
  let content =
    #|Usage: aitne mbxc [options]
    #| 
    #|options: 
    #|  --file, -f <file>     specify an eirene.toml file

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
