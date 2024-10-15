codeunit 31080 AccSchedExtensionManagement
{

    trigger OnRun()
    begin
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedExtension: Record "Acc. Schedule Extension";
        AccSchedMgt: Codeunit AccSchedManagement;
        StartDate: Date;
        EndDate: Date;
        Text001Txt: Label 'BD';
        Text002Txt: Label 'ED';
        Text003Err: Label 'Invalid value for Date Filter = %1.';

    [Scope('OnPrem')]
    procedure CalcCustomFunc(var NewAccSchedLine: Record "Acc. Schedule Line"; NewColumnLayout: Record "Column Layout"; NewStartDate: Date; NewEndDate: Date) Value: Decimal
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        Value := 0;
        AccSchedMgt.SetDateParameters(StartDate, EndDate);
        with AccSchedExtension do begin
            SetFilter(Code, NewAccSchedLine.Totaling);
            if FindFirst then
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
    end;

    [Scope('OnPrem')]
    procedure GetVATEntryValue() Result: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date");
        SetVATLedgEntryFilters(VATEntry);

        case AccSchedExtension."VAT Amount Type" of
            AccSchedExtension."VAT Amount Type"::Base:
                begin
                    VATEntry.CalcSums(Base);
                    Result := VATEntry.Base;
                end;
            AccSchedExtension."VAT Amount Type"::Amount:
                begin
                    VATEntry.CalcSums(Amount);
                    Result := VATEntry.Amount;
                end;
        end;
        if AccSchedExtension."Reverse Sign" then
            Result := -1 * Result;
    end;

    [Scope('OnPrem')]
    procedure GetValueEntry() Result: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type",
          "Variance Type", "Item Charge No.", "Location Code", "Variant Code",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
        SetValueLedgEntryFilters(ValueEntry);
        ValueEntry.CalcSums("Cost Posted to G/L");
        Result := ValueEntry."Cost Posted to G/L";
        if AccSchedExtension."Reverse Sign" then
            Result := -1 * Result;
    end;

    [Scope('OnPrem')]
    procedure CalcDateFormula(DateFormula: Text[250]): Date
    begin
        if DateFormula = '' then
            exit(0D);

        case CopyStr(DateFormula, 1, 2) of
            Text001Txt:
                exit(CalcDate(CopyStr(DateFormula, 3), StartDate));
            Text002Txt:
                exit(CalcDate(CopyStr(DateFormula, 3), EndDate));
        end;

        Error(Text003Err, DateFormula);
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
            Text001Txt:
                exit(Format(StartDate));
            Text002Txt:
                exit(Format(EndDate));
        end;

        exit(DateFilter);
    end;

    [Scope('OnPrem')]
    procedure SetCustLedgEntryFilters(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                CustLedgEntry.SetFilter("Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                CustLedgEntry.SetFilter("Posting Date", AccSchedMgt.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            CustLedgEntry.CopyFilter("Posting Date", CustLedgEntry."Date Filter");
            CustLedgEntry.SetFilter("Global Dimension 1 Code", AccSchedLine.GetFilter("Dimension 1 Filter"));
            CustLedgEntry.SetFilter("Global Dimension 2 Code", AccSchedLine.GetFilter("Dimension 2 Filter"));

            if "Document Type Filter" <> '' then
                CustLedgEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                CustLedgEntry.SetFilter("Customer Posting Group", "Posting Group Filter");
            if Prepayment = Prepayment::Yes then
                CustLedgEntry.SetRange(Prepayment, true);
            if Prepayment = Prepayment::No then
                CustLedgEntry.SetRange(Prepayment, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVendLedgEntryFilters(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        with AccSchedExtension do begin
            if "Posting Date Filter" <> '' then
                VendLedgEntry.SetFilter("Posting Date",
                  GetDateFilter("Posting Date Filter"))
            else
                VendLedgEntry.SetFilter("Posting Date", AccSchedMgt.GetPostingDateFilter(AccSchedLine, ColumnLayout));
            VendLedgEntry.CopyFilter("Posting Date", VendLedgEntry."Date Filter");
            VendLedgEntry.SetFilter("Global Dimension 1 Code", AccSchedLine.GetFilter("Dimension 1 Filter"));
            VendLedgEntry.SetFilter("Global Dimension 2 Code", AccSchedLine.GetFilter("Dimension 2 Filter"));

            if "Document Type Filter" <> '' then
                VendLedgEntry.SetFilter("Document Type", "Document Type Filter");
            if "Posting Group Filter" <> '' then
                VendLedgEntry.SetFilter("Vendor Posting Group", "Posting Group Filter");
            if Prepayment = Prepayment::Yes then
                VendLedgEntry.SetRange(Prepayment, true);
            if Prepayment = Prepayment::No then
                VendLedgEntry.SetRange(Prepayment, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVATLedgEntryFilters(var VATEntry: Record "VAT Entry")
    begin
        case AccSchedExtension."Entry Type" of
            AccSchedExtension."Entry Type"::Purchase:
                VATEntry.SetRange(Type, VATEntry.Type::Purchase);
            AccSchedExtension."Entry Type"::Sale:
                VATEntry.SetRange(Type, VATEntry.Type::Sale);
        end;
        VATEntry.SetFilter("Posting Date", AccSchedMgt.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        VATEntry.SetFilter("VAT Bus. Posting Group", AccSchedExtension."VAT Bus. Post. Group Filter");
        VATEntry.SetFilter("VAT Prod. Posting Group", AccSchedExtension."VAT Prod. Post. Group Filter");
    end;

    [Scope('OnPrem')]
    procedure SetValueLedgEntryFilters(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.SetFilter("Global Dimension 1 Code", AccSchedLine.GetFilter("Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", AccSchedLine.GetFilter("Dimension 2 Filter"));
        ValueEntry.SetFilter("Location Code", AccSchedExtension."Location Filter");
        ValueEntry.SetFilter("Posting Date", AccSchedMgt.GetPostingDateFilter(AccSchedLine, ColumnLayout));
    end;

    [Scope('OnPrem')]
    procedure GetCustEntryValue() Amount: Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        SetCustLedgEntryFilters(CustLedgEntry);
        if CustLedgEntry.FindSet then
            repeat
                CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
                case AccSchedExtension."Amount Sign" of
                    AccSchedExtension."Amount Sign"::" ":
                        Amount += CustLedgEntry."Remaining Amt. (LCY)";
                    AccSchedExtension."Amount Sign"::Positive:
                        if CustLedgEntry."Remaining Amt. (LCY)" > 0 then
                            Amount += CustLedgEntry."Remaining Amt. (LCY)";
                    AccSchedExtension."Amount Sign"::Negative:
                        if CustLedgEntry."Remaining Amt. (LCY)" < 0 then
                            Amount += CustLedgEntry."Remaining Amt. (LCY)";
                end;
            until CustLedgEntry.Next() = 0;

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure GetVendEntryValue() Amount: Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        SetVendLedgEntryFilters(VendLedgEntry);
        if VendLedgEntry.FindSet then
            repeat
                VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
                case AccSchedExtension."Amount Sign" of
                    AccSchedExtension."Amount Sign"::" ":
                        Amount += VendLedgEntry."Remaining Amt. (LCY)";
                    AccSchedExtension."Amount Sign"::Positive:
                        if VendLedgEntry."Remaining Amt. (LCY)" > 0 then
                            Amount += VendLedgEntry."Remaining Amt. (LCY)";
                    AccSchedExtension."Amount Sign"::Negative:
                        if VendLedgEntry."Remaining Amt. (LCY)" < 0 then
                            Amount += VendLedgEntry."Remaining Amt. (LCY)";
                end;
            until VendLedgEntry.Next() = 0;

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure DrillDownAmount(var NewAccSchedLine: Record "Acc. Schedule Line"; NewColumnLayout: Record "Column Layout"; ExtensionCode: Code[20]; NewStartDate: Date; NewEndDate: Date)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        AccSchedExtension.Get(ExtensionCode);
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        AccSchedMgt.SetDateParameters(StartDate, EndDate);
        case AccSchedExtension."Source Table" of
            AccSchedExtension."Source Table"::"VAT Entry":
                begin
                    SetVATLedgEntryFilters(VATEntry);
                    PAGE.Run(0, VATEntry);
                end;
            AccSchedExtension."Source Table"::"Customer Entry":
                begin
                    SetCustLedgEntryFilters(CustLedgEntry);
                    PAGE.Run(0, CustLedgEntry);
                end;
            AccSchedExtension."Source Table"::"Vendor Entry":
                begin
                    SetVendLedgEntryFilters(VendLedgEntry);
                    PAGE.Run(0, VendLedgEntry);
                end;
            AccSchedExtension."Source Table"::"Value Entry":
                begin
                    SetValueLedgEntryFilters(ValueEntry);
                    PAGE.Run(0, ValueEntry);
                end;
        end;
    end;
}

