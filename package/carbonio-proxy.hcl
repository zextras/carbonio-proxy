services {
  check {
    tcp = "127.0.0.1:443"
    timeout = "1s"
    interval = "5s"
  }
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "carbonio-files"
            local_bind_port = 20000
            local_bind_address = "127.78.0.1"
          }
        ]
      }
    }
  }
  name = "carbonio-proxy"
  port = 443
}