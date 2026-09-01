<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('crime_data', function (Blueprint $table) {
            $table->id();
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->string('area');
            $table->integer('hour');
            $table->string('crime_category');
            $table->decimal('risk_score', 5, 4);
            $table->string('risk_label'); // Low Risk, Medium Risk, High Risk
            $table->timestamps();
        });

        Schema::create('prediction_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->string('area');
            $table->integer('hour');
            $table->string('crime_category');
            $table->decimal('risk_score', 5, 4);
            $table->string('risk_label');
            $table->text('recommendation')->nullable();
            $table->timestamps();
        });

        Schema::create('safe_routes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('start_latitude', 10, 8);
            $table->decimal('start_longitude', 11, 8);
            $table->decimal('destination_latitude', 10, 8);
            $table->decimal('destination_longitude', 11, 8);
            $table->decimal('distance_km', 8, 2);
            $table->integer('duration_minutes');
            $table->longText('polyline');
            $table->decimal('risk_score', 5, 4);
            $table->string('risk_level'); // Low, Medium, High
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('safe_routes');
        Schema::dropIfExists('prediction_logs');
        Schema::dropIfExists('crime_data');
    }
};
