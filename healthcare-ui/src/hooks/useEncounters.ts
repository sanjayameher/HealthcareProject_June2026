import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { clinicalApi } from '@/api/clinicalApi';
import type { CreateEncounterRequest } from '@/types';
import { toast } from 'sonner';

export const ENCOUNTERS_KEY = ['encounters'] as const;

export function usePatientEncounters(patientId: string) {
  return useQuery({
    queryKey: [...ENCOUNTERS_KEY, 'patient', patientId],
    queryFn: () => clinicalApi.getPatientEncounters(patientId),
    enabled: !!patientId,
  });
}

export function useEncounter(id: string) {
  return useQuery({
    queryKey: [...ENCOUNTERS_KEY, id],
    queryFn: () => clinicalApi.getEncounter(id),
    enabled: !!id,
  });
}

export function useCreateEncounter() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateEncounterRequest) => clinicalApi.createEncounter(data),
    onSuccess: (encounter) => {
      queryClient.invalidateQueries({
        queryKey: [...ENCOUNTERS_KEY, 'patient', encounter.patientId],
      });
      queryClient.invalidateQueries({ queryKey: ENCOUNTERS_KEY });
      toast.success('Encounter created successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}
