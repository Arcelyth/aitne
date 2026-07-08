///|
test "load config" {
  let toml_content =
    #| [app]
    #| name = "cyber-dashboard"
    #| mode = "production"
    #| entry_html = "main.html"
    #| 
    #| [build]
    #| target = "js"
    #| src_dir = "source"
    #| out_dir = "build"
    #| public_path = "/assets/"
    #| minify = true
    #| sourcemap = false
    #| experimental_wasm_gc = true
    #| 
    #| [server]
    #| host = "0.0.0.0"
    #| port = 3000
    #| spa_fallback = false
    #| hmr_enabled = false
    #| hmr_port = 9999
    #| https_enabled = true
    #| 
    #| [server.proxy]
    #| "/api" = "http://backend-service"
    #| 
    #| [assets]
    #| static_dir = "static"
    #| inject_scripts = ["https://cdn.com/a.js", "https://cdn.com/b.js"]

  let config = try! load_config(toml_content)
  debug_inspect(
    config.app.name,
    content=(
      #|"cyber-dashboard"
    ),
  )
  debug_inspect(config.app.mode, content="Production")
  debug_inspect(
    config.app.entry_html,
    content=(
      #|"main.html"
    ),
  )

  debug_inspect(config.build.target, content="Js")
  debug_inspect(
    config.build.src_dir,
    content=(
      #|"source"
    ),
  )
  debug_inspect(
    config.build.out_dir,
    content=(
      #|"build"
    ),
  )
  debug_inspect(
    config.build.public_path,
    content=(
      #|"/assets/"
    ),
  )
  debug_inspect(config.build.minify, content="true")
  debug_inspect(config.build.sourcemap, content="false")
  debug_inspect(config.build.experimental_wasm_gc, content="true")

  debug_inspect(
    config.server.host,
    content=(
      #|"0.0.0.0"
    ),
  )
  debug_inspect(config.server.port, content="3000")
  debug_inspect(config.server.spa_fallback, content="false")
  debug_inspect(config.server.hmr_enabled, content="false")
  debug_inspect(config.server.hmr_port, content="9999")
  debug_inspect(config.server.https_enabled, content="true")
  debug_inspect(
    config.server.proxy.get("/api"),
    content=(
      #|Some("http://backend-service")
    ),
  )

  debug_inspect(
    config.assets.static_dir,
    content=(
      #|"static"
    ),
  )
  debug_inspect(config.assets.inject_scripts.length(), content="2")
}

///|
test "load minimal config" {
  let toml_content =
    #| [app]
    #| name = "minimal-app"

  let config = try! load_config(toml_content)
  debug_inspect(
    config.app.name,
    content=(
      #|"minimal-app"
    ),
  )

  debug_inspect(config.app.mode, content="Development")
  debug_inspect(
    config.app.entry_html,
    content=(
      #|"index.html"
    ),
  )

  debug_inspect(config.build.target, content="Js")
  debug_inspect(
    config.build.src_dir,
    content=(
      #|"src"
    ),
  )
  debug_inspect(
    config.build.out_dir,
    content=(
      #|"dist"
    ),
  )
  debug_inspect(config.build.minify, content="false")

  debug_inspect(
    config.server.host,
    content=(
      #|"127.0.0.1"
    ),
  )
  debug_inspect(config.server.port, content="8000")
  debug_inspect(config.server.spa_fallback, content="true")
  debug_inspect(config.server.proxy.length(), content="0")
}
