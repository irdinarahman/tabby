<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TabMember extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'tab_id',
        'user_id',
        'display_name',
        'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'joined_at' => 'datetime',
        ];
    }

    public function tab()
    {
        return $this->belongsTo(Tab::class);
    }

    // Nullable: a member added by name only (no account) has no linked user.
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function paidExpenses()
    {
        return $this->hasMany(Expense::class, 'paid_by');
    }

    public function expenseShares()
    {
        return $this->hasMany(ExpenseParticipant::class);
    }

    public function name(): string
    {
        return $this->user?->name ?? $this->display_name;
    }
}
