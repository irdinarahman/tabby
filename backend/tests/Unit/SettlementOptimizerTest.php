<?php

namespace Tests\Unit;

use App\Services\SettlementOptimizer;
use PHPUnit\Framework\TestCase;

class SettlementOptimizerTest extends TestCase
{
    private SettlementOptimizer $optimizer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->optimizer = new SettlementOptimizer();
    }

    public function test_it_settles_a_simple_two_person_debt(): void
    {
        $plan = $this->optimizer->plan([
            'alice' => 30.0,
            'bob' => -30.0,
        ]);

        $this->assertCount(1, $plan);
        $this->assertEquals('bob', $plan[0]['from']);
        $this->assertEquals('alice', $plan[0]['to']);
        $this->assertEquals(30.0, $plan[0]['amount']);
    }

    public function test_it_minimizes_transactions_for_the_brief_example(): void
    {
        // Alice: +100, Bob: +50, Charlie: -75, Diana: -75
        $plan = $this->optimizer->plan([
            'alice' => 100.0,
            'bob' => 50.0,
            'charlie' => -75.0,
            'diana' => -75.0,
        ]);

        // Expect exactly 3 transactions (n-1 max for 4 unbalanced parties),
        // never one transaction per original expense.
        $this->assertCount(3, $plan);

        $totalPaid = array_sum(array_column($plan, 'amount'));
        $this->assertEqualsWithDelta(150.0, $totalPaid, 0.01);

        // Every debtor's total outgoing payments must match their debt.
        $this->assertPayerTotals($plan, 'charlie', 75.0);
        $this->assertPayerTotals($plan, 'diana', 75.0);

        // Every creditor's total incoming payments must match what they're owed.
        $this->assertPayeeTotals($plan, 'alice', 100.0);
        $this->assertPayeeTotals($plan, 'bob', 50.0);
    }

    public function test_it_produces_no_transactions_when_everyone_is_settled(): void
    {
        $plan = $this->optimizer->plan([
            'alice' => 0.0,
            'bob' => 0.004, // within epsilon, treated as settled
            'charlie' => -0.004,
        ]);

        $this->assertEmpty($plan);
    }

    public function test_it_handles_many_to_many_balances_correctly(): void
    {
        $balances = [
            'a' => 40.0,
            'b' => 20.0,
            'c' => -10.0,
            'd' => -25.0,
            'e' => -25.0,
        ];

        $plan = $this->optimizer->plan($balances);

        $net = [];
        foreach ($balances as $id => $_) {
            $net[$id] = 0.0;
        }
        foreach ($plan as $t) {
            $net[$t['from']] -= $t['amount'];
            $net[$t['to']] += $t['amount'];
        }

        foreach ($balances as $id => $expected) {
            $this->assertEqualsWithDelta($expected, $net[$id], 0.01, "Mismatch for member {$id}");
        }
    }

    private function assertPayerTotals(array $plan, string $id, float $expected): void
    {
        $total = array_sum(array_column(array_filter($plan, fn ($t) => $t['from'] === $id), 'amount'));
        $this->assertEqualsWithDelta($expected, $total, 0.01);
    }

    private function assertPayeeTotals(array $plan, string $id, float $expected): void
    {
        $total = array_sum(array_column(array_filter($plan, fn ($t) => $t['to'] === $id), 'amount'));
        $this->assertEqualsWithDelta($expected, $total, 0.01);
    }
}
