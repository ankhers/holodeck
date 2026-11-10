defmodule HolodeckWeb.Components.PageHeader do
  @moduledoc """
  The heading every app page opens with: a kicker naming the Hologram feature
  on show, the page's `h1`, and an optional description.

  Slot content renders on the right (or below, on narrow screens) and is owned
  by the template that supplies it, so buttons there dispatch to that page or
  component as usual.
  """
  use HolodeckWeb, :component

  prop :kicker, :string, default: ""
  prop :title, :string
  prop :description, :string, default: ""

  def template do
    ~HOLO"""
    <header class="mb-6 sm:mb-8 flex flex-wrap items-end justify-between gap-x-6 gap-y-4">
      <div class="min-w-0">
        {%if @kicker != ""}
          <p class="text-primary text-[11px] font-mono uppercase tracking-[0.15em] mb-2">{@kicker}</p>
        {/if}
        <h1 class="text-2xl sm:text-3xl font-semibold tracking-tight text-base-content break-words">{@title}</h1>
        {%if @description != ""}
          <p class="text-base-content/50 text-sm leading-relaxed mt-2 max-w-xl">{@description}</p>
        {/if}
      </div>
      <div class="flex flex-wrap items-center gap-2 empty:hidden"><slot /></div>
    </header>
    """
  end
end
