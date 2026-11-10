defmodule HolodeckWeb.Components.Card do
  use HolodeckWeb, :component

  alias Hologram.UI.Link

  prop :icon, :string
  prop :title, :string
  prop :body, :string
  prop :link_page, :atom
  prop :feature, :string, default: ""

  def template do
    ~HOLO"""
      <Link to={@link_page} class="flex min-w-0 flex-col bg-base-200 border border-white/[0.08] rounded-xl p-6 no-underline text-base-content transition duration-200 hover:border-primary/35 hover:shadow-[0_8px_30px_-12px_rgba(167,139,250,0.25)] motion-safe:hover:-translate-y-1 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary">
        <div class="w-9 h-9 rounded-lg bg-primary/[0.12] border border-primary/20 flex items-center justify-center mb-4">
          <span class={"#{@icon} w-[18px] h-[18px] text-primary"}></span>
        </div>
        <div class="text-[15px] font-semibold text-base-content mb-1.5">{@title}</div>
        <div class="text-xs text-base-content/45 leading-relaxed">{@body}</div>
        <div class="mt-auto pt-3">
          {%if @feature != ""}
            <div class="mb-5 text-[11px] font-mono text-primary/90">{@feature}</div>
          {/if}
          <div class="text-[11px] font-semibold uppercase tracking-[0.08em] text-primary">Open →</div>
        </div>
      </Link>
    """
  end
end
