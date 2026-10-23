<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tab_members', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tab_id')->constrained('tabs')->cascadeOnDelete();
            // Nullable: a member can be a name-only placeholder with no linked account (MVP requirement).
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('display_name');
            $table->timestamp('joined_at')->useCurrent();
            $table->timestamps();

            $table->unique(['tab_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tab_members');
    }
};
