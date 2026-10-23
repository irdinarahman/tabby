<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tab;
use App\Models\TabMember;
use App\Services\BalanceCalculator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TabController extends Controller
{
    public function __construct(private BalanceCalculator $balances)
    {
    }

    /**
     * List tabs the authenticated user is a member of, with a summary
     * (total spent, your balance) for the home dashboard.
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $tabs = Tab::whereHas('members', fn ($q) => $q->where('user_id', $userId))
            ->with(['members', 'expenses.participants', 'settlements'])
            ->get();

        return response()->json($tabs->map(function (Tab $tab) use ($userId) {
            $memberId = $tab->members->firstWhere('user_id', $userId)?->id;
            $balances = $this->balances->calculate($tab);

            return [
                'id' => $tab->id,
                'name' => $tab->name,
                'description' => $tab->description,
                'member_count' => $tab->members->count(),
                'total_spent' => $tab->totalSpent(),
                'your_balance' => $memberId ? ($balances[$memberId] ?? 0) : 0,
            ];
        }));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'member_names' => ['required', 'array', 'min:1'],
            'member_names.*' => ['required', 'string', 'max:255'],
        ]);

        $tab = DB::transaction(function () use ($data, $request) {
            $tab = Tab::create([
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'created_by' => $request->user()->id,
            ]);

            // The creator is always a member, linked to their real account.
            $tab->members()->create([
                'user_id' => $request->user()->id,
                'display_name' => $request->user()->name,
            ]);

            foreach ($data['member_names'] as $name) {
                $tab->members()->create([
                    'user_id' => null,
                    'display_name' => $name,
                ]);
            }

            return $tab;
        });

        return response()->json($tab->load('members'), 201);
    }

    public function show(Tab $tab)
    {
        $tab->load(['members', 'expenses.participants', 'expenses.payer', 'settlements']);

        return response()->json([
            'tab' => $tab,
            'balances' => $this->balances->calculate($tab),
        ]);
    }

    public function addMember(Request $request, Tab $tab)
    {
        $data = $request->validate([
            'display_name' => ['required', 'string', 'max:255'],
        ]);

        $member = $tab->members()->create([
            'user_id' => null,
            'display_name' => $data['display_name'],
        ]);

        return response()->json($member, 201);
    }

    public function balances(Tab $tab)
    {
        return response()->json($this->balances->calculate($tab));
    }
}
