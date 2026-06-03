defmodule HolodeckWeb.HomePage do
  use HolodeckWeb, :page

  alias Hologram.UI.Link
  alias HolodeckWeb.Components.Card

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

        <div class="grid grid-cols-3 gap-3 max-w-[960px] mx-auto">
          <Card icon="hero-chat-bubble-left" title="Chat" body="Real-time messaging with rooms." link_page={HolodeckWeb.Chat.LobbyPage} />

          <Card icon="hero-squares-2x2" title="Dashboard" body="Live system metrics, process info, and log streaming." link_page={HolodeckWeb.Dashboard.DashboardPage} />

          <Card icon="hero-chart-bar" title="Polls" body="Live voting with real-time results, using Chart.js for visualizations." link_page={HolodeckWeb.Poll.PollPage} />
        </div>

      </div>

      <footer class="relative z-[1] text-center pb-8 text-xs text-base-content/30">
        Made with ♥ by <a href="https://ankhers.dev" class="hover:text-base-content/60 transition-colors">Ankhers</a> · <a href="https://git.sr.ht/~ankhers/holodeck" class="hover:text-base-content/60 transition-colors">Source</a>
      </footer>
    </div>
    """
  end
end
