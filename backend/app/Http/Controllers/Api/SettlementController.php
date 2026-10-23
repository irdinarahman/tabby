<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tab;
use App\Services\BalanceCalculator;
use App\Services\SettlementOptimizer;
use Illuminate\Http\Request;

class SettlementController extends Controller
{
    public function __construct(
        private BalanceCalculator $balances,
        private SettlementOptimizer $optimizer,
    ) {
    }

    /**
     * Suggested settlements: the minimal set of payments that would zero
     * out every outstanding balance in the tab.
     */
    public function suggestions(Tab $tab)
    {
        $balances = $this->balances->calculate($tab);

        return response()->json($this->optimizer->plan($balances));
    }

    public function index(Tab $tab)
    {
        return response()->json(
            $tab->settlements()->with(['payer', 'payee'])->get()
        );
    }

    public function store(Request $request, Tab $tab)
    {
        $data = $request->validate([
            'paid_by' => ['required', 'uuid', 'exists:tab_members,id'],
            'paid_to' => ['required', 'uuid', 'exists:tab_members,id', 'different:paid_by'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $settlement = $tab->settlements()->create([
            'paid_by' => $data['paid_by'],
            'paid_to' => $data['paid_to'],
            'amount' => $data['amount'],
            'settled_at' => now(),
            'notes' => $data['notes'] ?? null,
        ]);

        return response()->json($settlement->load(['payer', 'payee']), 201);
    }
}
