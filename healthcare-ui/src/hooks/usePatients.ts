import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { patientApi } from '@/api/patientApi';
import type { CreatePatientRequest, UpdatePatientRequest } from '@/types';
import { toast } from 'sonner';

export const PATIENTS_KEY = ['patients'] as const;

export function usePatients(search?: { name?: string; mrn?: string }) {
  const hasSearch = search?.name || search?.mrn;
  return useQuery({
    queryKey: hasSearch ? [...PATIENTS_KEY, search] : PATIENTS_KEY,
    queryFn: () =>
      hasSearch
        ? patientApi.searchPatients(search!)
        : patientApi.listPatients(),
    refetchInterval: hasSearch ? undefined : 30_000,
  });
}

export function usePatient(id: string) {
  return useQuery({
    queryKey: [...PATIENTS_KEY, id],
    queryFn: () => patientApi.getPatient(id),
    enabled: !!id,
  });
}

export function useCreatePatient() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePatientRequest) => patientApi.createPatient(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: PATIENTS_KEY });
      toast.success('Patient registered successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}

export function useUpdatePatient(id: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdatePatientRequest) => patientApi.updatePatient(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [...PATIENTS_KEY, id] });
      queryClient.invalidateQueries({ queryKey: PATIENTS_KEY });
      toast.success('Patient updated successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}

export function useDeletePatient() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => patientApi.deletePatient(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: PATIENTS_KEY });
      toast.success('Patient removed');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}
