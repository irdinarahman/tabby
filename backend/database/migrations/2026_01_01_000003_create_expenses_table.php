<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tab_id')->constrained('tabs')->cascadeOnDelete();
            $table->string('description');
            $table->decimal('amount', 12, 2);
            $table->foreignUuid('paid_by')->constrained('tab_members')->cascadeOnDelete();
            $table->enum('split_method', ['equal', 'custom']);
            $table->date('expense_date');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['tab_id', 'expense_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
