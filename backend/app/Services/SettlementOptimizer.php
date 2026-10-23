<?php

namespace App\Services;

/**
 * Given a set of net balances, produces the smallest set of payments that
 * settles every balance to zero (a classic greedy debt-simplification /
 * min-cash-flow algorithm).
 *
 * This is deliberately framework-agnostic and stateless: it takes plain
 * data in and returns plain data out, so it can be unit tested directly
 * with no database or HTTP involved.
 */
class SettlementOptimizer
{
    private const EPSILON = 0.01;

    /**
     * @param array<string, float> $balances map of member_id => net balance
     * @return array<int, array{from: string, to: string, amount: float}>
     */
    public function plan(array $balances): array
    {
        $creditors = [];
        $debtors = [];

        foreach ($balances as $id => $amount) {
            if ($amount > self::EPSILON) {
                $creditors[] = ['id' => $id, 'amount' => $amount];
            } elseif ($amount < -self::EPSILON) {
                $debtors[] = ['id' => $id, 'amount' => -$amount];
            }
        }

        usort($creditors, fn ($a, $b) => $b['amount'] <=> $a['amount']);
        usort($debtors, fn ($a, $b) => $b['amount'] <=> $a['amount']);

        $plan = [];
        $i = 0;
        $j = 0;

        while ($i < count($debtors) && $j < count($creditors)) {
            $amount = min($debtors[$i]['amount'], $creditors[$j]['amount']);
            $amount = round($amount, 2);

            if ($amount > self::EPSILON) {
                $plan[] = [
                    'from' => $debtors[$i]['id'],
                    'to' => $creditors[$j]['id'],
                    'amount' => $amount,
                ];
            }

            $debtors[$i]['amount'] -= $amount;
            $creditors[$j]['amount'] -= $amount;

            if ($debtors[$i]['amount'] <= self::EPSILON) {
                $i++;
            }
            if ($creditors[$j]['amount'] <= self::EPSILON) {
                $j++;
            }
        }

        return $plan;
    }
}
