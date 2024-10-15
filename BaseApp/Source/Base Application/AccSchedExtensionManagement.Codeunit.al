codeunit 26581 AccSchedExtensionManagement
{

    trigger OnRun()
    begin
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedExtension: Record "Acc. Schedule Extension";
        GLSetup: Record "General Ledger Setup";
        ReportPeriod: Record Date;
        AccSchedManagement: Codeunit AccSchedManagement;
        Text001: Label 'BD';
        Text002: Label 'ED';
        Text003: Label 'Invalid value for Date Filter = %1.';
        StartDate: Date;
        EndDate: Date;

    [Scope('OnPrem')]
    procedure CalcCustomFunc(var NewAccSchedLine: Record "Acc. Schedule Line"; NewColumnLayout: Record "Column Layout"; NewStartDate: Date; NewEndDate: Date) Value: Decimal
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        Value := 0;
        GLSetup.Get();
        AccSchedManagement.SetDateParameters(StartDate, EndDate);
        with AccSchedExtension do
            if Get(NewAccSchedLine.Totaling) then
                case "Source Table" of
                    "Source Table"::"VAT Entry":
                        Value := GetVATEntryValue;
                    "Source Table"::"Value Entry":
                        Value := GetValueEntry;
                    "Source Table"::"Customer Entry":
                        Value := GetCustEntryValue;
                    "Source Table"::"Vendor Entry":
                        Value := GetVendEntryValue;
                end;
    end;

    [Scope('OnPrem')]
    procedure SetAccSchedLine(var NewAccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.Copy(NewAccSchedLine);
    end;

    [Scope('OnPrem')]
    procedure SetReportPeriod(var NewReportPeriod: Record Date)
    begin
        ReportPeriod.Copy(NewReportPeriod);
    end;

    [Scope('OnPrem')]
    procedure CalcDateFormula(DateFormula: Text[250]): Date
    begin
        // ED or BD formulas proccessing
        // ED or BD have to be in the begining of the formula

        if DateFormula = '' then
            exit(0D);

        case CopyStr(DateFormula, 1, 2) of
            Text001:
                exit(CalcDate(CopyStr(DateFormula, 3), StartDate));
            Text002:
                exit(CalcDate(CopyStr(DateFormula, 3), EndDate));
        end;

        Error(Text003, DateFormula);
    end;

    [Scope('OnPrem')]
    procedure GetDateFilter(DateFilter: Text[250]): Text[250]
    var
        Position: Integer;
        LeftFormula: Text[250];
        RightFormula: Text[250];
    begin
        if DateFilter = '' then
            exit(DateFilter);

        Position := StrPos(DateFilter, '..');
        if Position > 0 then begin
            LeftFormula := CopyStr(DateFilter, 1, Position - 1);
            RightFormula := CopyStr(DateFilter, Position + 2);
            exit(Format(CalcDateFormula(LeftFormula)) + '..' + Format(CalcDateFormula(RightFormula)));
        end;

        case DateFilter of
            Text001:
                exit(Format(StartDate));
            Text002:
                exit(Format(EndDate));
            else
                Error(Text003, DateFilter);
        end;

        exit(DateFilter);
    end;

    [Scope('OnPrem')]
    procedure SetCustLedgEntryFilters(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                CustLedgerEntry.SetFilter("Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                CustLedgerEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            CustLedgerEntry.CopyFilter("Posting Date", CustLedgerEntry."Date Filter");

            if NetChangeFilter(CustLedgerEntry.GetFilter("Posting Date")) then
                CustLedgerEntry.SetRange("Posting Date", 0D);

            CustLedgerEntry.SetFilter("Due Date", GetDueDateFilter);
            if "Document Type Filter" <> '' then
                CustLedgerEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                CustLedgerEntry.SetFilter("Customer Posting Group", "Posting Group Filter");
            case "Prepayment Filter" of
                "Prepayment Filter"::Yes:
                    CustLedgerEntry.SetRange(Prepayment, true);
                "Prepayment Filter"::No:
                    CustLedgerEntry.SetRange(Prepayment, false);
            end;
            case "Amount Sign" of
                "Amount Sign"::Positive:
                    CustLedgerEntry.SetRange(Positive, true);
                "Amount Sign"::Negative:
                    CustLedgerEntry.SetRange(Positive, false);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDtldCustLedgEntryFilters(var DtldCustLedgerEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                DtldCustLedgerEntry.SetFilter("Initial Entry Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                DtldCustLedgerEntry.SetFilter(
                  "Initial Entry Posting Date",
                  AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            DtldCustLedgerEntry.CopyFilter("Initial Entry Posting Date", DtldCustLedgerEntry."Posting Date");

            if NetChangeFilter(DtldCustLedgerEntry.GetFilter("Initial Entry Posting Date")) then
                DtldCustLedgerEntry.SetRange("Initial Entry Posting Date", 0D);

            DtldCustLedgerEntry.SetFilter("Initial Entry Due Date", GetDueDateFilter);
            DtldCustLedgerEntry.SetRange("Prepmt. Diff. in TA", false);
            if "Document Type Filter" <> '' then
                DtldCustLedgerEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                DtldCustLedgerEntry.SetFilter("Customer Posting Group", "Posting Group Filter");
            case "Prepayment Filter" of
                "Prepayment Filter"::Yes:
                    DtldCustLedgerEntry.SetRange(Prepayment, true);
                "Prepayment Filter"::No:
                    DtldCustLedgerEntry.SetRange(Prepayment, false);
            end;
            case "Amount Sign" of
                "Amount Sign"::Positive:
                    DtldCustLedgerEntry.SetRange("Initial Entry Positive", true);
                "Amount Sign"::Negative:
                    DtldCustLedgerEntry.SetRange("Initial Entry Positive", false);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVendLedgEntryFilters(var VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                VendLedgerEntry.SetFilter("Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                VendLedgerEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            VendLedgerEntry.CopyFilter("Posting Date", VendLedgerEntry."Date Filter");

            if NetChangeFilter(VendLedgerEntry.GetFilter("Posting Date")) then
                VendLedgerEntry.SetRange("Posting Date", 0D);

            VendLedgerEntry.SetFilter("Due Date", GetDueDateFilter);
            if "Document Type Filter" <> '' then
                VendLedgerEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                VendLedgerEntry.SetFilter("Vendor Posting Group", "Posting Group Filter");
            case "Prepayment Filter" of
                "Prepayment Filter"::Yes:
                    VendLedgerEntry.SetRange(Prepayment, true);
                "Prepayment Filter"::No:
                    VendLedgerEntry.SetRange(Prepayment, false);
            end;
            case "Amount Sign" of
                "Amount Sign"::Positive:
                    VendLedgerEntry.SetRange(Positive, true);
                "Amount Sign"::Negative:
                    VendLedgerEntry.SetRange(Positive, false);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDtldVendLedgEntryFilters(var DtldVendLedgerEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                DtldVendLedgerEntry.SetFilter("Initial Entry Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                DtldVendLedgerEntry.SetFilter(
                  "Initial Entry Posting Date",
                  AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            DtldVendLedgerEntry.CopyFilter("Initial Entry Posting Date", DtldVendLedgerEntry."Posting Date");

            if NetChangeFilter(DtldVendLedgerEntry.GetFilter("Initial Entry Posting Date")) then
                DtldVendLedgerEntry.SetRange("Initial Entry Posting Date", 0D);

            DtldVendLedgerEntry.SetFilter("Initial Entry Due Date", GetDueDateFilter);
            DtldVendLedgerEntry.SetRange("Prepmt. Diff. in TA", false);
            if "Document Type Filter" <> '' then
                DtldVendLedgerEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                DtldVendLedgerEntry.SetFilter("Vendor Posting Group", "Posting Group Filter");
            case "Prepayment Filter" of
                "Prepayment Filter"::Yes:
                    DtldVendLedgerEntry.SetRange(Prepayment, true);
                "Prepayment Filter"::No:
                    DtldVendLedgerEntry.SetRange(Prepayment, false);
            end;
            case "Amount Sign" of
                "Amount Sign"::Positive:
                    DtldVendLedgerEntry.SetRange("Initial Entry Positive", true);
                "Amount Sign"::Negative:
                    DtldVendLedgerEntry.SetRange("Initial Entry Positive", false);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVATLedgEntryFilters(var VATEntry: Record "VAT Entry")
    begin
        with AccSchedExtension do begin
            case "VAT Entry Type" of
                "VAT Entry Type"::Purchase:
                    VATEntry.SetRange(Type, VATEntry.Type::Purchase);
                "VAT Entry Type"::Sale:
                    VATEntry.SetRange(Type, VATEntry.Type::Sale);
            end;
            case "Prepayment Filter" of
                "Prepayment Filter"::Yes:
                    VATEntry.SetRange(Prepayment, true);
                "Prepayment Filter"::No:
                    VATEntry.SetRange(Prepayment, false);
            end;
            VATEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            VATEntry.SetFilter("VAT Bus. Posting Group", "VAT Bus. Post. Group Filter");
            VATEntry.SetFilter("VAT Prod. Posting Group", "VAT Prod. Post. Group Filter");
            VATEntry.SetFilter("Gen. Bus. Posting Group", "Gen. Bus. Post. Group Filter");
            VATEntry.SetFilter("Gen. Prod. Posting Group", "Gen. Prod. Post. Group Filter");
            if "Object Type Filter" <> "Object Type Filter"::" " then
                VATEntry.SetRange("Object Type", "Object Type Filter" - 1);
            VATEntry.SetFilter("Object No.", "Object No. Filter");
            if "VAT Allocation Type Filter" <> "VAT Allocation Type Filter"::" " then
                VATEntry.SetRange("VAT Allocation Type", "VAT Allocation Type Filter" - 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetValueLedgEntryFilters(var ValueEntry: Record "Value Entry")
    begin
        with AccSchedExtension do begin
            ValueEntry.SetFilter("Location Code", "Location Filter");
            ValueEntry.SetFilter("Item Charge No.", "Item Charge No. Filter");
            ValueEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            ValueEntry.SetFilter("Inventory Posting Group", AccSchedExtension."Inventory Posting Group Filter");
            if "Value Entry Type Filter" <> "Value Entry Type Filter"::" " then
                ValueEntry.SetRange("Entry Type", "Value Entry Type Filter" - 1);
            case "Amount Sign" of
                "Amount Sign"::Positive:
                    ValueEntry.SetRange(Positive, true);
                "Amount Sign"::Negative:
                    ValueEntry.SetRange(Positive, false);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATEntryValue() Result: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey(
          Type,
          "Posting Date",
          "VAT Bus. Posting Group",
          "VAT Prod. Posting Group",
          "Gen. Bus. Posting Group",
          "Gen. Prod. Posting Group",
          "Object Type",
          "Object No.",
          "VAT Allocation Type",
          Prepayment);

        SetVATLedgEntryFilters(VATEntry);
        VATEntry.CalcSums(
          Base,
          Amount,
          "Unrealized Amount",
          "Unrealized Base",
          "Remaining Unrealized Amount",
          "Remaining Unrealized Base");

        with AccSchedExtension do begin
            case "VAT Type" of
                "VAT Type"::Realized:
                    case "VAT Amount Type" of
                        "VAT Amount Type"::Base:
                            Result := VATEntry.Base;
                        "VAT Amount Type"::Amount:
                            Result := VATEntry.Amount;
                        "VAT Amount Type"::Total:
                            Result := VATEntry.Base + VATEntry.Amount;
                    end;
                "VAT Type"::Unrealized:
                    case "VAT Amount Type" of
                        "VAT Amount Type"::Base:
                            Result := VATEntry."Unrealized Base";
                        "VAT Amount Type"::Amount:
                            Result := VATEntry."Unrealized Amount";
                        "VAT Amount Type"::Total:
                            Result := VATEntry."Unrealized Base" + VATEntry."Unrealized Amount";
                    end;
                "VAT Type"::"Remaining Unrealized":
                    case "VAT Amount Type" of
                        "VAT Amount Type"::Base:
                            Result := VATEntry."Remaining Unrealized Base";
                        "VAT Amount Type"::Amount:
                            Result := VATEntry."Remaining Unrealized Amount";
                        "VAT Amount Type"::Total:
                            Result := VATEntry."Remaining Unrealized Base" + VATEntry."Remaining Unrealized Amount";
                    end;
            end;

            if "Reverse Sign" then
                Result := -1 * Result;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetValueEntry() Result: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Posting Date", "Location Code", "Entry Type", "Inventory Posting Group", "Item Charge No.", Positive);
        SetValueLedgEntryFilters(ValueEntry);
        ValueEntry.CalcSums(
          "Cost Posted to G/L",
          "Sales Amount (Expected)",
          "Sales Amount (Actual)",
          "Cost Amount (Expected)",
          "Cost Amount (Actual)",
          "Cost Amount (Non-Invtbl.)",
          "Purchase Amount (Actual)",
          "Purchase Amount (Expected)");

        with AccSchedExtension do begin
            case "Value Entry Amount Type" of
                "Value Entry Amount Type"::"Cost Posted to G/L":
                    Result := ValueEntry."Cost Posted to G/L";
                "Value Entry Amount Type"::"Sales Amount (Expected)":
                    Result := ValueEntry."Sales Amount (Expected)";
                "Value Entry Amount Type"::"Sales Amount (Actual)":
                    Result := ValueEntry."Sales Amount (Actual)";
                "Value Entry Amount Type"::"Cost Amount (Expected)":
                    Result := ValueEntry."Cost Amount (Expected)";
                "Value Entry Amount Type"::"Cost Amount (Actual)":
                    Result := ValueEntry."Cost Amount (Actual)";
                "Value Entry Amount Type"::"Cost Amount (Non-Invtbl.)":
                    Result := ValueEntry."Cost Amount (Non-Invtbl.)";
                "Value Entry Amount Type"::"Purchase Amount (Actual)":
                    Result := ValueEntry."Purchase Amount (Actual)";
                "Value Entry Amount Type"::"Purchase Amount (Expected)":
                    Result := ValueEntry."Purchase Amount (Expected)";
            end;

            if "Reverse Sign" then
                Result := -1 * Result;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCustEntryValue() Amount: Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetCurrentKey(
          "Posting Date", "Initial Entry Posting Date", "Document Type",
          "Initial Entry Due Date", "Customer Posting Group", Prepayment, "Initial Entry Positive");
        SetDtldCustLedgEntryFilters(DetailedCustLedgEntry);
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");
        Amount := DetailedCustLedgEntry."Amount (LCY)";

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure GetVendEntryValue() Amount: Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetCurrentKey(
          "Posting Date", "Initial Entry Posting Date", "Document Type",
          "Initial Entry Due Date", "Vendor Posting Group", Prepayment, "Initial Entry Positive");
        SetDtldVendLedgEntryFilters(DetailedVendorLedgEntry);
        DetailedVendorLedgEntry.CalcSums("Amount (LCY)");
        Amount := DetailedVendorLedgEntry."Amount (LCY)";

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure DrillDownAmount(var NewAccSchedLine: Record "Acc. Schedule Line"; var NewColumnLayout: Record "Column Layout"; ExtensionCode: Code[20]; NewStartDate: Date; NewEndDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        AccSchedExtension.Get(ExtensionCode);
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        GLSetup.Get();
        AccSchedManagement.SetDateParameters(StartDate, EndDate);
        case AccSchedExtension."Source Table" of
            AccSchedExtension."Source Table"::"VAT Entry":
                begin
                    SetVATLedgEntryFilters(VATEntry);
                    PAGE.Run(0, VATEntry);
                end;
            AccSchedExtension."Source Table"::"Customer Entry":
                begin
                    SetCustLedgEntryFilters(CustLedgerEntry);
                    PAGE.Run(0, CustLedgerEntry);
                end;
            AccSchedExtension."Source Table"::"Vendor Entry":
                begin
                    SetVendLedgEntryFilters(VendLedgerEntry);
                    PAGE.Run(0, VendLedgerEntry);
                end;
            AccSchedExtension."Source Table"::"Value Entry":
                begin
                    SetValueLedgEntryFilters(ValueEntry);
                    PAGE.Run(0, ValueEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDueDateFilter(): Text[100]
    var
        DateFormula: DateFormula;
        Period: Text[30];
        ShortTermDate: Date;
        ClosDate: Boolean;
    begin
        GLSetup.TestField("Short-Term Due Period");
        case ColumnLayout."Column Type" of
            ColumnLayout."Column Type"::"Beginning Balance":
                begin
                    ClosDate := true;
                    Evaluate(DateFormula, '<-1D>');
                    Period := Text001 + Format(DateFormula);
                end;
            ColumnLayout."Column Type"::"Balance at Date":
                Period := Text002;
            else
                exit('');
        end;
        with AccSchedExtension do
            case "Liability Type" of
                "Liability Type"::" ":
                    exit(GetDateFilter("Due Date Filter"));
                "Liability Type"::"Short Term":
                    begin
                        ShortTermDate := CalcDateFormula(Period + Format(GLSetup."Short-Term Due Period"));
                        if ClosDate then
                            ShortTermDate := ClosingDate(ShortTermDate);
                        exit('..' + Format(ShortTermDate));
                    end;
                "Liability Type"::"Long Term":
                    begin
                        Evaluate(DateFormula, '<+1D>');
                        exit(Format(CalcDateFormula(Period + Format(GLSetup."Short-Term Due Period") + Format(DateFormula))) + '..');
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckDateFilter(DueDateFilter: Code[20])
    begin
        GLSetup.Get();
        StartDate := Today;
        EndDate := Today;
        GetDateFilter(DueDateFilter);
    end;

    [Scope('OnPrem')]
    procedure NetChangeFilter(DateFilter: Text[30]): Boolean
    begin
        exit(DateFilter[1] in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
    end;
}

