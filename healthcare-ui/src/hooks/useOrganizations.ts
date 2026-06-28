import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { patientApi } from '@/api/patientApi';
import type { CreateOrganizationRequest } from '@/types';
import { toast } from 'sonner';

export const ORGS_KEY = ['organizations'] as const;

export function useOrganizations() {
  return useQuery({
    queryKey: ORGS_KEY,
    queryFn: () => patientApi.listOrganizations(),
  });
}

export function useOrganization(id: string) {
  return useQuery({
    queryKey: [...ORGS_KEY, id],
    queryFn: () => patientApi.getOrganization(id),
    enabled: !!id,
  });
}

export function useCreateOrganization() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateOrganizationRequest) => patientApi.createOrganization(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ORGS_KEY });
      toast.success('Organization created successfully');
    },
    onError: (err: Error) => toast.error(err.message),
  });
}
