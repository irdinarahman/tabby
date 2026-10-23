<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Settlement extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'tab_id',
        'paid_by',
        'paid_to',
        'amount',
        'settled_at',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'settled_at' => 'datetime',
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

    public function payee()
    {
        return $this->belongsTo(TabMember::class, 'paid_to');
    }
}
