<?php

namespace Tests\Unit;

use App\Services\BalanceCalculator;
use PHPUnit\Framework\TestCase;

class BalanceCalculatorTest extends TestCase
{
    private BalanceCalculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calculator = new BalanceCalculator();
    }

    public function test_it_splits_an_equal_expense_correctly(): void
    {
        // Alice pays RM120 for dinner, split equally between 4 people.
        $balances = $this->calculator->calculateFromArrays(
            memberIds: ['alice', 'bob', 'charlie', 'diana'],
            expenses: [
                [
                    'paid_by' => 'alice',
                    'amount' => 120.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 30.0],
                        ['tab_member_id' => 'bob', 'share_amount' => 30.0],
                        ['tab_member_id' => 'charlie', 'share_amount' => 30.0],
                        ['tab_member_id' => 'diana', 'share_amount' => 30.0],
                    ],
                ],
            ],
            settlements: []
        );

        $this->assertEquals(90.0, $balances['alice']); // paid 120, owes 30
        $this->assertEquals(-30.0, $balances['bob']);
        $this->assertEquals(-30.0, $balances['charlie']);
        $this->assertEquals(-30.0, $balances['diana']);
    }

    public function test_it_matches_the_smart_settlement_brief_example(): void
    {
        // Reproduces the exact balances from the product brief:
        // Alice: +100, Bob: +50, Charlie: -75, Diana: -75
        $balances = $this->calculator->calculateFromArrays(
            memberIds: ['alice', 'bob', 'charlie', 'diana'],
            expenses: [
                [
                    'paid_by' => 'alice',
                    'amount' => 200.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 50.0],
                        ['tab_member_id' => 'bob', 'share_amount' => 50.0],
                        ['tab_member_id' => 'charlie', 'share_amount' => 50.0],
                        ['tab_member_id' => 'diana', 'share_amount' => 50.0],
                    ],
                ],
                [
                    'paid_by' => 'bob',
                    'amount' => 100.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 25.0],
                        ['tab_member_id' => 'bob', 'share_amount' => 25.0],
                        ['tab_member_id' => 'charlie', 'share_amount' => 25.0],
                        ['tab_member_id' => 'diana', 'share_amount' => 25.0],
                    ],
                ],
            ],
            settlements: []
        );

        $this->assertEquals(100.0, $balances['alice']);
        $this->assertEquals(50.0, $balances['bob']);
        $this->assertEquals(-75.0, $balances['charlie']);
        $this->assertEquals(-75.0, $balances['diana']);
    }

    public function test_a_settlement_reduces_the_payers_debt_and_the_payees_credit(): void
    {
        $balances = $this->calculator->calculateFromArrays(
            memberIds: ['alice', 'charlie'],
            expenses: [
                [
                    'paid_by' => 'alice',
                    'amount' => 100.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 50.0],
                        ['tab_member_id' => 'charlie', 'share_amount' => 50.0],
                    ],
                ],
            ],
            settlements: [
                ['paid_by' => 'charlie', 'paid_to' => 'alice', 'amount' => 30.0],
            ]
        );

        $this->assertEquals(20.0, $balances['alice']); // was owed 50, received 30
        $this->assertEquals(-20.0, $balances['charlie']); // owed 50, paid 30
    }

    public function test_custom_split_amounts_are_respected_even_if_uneven(): void
    {
        $balances = $this->calculator->calculateFromArrays(
            memberIds: ['alice', 'bob', 'charlie'],
            expenses: [
                [
                    'paid_by' => 'charlie',
                    'amount' => 34.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 12.0],
                        ['tab_member_id' => 'bob', 'share_amount' => 12.0],
                        ['tab_member_id' => 'charlie', 'share_amount' => 10.0],
                    ],
                ],
            ],
            settlements: []
        );

        $this->assertEquals(-12.0, $balances['alice']);
        $this->assertEquals(-12.0, $balances['bob']);
        $this->assertEquals(24.0, $balances['charlie']); // paid 34, owes 10
    }

    public function test_a_member_with_no_activity_has_a_zero_balance(): void
    {
        $balances = $this->calculator->calculateFromArrays(
            memberIds: ['alice', 'idle_member'],
            expenses: [
                [
                    'paid_by' => 'alice',
                    'amount' => 10.0,
                    'participants' => [
                        ['tab_member_id' => 'alice', 'share_amount' => 10.0],
                    ],
                ],
            ],
            settlements: []
        );

        $this->assertEquals(0.0, $balances['idle_member']);
    }
}
