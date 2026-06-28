import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { patientApi } from '@/api/patientApi';
import type { CreatePractitionerRequest } from '@/types';
import { toast } from 'sonner';

export const PRACTITIONERS_KEY = ['practitioners'] as const;

export function usePractitioners() {
  return useQuery({
    queryKey: PRACTITIONERS_KEY,
    queryFn: () => patientApi.listPractitioners(),
  });
}

export function usePractitioner(id: string) {
  return useQuery({
    queryKey: [...PRACTITIONERS_KEY, id],
    queryFn: () => patientApi.getPractitioner(id),
    enabled: !!id,
  });
}

export function useCreatePractitioner() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePractitionerRequest) => patientApi.createPractitioner(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: PRACTITIONERS_KEY });
      toast.success('Practitioner registered successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}
