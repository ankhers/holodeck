defmodule HolodeckWeb.Components.Card do
  use HolodeckWeb, :component

  alias Hologram.UI.Link

  prop :icon, :string
  prop :title, :string
  prop :body, :string
  prop :link_page, :atom

  def template do
    ~HOLO"""
      <Link to={@link_page} class="block bg-base-200 border border-white/[0.08] rounded-xl p-6 no-underline text-base-content transition-colors hover:border-white/20">
        <div class="w-9 h-9 rounded-lg bg-primary/[0.12] border border-primary/20 flex items-center justify-center mb-4">
          <span class={"#{@icon} w-[18px] h-[18px] text-primary"}></span>
        </div>
        <div class="text-[15px] font-semibold text-base-content mb-1.5">{@title}</div>
        <div class="text-xs text-base-content/45 leading-relaxed">{@body}</div>
        <div class="mt-4 text-[11px] font-semibold uppercase tracking-[0.08em] text-primary">Open →</div>
      </Link>
    """
  end
end
