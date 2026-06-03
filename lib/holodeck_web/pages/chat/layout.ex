defmodule HolodeckWeb.Chat.Layout do
  use HolodeckWeb, :layout

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Holodeck</title>
        <Hologram.UI.Runtime />
        <link rel="stylesheet" href="/assets/css/app.css" />
      </head>
      <body style="margin: 0; padding: 0; background: #0f1014;">
        <slot />
      </body>
    </html>
    """
  end
end
