<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ExpenseParticipant extends Model
{
    use HasUuids;

    protected $fillable = [
        'expense_id',
        'tab_member_id',
        'share_amount',
    ];

    protected function casts(): array
    {
        return [
            'share_amount' => 'decimal:2',
        ];
    }

    public function expense()
    {
        return $this->belongsTo(Expense::class);
    }

    public function member()
    {
        return $this->belongsTo(TabMember::class, 'tab_member_id');
    }
}
