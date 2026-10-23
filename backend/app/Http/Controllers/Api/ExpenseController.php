<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseRequest;
use App\Models\Tab;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    public function index(Tab $tab)
    {
        return response()->json(
            $tab->expenses()->with(['participants', 'payer'])->get()
        );
    }

    public function store(StoreExpenseRequest $request, Tab $tab)
    {
        $data = $request->validated();

        $expense = DB::transaction(function () use ($data, $tab) {
            $expense = $tab->expenses()->create([
                'description' => $data['description'],
                'amount' => $data['amount'],
                'paid_by' => $data['paid_by'],
                'split_method' => $data['split_method'],
                'expense_date' => $data['expense_date'],
                'notes' => $data['notes'] ?? null,
            ]);

            if ($data['split_method'] === 'equal') {
                $count = count($data['participants']);
                // Split to the cent; any leftover cent from rounding goes to
                // the first participant so shares always sum exactly to the total.
                $share = round($data['amount'] / $count, 2);
                $remainder = round($data['amount'] - ($share * $count), 2);

                foreach ($data['participants'] as $index => $participant) {
                    $expense->participants()->create([
                        'tab_member_id' => $participant['tab_member_id'],
                        'share_amount' => $share + ($index === 0 ? $remainder : 0),
                    ]);
                }
            } else {
                foreach ($data['participants'] as $participant) {
                    $expense->participants()->create([
                        'tab_member_id' => $participant['tab_member_id'],
                        'share_amount' => $participant['share_amount'],
                    ]);
                }
            }

            return $expense;
        });

        return response()->json($expense->load('participants'), 201);
    }

    public function show(Tab $tab, $expenseId)
    {
        $expense = $tab->expenses()->with(['participants', 'payer'])->findOrFail($expenseId);

        return response()->json($expense);
    }

    public function update(StoreExpenseRequest $request, Tab $tab, $expenseId)
    {
        $expense = $tab->expenses()->findOrFail($expenseId);
        $data = $request->validated();

        DB::transaction(function () use ($expense, $data) {
            $expense->update([
                'description' => $data['description'],
                'amount' => $data['amount'],
                'paid_by' => $data['paid_by'],
                'split_method' => $data['split_method'],
                'expense_date' => $data['expense_date'],
                'notes' => $data['notes'] ?? null,
            ]);

            $expense->participants()->delete();

            if ($data['split_method'] === 'equal') {
                $count = count($data['participants']);
                $share = round($data['amount'] / $count, 2);
                $remainder = round($data['amount'] - ($share * $count), 2);

                foreach ($data['participants'] as $index => $participant) {
                    $expense->participants()->create([
                        'tab_member_id' => $participant['tab_member_id'],
                        'share_amount' => $share + ($index === 0 ? $remainder : 0),
                    ]);
                }
            } else {
                foreach ($data['participants'] as $participant) {
                    $expense->participants()->create([
                        'tab_member_id' => $participant['tab_member_id'],
                        'share_amount' => $participant['share_amount'],
                    ]);
                }
            }
        });

        return response()->json($expense->fresh('participants'));
    }

    public function destroy(Tab $tab, $expenseId)
    {
        $tab->expenses()->findOrFail($expenseId)->delete();

        return response()->json(null, 204);
    }
}
