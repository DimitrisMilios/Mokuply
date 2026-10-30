import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../widgets/clay/clay.dart';
import 'info_page.dart';

enum _AiClient { claudeCode, claudeDesktop, cursor, other }

/// Step-by-step setup for the Mockuply MCP server (tools/mcp-server) in
/// Claude Code, Claude Desktop, Cursor and other MCP clients.
class ConnectAiView extends StatefulWidget {
  const ConnectAiView({super.key});

  @override
  State<ConnectAiView> createState() => _ConnectAiViewState();
}

class _ConnectAiViewState extends State<ConnectAiView> {
  _AiClient _client = _AiClient.claudeCode;

  static const String _install = 'git clone ${AppLinks.repo}.git\n'
      'cd Mokuply/tools/mcp-server\n'
      'npm install\n'
      'npm run build';

  static const String _claudeCodeAdd = 'claude mcp add --scope user mokuply -- node "\$PWD/dist/index.js"';

  static const String _configJson = '{\n'
      '  "mcpServers": {\n'
      '    "mokuply": {\n'
      '      "command": "node",\n'
      '      "args": ["/path/to/Mokuply/tools/mcp-server/dist/index.js"]\n'
      '    }\n'
      '  }\n'
      '}';

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: 'Connect your AI',
      subtitle:
          'The Mockuply MCP server lets Claude Code, Claude Desktop, Cursor and other AI assistants capture your '
          'simulator, write store copy and open the finished project right here, ready to export. It runs on your '
          'computer and never uploads your screenshots.',
      children: [
        const InfoSection(
          step: 1,
          title: 'What you need',
          children: [
            InfoBullets([
              InfoBullet('Node.js 18 or newer, and Git.', lead: 'Required:'),
              InfoBullet(
                'Xcode on a Mac for iOS Simulator capture, or Android platform-tools (adb) for Android emulators '
                'and devices. Without them you can still use screenshot files from your project.',
                lead: 'Optional:',
              ),
            ]),
            InfoLinks({'Download Node.js': AppLinks.nodeJs}),
          ],
        ),
        const InfoSection(
          step: 2,
          title: 'Install the server (once)',
          children: [
            InfoText('Run this in a terminal (macOS, Linux or Windows PowerShell). It downloads Mockuply and builds '
                'the MCP server:'),
            InfoCode(_install),
            InfoText('Stay in the tools/mcp-server folder for the next step.'),
          ],
        ),
        InfoSection(
          step: 3,
          title: 'Add it to your AI assistant',
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ClaySegmented<_AiClient>(
                  selected: _client,
                  onChanged: (value) => setState(() => _client = value),
                  segments: const [
                    ClaySegment(value: _AiClient.claudeCode, label: 'Claude Code'),
                    ClaySegment(value: _AiClient.claudeDesktop, label: 'Claude Desktop'),
                    ClaySegment(value: _AiClient.cursor, label: 'Cursor'),
                    ClaySegment(value: _AiClient.other, label: 'Other'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(key: ValueKey(_client), child: _clientSteps(_client)),
            ),
          ],
        ),
        const InfoSection(
          step: 4,
          title: 'Ask your AI',
          children: [
            InfoText('Start a new chat and try one of these:'),
            InfoCode(
              'Capture my running simulator and build a 3-screen App Store and Google Play showcase for my '
              'workout app with the Titanium theme. Then open it in Mockuply.',
            ),
            InfoCode(
              'Find the screenshots in this project and create a 4-screen store set with punchy headlines '
              'using the Midnight theme. Save it to ./store_mockups.mokuply.',
            ),
            InfoText(
              'The project opens in this site with your screens loaded. If your browser asks whether '
              'mockuply.web.app may access devices on your local network, allow it: that is how the page reads the '
              'project from the MCP server on your computer. A saved .mokuply file opens with Import template on '
              'the home page.',
            ),
          ],
        ),
        const InfoSection(
          title: 'Something not working?',
          children: [
            InfoBullets([
              InfoBullet(
                'Run node --version. Anything below 18 needs an update.',
                lead: '"node" not found or too old:',
              ),
              InfoBullet(
                'Check the path in your config points to dist/index.js and that npm run build finished. Restart the '
                'app after editing the config.',
                lead: 'Tools do not show up:',
              ),
              InfoBullet(
                'Open Simulator (macOS) or run adb devices to confirm a device is running.',
                lead: 'No device found:',
              ),
            ]),
            InfoLinks({'Full MCP guide': AppLinks.mcpGuide, 'Report a problem': AppLinks.issues}),
          ],
        ),
      ],
    );
  }

  Widget _clientSteps(_AiClient client) {
    final List<Widget> steps = switch (client) {
      _AiClient.claudeCode => const [
          InfoText('From the tools/mcp-server folder, register the server for all your projects:'),
          InfoCode(_claudeCodeAdd, label: 'macOS / Linux / PowerShell'),
          InfoText('In the classic Windows Command Prompt use %cd% instead of \$PWD. Check it worked with '
              '"claude mcp list", or type /mcp inside Claude Code.'),
        ],
      _AiClient.claudeDesktop => const [
          InfoText('In Claude Desktop open Settings → Developer → Edit Config, add the mokuply entry to '
              'claude_desktop_config.json, then quit and reopen the app:'),
          InfoCode(_configJson),
          InfoBullets([
            InfoBullet('Replace /path/to/Mokuply with the folder you cloned. Run pwd inside it to print the path.'),
            InfoBullet('On Windows use forward slashes, e.g. C:/Users/you/Mokuply/tools/mcp-server/dist/index.js.'),
            InfoBullet(
              '~/Library/Application Support/Claude/ on macOS, %APPDATA%\\Claude\\ on Windows.',
              lead: 'Config folder:',
            ),
          ]),
        ],
      _AiClient.cursor => const [
          InfoText('Open Cursor Settings → MCP → Add new MCP server, or add this to ~/.cursor/mcp.json '
              '(all projects) or .cursor/mcp.json (one project):'),
          InfoCode(_configJson),
          InfoText('Replace /path/to/Mokuply with the folder you cloned (forward slashes on Windows too).'),
        ],
      _AiClient.other => const [
          InfoText('Windsurf, Antigravity, VS Code and most other MCP clients accept a local "stdio" server. '
              'Use these values in their MCP settings:'),
          InfoBullets([
            InfoBullet('mokuply', lead: 'Name:'),
            InfoBullet('node', lead: 'Command:'),
            InfoBullet('/path/to/Mokuply/tools/mcp-server/dist/index.js', lead: 'Argument:'),
          ]),
          InfoText('Clients that use a JSON file usually take the same shape:'),
          InfoCode(_configJson),
        ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          steps[i],
        ],
      ],
    );
  }
}

/// Small "AI" entry used by the home navbar to open [ConnectAiView].
class ConnectAiButton extends StatelessWidget {
  final bool compact;

  const ConnectAiButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).pushNamed(AppLinks.connectAiRoute);
    if (compact) {
      return ClayIconButton(
        icon: Icons.smart_toy_rounded,
        tooltip: 'Connect your AI (MCP)',
        iconColor: AppColors.primary,
        size: 44,
        radius: 22,
        onPressed: open,
      );
    }
    return ClayButton.neutral(label: 'Connect AI', icon: Icons.smart_toy_rounded, onPressed: open);
  }
}
