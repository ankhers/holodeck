defmodule HolodeckWeb.HomePage do
  use HolodeckWeb, :page

  alias Hologram.UI.Link

  route "/"

  layout HolodeckWeb.Chat.Layout

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-100 text-base-content font-sans text-sm relative overflow-x-hidden">

      <div class="hd-grain fixed inset-0 pointer-events-none z-0 opacity-[0.025]"></div>
      <div class="hd-glow fixed top-[-30%] left-1/2 -translate-x-1/2 w-[70vw] h-[50vh] pointer-events-none z-0"></div>

      <div class="relative z-[1] max-w-[1180px] mx-auto px-6 pb-12">

        <nav class="flex items-center py-[18px] mb-12 border-b border-white/[0.08]">
          <div class="flex items-center gap-2.5 text-[15px] font-semibold tracking-[-0.01em]">
            <div class="hd-logo-icon w-7 h-7 rounded-[7px] flex items-center justify-center text-sm font-bold text-white shrink-0">H</div>
            Holodeck
          </div>
        </nav>

        <div class="text-center mb-12">
          <div class="text-[11px] font-semibold uppercase tracking-[0.12em] text-primary mb-3.5">Hologram Framework</div>
          <h1 class="text-4xl font-bold tracking-tight text-base-content mb-3 leading-[1.15]">Holodeck</h1>
          <p class="text-sm text-base-content/50 max-w-[400px] mx-auto leading-relaxed">A showcase app demonstrating the Hologram framework running in different contexts.</p>
        </div>

        <div class="grid grid-cols-2 gap-3 max-w-[640px] mx-auto">

          <Link to={HolodeckWeb.Chat.LobbyPage} class="block bg-base-200 border border-white/[0.08] rounded-xl p-6 no-underline text-base-content transition-colors hover:border-white/20">
            <div class="w-9 h-9 rounded-lg bg-primary/[0.12] border border-primary/20 flex items-center justify-center mb-4">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
            </div>
            <div class="text-[15px] font-semibold text-base-content mb-1.5">Chat</div>
            <div class="text-xs text-base-content/45 leading-relaxed">Real-time messaging with rooms.</div>
            <div class="mt-4 text-[11px] font-semibold uppercase tracking-[0.08em] text-primary">Open →</div>
          </Link>

          <Link to={HolodeckWeb.Dashboard.DashboardPage} class="block bg-base-200 border border-white/[0.08] rounded-xl p-6 no-underline text-base-content transition-colors hover:border-white/20">
            <div class="w-9 h-9 rounded-lg bg-primary/[0.12] border border-primary/20 flex items-center justify-center mb-4">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
            </div>
            <div class="text-[15px] font-semibold text-base-content mb-1.5">Dashboard</div>
            <div class="text-xs text-base-content/45 leading-relaxed">Live system metrics, process info, and log streaming.</div>
            <div class="mt-4 text-[11px] font-semibold uppercase tracking-[0.08em] text-primary">Open →</div>
          </Link>

        </div>

      </div>
    </div>
    """
  end
end
