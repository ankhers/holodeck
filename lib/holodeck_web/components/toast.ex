defmodule HolodeckWeb.Components.Toast do
  use HolodeckWeb, :component

  @auto_dismiss_ms 4000

  def init(_props, component, server) do
    {put_state(component, visible: false, message: "", variant: :info), server}
  end

  def action(:show, params, component) do
    component
    |> put_state(visible: true, message: params.message, variant: params.variant)
    |> put_action(name: :hide, delay: @auto_dismiss_ms)
  end

  def action(:hide, _params, component) do
    put_state(component, :visible, false)
  end

  def template do
    ~HOLO"""
    {%if @visible}
      <div id="toast" role="status" aria-live="polite" class={"hd-toast fixed top-4 inset-x-4 sm:top-5 sm:left-auto sm:right-5 z-50 flex items-start gap-3 sm:w-96 max-w-sm mx-auto sm:mx-0 bg-base-200 border rounded-xl px-4 py-3 shadow-xl shadow-black/40 #{border_class(@variant)}"}>
        <span class={"#{icon_class(@variant)} w-[18px] h-[18px] shrink-0 mt-px #{text_class(@variant)}"}></span>
        <div class="min-w-0 break-words text-[13px] leading-relaxed text-base-content/85 flex-1">{@message}</div>
        <button type="button" aria-label="Dismiss" $click="hide" class="flex items-center justify-center w-7 h-7 -mr-1 -my-0.5 shrink-0 rounded-md text-base-content/50 border-none p-0 cursor-pointer hover:text-base-content hover:bg-white/5 focus-visible:outline-2 focus-visible:outline-primary transition-colors"><span aria-hidden="true" class="hero-x-mark w-4 h-4"></span></button>
      </div>
    {/if}
    """
  end

  def icon_class(:success), do: "hero-check-circle"
  def icon_class(:error), do: "hero-x-circle"
  def icon_class(_), do: "hero-information-circle"

  def text_class(:success), do: "text-success"
  def text_class(:error), do: "text-error"
  def text_class(_), do: "text-primary"

  def border_class(:success), do: "border-success/30"
  def border_class(:error), do: "border-error/30"
  def border_class(_), do: "border-primary/30"
end
