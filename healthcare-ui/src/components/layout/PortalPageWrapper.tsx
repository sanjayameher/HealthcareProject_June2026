interface Props {
  title: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}

export function PortalPageWrapper({ title, children, actions }: Props) {
  return (
    <div className="p-6 min-h-full">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
      {children}
    </div>
  );
}