codeunit 17416 "Payroll Application Management"
{

    trigger OnRun()
    begin
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        ApplyingVendLedgEntry: Record "Vendor Ledger Entry";
        VendEntryApply: Codeunit "VendEntry-Apply Posted Entries";
        RemainingBalance: Decimal;
        ApplyRequired: Boolean;

    [Scope('OnPrem')]
    procedure ApplyEmployee(Employee: Record Employee; PayrollPeriod: Record "Payroll Period"; PaymentDate: Date)
    var
        Person: Record Person;
        Vend: Record Vendor;
    begin
        Person.Get(Employee."Person No.");
        Vend.Get(Person."Vendor No.");
        PayrollPeriod.TestField(Code);
        PayrollPeriod.TestField("Ending Date");
        PayrollPeriod.TestField("Starting Date");

        ApplyRequired := false;
        RemainingBalance := 0;
        VendLedgEntry.Reset;
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange(Open, true);
        if PaymentDate = 0D then
            VendLedgEntry.SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date")
        else
            VendLedgEntry.SetRange("Posting Date", PayrollPeriod."Starting Date", PaymentDate);
        if VendLedgEntry.FindSet then
            repeat
                VendLedgEntry.CalcFields("Remaining Amount");
                if VendLedgEntry."Remaining Amount" <> 0 then begin
                    RemainingBalance := RemainingBalance + VendLedgEntry."Remaining Amount";
                    ApplyRequired := true;
                end;
            until VendLedgEntry.Next = 0;

        if not ApplyRequired then
            exit;

        VendLedgEntry.SetRange(Positive, false);
        VendLedgEntry.FindFirst;
        ApplyingVendLedgEntry.Get(VendLedgEntry."Entry No.");
        ApplyingVendLedgEntry.CalcFields(Amount, "Remaining Amount");
        ApplyingVendLedgEntry."Applying Entry" := true;
        ApplyingVendLedgEntry."Applies-to ID" := ApplyingVendLedgEntry."Document No.";
        ApplyingVendLedgEntry."Amount to Apply" := ApplyingVendLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", ApplyingVendLedgEntry);
        Commit;

        VendLedgEntry.SetRange(Positive, true);
        VendEntrySetApplID.SetApplId(
          VendLedgEntry, ApplyingVendLedgEntry, ApplyingVendLedgEntry."Document No.");
        VendLedgEntry."Entry No." := ApplyingVendLedgEntry."Entry No.";
        PostApply(VendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure ApplyTaxAuthority(var PaymentVendLedgEntry: Record "Vendor Ledger Entry"; PayrollPeriod: Record "Payroll Period"; FromDate: Date; ToDate: Date)
    var
        PstdPayrollDocHeader: Record "Posted Payroll Document";
        PstdPayrollDocLine: Record "Posted Payroll Document Line";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        PayrollPostingGr: Record "Payroll Posting Group";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        NDFLAmount: Decimal;
        LastPayment: Boolean;
    begin
        PaymentVendLedgEntry.CalcFields("Remaining Amount");
        if PaymentVendLedgEntry."Remaining Amount" = 0 then
            exit;

        ApplyingVendLedgEntry.Get(PaymentVendLedgEntry."Entry No.");
        ApplyingVendLedgEntry.CalcFields(Amount, "Remaining Amount");
        ApplyingVendLedgEntry."Applying Entry" := true;
        ApplyingVendLedgEntry."Applies-to ID" := Format(ApplyingVendLedgEntry."Entry No.");
        ApplyingVendLedgEntry."Amount to Apply" := ApplyingVendLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", ApplyingVendLedgEntry);
        Commit;

        LastPayment := false;

        VendLedgEntry2.Reset;
        VendLedgEntry2.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry2.SetRange("Vendor No.", PaymentVendLedgEntry."Vendor No.");
        VendLedgEntry2.SetRange(Open, true);
        VendLedgEntry2.SetRange(Positive, true);
        VendLedgEntry2.SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
        if VendLedgEntry2.Count = 1 then
            LastPayment := true;

        VendLedgEntry2.SetRange(Positive, false);
        if VendLedgEntry2.FindSet then
            repeat
                if LastPayment then begin
                    VendLedgEntry3.Get(VendLedgEntry2."Entry No.");
                    VendLedgEntry3.CalcFields("Remaining Amount");
                    VendLedgEntry3."Applies-to ID" := ApplyingVendLedgEntry."Applies-to ID";
                    VendLedgEntry3."Amount to Apply" := VendLedgEntry3."Remaining Amount";
                    VendLedgEntry3.Modify;
                end else begin
                    NDFLAmount := 0;
                    PayrollLedgEntry.Get(VendLedgEntry2."Payroll Ledger Entry No.");
                    PstdPayrollDocLine.Reset;
                    PstdPayrollDocLine.SetCurrentKey("Employee No.", "Period Code");
                    PstdPayrollDocLine.SetRange("Employee No.", PayrollLedgEntry."Employee No.");
                    PstdPayrollDocLine.SetRange("Period Code", PayrollPeriod.Code);
                    PstdPayrollDocLine.SetRange("Element Type", PstdPayrollDocLine."Element Type"::"Income Tax");
                    if PstdPayrollDocLine.Find('-') then
                        repeat
                            PstdPayrollDocHeader.Get(PstdPayrollDocLine."Document No.");
                            if (FromDate <= PstdPayrollDocHeader."Posting Date") and
                               (PstdPayrollDocHeader."Posting Date" <= ToDate)
                            then
                                if PayrollPostingGr.Get(PstdPayrollDocLine."Posting Group") then
                                    if PayrollPostingGr."Account No." = PaymentVendLedgEntry."Vendor No." then
                                        if PstdPayrollDocLine."Payroll Amount" <> 0 then
                                            NDFLAmount += PstdPayrollDocLine."Payroll Amount";
                        until PstdPayrollDocLine.Next = 0;
                    VendLedgEntry3.Get(VendLedgEntry2."Entry No.");
                    VendLedgEntry3."Applies-to ID" := ApplyingVendLedgEntry."Applies-to ID";
                    VendLedgEntry3.CalcFields("Remaining Amount");
                    if VendLedgEntry3."Remaining Amount" > NDFLAmount then
                        VendLedgEntry3."Amount to Apply" := VendLedgEntry3."Remaining Amount"
                    else
                        VendLedgEntry3."Amount to Apply" := NDFLAmount;
                    VendLedgEntry3.Modify;
                end;
            until VendLedgEntry2.Next = 0;

        PostApply(ApplyingVendLedgEntry);
        Commit;
    end;

    [Scope('OnPrem')]
    procedure PostApply(var Rec: Record "Vendor Ledger Entry")
    var
        VendLedgEntryToApply: Record "Vendor Ledger Entry";
    begin
        VendLedgEntryToApply.Copy(Rec);
        VendEntryApply.Run(VendLedgEntryToApply);
    end;
}

