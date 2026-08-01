import { useCallback, useState } from 'react';
import type { LlmProvider } from '@/types';

const STORAGE_KEY = 'cds:llmProvider';

function readStoredProvider(): LlmProvider {
  const stored = localStorage.getItem(STORAGE_KEY);
  return stored === 'claude' ? 'claude' : 'groq';
}

export function useLlmProvider() {
  const [provider, setProviderState] = useState<LlmProvider>(readStoredProvider);

  const setProvider = useCallback((next: LlmProvider) => {
    localStorage.setItem(STORAGE_KEY, next);
    setProviderState(next);
  }, []);

  return { provider, setProvider };
}
