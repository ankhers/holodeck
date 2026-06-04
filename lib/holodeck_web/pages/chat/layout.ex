defmodule HolodeckWeb.Chat.Layout do
  use HolodeckWeb, :layout

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en" data-theme="holodeck">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Holodeck</title>
        <Hologram.UI.Runtime />
        <link rel="stylesheet" href="/assets/css/app.css" />
      </head>
      <body class="m-0 p-0 bg-base-100">
        <slot />
        <HolodeckWeb.Components.Toast cid="toast" />
      </body>
    </html>
    """
  end
end
