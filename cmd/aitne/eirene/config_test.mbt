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
  inspect(config.app.name, content="cyber-dashboard")
  inspect(config.app.mode, content="Production")
  inspect(config.app.entry_html, content="main.html")

  inspect(config.build.target, content="Js")
  inspect(config.build.src_dir, content="source")
  inspect(config.build.out_dir, content="build")
  inspect(config.build.public_path, content="/assets/")
  inspect(config.build.minify, content="true")
  inspect(config.build.sourcemap, content="false")
  inspect(config.build.experimental_wasm_gc, content="true")

  inspect(config.server.host, content="0.0.0.0")
  inspect(config.server.port, content="3000")
  inspect(config.server.spa_fallback, content="false")
  inspect(config.server.hmr_enabled, content="false")
  inspect(config.server.hmr_port, content="9999")
  inspect(config.server.https_enabled, content="true")
  inspect(
    config.server.proxy.get("/api"),
    content="Some(http://backend-service)",
  )

  inspect(config.assets.static_dir, content="static")
  inspect(config.assets.inject_scripts.length(), content="2")
}

///|
test "load minimal config" {
  let toml_content =
    #| [app]
    #| name = "minimal-app"

  let config = try! load_config(toml_content)
  inspect(config.app.name, content="minimal-app")

  inspect(config.app.mode, content="Development")
  inspect(config.app.entry_html, content="index.html")

  inspect(config.build.target, content="Js")
  inspect(config.build.src_dir, content="src")
  inspect(config.build.out_dir, content="dist")
  inspect(config.build.minify, content="false")

  inspect(config.server.host, content="127.0.0.1")
  inspect(config.server.port, content="8000")
  inspect(config.server.spa_fallback, content="true")
  inspect(config.server.proxy.length(), content="0")
}
