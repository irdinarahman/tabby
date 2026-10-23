<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expense_participants', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('expense_id')->constrained('expenses')->cascadeOnDelete();
            $table->foreignUuid('tab_member_id')->constrained('tab_members')->cascadeOnDelete();
            // Stored at creation time so historical expenses stay accurate even if
            // splitting rules change later. Net balances are still always derived
            // live from expenses + settlements, never cached.
            $table->decimal('share_amount', 12, 2);
            $table->timestamps();

            $table->unique(['expense_id', 'tab_member_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expense_participants');
    }
};
