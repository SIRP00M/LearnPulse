import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ColumnDef } from '@tanstack/react-table';
import { csvCell, DataTable } from './DataTable';
import { Button, EmptyState, ErrorState, Frame, ProgressBar, Query, Stat } from './kit';
import i18n from '../i18n';
import { OccChip, OCC, TaskChip, SubChip, AttChip } from './status';
import type { UseQueryResult } from '@tanstack/react-query';

describe('csvCell', () => {
  it('quotes and neutralises spreadsheet formulas', () => {
    expect(csvCell('=HYPERLINK("http://evil")')).toBe(`"'=HYPERLINK(""http://evil"")"`);
    expect(csvCell('+1')).toBe(`"'+1"`);
    expect(csvCell('-2')).toBe(`"'-2"`);
    expect(csvCell('@SUM(A1)')).toBe(`"'@SUM(A1)"`);
    expect(csvCell('plain, with comma')).toBe('"plain, with comma"');
    expect(csvCell(null)).toBe('""');
  });
});

type Row = { name: string; score: number };
const cols: ColumnDef<Row, unknown>[] = [{ accessorKey: 'name', header: 'Name' }, { accessorKey: 'score', header: 'Score' }];
const data: Row[] = [{ name: 'Beta', score: 2 }, { name: 'Alpha', score: 9 }, { name: 'Gamma', score: 5 }];

describe('DataTable', () => {
  it('sorts via accessible header buttons and exposes aria-sort', async () => {
    render(<DataTable<Row> caption="People" data={data} columns={cols} />);
    const names = () => screen.getAllByRole('row').slice(1).map((r) => r.textContent);
    await userEvent.click(screen.getByRole('button', { name: /Name/ }));
    expect(names()[0]).toContain('Alpha');
    expect(screen.getByRole('columnheader', { name: /Name/ })).toHaveAttribute('aria-sort', 'ascending');
    await userEvent.click(screen.getByRole('button', { name: /Name/ }));
    expect(names()[0]).toContain('Gamma');
  });

  it('filters rows, reports the count and shows an empty state', async () => {
    render(<DataTable<Row> caption="People" data={data} columns={cols} filterLabel="Filter people" />);
    await userEvent.type(screen.getByPlaceholderText('Filter people'), 'alp');
    expect(screen.getAllByRole('row')).toHaveLength(2);
    expect(screen.getByRole('status')).toHaveTextContent('1 of 3');
    await userEvent.clear(screen.getByPlaceholderText('Filter people'));
    await userEvent.type(screen.getByPlaceholderText('Filter people'), 'zzz');
    expect(screen.getByText('Nothing matches')).toBeInTheDocument();
  });

  it('the scrollable region is keyboard focusable', () => {
    render(<DataTable<Row> caption="People" data={data} columns={cols} />);
    expect(screen.getByRole('region', { name: /People \(scrollable\)/ })).toHaveAttribute('tabindex', '0');
  });
});

describe('status vocabulary', () => {
  it('every occurrence state has an icon AND a word (never colour alone)', () => {
    for (const s of Object.keys(OCC) as (keyof typeof OCC)[]) {
      const { container, unmount } = render(<OccChip state={s} />);
      expect(container.textContent).toContain(i18n.t(`status:occ.${s}`));
      expect(container.querySelector('.mi')).not.toBeNull();
      unmount();
    }
    render(<><TaskChip status="needs_revision" /><SubChip status="graded" /><AttChip status="late" /><AttChip /></>);
    expect(screen.getByText('Needs revision')).toBeInTheDocument();
    expect(screen.getByText('Not marked')).toBeInTheDocument();
  });
});

describe('kit', () => {
  it('Query keeps old data visible when a refresh fails', () => {
    const q = { data: ['kept'], isError: true, error: new TypeError('Failed to fetch'), refetch: async () => ({}) } as unknown as UseQueryResult<string[]>;
    render(<Query q={q}>{(d) => <p>{d.join()}</p>}</Query>);
    expect(screen.getByText('kept')).toBeInTheDocument();
    expect(screen.getByRole('status')).toHaveTextContent(/last loaded data/);
  });
  it('Query shows an error with retry when nothing was ever loaded', () => {
    const q = { data: undefined, isError: true, error: { code: 'PT403' }, refetch: async () => ({}) } as unknown as UseQueryResult<string[]>;
    render(<Query q={q}>{() => null}</Query>);
    expect(screen.getByRole('alert')).toHaveTextContent('You do not have permission');
  });
  it('ErrorState hides retry for forbidden/not-found and shows it for network errors', () => {
    const { rerender } = render(<ErrorState error={{ code: 'PT404' }} onRetry={() => {}} />);
    expect(screen.queryByRole('button', { name: 'Try again' })).toBeNull();
    rerender(<ErrorState error={new TypeError('Failed to fetch')} onRetry={() => {}} />);
    expect(screen.getByRole('button', { name: 'Try again' })).toBeInTheDocument();
  });
  it('Button blocks clicks while busy; Frame labels its region; ProgressBar and Stat expose values', async () => {
    let n = 0;
    render(<><Button busy onClick={() => n++}>Go</Button>
      <Frame title="Box"><ProgressBar value={42.4} label="Course" /><Stat value="3 of 4" label="Done" /></Frame><EmptyState title="Empty" /></>);
    await userEvent.click(screen.getByRole('button', { name: /Go/ }));
    expect(n).toBe(0);
    expect(screen.getByRole('region', { name: 'Box' })).toBeInTheDocument();
    expect(screen.getByRole('progressbar', { name: 'Course' })).toHaveAttribute('aria-valuenow', '42');
    expect(screen.getByRole('group', { name: 'Done: 3 of 4' })).toBeInTheDocument();
  });
});
