
import { common } from '@kit.AbilityKit';
/**
 * Interface for UI context objects that may contain ability context
 */
interface UIContextLike {
  abilityContext?: common.Context;
  context?: common.Context;
  getHostContext?: () => common.Context;
}

interface ComponentWithUIContext {
  getUIContext?(): Object;
}

/**
 * Type guard to check if a candidate is a valid common.Context
 */
function isCommonContext(candidate: Object): boolean {
  if (!candidate || typeof candidate !== 'object') {
    return false;
  }
  const record = candidate as Record<string, Object>;
  return typeof record['getApplicationContext'] === 'function'
    || typeof record['databaseDir'] === 'string'
    || typeof record['cacheDir'] === 'string'
    || typeof record['filesDir'] === 'string'
    || typeof record['tempDir'] === 'string';
}

/**
 * Type guard to check if a candidate is a UIAbilityContext
 */
function isUIAbilityContext(candidate: Object): boolean {
  if (!isCommonContext(candidate)) {
    return false;
  }
  const record = candidate as Record<string, Object>;
  return typeof record['startAbility'] === 'function'
    || typeof record['terminateSelf'] === 'function'
    || typeof record['abilityInfo'] === 'object';
}

/**
 * Resolves ability context from UI context with comprehensive type checking
 * @param uiContext The UI context from getUIContext()
 * @returns A valid common.Context or null if resolution fails
 */
export function resolveAbilityContext(uiContext: Object): common.Context | null {
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
  const abilityContext: common.Context | undefined = contextLike.abilityContext;
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
 * Resolves common.Context from UI context with specific type checking
 * @param uiContext The UI context from getUIContext()
 * @returns A common.Context or null if resolution fails
 */
export function resolveUIAbilityContext(uiContext: Object): common.Context | null {
  const context = resolveAbilityContext(uiContext);
  if (!context) {
    return null;
  }

  return isUIAbilityContext(context) ? context as common.Context : null;
}

/**
 * Helper function to get context from a component with proper error handling
 * This is a convenience wrapper for the common pattern: resolveAbilityContext(this.getUIContext())
 * @param component The component instance (typically 'this')
 * @returns A valid common.Context or null if resolution fails
 */
export function getComponentContext(component: ComponentWithUIContext): common.Context | null {
  try {
    const getUIContextMethod = component.getUIContext;
    if (getUIContextMethod) {
      const uiContext = getUIContextMethod();
      return resolveAbilityContext(uiContext);
    }
    return null;
  } catch (e) {
    return null;
  }
}
/**
 * Helper function to get common.Context from a component with proper error handling
 * @param component The component instance (typically 'this')
 * @returns A common.Context or null if resolution fails
 */
export function getComponentUIAbilityContext(component: ComponentWithUIContext): common.Context | null {
  try {
    const getUIContextMethod = component.getUIContext;
    if (getUIContextMethod) {
      const uiContext = getUIContextMethod();
      return resolveUIAbilityContext(uiContext);
    }
    return null;
  } catch (e) {
    return null;
  }
}

/**
 * Type guard utility functions for external use
 */
export { isCommonContext, isUIAbilityContext };
