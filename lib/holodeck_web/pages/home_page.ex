defmodule HolodeckWeb.HomePage do
  use HolodeckWeb, :page

  alias HolodeckWeb.Components.Card

  route "/"

  layout HolodeckWeb.Layout, title: "Home · Holodeck"

  def template do
    ~HOLO"""
    <HolodeckWeb.Components.AppShell>

      <div class="text-center mb-8 sm:mb-12">
        <div class="text-[11px] font-semibold uppercase tracking-[0.12em] text-primary mb-3.5">Hologram Framework</div>
        <h1 class="text-3xl sm:text-4xl font-bold tracking-tight text-base-content mb-3 leading-[1.15]">Holodeck</h1>
        <p class="text-sm text-base-content/50 max-w-[400px] mx-auto leading-relaxed">A showcase app demonstrating the Hologram framework running in different contexts.</p>
      </div>

      <div id="home-demos" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 max-w-[960px] mx-auto">
        <Card icon="hero-chat-bubble-left" title="Chat" body="Real-time messaging with rooms." feature="Commands, broadcasts & sessions" link_page={HolodeckWeb.Chat.LobbyPage} />

        <Card icon="hero-squares-2x2" title="Dashboard" body="Live system metrics, process info, and log streaming." feature="Server ticks & log streaming" link_page={HolodeckWeb.Dashboard.DashboardPage} />

        <Card icon="hero-chart-bar" title="Polls" body="Live voting with real-time results, using Chart.js for visualizations." feature="JS interop with Chart.js" link_page={HolodeckWeb.Poll.PollPage} />

        <Card icon="hero-sparkles" title="Game of Life" body="Explore Conway's cellular automaton." feature="Client-side Elixir · delayed actions · zero simulation commands" link_page={HolodeckWeb.Life.LifePage} />

        <Card icon="hero-view-columns" title="Shared Kanban" body="Move cards together on a shared board." feature="Nested stateful components · targeted actions · optimistic updates" link_page={HolodeckWeb.Kanban.BoardPage} />
      </div>

      <!-- The footer follows the content's 12-unit bottom gap; its negative margin cancels the shell's bottom padding. -->
      <footer class="relative z-[1] text-center mt-12 -mb-12 pb-8 text-xs text-base-content/30">
        Made with ♥ by <a href="https://ankhers.dev" class="hover:text-base-content/60 transition-colors">Ankhers</a> · <a href="https://github.com/ankhers/holodeck" class="hover:text-base-content/60 transition-colors">Source</a>
      </footer>
    </HolodeckWeb.Components.AppShell>
    """
  end
end
