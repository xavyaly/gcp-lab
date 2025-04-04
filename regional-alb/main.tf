provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_instance_group" "default" {
  name        = "external-alb"
  zone        = "${var.region}-a"
  instances   = []
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "http" {
  name               = "http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5

  http_health_check {
    port = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  health_checks         = [google_compute_health_check.http.id]
  backend {
    group = google_compute_instance_group.default.self_link
  }
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name   = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-forwarding-rule"
  #load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.self_link
  ip_protocol           = "TCP"
  #network_tier          = "PREMIUM"
  #region                = var.region
}