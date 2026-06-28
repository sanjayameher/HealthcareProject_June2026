import axios from 'axios';
import type {
  ApiResponse,
  Payer,
  CreatePayerRequest,
  Coverage,
  CreateCoverageRequest,
} from '@/types';

const billingAxios = axios.create({
  baseURL: '/billing-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
});

billingAxios.interceptors.response.use(
  (res) => res,
  (error) => {
    const msg =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message ||
      'An unexpected error occurred';
    return Promise.reject(new Error(msg));
  }
);

function unwrap<T>(res: { data: ApiResponse<T> }): T {
  return res.data.data;
}

export const billingApi = {
  createPayer: (data: CreatePayerRequest) =>
    billingAxios.post<ApiResponse<Payer>>('/payers', data).then(unwrap),

  listPayers: () =>
    billingAxios.get<ApiResponse<Payer[]>>('/payers').then(unwrap),

  getPayer: (id: string) =>
    billingAxios.get<ApiResponse<Payer>>(`/payers/${id}`).then(unwrap),

  addCoverage: (data: CreateCoverageRequest) =>
    billingAxios.post<ApiResponse<Coverage>>('/coverage', data).then(unwrap),

  getPatientCoverage: (patientId: string) =>
    billingAxios
      .get<ApiResponse<Coverage[]>>(`/coverage/patient/${patientId}`)
      .then(unwrap),

  removeCoverage: (id: string) =>
    billingAxios.delete<ApiResponse<void>>(`/coverage/${id}`).then(unwrap),
};
