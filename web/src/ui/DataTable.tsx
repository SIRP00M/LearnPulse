import { useMemo, useState, type ReactNode } from 'react';
import {
  flexRender, getCoreRowModel, getFilteredRowModel, getSortedRowModel, useReactTable,
  type ColumnDef, type SortingState,
} from '@tanstack/react-table';
import { useTranslation } from 'react-i18next';
import { Button, EmptyState, Icon } from './kit';

/** CSV cell with spreadsheet-formula neutralisation (a cell starting with = + - @ would run as a formula). */
export function csvCell(v: unknown): string {
  let s = v == null ? '' : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return `"${s.replace(/"/g, '""')}"`;
}

interface Props<T> {
  data: T[];
  columns: ColumnDef<T, unknown>[];
  caption: string;
  getRowId?: (row: T) => string;
  filterLabel?: string;
  exportName?: string;
  empty?: ReactNode;
  toolbar?: ReactNode;
  onRowActivate?: (row: T) => void;
  dense?: boolean;
}

export function DataTable<T>({ data, columns, caption, getRowId, filterLabel, exportName, empty, toolbar, onRowActivate, dense: denseInit }: Props<T>) {
  const { t } = useTranslation('table');
  const [sorting, setSorting] = useState<SortingState>([]);
  const [filter, setFilter] = useState('');
  const [dense, setDense] = useState(!!denseInit);
  const table = useReactTable({
    data, columns, getRowId, state: { sorting, globalFilter: filter },
    onSortingChange: setSorting, onGlobalFilterChange: setFilter,
    getCoreRowModel: getCoreRowModel(), getSortedRowModel: getSortedRowModel(), getFilteredRowModel: getFilteredRowModel(),
    globalFilterFn: 'includesString',
  });
  const rows = table.getRowModel().rows;
  const exportCsv = useMemo(() => () => {
    const cols = table.getVisibleLeafColumns().filter((c) => c.id !== 'actions');
    const head = cols.map((c) => csvCell(typeof c.columnDef.header === 'string' ? c.columnDef.header : c.id)).join(',');
    const body = rows.map((r) => cols.map((c) => csvCell(r.getValue(c.id))).join(','));
    const blob = new Blob(['﻿' + [head, ...body].join('\r\n')], { type: 'text/csv;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `${exportName ?? 'export'}.csv`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  }, [rows, table, exportName]);

  return (
    <div>
      <div className="tbl-tools">
        <label className="sr-only" htmlFor={`f-${caption}`}>{filterLabel ?? t('filter')}</label>
        <input id={`f-${caption}`} className="input" style={{ maxWidth: 260, minHeight: 36 }} type="search" placeholder={filterLabel ?? t('filter')} value={filter} onChange={(e) => setFilter(e.target.value)} />
        <Button variant="outline" size="sm" icon={dense ? 'density_small' : 'density_medium'} aria-pressed={dense} onClick={() => setDense(!dense)}>{t('compactRows')}</Button>
        {exportName && <Button variant="outline" size="sm" icon="download" onClick={exportCsv}>{t('exportCsv')}</Button>}
        <span className="muted small" role="status">{t('count', { shown: rows.length, total: data.length })}</span>
        {toolbar}
      </div>
      {rows.length === 0 ? (
        empty ?? <EmptyState icon="search_off" title={t('nothingMatches')}>{t('clearFilter')}</EmptyState>
      ) : (
        <div className="table-wrap" tabIndex={0} role="region" aria-label={t('scrollable', { caption })}>
          <table className={`tbl${dense ? ' dense' : ''}`}>
            <caption className="sr-only">{caption}</caption>
            <thead>
              {table.getHeaderGroups().map((hg) => (
                <tr key={hg.id}>
                  {hg.headers.map((h, i) => {
                    const sorted = h.column.getIsSorted();
                    return (
                      <th key={h.id} scope="col" className={i === 0 ? 'sticky-col' : undefined} aria-sort={sorted === 'asc' ? 'ascending' : sorted === 'desc' ? 'descending' : undefined}>
                        {h.column.getCanSort() ? (
                          <button onClick={h.column.getToggleSortingHandler()}>
                            {flexRender(h.column.columnDef.header, h.getContext())}
                            <Icon name={sorted === 'asc' ? 'arrow_upward' : sorted === 'desc' ? 'arrow_downward' : 'unfold_more'} />
                          </button>
                        ) : flexRender(h.column.columnDef.header, h.getContext())}
                      </th>
                    );
                  })}
                </tr>
              ))}
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}
                  tabIndex={onRowActivate ? 0 : undefined}
                  onKeyDown={onRowActivate ? (e) => { if (e.key === 'Enter' && e.target === e.currentTarget) onRowActivate(r.original); } : undefined}
                  onClick={onRowActivate ? (e) => { if (!(e.target as HTMLElement).closest('button,a,input,select')) onRowActivate(r.original); } : undefined}
                  style={onRowActivate ? { cursor: 'pointer' } : undefined}>
                  {r.getVisibleCells().map((c, i) => (
                    <td key={c.id} className={i === 0 ? 'sticky-col' : undefined}>{flexRender(c.column.columnDef.cell, c.getContext())}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
