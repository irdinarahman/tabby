<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('settlements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tab_id')->constrained('tabs')->cascadeOnDelete();
            $table->foreignUuid('paid_by')->constrained('tab_members')->cascadeOnDelete();
            $table->foreignUuid('paid_to')->constrained('tab_members')->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->timestamp('settled_at')->useCurrent();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['tab_id', 'settled_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('settlements');
    }
};
