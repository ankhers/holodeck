defmodule HolodeckWeb.Components.Toast do
  use HolodeckWeb, :component

  @auto_dismiss_ms 4000

  def init(_props, component, server) do
    {put_state(component, visible: false, message: "", variant: :info, generation: 0), server}
  end

  def action(:show, params, component) do
    generation = component.state.generation + 1

    # Tag delayed actions so an older toast's timer cannot dismiss a newer toast.
    component
    |> put_state(
      visible: true,
      message: params.message,
      variant: params.variant,
      generation: generation
    )
    |> put_action(name: :hide, params: %{generation: generation}, delay: @auto_dismiss_ms)
  end

  def action(:hide, %{generation: generation}, component) do
    if generation == component.state.generation do
      put_state(component, :visible, false)
    else
      component
    end
  end

  def action(:hide, _params, component) do
    put_state(component, :visible, false)
  end

  def template do
    ~HOLO"""
    {%for {region, role, live} <- [{:error, "alert", "assertive"}, {:other, "status", "polite"}]}
      <div id={"toast-region-#{region}"} role={role} aria-live={live} aria-atomic="true">
        {%if @visible and ((region == :error and @variant == :error) or (region == :other and @variant != :error))}
          <div id="toast" class={toast_class(@variant)}>
            <span aria-hidden="true" class={"#{icon_class(@variant)} w-[18px] h-[18px] shrink-0 mt-px #{text_class(@variant)}"}></span>
            <div class="min-w-0 break-words text-[13px] leading-relaxed text-base-content/85 flex-1">{@message}</div>
            <button type="button" aria-label="Dismiss" $click="hide" class="flex items-center justify-center w-8 h-8 -mr-1 -my-1 shrink-0 rounded-md text-base-content/70 border-none p-0 cursor-pointer hover:text-base-content hover:bg-white/5 hover:ring-2 hover:ring-primary/50 focus-visible:outline-2 focus-visible:outline-primary transition-colors"><span aria-hidden="true" class="hero-x-mark w-4 h-4"></span></button>
          </div>
        {/if}
      </div>
    {/for}
    """
  end

  def toast_class(variant) do
    [
      "hd-toast fixed z-50 flex items-start gap-3",
      "top-4 inset-x-4 max-w-sm mx-auto",
      "sm:top-5 sm:left-auto sm:right-5 sm:w-96 sm:mx-0",
      "bg-base-200 border rounded-xl px-4 py-3 shadow-xl shadow-black/40",
      border_class(variant)
    ]
    |> Enum.join(" ")
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
