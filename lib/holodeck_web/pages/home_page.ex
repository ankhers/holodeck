defmodule HolodeckWeb.HomePage do
  use HolodeckWeb, :page

  alias Hologram.UI.Link

  route "/"

  layout HolodeckWeb.Chat.Layout

  def template do
    ~HOLO"""
    <div style="background: #0f1014; color: #eeeeee; font-family: ui-sans-serif, system-ui, sans-serif; font-size: 14px; min-height: 100vh; position: relative; overflow-x: hidden;">

      <!-- Grain overlay -->
      <div style="position: fixed; inset: 0; background-image: url(&quot;data:image/svg+xml,%3Csvg viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/%3E%3C/svg%3E&quot;); background-size: 256px 256px; pointer-events: none; z-index: 0; opacity: 0.025;"></div>

      <!-- Violet glow -->
      <div style="position: fixed; top: -30%; left: 50%; transform: translateX(-50%); width: 70vw; height: 50vh; background: radial-gradient(ellipse, rgba(167,139,250,0.1) 0%, transparent 70%); pointer-events: none; z-index: 0;"></div>

      <div style="position: relative; z-index: 1; max-width: 1180px; margin: 0 auto; padding: 0 24px 48px;">

        <!-- Navbar -->
        <nav style="display: flex; align-items: center; padding: 18px 0; margin-bottom: 48px; border-bottom: 1px solid rgba(255,255,255,0.08);">
          <div style="display: flex; align-items: center; gap: 10px; font-size: 15px; font-weight: 600; letter-spacing: -0.01em;">
            <div style="width: 28px; height: 28px; border-radius: 7px; background: linear-gradient(135deg, #7c3aed, #a78bfa); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; color: white; flex-shrink: 0; box-shadow: 0 0 14px rgba(167,139,250,0.45), 0 0 0 1px rgba(167,139,250,0.2);">H</div>
            Holodeck
          </div>
        </nav>

        <!-- Hero -->
        <div style="text-align: center; margin-bottom: 48px;">
          <div style="font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.12em; color: #a78bfa; margin-bottom: 14px;">Hologram Framework</div>
          <h1 style="font-size: 36px; font-weight: 700; letter-spacing: -0.03em; color: #eeeeee; margin: 0 0 12px 0; line-height: 1.15;">Holodeck</h1>
          <p style="font-size: 14px; color: rgba(194,194,194,0.5); margin: 0; max-width: 400px; margin: 0 auto; line-height: 1.6;">A showcase app demonstrating the Hologram framework running in different contexts.</p>
        </div>

        <!-- Nav cards -->
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; max-width: 640px; margin: 0 auto;">

          <Link to={HolodeckWeb.Chat.LobbyPage} style="display: block; background: #1a1b21; border: 1px solid rgba(255,255,255,0.08); border-radius: 10px; padding: 24px; text-decoration: none; color: inherit; transition: border-color 0.15s;">
            <div style="width: 36px; height: 36px; border-radius: 8px; background: rgba(167,139,250,0.12); border: 1px solid rgba(167,139,250,0.2); display: flex; align-items: center; justify-content: center; margin-bottom: 16px;">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#a78bfa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
            </div>
            <div style="font-size: 15px; font-weight: 600; color: #eeeeee; margin-bottom: 6px;">Chat</div>
            <div style="font-size: 12px; color: rgba(194,194,194,0.45); line-height: 1.5;">Real-time messaging with rooms.</div>
            <div style="margin-top: 16px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em; color: #a78bfa;">Open &rarr;</div>
          </Link>

          <Link to={HolodeckWeb.Dashboard.DashboardPage} style="display: block; background: #1a1b21; border: 1px solid rgba(255,255,255,0.08); border-radius: 10px; padding: 24px; text-decoration: none; color: inherit; transition: border-color 0.15s;">
            <div style="width: 36px; height: 36px; border-radius: 8px; background: rgba(167,139,250,0.12); border: 1px solid rgba(167,139,250,0.2); display: flex; align-items: center; justify-content: center; margin-bottom: 16px;">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#a78bfa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
            </div>
            <div style="font-size: 15px; font-weight: 600; color: #eeeeee; margin-bottom: 6px;">Dashboard</div>
            <div style="font-size: 12px; color: rgba(194,194,194,0.45); line-height: 1.5;">Live system metrics, process info, and log streaming.</div>
            <div style="margin-top: 16px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em; color: #a78bfa;">Open &rarr;</div>
          </Link>

        </div>

      </div>
    </div>
    """
  end
end
