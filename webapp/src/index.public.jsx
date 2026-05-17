import manifest from '../../plugin.json';
import ScopedTeamsInput from './components/ScopedTeamsInput';

const pluginId = manifest.id;

class Plugin {
  initialize(registry) {
    if (registry.registerAdminConsoleCustomSetting) {
      registry.registerAdminConsoleCustomSetting('ScopedTeamNames', ScopedTeamsInput);
    }
  }
}

window.registerPlugin(pluginId, new Plugin());
