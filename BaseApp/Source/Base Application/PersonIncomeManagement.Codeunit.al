codeunit 17409 "Person Income Management"
{

    trigger OnRun()
    begin
    end;

    var
        Employee: Record Employee;
        Person: Record Person;
        PayrollPeriod: Record "Payroll Period";
        HRSetup: Record "Human Resources Setup";
        PersonIncomeLine: Record "Person Income Line";
        PayrollPostingGr: Record "Payroll Posting Group";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollCalcGr: Record "Payroll Calc Group";
        PayrollDoc: Record "Payroll Document";
        PstdPayrollDoc: Record "Posted Payroll Document";
        DocNo: Code[20];
        NextLineNo: Integer;
        TaxPercent: Integer;
        IsInterim: Boolean;
        Text001: Label 'There is no Open or Posted %1 %2.';

    [Scope('OnPrem')]
    procedure CreateIncomeTaxLine(PostedPayrollDocLine: Record "Posted Payroll Document Line"; PostingDate: Date; Correction: Boolean)
    var
        PersonIncomeEntry2: Record "Person Income Entry";
        PayrollElement: Record "Payroll Element";
        PersonIncomeHeader: Record "Person Income Header";
        BaseAmount: Decimal;
    begin
        HRSetup.Get();
        with PostedPayrollDocLine do begin
            Employee.Get("Employee No.");
            Person.Get(Employee."Person No.");
            PayrollPeriod.Get("Period Code");
            PayrollElement.Get("Element Code");

            CreateIncomeHeader(PersonIncomeHeader, Person."No.", Date2DMY(PayrollPeriod."Ending Date", 3));
            CreateIncomeLine(PersonIncomeHeader, "Period Code");

            if PstdPayrollDoc.Get("Document No.") then begin
                PayrollCalcGr.Get(PstdPayrollDoc."Calc Group Code");
                IsInterim := PayrollCalcGr.Type = PayrollCalcGr.Type::Between;
            end else
                if PayrollDoc.Get("Document No.") then begin
                    PayrollCalcGr.Get(PayrollDoc."Calc Group Code");
                    IsInterim := PayrollCalcGr.Type = PayrollCalcGr.Type::Between;
                end else
                    Error(Text001, PayrollDoc.TableCaption, "Document No.");

            case "Element Type" of
                "Element Type"::Wage,
              "Element Type"::Bonus:
                    CreateGainTaxLine(PostedPayrollDocLine, PostingDate, PayrollElement."Advance Payment", Correction);
                "Element Type"::Other:
                    if PayrollElement."Income Tax Base" then
                        CreateGainTaxLine(PostedPayrollDocLine, PostingDate, PayrollElement."Advance Payment", Correction);
                "Element Type"::"Tax Deduction":
                    InsertPersonIncomeEntry(
                      PersonIncomeEntry2."Entry Type"::"Tax Deduction", "Document No.",
                      '', 0, 0, 0, Quantity, "Directory Code", -"Payroll Amount", PostingDate, PostingDate,
                      0, "Employee Ledger Entry No.", IsInterim, false);
                "Element Type"::"Income Tax":
                    begin
                        case true of
                            HRSetup."Income Tax 13%" = "Element Code":
                                TaxPercent := 1;
                            HRSetup."Income Tax 30%" = "Element Code":
                                TaxPercent := 2;
                            HRSetup."Income Tax 35%" = "Element Code":
                                TaxPercent := 3;
                            HRSetup."Income Tax 9%" = "Element Code":
                                TaxPercent := 4;
                        end;
                        InsertPersonIncomeEntry(
                          PersonIncomeEntry2."Entry Type"::"Accrued Income Tax", "Document No.",
                          '', TaxPercent, 0, -"Payroll Amount", 0, '', 0, PostingDate, PostingDate,
                          0, "Employee Ledger Entry No.", IsInterim, false);
                        // insert tax authority payment information
                        if PayrollLedgEntry.Get("Payroll Ledger Entry No.") then begin
                            PayrollPostingGr.Get("Posting Group");
                            CreatePaidToBudget(PostedPayrollDocLine, PayrollPostingGr."Account No.", PostingDate);
                        end;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateSocialTaxLine(PostedPayrollDocLine: Record "Posted Payroll Document Line")
    var
        PersonIncomeLine: Record "Person Income FSI";
    begin
        with PostedPayrollDocLine do begin
            if not ("FSI Base" or "FSI Injury Base") then
                exit;

            if not ("Element Type" in ["Element Type"::Wage, "Element Type"::Bonus]) then
                exit;

            Employee.Get("Employee No.");
            PayrollPeriod.Get("Period Code");

            PersonIncomeLine.Reset();
            PersonIncomeLine.SetRange("Person No.", Employee."Person No.");
            PersonIncomeLine.SetRange("Document No.", "Document No.");
            PersonIncomeLine.SetRange("Period Code", "Period Code");
            PersonIncomeLine.SetRange(Calculation, true);
            if PersonIncomeLine.FindFirst then begin
                PersonIncomeLine.Amount += "Payroll Amount";
                PersonIncomeLine.Modify();
            end else begin
                PersonIncomeLine.Init();
                PersonIncomeLine.Validate("Person No.", Employee."Person No.");
                PersonIncomeLine.Validate("Period Code", "Period Code");
                PersonIncomeLine."Document No." := "Document No.";
                PersonIncomeLine.Description := Description;
                PersonIncomeLine.Amount := "Payroll Amount";
                PersonIncomeLine.Calculation := true;
                if PersonIncomeLine.Amount <> 0 then
                    PersonIncomeLine.Insert();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateIncomeHeader(var PersonIncomeHeader: Record "Person Income Header"; PersonNo: Code[20]; NewYear: Integer)
    begin
        with PersonIncomeHeader do begin
            Reset;
            SetCurrentKey("Person No.");
            SetRange("Person No.", PersonNo);
            SetRange(Year, NewYear);
            SetRange(Calculation, true);
            if DocNo <> '' then
                SetRange("No.", DocNo);
            if not FindFirst then begin
                Init;
                "No." := '';
                Insert(true);
                "Person No." := PersonNo;
                Validate(Year, NewYear);
                Calculation := true;
                Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateIncomeLine(NewPersonIncomeHeader: Record "Person Income Header"; PeriodCode: Code[10])
    begin
        with PersonIncomeLine do begin
            Reset;
            SetRange("Document No.", NewPersonIncomeHeader."No.");
            if FindLast then
                NextLineNo := "Line No." + 10000
            else
                NextLineNo := 10000;
            SetRange("Period Code", PeriodCode);
            SetRange(Calculation, true);
            if IsEmpty then begin
                Init;
                "Document No." := NewPersonIncomeHeader."No.";
                "Person No." := NewPersonIncomeHeader."Person No.";
                Year := NewPersonIncomeHeader.Year;
                "Line No." := NextLineNo;
                "Period Code" := PeriodCode;
                Calculation := true;
                Insert;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDocNo(DocNo2: Code[20])
    begin
        DocNo := DocNo2;
    end;

    [Scope('OnPrem')]
    procedure CreatePaidToBudget(PostedPayrollDocLine: Record "Posted Payroll Document Line"; VendorNo: Code[20]; PostingDate: Date)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        PersonIncomeEntry2: Record "Person Income Entry";
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Payroll Ledger Entry No.");
        VendLedgEntry.SetRange("Payroll Ledger Entry No.", PayrollLedgEntry."Entry No.");
        VendLedgEntry.SetRange("Vendor No.", VendorNo);
        if VendLedgEntry.FindSet then
            repeat
                VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                if VendLedgEntry."Amount (LCY)" <> VendLedgEntry."Remaining Amt. (LCY)" then begin
                    DtldVendLedgEntry.Reset();
                    DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                    DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                    DtldVendLedgEntry.SetRange(Unapplied, false);
                    if DtldVendLedgEntry.FindSet then
                        repeat
                            if DtldVendLedgEntry."Vendor Ledger Entry No." =
                               DtldVendLedgEntry."Applied Vend. Ledger Entry No."
                            then begin
                                DtldVendLedgEntry2.Reset();
                                DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                                DtldVendLedgEntry2.SetRange(
                                  "Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                                DtldVendLedgEntry2.SetRange(
                                  "Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                                DtldVendLedgEntry2.SetRange(Unapplied, false);
                                if DtldVendLedgEntry2.FindSet then
                                    repeat
                                        if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                                           DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                                        then
                                            InsertPersonIncomeEntry(
                                              PersonIncomeEntry2."Entry Type"::"Paid Income Tax", DtldVendLedgEntry2."Document No.",
                                              '', 0, 0, Abs(DtldVendLedgEntry2."Amount (LCY)"), 0, '', 0,
                                              DtldVendLedgEntry2."Posting Date", DtldVendLedgEntry2."Posting Date",
                                              DtldVendLedgEntry2."Vendor Ledger Entry No.", PostedPayrollDocLine."Employee Ledger Entry No.",
                                              DtldVendLedgEntry2."Posting Date" <> DtldVendLedgEntry."Posting Date", false);
                                    until DtldVendLedgEntry2.Next = 0;
                            end else
                                if VendLedgEntry2.Get(DtldVendLedgEntry."Applied Vend. Ledger Entry No.") then
                                    InsertPersonIncomeEntry(
                                      PersonIncomeEntry2."Entry Type"::"Paid Income Tax", DtldVendLedgEntry."Document No.",
                                      '', 0, 0, Abs(DtldVendLedgEntry."Amount (LCY)"), 0, '', 0,
                                      VendLedgEntry2."Posting Date", VendLedgEntry2."Posting Date",
                                      DtldVendLedgEntry."Applied Vend. Ledger Entry No.", PostedPayrollDocLine."Employee Ledger Entry No.",
                                      DtldVendLedgEntry."Posting Date" <> VendLedgEntry2."Posting Date", false);
                        until DtldVendLedgEntry.Next = 0;
                end;
            until VendLedgEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreatePaidToPerson(PersonNo: Code[20]; PayrollPeriod: Record "Payroll Period")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PersonIncomeEntry2: Record "Person Income Entry";
    begin
        Person.Get(PersonNo);
        Person.TestField("Vendor No.");
        PayrollPeriod.Get(PayrollPeriod.Code);
        with VendLedgEntry do begin
            Reset;
            SetCurrentKey("Vendor No.");
            SetRange("Vendor No.", Person."Vendor No.");
            SetRange("Posting Date", PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
            SetRange("Document Type", "Document Type"::Payment);
            if FindSet then
                repeat
                    CalcFields("Amount (LCY)");
                    InsertPersonIncomeEntry(
                      PersonIncomeEntry2."Entry Type"::"Paid Taxable Income", "Document No.",
                      '', 0, "Amount (LCY)", 0, 0, '', 0,
                      "Posting Date", "Posting Date",
                      0, 0, "Posting Date" < PayrollPeriod."Ending Date", false);
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertPersonIncomeEntry(EntryType: Option; DocNo: Code[20]; TaxCode: Code[10]; TaxPercent: Option; Base: Decimal; Amount: Decimal; Quantity: Decimal; TaxDeductionCode: Code[10]; TaxDeductionAmount: Decimal; PostingDate: Date; DocumentDate: Date; VendLedgEntryNo: Integer; EmplLedgEntryNo: Integer; Interim: Boolean; Advance: Boolean)
    var
        PersonIncomeEntry: Record "Person Income Entry";
        PersonIncomeEntry3: Record "Person Income Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PayrollDirectory: Record "Payroll Directory";
        NextEntryNo: Integer;
    begin
        PersonIncomeEntry3.Reset();
        PersonIncomeEntry3.SetRange("Person Income No.", PersonIncomeLine."Document No.");
        PersonIncomeEntry3.SetRange("Person Income Line No.", PersonIncomeLine."Line No.");
        if PersonIncomeEntry3.FindLast then
            NextEntryNo := PersonIncomeEntry3."Line No." + 1
        else
            NextEntryNo := 1;

        PersonIncomeEntry.Init();
        PersonIncomeEntry."Person Income No." := PersonIncomeLine."Document No.";
        PersonIncomeEntry."Person Income Line No." := PersonIncomeLine."Line No.";
        PersonIncomeEntry."Line No." := NextEntryNo;
        PersonIncomeEntry."Person No." := PersonIncomeLine."Person No.";
        PersonIncomeEntry."Period Code" := PersonIncomeLine."Period Code";
        PersonIncomeEntry."Entry Type" := EntryType;
        PersonIncomeEntry."Document No." := DocNo;
        PersonIncomeEntry."Document Date" := DocumentDate;
        PersonIncomeEntry."Posting Date" := PostingDate;
        PersonIncomeEntry."Tax Code" := TaxCode;
        PersonIncomeEntry."Tax %" := TaxPercent;
        if TaxCode <> '' then begin
            PayrollDirectory.Reset();
            PayrollDirectory.SetRange(Type, PayrollDirectory.Type::Income);
            PayrollDirectory.SetRange(Code, TaxCode);
            PayrollDirectory.SetFilter("Starting Date", '..%1', PostingDate);
            PayrollDirectory.FindLast;
            PersonIncomeEntry."Tax %" := PayrollDirectory."Income Tax Percent";
        end;
        PersonIncomeEntry.Base := Base;
        PersonIncomeEntry.Amount := Amount;
        PersonIncomeEntry."Tax Deduction Code" := TaxDeductionCode;
        PersonIncomeEntry."Tax Deduction Amount" := TaxDeductionAmount;
        PersonIncomeEntry.Quantity := Quantity;
        PersonIncomeEntry."User ID" := UserId;
        PersonIncomeEntry.Calculation := true;
        PersonIncomeEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        if VendLedgEntryNo <> 0 then begin
            VendLedgEntry.Get(VendLedgEntryNo);
            PersonIncomeEntry."Document Type" := VendLedgEntry."Document Type".AsInteger();
            if EntryType = PersonIncomeEntry."Entry Type"::"Paid Taxable Income" then begin
                if VendLedgEntry."Document Type" <> VendLedgEntry."Document Type"::Payment then
                    exit;
                VendLedgEntry.CalcFields("Amount (LCY)");
                PersonIncomeEntry.Base := Abs(VendLedgEntry."Amount (LCY)");
            end;
        end;
        PersonIncomeEntry."Employee Ledger Entry No." := EmplLedgEntryNo;
        PersonIncomeEntry.Interim := Interim;
        PersonIncomeEntry."Advance Payment" := Advance;
        if (Base <> 0) or (Amount <> 0) or (TaxDeductionAmount <> 0) then
            PersonIncomeEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateGainTaxLine(PostedPayrollDocLine: Record "Posted Payroll Document Line"; PostingDate: Date; AdvancePayment: Boolean; Correction: Boolean)
    var
        PersonIncomeEntry: Record "Person Income Entry";
        BaseAmount: Decimal;
    begin
        with PostedPayrollDocLine do begin
            BaseAmount := "Payroll Amount";

            if ("Employee Ledger Entry No." <> 0) and not Correction then begin
                PersonIncomeEntry.SetCurrentKey("Employee Ledger Entry No.");
                PersonIncomeEntry.SetRange("Period Code", "Period Code");
                PersonIncomeEntry.SetRange("Person No.", Person."No.");
                PersonIncomeEntry.SetRange("Document No.", "Document No.");
                PersonIncomeEntry.SetRange(Interim, IsInterim);
                PersonIncomeEntry.SetRange("Employee Ledger Entry No.", "Employee Ledger Entry No.");
                if PersonIncomeEntry.FindSet then
                    repeat
                        BaseAmount := BaseAmount - PersonIncomeEntry.Base;
                    until PersonIncomeEntry.Next = 0;
            end;

            InsertPersonIncomeEntry(
              PersonIncomeEntry."Entry Type"::"Taxable Income", "Document No.",
              "Directory Code", 0, BaseAmount, 0, 0, '', 0, PostingDate, PostingDate,
              0, "Employee Ledger Entry No.", IsInterim, AdvancePayment);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateSocialTaxLine(PostedPayrollDocLine: Record "Posted Payroll Document Line")
    var
        PersonIncomeLine: Record "Person Income FSI";
        PersonExcludedDays: Record "Person Excluded Days";
    begin
        with PostedPayrollDocLine do begin
            Employee.Get("Employee No.");
            PayrollPeriod.Get("Period Code");

            PersonIncomeLine.Reset();
            PersonIncomeLine.SetRange("Person No.", Employee."Person No.");
            PersonIncomeLine.SetRange("Period Code", "Period Code");
            PersonIncomeLine.SetRange("Document No.", "Document No.");
            PersonIncomeLine.SetRange(Calculation, true);
            if PersonIncomeLine.FindSet then
                repeat
                    PersonExcludedDays.Init();
                    PersonExcludedDays."Person No." := PersonIncomeLine."Person No.";
                    PersonExcludedDays."Period Code" := PersonIncomeLine."Period Code";
                    PersonExcludedDays."Document No." := "Document No.";
                    PersonExcludedDays."Absence Starting Date" := "Action Starting Date";
                    PersonExcludedDays."Absence Ending Date" := "Action Ending Date";
                    PersonExcludedDays."Calendar Days" := "Days To Exclude";
                    PersonExcludedDays.Description := Description;
                    PersonExcludedDays.Insert();
                until PersonIncomeLine.Next = 0;
        end;
    end;
}

