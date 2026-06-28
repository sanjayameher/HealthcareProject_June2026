import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { billingApi } from '@/api/billingApi';
import type { CreatePayerRequest, CreateCoverageRequest } from '@/types';
import { toast } from 'sonner';

export const PAYERS_KEY = ['payers'] as const;
export const COVERAGE_KEY = ['coverage'] as const;

export function usePayers() {
  return useQuery({
    queryKey: PAYERS_KEY,
    queryFn: () => billingApi.listPayers(),
  });
}

export function usePayer(id: string) {
  return useQuery({
    queryKey: [...PAYERS_KEY, id],
    queryFn: () => billingApi.getPayer(id),
    enabled: !!id,
  });
}

export function useCreatePayer() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePayerRequest) => billingApi.createPayer(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: PAYERS_KEY });
      toast.success('Payer added successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}

export function usePatientCoverage(patientId: string) {
  return useQuery({
    queryKey: [...COVERAGE_KEY, 'patient', patientId],
    queryFn: () => billingApi.getPatientCoverage(patientId),
    enabled: !!patientId,
  });
}

export function useAddCoverage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateCoverageRequest) => billingApi.addCoverage(data),
    onSuccess: (coverage) => {
      queryClient.invalidateQueries({
        queryKey: [...COVERAGE_KEY, 'patient', coverage.patientId],
      });
      toast.success('Coverage added successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}

export function useRemoveCoverage(patientId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => billingApi.removeCoverage(id),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: [...COVERAGE_KEY, 'patient', patientId],
      });
      toast.success('Coverage removed');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}
