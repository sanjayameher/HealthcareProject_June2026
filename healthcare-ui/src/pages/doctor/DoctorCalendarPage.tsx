import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { format, getDaysInMonth, startOfMonth, getDay } from 'date-fns';
import { ChevronLeft, ChevronRight, Plus, Trash2, Lock } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import type { AvailabilitySlot, AvailabilitySlotRequest } from '@/types';
import { cn } from '@/utils/cn';

const slotSchema = z.object({
  slotDate: z.string().min(1),
  startTime: z.string().min(1),
  endTime: z.string().min(1),
  slotType: z.enum(['regular', 'leave', 'blocked']),
  notes: z.string().optional(),
});

export function DoctorCalendarPage() {
  const { user } = useAuthStore();
  const practitionerId = user?.userId ?? '';
  const qc = useQueryClient();
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [addOpen, setAddOpen] = useState(false);

  const { data: slots = [] } = useQuery({
    queryKey: ['slots', practitionerId, year, month],
    queryFn: () => portalApi.getMonthSlots(practitionerId, year, month),
    enabled: !!practitionerId,
  });

  const { register, handleSubmit, reset, formState: { errors } } = useForm<AvailabilitySlotRequest>({
    resolver: zodResolver(slotSchema),
    defaultValues: { slotType: 'regular' },
  });

  const addMutation = useMutation({
    mutationFn: (data: AvailabilitySlotRequest) => portalApi.addSlot(practitionerId, data),
    onSuccess: () => {
      toast.success('Slot added');
      qc.invalidateQueries({ queryKey: ['slots'] });
      setAddOpen(false);
      reset();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: portalApi.deleteSlot,
    onSuccess: () => { toast.success('Slot deleted'); qc.invalidateQueries({ queryKey: ['slots'] }); },
    onError: (e: Error) => toast.error(e.message),
  });

  const blockMutation = useMutation({
    mutationFn: (id: string) => portalApi.blockSlot(id, 'blocked'),
    onSuccess: () => { toast.success('Slot blocked'); qc.invalidateQueries({ queryKey: ['slots'] }); },
    onError: (e: Error) => toast.error(e.message),
  });

  const slotsByDate = slots.reduce<Record<string, AvailabilitySlot[]>>((acc, s) => {
    (acc[s.slotDate] ??= []).push(s);
    return acc;
  }, {});

  const firstDay = getDay(startOfMonth(new Date(year, month - 1)));
  const daysInMonth = getDaysInMonth(new Date(year, month - 1));
  const prevMonth = () => { if (month === 1) { setMonth(12); setYear(y => y - 1); } else setMonth(m => m - 1); };
  const nextMonth = () => { if (month === 12) { setMonth(1); setYear(y => y + 1); } else setMonth(m => m + 1); };

  return (
    <PortalPageWrapper title="My Calendar">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Button variant="outline" size="icon" onClick={prevMonth}><ChevronLeft className="w-4 h-4" /></Button>
          <h2 className="text-lg font-semibold w-40 text-center">
            {format(new Date(year, month - 1), 'MMMM yyyy')}
          </h2>
          <Button variant="outline" size="icon" onClick={nextMonth}><ChevronRight className="w-4 h-4" /></Button>
        </div>
        <Button onClick={() => setAddOpen(true)} className="gap-2 bg-emerald-600 hover:bg-emerald-700">
          <Plus className="w-4 h-4" /> Add Slot
        </Button>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-7 gap-1 mb-1">
            {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => (
              <div key={d} className="text-center text-xs font-medium text-gray-500 py-1">{d}</div>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-1">
            {Array.from({ length: firstDay }).map((_, i) => <div key={`e${i}`} />)}
            {Array.from({ length: daysInMonth }, (_, i) => i + 1).map(day => {
              const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
              const daySlots = slotsByDate[dateStr] ?? [];
              return (
                <div key={day} className="min-h-20 border rounded p-1 bg-white hover:bg-emerald-50/40">
                  <p className="text-xs font-medium text-gray-600 mb-1">{day}</p>
                  {daySlots.map(s => (
                    <div key={s.id} className={cn(
                      'text-xs rounded px-1 py-0.5 mb-0.5 flex items-center justify-between gap-1',
                      !s.available ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'
                    )}>
                      <span className="truncate">{s.startTime.substring(0, 5)}</span>
                      <div className="flex gap-0.5 flex-shrink-0">
                        {s.available && (
                          <button title="Block slot" onClick={() => blockMutation.mutate(s.id)}>
                            <Lock className="w-3 h-3" />
                          </button>
                        )}
                        <button title="Delete slot" onClick={() => deleteMutation.mutate(s.id)}>
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Add Availability Slot</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit((d) => addMutation.mutate(d))} className="space-y-4">
            <div className="space-y-1">
              <Label>Date</Label>
              <Input type="date" {...register('slotDate')} />
              {errors.slotDate && <p className="text-xs text-red-500">Required</p>}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label>Start</Label>
                <Input type="time" {...register('startTime')} />
              </div>
              <div className="space-y-1">
                <Label>End</Label>
                <Input type="time" {...register('endTime')} />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Type</Label>
              <select className="w-full border rounded px-3 py-2 text-sm" {...register('slotType')}>
                <option value="regular">Regular</option>
                <option value="leave">Leave</option>
                <option value="blocked">Blocked</option>
              </select>
            </div>
            <div className="space-y-1">
              <Label>Notes</Label>
              <Input placeholder="Optional" {...register('notes')} />
            </div>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setAddOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={addMutation.isPending} className="bg-emerald-600 hover:bg-emerald-700">
                {addMutation.isPending ? 'Adding…' : 'Add Slot'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </PortalPageWrapper>
  );
}