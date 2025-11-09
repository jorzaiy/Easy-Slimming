import { common } from '@kit.AbilityKit';

interface UIContextLike {
  abilityContext?: unknown;
  context?: unknown;
  getHostContext?: () => unknown;
}

function looksLikeAbilityContext(candidate: unknown): candidate is common.Context {
  if (!candidate || typeof candidate !== 'object') {
    return false;
  }
  const record = candidate as Record<string, unknown>;
  return typeof record['getApplicationContext'] === 'function'
    || typeof record['databaseDir'] === 'string'
    || typeof record['cacheDir'] === 'string';
}

export function resolveAbilityContext(uiContext: unknown): common.Context | null {
  if (!uiContext) {
    return null;
  }

  if (looksLikeAbilityContext(uiContext)) {
    return uiContext as common.Context;
  }

  const contextLike = uiContext as UIContextLike;

  const abilityContext = contextLike.abilityContext;
  if (abilityContext && looksLikeAbilityContext(abilityContext)) {
    return abilityContext;
  }

  if (typeof contextLike.getHostContext === 'function') {
    const hostContext = contextLike.getHostContext();
    if (looksLikeAbilityContext(hostContext)) {
      return hostContext;
    }
  }

  if (contextLike.context && looksLikeAbilityContext(contextLike.context)) {
    return contextLike.context as common.Context;
  }

  return null;
}
