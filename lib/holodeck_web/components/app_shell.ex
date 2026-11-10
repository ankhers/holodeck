defmodule HolodeckWeb.Components.AppShell do
  @moduledoc """
  Shared page chrome with linked breadcrumbs and a default content slot.

  Breadcrumbs are `{label, page}` pairs; use `nil` for the current page.
  A page may also be `{Module, params}`, for example
  `{"# general", {HolodeckWeb.Chat.RoomPage, room_name: "general"}}`.
  `full_height` preserves the chat room's viewport and scroll regions, while
  `connected` adds the dashboard's status pill. An empty breadcrumb list is home.
  """
  use HolodeckWeb, :component

  prop :breadcrumbs, :list, default: []
  prop :full_height, :boolean, default: false
  prop :connected, :boolean, default: false

  def template do
    ~HOLO"""
    <div class={if(@full_height, do: "h-dvh bg-base-100 text-base-content flex flex-col relative overflow-hidden", else: "min-h-screen bg-base-100 text-base-content font-sans text-sm relative overflow-x-hidden")}>
      <div class="hd-grain fixed inset-0 pointer-events-none z-0 opacity-[0.025]"></div>
      <div class="hd-glow fixed top-[-30%] left-1/2 -translate-x-1/2 w-[70vw] h-[50vh] pointer-events-none z-0"></div>

      <div class={if(@full_height, do: "contents", else: "relative z-[1] max-w-[1180px] mx-auto px-4 sm:px-6 pb-12")}>
        <nav aria-label="Breadcrumb" class={nav_class(@full_height, @breadcrumbs, @connected)}>
          <div class="flex min-w-0 flex-1 items-center gap-2 sm:gap-2.5 text-[13px] sm:text-[15px] font-semibold tracking-[-0.01em]">
            <Hologram.UI.Link to={HolodeckWeb.HomePage} class="flex shrink-0 items-center gap-2 sm:gap-2.5 no-underline text-base-content">
              <div class="hd-logo-icon w-7 h-7 rounded-[7px] flex items-center justify-center text-sm font-bold text-white shrink-0">H</div>
              {if(@breadcrumbs == [], do: "Holodeck", else: "Home")}
            </Hologram.UI.Link>
            {%if @breadcrumbs != []}
              {%for {label, page} <- @breadcrumbs}
                <span class="shrink-0 text-base-content/50 mx-px">/</span>
                {%if page}
                  <Hologram.UI.Link to={page} class="shrink-0 text-base-content/75 font-normal no-underline">{label}</Hologram.UI.Link>
                {%else}
                  <span aria-current="page" title={label} class={if(@full_height, do: "min-w-0 truncate text-secondary font-normal", else: "min-w-0 truncate text-base-content/75 font-normal")}>{label}</span>
                {/if}
              {/for}
            {/if}
          </div>
          {%if @connected}
            <div class="flex shrink-0 items-center gap-1.5 text-xs text-success bg-success/[0.07] border border-success/[0.18] px-[11px] py-1 rounded-full">
              <div class="hd-live-dot"></div>
              connected
            </div>
          {/if}
        </nav>
        <slot />
      </div>
    </div>
    """
  end

  def nav_class(true, _breadcrumbs, _connected),
    do:
      "relative z-[1] flex min-w-0 items-center gap-3 px-4 sm:px-6 py-[18px] border-b border-white/[0.08] shrink-0"

  def nav_class(false, breadcrumbs, _connected) do
    margin = if breadcrumbs == [], do: "mb-8 sm:mb-12", else: "mb-6"

    [
      "flex min-w-0 items-center gap-3",
      "py-[18px]",
      margin,
      "border-b border-white/[0.08]"
    ]
    |> Enum.join(" ")
  end
end
