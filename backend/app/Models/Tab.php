<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tab extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'name',
        'description',
        'created_by',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members()
    {
        return $this->hasMany(TabMember::class);
    }

    public function expenses()
    {
        return $this->hasMany(Expense::class)->orderByDesc('expense_date');
    }

    public function settlements()
    {
        return $this->hasMany(Settlement::class)->orderByDesc('settled_at');
    }

    public function totalSpent(): float
    {
        return (float) $this->expenses()->sum('amount');
    }
}
