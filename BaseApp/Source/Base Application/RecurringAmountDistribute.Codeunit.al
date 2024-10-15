codeunit 17100 "Recurring Amount - Distribute"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        TestField("Account Type", "Account Type"::"G/L Account");
        if not
           ("Recurring Method" in ["Recurring Method"::"B  Balance",
                                   "Recurring Method"::"RB Reversing Balance"])
        then begin
            GenJnlLine1."Recurring Method" := "Recurring Method"::"B  Balance";
            GenJnlLine2."Recurring Method" := "Recurring Method"::"RB Reversing Balance";
            Error(
              '%1 must be either %2 or %3.',
              FieldName("Recurring Method"),
              GenJnlLine1."Recurring Method",
              GenJnlLine2."Recurring Method");
        end;

        Clear(AmtDistrForm);
        Clear(SumOnAllocAccounts);
        if AmtDistrForm.RunModal = ACTION::OK then begin
            AmtDistrForm.ReturnDates(FromDate, ToDate, WhatToCalculate);

            if not Confirm(Text1450000 + Text1450001, false) then
                exit;

            if "Shortcut Dimension 1 Code" <> '' then
                "G/L Account".SetRange("Global Dimension 1 Filter", "Shortcut Dimension 1 Code");
            if "Shortcut Dimension 2 Code" <> '' then
                "G/L Account".SetRange("Global Dimension 2 Filter", "Shortcut Dimension 2 Code");
            if WhatToCalculate = WhatToCalculate::"Net Change" then
                "G/L Account".SetRange("Date Filter", FromDate, ToDate);

            "G/L Alloc. Line".Reset();
            "G/L Alloc. Line".SetRange("Journal Template Name", "Journal Template Name");
            "G/L Alloc. Line".SetRange("Journal Batch Name", "Journal Batch Name");
            "G/L Alloc. Line".SetRange("Journal Line No.", "Line No.");
            if "G/L Alloc. Line".Find('-') then
                repeat
                    "G/L Account".Get("G/L Alloc. Line"."Account No.");
                    if WhatToCalculate = WhatToCalculate::"Net Change" then begin
                        "G/L Account".CalcFields("Net Change");
                        SumOnAllocAccounts := SumOnAllocAccounts + "G/L Account"."Net Change";
                    end else begin
                        "G/L Account".CalcFields(Balance);
                        SumOnAllocAccounts := SumOnAllocAccounts + "G/L Account".Balance;
                    end;
                until "G/L Alloc. Line".Next() = 0;

            "G/L Alloc. Line".Find('-');
            repeat
                "G/L Account".Get("G/L Alloc. Line"."Account No.");
                if WhatToCalculate = WhatToCalculate::"Net Change" then begin
                    "G/L Account".CalcFields("Net Change");
                    if SumOnAllocAccounts = 0 then
                        "G/L Alloc. Line".Validate("Allocation %", 0)
                    else
                        "G/L Alloc. Line".Validate(
                          "Allocation %",
                          Round(
                            "G/L Account"."Net Change" / SumOnAllocAccounts * 100,
                            0.01, '='));
                end else begin
                    "G/L Account".CalcFields(Balance);
                    if SumOnAllocAccounts = 0 then
                        "G/L Alloc. Line".Validate("Allocation %", 0)
                    else
                        "G/L Alloc. Line".Validate(
                          "Allocation %",
                          Round(
                            "G/L Account".Balance / SumOnAllocAccounts * 100,
                            0.01, '='));
                end;
                "G/L Alloc. Line".Modify();
                SumAllocationPercent += "G/L Alloc. Line"."Allocation %";
            until "G/L Alloc. Line".Next() = 0;
            PercentageRoundDiff := 100 - SumAllocationPercent;
            "G/L Alloc. Line".FindLast;
            "G/L Alloc. Line"."Allocation %" := "G/L Alloc. Line"."Allocation %" + PercentageRoundDiff;
            "G/L Alloc. Line".Modify();
            Message(Text1450002);
        end;
    end;

    var
        "G/L Account": Record "G/L Account";
        "G/L Alloc. Line": Record "Gen. Jnl. Allocation";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        SumOnAllocAccounts: Decimal;
        AmtDistrForm: Page "Amount Distribution";
        FromDate: Date;
        ToDate: Date;
        WhatToCalculate: Option "Net Change",Balance;
        Text1450000: Label 'You are about to overwrite the Allocation Percentages \';
        Text1450001: Label 'on the Allocation Lines. Do you wish to continue?';
        Text1450002: Label 'The percentages were successfully calculated.';
        SumAllocationPercent: Decimal;
        PercentageRoundDiff: Decimal;
}

