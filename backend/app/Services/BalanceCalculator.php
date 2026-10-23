<?php

namespace App\Services;

use App\Models\Tab;

/**
 * Computes each member's net balance for a tab, derived purely from the
 * underlying expense and settlement records. Balances are never cached or
 * stored — this class is the single source of truth for "who owes what",
 * called fresh whenever a balance is needed.
 *
 * balance[member] = (amount paid across expenses)
 *                  - (their share owed across expenses)
 *                  + (settlements they paid, reducing their debt)
 *                  - (settlements they received, reducing what they're owed)
 *
 * A positive balance means the member is owed money.
 * A negative balance means the member owes money.
 */
class BalanceCalculator
{
    /**
     * Eloquent-aware entry point: extracts plain data from a Tab and its
     * relations, then delegates to the pure calculation below.
     *
     * @return array<string, float> map of tab_member_id => net balance
     */
    public function calculate(Tab $tab): array
    {
        $memberIds = $tab->members->pluck('id')->all();

        $expenses = $tab->expenses->map(fn ($e) => [
            'paid_by' => $e->paid_by,
            'amount' => (float) $e->amount,
            'participants' => $e->participants->map(fn ($p) => [
                'tab_member_id' => $p->tab_member_id,
                'share_amount' => (float) $p->share_amount,
            ])->all(),
        ])->all();

        $settlements = $tab->settlements->map(fn ($s) => [
            'paid_by' => $s->paid_by,
            'paid_to' => $s->paid_to,
            'amount' => (float) $s->amount,
        ])->all();

        return $this->calculateFromArrays($memberIds, $expenses, $settlements);
    }

    /**
     * Pure calculation, no Eloquent/DB involved — this is what's unit tested.
     *
     * @param array<int, string> $memberIds
     * @param array<int, array{paid_by: string, amount: float, participants: array<int, array{tab_member_id: string, share_amount: float}>}> $expenses
     * @param array<int, array{paid_by: string, paid_to: string, amount: float}> $settlements
     * @return array<string, float>
     */
    public function calculateFromArrays(array $memberIds, array $expenses, array $settlements): array
    {
        $balances = [];

        foreach ($memberIds as $id) {
            $balances[$id] = 0.0;
        }

        foreach ($expenses as $expense) {
            $balances[$expense['paid_by']] = ($balances[$expense['paid_by']] ?? 0.0) + $expense['amount'];

            foreach ($expense['participants'] as $participant) {
                $balances[$participant['tab_member_id']] =
                    ($balances[$participant['tab_member_id']] ?? 0.0) - $participant['share_amount'];
            }
        }

        foreach ($settlements as $settlement) {
            $balances[$settlement['paid_by']] = ($balances[$settlement['paid_by']] ?? 0.0) + $settlement['amount'];
            $balances[$settlement['paid_to']] = ($balances[$settlement['paid_to']] ?? 0.0) - $settlement['amount'];
        }

        return array_map(fn ($v) => round($v, 2), $balances);
    }

    /**
     * Convenience helper for a single member's balance within a tab.
     */
    public function forMember(Tab $tab, string $tabMemberId): float
    {
        return $this->calculate($tab)[$tabMemberId] ?? 0.0;
    }
}
