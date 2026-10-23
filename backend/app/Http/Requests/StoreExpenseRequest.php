<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Tab membership is checked in the controller.
    }

    public function rules(): array
    {
        return [
            'description' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'paid_by' => ['required', 'uuid', 'exists:tab_members,id'],
            'split_method' => ['required', 'in:equal,custom'],
            'expense_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
            'participants' => ['required', 'array', 'min:1'],
            'participants.*.tab_member_id' => ['required', 'uuid', 'exists:tab_members,id'],
            'participants.*.share_amount' => ['required_if:split_method,custom', 'numeric', 'min:0'],
        ];
    }

    /**
     * Custom amounts must add up exactly (to the cent) to the total expense,
     * per the product brief. Equal splits are computed server-side and don't
     * need this check.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($this->input('split_method') !== 'custom') {
                return;
            }

            $amount = round((float) $this->input('amount', 0), 2);
            $participants = $this->input('participants', []);
            $sum = round(array_sum(array_column($participants, 'share_amount')), 2);

            if (abs($sum - $amount) > 0.01) {
                $validator->errors()->add(
                    'participants',
                    "Custom amounts must add up to the total (RM {$amount}); currently RM {$sum}."
                );
            }
        });
    }
}
