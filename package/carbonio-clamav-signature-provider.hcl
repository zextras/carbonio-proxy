services {
  checks = [
    {
      http     = "http://127.78.0.1:10000",
      method   = "GET",
      timeout  = "1s",
      interval = "5s"
    }
  ],

  connect {
    sidecar_service {}
  }

  name = "carbonio-clamav-signature-provider"
  port = 10000
}
