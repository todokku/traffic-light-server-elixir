defmodule TrafficLightWeb.Router do
  use TrafficLightWeb, :router

  alias TrafficLightWeb.Plugs.WebhookToken

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TrafficLightWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :webhooks do
    plug :accepts, ["json"]
    plug WebhookToken, token: Application.get_env(:traffic_light, :ci_secret)
  end

  scope "/", TrafficLightWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  scope "/", TrafficLightWeb do
    pipe_through :api

    resources "/lights", LightSettingController, only: [:show], singleton: true
  end

  scope "/webhooks", TrafficLightWeb do
    pipe_through :webhooks

    resources "/codeship", Webhook.CodeshipController, only: [:create], singleton: true
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: TrafficLightWeb.Telemetry
    end
  end
end
