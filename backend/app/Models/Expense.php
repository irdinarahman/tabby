<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'tab_id',
        'description',
        'amount',
        'paid_by',
        'split_method',
        'expense_date',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'expense_date' => 'date',
        ];
    }

    public function tab()
    {
        return $this->belongsTo(Tab::class);
    }

    public function payer()
    {
        return $this->belongsTo(TabMember::class, 'paid_by');
    }

    public function participants()
    {
        return $this->hasMany(ExpenseParticipant::class);
    }
}
