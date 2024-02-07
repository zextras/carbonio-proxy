services {
  checks = [
    {
      http     = "http://127.78.0.21:10000"
      method   = "GET"
      timeout  = "1s"
      interval = "5s"
    }
  ]

  connect {
    sidecar_service {
      proxy {
        local_service_address = "127.78.0.21"
      }
    }
  }
  name = "carbonio-clamav-signature-provider"
  port = 10000
}

