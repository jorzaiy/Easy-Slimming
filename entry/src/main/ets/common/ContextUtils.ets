import { common, UIAbilityContext } from '@kit.AbilityKit';

/**
 * Interface for UI context objects that may contain ability context
 */
interface UIContextLike {
  abilityContext?: unknown;
  context?: unknown;
  getHostContext?: () => unknown;
}

/**
 * Type guard to check if a candidate is a valid common.Context
 */
function isCommonContext(candidate: unknown): candidate is common.Context {
  if (!candidate || typeof candidate !== 'object') {
    return false;
  }
  const record = candidate as Record<string, unknown>;
  return typeof record['getApplicationContext'] === 'function'
    || typeof record['databaseDir'] === 'string'
    || typeof record['cacheDir'] === 'string'
    || typeof record['filesDir'] === 'string'
    || typeof record['tempDir'] === 'string';
}

/**
 * Type guard to check if a candidate is a UIAbilityContext
 */
function isUIAbilityContext(candidate: unknown): candidate is UIAbilityContext {
  if (!isCommonContext(candidate)) {
    return false;
  }
  const record = candidate as Record<string, unknown>;
  return typeof record['startAbility'] === 'function'
    || typeof record['terminateSelf'] === 'function'
    || typeof record['abilityInfo'] === 'object';
}

/**
 * Resolves ability context from UI context with comprehensive type checking
 * @param uiContext The UI context from getUIContext()
 * @returns A valid common.Context or null if resolution fails
 */
export function resolveAbilityContext(uiContext: unknown): common.Context | null {
  if (!uiContext) {
    return null;
  }

  // Direct check if uiContext is already a common.Context
  if (isCommonContext(uiContext)) {
    return uiContext as common.Context;
  }

  // Check through UIContextLike interface
  const contextLike = uiContext as UIContextLike;

  // Check abilityContext property
  const abilityContext = contextLike.abilityContext;
  if (abilityContext && isCommonContext(abilityContext)) {
    return abilityContext as common.Context;
  }

  // Check getHostContext method
  if (typeof contextLike.getHostContext === 'function') {
    try {
      const hostContext = contextLike.getHostContext();
      if (hostContext && isCommonContext(hostContext)) {
        return hostContext as common.Context;
      }
    } catch (e) {
      // Ignore errors from getHostContext
    }
  }

  // Check context property
  if (contextLike.context && isCommonContext(contextLike.context)) {
    return contextLike.context as common.Context;
  }

  return null;
}

/**
 * Resolves UIAbilityContext from UI context with specific type checking
 * @param uiContext The UI context from getUIContext()
 * @returns A UIAbilityContext or null if resolution fails
 */
export function resolveUIAbilityContext(uiContext: unknown): UIAbilityContext | null {
  const context = resolveAbilityContext(uiContext);
  if (!context) {
    return null;
  }

  return isUIAbilityContext(context) ? context as UIAbilityContext : null;
}

/**
 * Helper function to get context from a component with proper error handling
 * This is a convenience wrapper for the common pattern: resolveAbilityContext(this.getUIContext())
 * @param component The component instance (typically 'this')
 * @returns A valid common.Context or null if resolution fails
 */
export function getComponentContext(component: { getUIContext(): unknown }): common.Context | null {
  try {
    const uiContext = component.getUIContext();
    return resolveAbilityContext(uiContext);
  } catch (e) {
    return null;
  }
}

/**
 * Helper function to get UIAbilityContext from a component with proper error handling
 * @param component The component instance (typically 'this')
 * @returns A UIAbilityContext or null if resolution fails
 */
export function getComponentUIAbilityContext(component: { getUIContext(): unknown }): UIAbilityContext | null {
  try {
    const uiContext = component.getUIContext();
    return resolveUIAbilityContext(uiContext);
  } catch (e) {
    return null;
  }
}

/**
 * Type guard utility functions for external use
 */
export { isCommonContext, isUIAbilityContext };
