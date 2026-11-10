defmodule HolodeckWeb.Components.AppShell do
  @moduledoc """
  Shared page chrome with linked breadcrumbs and a default content slot.

  Breadcrumbs are `{label, page}` pairs; use `nil` for the current page.
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

      <div class={if(@full_height, do: "contents", else: "relative z-[1] max-w-[1180px] mx-auto px-6 pb-12")}>
        <nav aria-label="Breadcrumb" class={nav_class(@full_height, @breadcrumbs, @connected)}>
          <div class="flex items-center gap-2.5 text-[15px] font-semibold tracking-[-0.01em]">
            {%if @breadcrumbs == []}
              <div class="hd-logo-icon w-7 h-7 rounded-[7px] flex items-center justify-center text-sm font-bold text-white shrink-0">H</div>
              Holodeck
            {%else}
              <Hologram.UI.Link to={HolodeckWeb.HomePage} aria-label="Home" class="flex items-center gap-2.5 no-underline text-base-content">
                <div class="hd-logo-icon w-7 h-7 rounded-[7px] flex items-center justify-center text-sm font-bold text-white shrink-0">H</div>
                Home
              </Hologram.UI.Link>
              {%for {label, page} <- @breadcrumbs}
                <span class="text-base-content/50 mx-px">/</span>
                {%if page}
                  <Hologram.UI.Link to={page} class="text-base-content/75 font-normal no-underline">{label}</Hologram.UI.Link>
                {%else}
                  <span aria-current="page" class={if(@full_height, do: "text-secondary font-normal", else: "text-base-content/75 font-normal")}>{label}</span>
                {/if}
              {/for}
            {/if}
          </div>
          {%if @connected}
            <div class="flex items-center gap-1.5 text-xs text-success bg-success/[0.07] border border-success/[0.18] px-[11px] py-1 rounded-full">
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
    do: "relative z-[1] flex items-center px-6 py-[18px] border-b border-white/[0.08] shrink-0"

  def nav_class(false, breadcrumbs, connected) do
    margin = if breadcrumbs == [], do: "mb-12", else: "mb-6"
    alignment = if connected, do: "justify-between", else: ""
    "flex items-center #{alignment} py-[18px] #{margin} border-b border-white/[0.08]"
  end
end
