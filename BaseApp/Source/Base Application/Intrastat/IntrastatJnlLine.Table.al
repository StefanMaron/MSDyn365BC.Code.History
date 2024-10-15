table 263 "Intrastat Jnl. Line"
{
    Caption = 'Intrastat Jnl. Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Intrastat Jnl. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Intrastat Jnl. Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            NotBlank = true;
            TableRelation = "Tariff Number";

            trigger OnValidate()
            begin
                GetItemDescription;
            end;
        }
        field(7; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(9; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(10; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(11; "Source Type"; Enum "Intrastat Source Type")
        {
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if "Source Type" = "Source Type"::"VAT Entry" then
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, false);
                if "Source Type" <> xRec."Source Type" then begin
                    "Source Entry No." := 0;
                    if xRec."Source Type" = xRec."Source Type"::"VAT Entry" then
                        ClearFieldValues;
                end;
            end;
        }
        field(12; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';

            trigger OnLookup()
            begin
                LookUpSourceEntryNo;
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                JobLedgEntry: Record "Job Ledger Entry";
                VATEntry: Record "VAT Entry";
            begin
                case "Source Type" of
                    "Source Type"::"Item Entry":
                        if not ItemLedgEntry.Get("Source Entry No.") then
                            Error(
                              Text12101, ItemLedgEntry.FieldCaption("Entry No."), "Source Entry No.");
                    "Source Type"::"Job Entry":
                        if not JobLedgEntry.Get("Source Entry No.") then
                            Error(
                              Text12101, JobLedgEntry.FieldCaption("Entry No."), "Source Entry No.");
                    "Source Type"::"VAT Entry":
                        begin
                            SetVATEntryFilters(VATEntry);
                            VATEntry.SetRange("Entry No.", "Source Entry No.");
                            if not VATEntry.FindFirst then
                                Error(
                                  Text12100, VATEntry.FieldCaption("Entry No."), VATEntry.GetFilters)
                            else
                                ValidateSourceEntryNo("Source Entry No.");
                        end;
                end;
            end;
        }
        field(13; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                if Quantity <> 0 then
                    "Total Weight" := Round("Net Weight" * Quantity, 0.00001)
                else
                    "Total Weight" := 0;
            end;
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if "Cost Regulation %" <> 0 then
                    Validate("Cost Regulation %")
                else
                    CheckIndirectCost;
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if (Quantity <> 0) and Item.Get("Item No.") then
                    Validate("Net Weight", Item."Net Weight")
                else
                    Validate("Net Weight", 0);
            end;
        }
        field(16; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = -100;

            trigger OnValidate()
            begin
                "Indirect Cost" := Round(Amount * "Cost Regulation %" / 100, 1);
                "Statistical Value" := Round(Amount + "Indirect Cost", 1);
                CheckIndirectCost;
            end;
        }
        field(17; "Indirect Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Indirect Cost';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                "Cost Regulation %" := 0;
                CheckIndirectCost;
            end;
        }
        field(18; "Statistical Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Statistical Value';
            DecimalPlaces = 0 : 0;
        }
        field(19; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                TestField("Source Type", 0);

                if "Item No." = '' then
                    Clear(Item)
                else
                    Item.Get("Item No.");

                Name := Item.Description;
                "Tariff No." := Item."Tariff No.";
                "Country/Region of Origin Code" := GetIntrastatCountryCode(Item."Country/Region of Origin Code");
                GetItemDescription;
            end;
        }
        field(21; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(23; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
            Editable = false;
        }
        field(24; "Internal Ref. No."; Text[10])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(25; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(26; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";

            trigger OnValidate()
            begin
                if EntryExitPoint.Get("Entry/Exit Point") then
                    "Group Code" := EntryExitPoint."Group Code"
                else
                    "Group Code" := '';
                Validate("Indirect Cost");
            end;
        }
        field(27; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(28; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            var
                Country: Record "Country/Region";
            begin
                Country.SetRange("EU Country/Region Code", "Transaction Specification");
                if Country.IsEmpty() then
                    FieldError("Transaction Specification");
            end;
        }
        field(29; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(30; "Partner VAT ID"; Text[50])
        {
            Caption = 'Partner VAT ID';
        }
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(32; Counterparty; Boolean)
        {
            Caption = 'Counterparty';
        }
        field(12100; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(12101; "Source Currency Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
        }
        field(12102; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
            ObsoleteState = Pending;
            ObsoleteReason = 'Merged to W1';
            ObsoleteTag = '18.0';
        }
        field(12103; "Corrective entry"; Boolean)
        {
            Caption = 'Corrective entry';
        }
        field(12104; "Group Code"; Code[10])
        {
            Caption = 'Group Code';
            Editable = false;
        }
        field(12105; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            Editable = true;
        }
        field(12115; "Reference Period"; Code[10])
        {
            Caption = 'Reference Period';
            Numeric = true;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            TableRelation = "Service Tariff Number";

            trigger OnValidate()
            begin
                if "Service Tariff No." <> '' then
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, false);
            end;
        }
        field(12178; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                if "Payment Method" <> '' then
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, false);
            end;
        }
        field(12179; "Custom Office No."; Code[6])
        {
            Caption = 'Custom Office No.';
            TableRelation = "Customs Office";

            trigger OnValidate()
            begin
                if "Custom Office No." <> '' then
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, true);
            end;
        }
        field(12180; "Corrected Intrastat Report No."; Code[10])
        {
            Caption = 'Corrected Intrastat Report No.';

            trigger OnLookup()
            var
                IntrastatJnlBatch2: Record "Intrastat Jnl. Batch";
            begin
                SetIntrastatJnlBatchFilters(IntrastatJnlBatch2);
                IntrastatJnlBatch2.Name := "Corrected Intrastat Report No.";
                if PAGE.RunModal(0, IntrastatJnlBatch2, IntrastatJnlBatch2.Name) = ACTION::LookupOK then
                    Validate("Corrected Intrastat Report No.", IntrastatJnlBatch2.Name);
            end;

            trigger OnValidate()
            var
                IntrastatJnlBatch2: Record "Intrastat Jnl. Batch";
            begin
                if "Corrected Intrastat Report No." <> '' then begin
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", false, true);
                    SetIntrastatJnlBatchFilters(IntrastatJnlBatch2);
                    IntrastatJnlBatch2.SetRange(Name, "Corrected Intrastat Report No.");
                    if not IntrastatJnlBatch2.FindFirst then
                        FieldError("Corrected Intrastat Report No.")
                    else
                        Validate("Reference Period", IntrastatJnlBatch2."Statistics Period");
                end;
            end;
        }
        field(12181; "Corrected Document No."; Code[20])
        {
            Caption = 'Corrected Document No.';

            trigger OnLookup()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
                IntrastatJnlLines: Page "Intrastat Jnl. Lines";
            begin
                IntrastatJnlLines.LookupMode := true;
                IntrastatJnlLine.SetRange("Journal Batch Name", "Corrected Intrastat Report No.");
                IntrastatJnlLines.SetTableView(IntrastatJnlLine);
                IntrastatJnlLines.SetRecord(IntrastatJnlLine);
                if IntrastatJnlLines.RunModal = ACTION::LookupOK then begin
                    IntrastatJnlLines.GetRecord(IntrastatJnlLine);
                    Validate("Corrected Document No.", IntrastatJnlLine."Document No.");
                end;
            end;

            trigger OnValidate()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
            begin
                if "Corrected Document No." <> '' then begin
                    IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", false, true);
                    IntrastatJnlLine.SetRange("Journal Batch Name", "Corrected Intrastat Report No.");
                    IntrastatJnlLine.SetRange("Document No.", "Corrected Document No.");
                    if not IntrastatJnlLine.FindFirst then
                        Error(
                          Text12100, FieldCaption("Document No."), IntrastatJnlLine.GetFilters);
                end;
            end;
        }
        field(12182; "Country/Region of Payment Code"; Code[10])
        {
            Caption = 'Country/Region of Payment Code';
            TableRelation = "Country/Region";
        }
        field(12183; "Progressive No."; Code[5])
        {
            Caption = 'Progressive No.';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Entry No.")
        {
        }
        key(Key3; Type, "Country/Region Code", "VAT Registration No.", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", "Area", "Corrective entry")
        {
        }
        key(Key4; "Internal Ref. No.")
        {
        }
        key(Key5; "Document No.")
        {
        }
        key(Key6; Type, "Country/Region Code", "Partner VAT ID", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", "Area", "Corrective entry")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ErrorMessage: Record "Error Message";
    begin
        AssertBatchIsNotReported(Rec);
        ErrorMessage.SetContext(IntrastatJnlBatch);
        ErrorMessage.ClearLogRec(Rec);
    end;

    trigger OnInsert()
    begin
        IntraJnlTemplate.Get("Journal Template Name");
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        if "Statistics Period" = '' then
            "Statistics Period" := IntrastatJnlBatch."Statistics Period"
        else
            if ("Statistics Period" < IntrastatJnlBatch."Statistics Period") and
               (IntrastatJnlBatch."Corrective Entry") then begin
                "Reference Period" := "Statistics Period";
                "Statistics Period" := IntrastatJnlBatch."Statistics Period";
            end;

        if "Entry/Exit Point" <> '' then
            Validate("Entry/Exit Point");

        if ("Source Type" = "Source Type"::"VAT Entry") or
          ("Payment Method" <> '') or
          ("Service Tariff No." <> '')
        then
            IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, false);
        if "Custom Office No." <> '' then
            IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", true, true);
        if ("Corrected Intrastat Report No." <> '') or
          ("Corrected Document No." <> '')
        then
            IntrastatJnlBatch.CheckEUServAndCorrection("Journal Template Name", "Journal Batch Name", false, true);
    end;

    trigger OnModify()
    begin
        AssertBatchIsNotReported(Rec);
    end;

    trigger OnRename()
    begin
        AssertBatchIsNotReported(xRec);
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        EntryExitPoint: Record "Entry/Exit Point";
        Text12100: Label 'There is no %1 with in the filter.\\Filters: %2';
        Text12101: Label '%1 %2 does not exist.';
        CompanyInfo: Record "Company Information";

    local procedure GetItemDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemDescription(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Tariff No." <> '' then begin
            TariffNumber.Get("Tariff No.");
            "Item Description" := TariffNumber.Description;
            "Supplementary Units" := TariffNumber."Supplementary Units";
        end else
            "Item Description" := '';
    end;

    procedure CheckIndirectCost()
    begin
        if EntryExitPoint.Get("Entry/Exit Point") then;
        if EntryExitPoint."Reduce Statistical Value" then
            "Statistical Value" := Amount - "Indirect Cost"
        else
            "Statistical Value" := Amount + "Indirect Cost";
    end;

    local procedure LookUpSourceEntryNo()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATEntries: Page "VAT Entries";
    begin
        case "Source Type" of
            "Source Type"::"Item Entry":
                PAGE.RunModal(0, ItemLedgEntry);
            "Source Type"::"Job Entry":
                PAGE.RunModal(0, JobLedgEntry);
            "Source Type"::"VAT Entry":
                begin
                    VATEntries.LookupMode := true;
                    SetVATEntryFilters(VATEntry);
                    VATEntries.SetTableView(VATEntry);
                    VATEntries.SetRecord(VATEntry);
                    if VATEntries.RunModal = ACTION::LookupOK then begin
                        VATEntries.GetRecord(VATEntry);
                        Validate("Source Entry No.", VATEntry."Entry No.");
                    end;
                end;
        end;
    end;

    procedure ValidateSourceEntryNo(SourceEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        GLSetup.Get();
        if VATEntry.Get(SourceEntryNo) then begin
            Date := VATEntry."Document Date";
            "Country/Region Code" := GetIntrastatCountryCode(VATEntry."Country/Region Code");
            "Partner VAT ID" := VATEntry."VAT Registration No.";
            Amount := GetLineAmount(VATEntry);
            "Document No." := VATEntry."Document No.";
            "Statistics Period" := IntrastatJnlBatch."Statistics Period";
            "Service Tariff No." := VATEntry."Service Tariff No.";
            "Transport Method" := VATEntry."Transport Method";
            "Payment Method" := VATEntry."Payment Method";
            if VATEntry.Type = VATEntry.Type::Sale then begin
                Type := Type::Shipment;
                Amount := Round(Amount, GLSetup."Amount Rounding Precision");
                "Country/Region of Payment Code" := GetIntrastatCountryCode('');
                if VATEntry."Document Type" = VATEntry."Document Type"::"Credit Memo" then begin
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then begin
                        "Corrected Document No." := SalesCrMemoHeader."Applies-to Doc. No.";
                        VATEntry2.Reset();
                        VATEntry2.SetRange("Document No.", SalesCrMemoHeader."Applies-to Doc. No.");
                        if VATEntry2.FindFirst then
                            "Reference Period" := Format(Date2DMY(VATEntry2."Operation Occurred Date", 3));
                    end else
                        if ServCrMemoHeader.Get(VATEntry."Document No.") then begin
                            "Corrected Document No." := ServCrMemoHeader."Applies-to Doc. No.";
                            VATEntry2.Reset();
                            VATEntry2.SetRange("Document No.", ServCrMemoHeader."Applies-to Doc. No.");
                            if VATEntry2.FindFirst then
                                "Reference Period" := Format(Date2DMY(VATEntry2."Operation Occurred Date", 3));
                        end;
                end;
            end else
                if VATEntry.Type = VATEntry.Type::Purchase then begin
                    Type := Type::Receipt;
                    Amount := Round(Amount, GLSetup."Amount Rounding Precision");
                    "Country/Region of Payment Code" := GetIntrastatCountryCode(VATEntry."Country/Region Code");
                    if VATEntry."Document Type" = VATEntry."Document Type"::"Credit Memo" then
                        if PurchCrMemoHeader.Get(VATEntry."Document No.") then begin
                            "Corrected Document No." := PurchCrMemoHeader."Applies-to Doc. No.";
                            VATEntry2.Reset();
                            VATEntry2.SetRange("Document No.", PurchCrMemoHeader."Applies-to Doc. No.");
                            if VATEntry2.FindFirst then
                                "Reference Period" := Format(Date2DMY(VATEntry2."Operation Occurred Date", 3));
                        end;
                    FindSourceCurrency(VATEntry."Bill-to/Pay-to No.", VATEntry."Document Date", VATEntry."Posting Date");
                end;
        end;
    end;

    procedure FindSourceCurrency(VendorNo: Code[20]; DocumentDate: Date; PostingDate: Date)
    var
        Country: Record "Country/Region";
        Vendor: Record Vendor;
        CurrencyExchRate: Record "Currency Exchange Rate";
        CurrencyDate: Date;
        Factor: Decimal;
    begin
        if DocumentDate <> 0D then
            CurrencyDate := DocumentDate
        else
            CurrencyDate := PostingDate;
        if Vendor.Get(VendorNo) then begin
            if Country.Get(Vendor."Country/Region Code") then
                "Currency Code" := Country."Currency Code";
            if "Currency Code" <> '' then begin
                Factor := CurrencyExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                "Source Currency Amount" :=
                  CurrencyExchRate.ExchangeAmtLCYToFCY(
                    CurrencyDate, "Currency Code", Amount, Factor);
            end;
        end;
    end;

    procedure SetVATEntryFilters(var VATEntry: Record "VAT Entry")
    var
        DateFilter: Text[30];
        StartDate: Date;
        EndDate: Date;
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        CalcStartEndDate(StartDate, EndDate);
        DateFilter := Format(StartDate) + '..' + Format(EndDate);
        with VATEntry do begin
            SetFilter("Operation Occurred Date", DateFilter);
            SetRange("EU Service", true);
            if IntrastatJnlBatch.Type = IntrastatJnlBatch.Type::Purchases then
                SetRange(Type, VATEntry.Type::Purchase)
            else
                SetRange(Type, VATEntry.Type::Sale);
            if IntrastatJnlBatch."Corrective Entry" then
                SetRange("Document Type", VATEntry."Document Type"::"Credit Memo")
            else
                SetRange("Document Type", VATEntry."Document Type"::Invoice);
        end;
    end;

    procedure CalcStartEndDate(var StartDate: Date; var EndDate: Date)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Century: Integer;
        Year: Integer;
        Month: Integer;
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        IntrastatJnlBatch.TestField("Statistics Period");
        Century := Date2DMY(WorkDate, 3) div 100;
        Evaluate(Year, CopyStr(IntrastatJnlBatch."Statistics Period", 1, 2));
        Year := Year + Century * 100;
        Evaluate(Month, CopyStr(IntrastatJnlBatch."Statistics Period", 3, 2));
        StartDate := DMY2Date(1, Month, Year);
        case IntrastatJnlBatch.Periodicity of
            IntrastatJnlBatch.Periodicity::Month:
                EndDate := CalcDate('<+1M-1D>', StartDate);
            IntrastatJnlBatch.Periodicity::Quarter:
                EndDate := CalcDate('<+1Q-1D>', StartDate);
            IntrastatJnlBatch.Periodicity::Year:
                EndDate := CalcDate('<+1Y-1D>', StartDate);
        end;
    end;

    procedure ClearFieldValues()
    begin
        Date := 0D;
        "Country/Region Code" := '';
        "VAT Registration No." := '';
        Amount := 0;
        "Document No." := '';
        "Service Tariff No." := '';
        "Transport Method" := '';
        "Payment Method" := '';
        "Reference Period" := '';
        "Corrected Document No." := '';
        "Source Currency Amount" := 0;
        "Custom Office No." := '';
        "Corrected Intrastat Report No." := '';
    end;

    procedure SetIntrastatJnlBatchFilters(var IntrastatJnlBatch2: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlBatch3: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch3.Get("Journal Template Name", "Journal Batch Name");
        IntrastatJnlBatch2.SetRange("Corrective Entry", false);
        IntrastatJnlBatch2.SetRange(Reported, true);
        IntrastatJnlBatch2.SetRange("EU Service", IntrastatJnlBatch3."EU Service");
        IntrastatJnlBatch2.SetRange(Periodicity, IntrastatJnlBatch3.Periodicity);
        IntrastatJnlBatch2.SetRange(Type, IntrastatJnlBatch3.Type);
        IntrastatJnlBatch2.SetRange("Journal Template Name", IntrastatJnlBatch3."Journal Template Name");
    end;

    procedure CalcTotalWeight()
    begin
        if "Net Weight" = 0 then begin
            "Total Weight" := 0;
            exit;
        end;
        if Quantity <> 0 then
            "Total Weight" := Round("Net Weight" * Abs(Quantity), 1, '<')
        else
            "Total Weight" := Round("Net Weight", 1, '<');
        if "Total Weight" = 0 then
            "Total Weight" := 1;
    end;

    procedure GetFormattedTotalWeight(): Integer
    var
        TotalWeight: Decimal;
    begin
        TotalWeight := "Net Weight" * Abs(Quantity);
        if TotalWeight = 0 then
            exit(0);

        TotalWeight := Round(TotalWeight, 1);
        if TotalWeight = 0 then
            exit(1);

        exit(TotalWeight);
    end;

    procedure GetIntrastatCountryCode(CountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        if CountryRegionCode = '' then
            if CompanyInformation.Get() then
                CountryRegionCode := CompanyInformation."Country/Region Code";

        if CountryRegion.Get(CountryRegionCode) then
            if CountryRegion."Intrastat Code" <> '' then
                CountryRegionCode := CountryRegion."Intrastat Code";

        exit(CountryRegionCode);
    end;

    local procedure GetLineAmount(VATEntry: Record "VAT Entry"): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        StartDate: Date;
        EndDate: Date;
        ClosedEntry: Boolean;
        IsCorrective: Boolean;
        TotalAppliedAmount: Decimal;
    begin
        CalcStartEndDate(StartDate, EndDate);
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        IsCorrective := IntrastatJnlBatch."Corrective Entry";

        case VATEntry.Type of
            VATEntry.Type::Purchase:
                begin
                    with VendLedgEntry do begin
                        SetCurrentKey("Transaction No.");
                        SetRange("Transaction No.", VATEntry."Transaction No.");
                        SetRange("Document No.", VATEntry."Document No.");
                        SetFilter("Posting Date", '..%1', EndDate);
                        if FindFirst then begin
                            TotalAppliedAmount :=
                              GetTotalBaseAmount("Transaction No.", "Document No.", VATEntry.Type::Purchase, StartDate, EndDate, IsCorrective);
                            ClosedEntry := "Closed by Entry No." <> 0;
                            exit(CalcApplnDtldVendLedgEntry(VendLedgEntry, StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount));
                        end;
                    end;
                end;
            VATEntry.Type::Sale:
                begin
                    with CustLedgEntry do begin
                        SetCurrentKey("Transaction No.");
                        SetRange("Transaction No.", VATEntry."Transaction No.");
                        SetRange("Document No.", VATEntry."Document No.");
                        SetFilter("Posting Date", '..%1', EndDate);
                        if FindFirst then begin
                            TotalAppliedAmount :=
                              GetTotalBaseAmount("Transaction No.", "Document No.", VATEntry.Type::Sale, StartDate, EndDate, IsCorrective);
                            ClosedEntry := "Closed by Entry No." <> 0;
                            exit(CalcApplnDtldCustLedgEntry(CustLedgEntry, StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount));
                        end;
                    end;
                end;
        end;
    end;

    local procedure CalcApplnDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; StartDate: Date; EndDate: Date; ClosedEntry: Boolean; IsCorrective: Boolean; TotalAppliedAmount: Decimal): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindSet then
            repeat
                if DtldVendLedgEntry."Vendor Ledger Entry No." = DtldVendLedgEntry."Applied Vend. Ledger Entry No." then begin
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgEntry2.FindSet then begin
                        repeat
                            if DtldVendLedgEntry2."Vendor Ledger Entry No." <> DtldVendLedgEntry2."Applied Vend. Ledger Entry No." then
                                FindAppliedVendLedgEntryAmtLCY(
                                  DtldVendLedgEntry2."Vendor Ledger Entry No.", StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount);
                        until DtldVendLedgEntry2.Next() = 0;
                    end;
                end else
                    FindAppliedVendLedgEntryAmtLCY(
                      DtldVendLedgEntry."Applied Vend. Ledger Entry No.", StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount);
            until DtldVendLedgEntry.Next() = 0;
        exit(TotalAppliedAmount);
    end;

    local procedure CalcApplnDtldCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; StartDate: Date; EndDate: Date; ClosedEntry: Boolean; IsCorrective: Boolean; TotalAppliedAmount: Decimal): Decimal
    var
        DtldCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgerEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgerEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DtldCustLedgerEntry.SetRange(Unapplied, false);
        if DtldCustLedgerEntry.FindSet then
            repeat
                if DtldCustLedgerEntry."Cust. Ledger Entry No." = DtldCustLedgerEntry."Applied Cust. Ledger Entry No." then begin
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DtldCustLedgerEntry."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    if DtldCustLedgEntry2.FindSet then begin
                        repeat
                            if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry2."Applied Cust. Ledger Entry No." then
                                FindAppliedCustLedgEntryAmtLCY(
                                  DtldCustLedgEntry2."Cust. Ledger Entry No.", StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount);
                        until DtldCustLedgEntry2.Next() = 0;
                    end;
                end else
                    FindAppliedCustLedgEntryAmtLCY(
                      DtldCustLedgerEntry."Applied Cust. Ledger Entry No.", StartDate, EndDate, ClosedEntry, IsCorrective, TotalAppliedAmount);
            until DtldCustLedgerEntry.Next() = 0;
        exit(TotalAppliedAmount);
    end;

    local procedure FindAppliedVendLedgEntryAmtLCY(EntryNo: Integer; StartDate: Date; EndDate: Date; ClosedEntry: Boolean; IsCorrective: Boolean; var TotalAppliedAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        with VendLedgEntry do begin
            SetRange("Entry No.", EntryNo);
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            if IsCorrective then
                SetFilter("Posting Date", '..%1', EndDate)
            else
                SetRange("Posting Date", StartDate, EndDate);

            if FindFirst then begin
                if IsCorrective then
                    ClosedEntry := ClosedEntry and ("Closed by Entry No." <> 0);
                if ClosedEntry then
                    TotalAppliedAmount := 0
                else
                    TotalAppliedAmount +=
                      GetTotalBaseAmount("Transaction No.", "Document No.", VATEntry.Type::Purchase, StartDate, EndDate, IsCorrective);
            end;
        end;
    end;

    local procedure FindAppliedCustLedgEntryAmtLCY(EntryNo: Integer; StartDate: Date; EndDate: Date; ClosedEntry: Boolean; IsCorrective: Boolean; var TotalAppliedAmount: Decimal): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        with CustLedgEntry do begin
            SetRange("Entry No.", EntryNo);
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            if IsCorrective then
                SetFilter("Posting Date", '..%1', EndDate)
            else
                SetRange("Posting Date", StartDate, EndDate);

            if FindFirst then begin
                if IsCorrective then
                    ClosedEntry := ClosedEntry and ("Closed by Entry No." <> 0);
                if ClosedEntry then
                    TotalAppliedAmount := 0
                else
                    TotalAppliedAmount +=
                      GetTotalBaseAmount("Transaction No.", "Document No.", VATEntry.Type::Sale, StartDate, EndDate, IsCorrective);
            end;
        end;
    end;

    local procedure GetTotalBaseAmount(TransactionNo: Integer; DocumentNo: Code[20]; TypeFilter: Enum "General Posting Type"; StartDate: Date; EndDate: Date; IsCorrective: Boolean) Result: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange(Type, TypeFilter);
            SetRange("Transaction No.", TransactionNo);
            SetRange("Document No.", DocumentNo);
            if IsCorrective then
                SetFilter("Posting Date", '..%1', EndDate)
            else
                SetRange("Posting Date", StartDate, EndDate);

            if FindSet then
                repeat
                    Result += (Base + "Nondeductible Base");
                until Next() = 0;
        end;
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                IntrastatJnlBatch.SetFilter("Journal Template Name", TemplateFilter);
            IntrastatJnlBatch.SetFilter(Name, BatchFilter);
            IntrastatJnlBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    local procedure AssertBatchIsNotReported(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        CheckBatchIsNotReported(IntrastatJnlBatch);
    end;

    local procedure CheckBatchIsNotReported(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBatchIsNotReported(xRec, IntrastatJnlBatch, IsHandled);
        if IsHandled then
            exit;

        IntrastatJnlBatch.TestField(Reported, false);
    end;

    procedure GetCountryOfOriginCode() CountryOfOriginCode: Code[10]
    var
        ItemVendor: Record "Item Vendor";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        CountryOfOriginCode := GetIntrastatCountryCode(Item."Country/Region of Origin Code");
        if IntrastatJnlBatch.Type = IntrastatJnlBatch.Type::Purchases then
            if ("Source Type"::"Item Entry" = "Source Type"::"Item Entry") and ItemLedgerEntry.Get("Source Entry No.") then
                if ItemVendor.Get(ItemLedgerEntry."Source No.", ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code") and
                   (ItemVendor."Country/Region of Origin Code" <> '')
                then
                    CountryOfOriginCode := GetIntrastatCountryCode(ItemVendor."Country/Region of Origin Code");

        OnAfterGetCountryOfOriginCode(Rec, CountryOfOriginCode);
    end;

    procedure GetPartnerID() PartnerID: Text[50]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPartnerID(Rec, PartnerID, IsHandled);
        if IsHandled then
            exit(PartnerID);

        case "Source Type" of
            "Source Type"::"Job Entry":
                exit(GetPartnerIDFromJobEntry());
            "Source Type"::"Item Entry":
                exit(GetPartnerIDFromItemEntry());
        end;
    end;

    local procedure GetPartnerIDFromItemEntry(): Text[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        Vendor: Record Vendor;
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        EU3rdPartyTrade: Boolean;
    begin
        if not ItemLedgerEntry.Get("Source Entry No.") then
            exit('');
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesInvoiceHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesCrMemoHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                if SalesShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesShipmentHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                if ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := ReturnReceiptHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code", PurchCrMemoHdr."VAT Registration No.",
                        IsVendorPrivatePerson(PurchCrMemoHdr."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                if ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code", ReturnShipmentHeader."VAT Registration No.",
                        IsVendorPrivatePerson(ReturnShipmentHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                if PurchRcptHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Vendor.Get(PurchRcptHeader."Buy-from Vendor No.");
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Buy-from Country/Region Code", Vendor."VAT Registration No.",
                        IsVendorPrivatePerson(Vendor."No."), false));
                end;
            ItemLedgerEntry."Document Type"::"Service Shipment":
                if ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceShipmentHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code", ServiceShipmentHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceShipmentHeader."Bill-to Customer No."), ServiceShipmentHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                if ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceInvoiceHeader."Bill-to Customer No."), ServiceInvoiceHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceCrMemoHeader."Bill-to Country/Region Code", ServiceCrMemoHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceCrMemoHeader."Bill-to Customer No."), ServiceCrMemoHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Transfer Receipt":
                if TransferReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferReceiptHeader."Partner VAT ID", false, false));
            ItemLedgerEntry."Document Type"::"Transfer Shipment":
                if TransferShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferShipmentHeader."Partner VAT ID", false, false));
        end;

        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    if not Customer.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Customer."VAT Registration No.",
                        Customer."Partner Type" = Customer."Partner Type"::Person, EU3rdPartyTrade));
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    if not Vendor.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Vendor."VAT Registration No.",
                        Vendor."Partner Type" = Vendor."Partner Type"::Person, false));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry(): Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
    begin
        if not JobLedgerEntry.Get("Source Entry No.") then
            exit('');
        if not Job.Get(JobLedgerEntry."Job No.") then
            exit('');
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit('');
        exit(
          GetPartnerIDForCountry(
            Customer."Country/Region Code", Customer."VAT Registration No.",
            Customer."Partner Type" = Customer."Partner Type"::Person, false));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        if IsPrivatePerson then
            exit('QV999999999999');

        if IsThirdPartyTrade then
            exit('QV999999999999');

        if (CountryRegionCode <> '') and CountryRegion.Get(CountryRegionCode) then
            exit(VATRegistrationNo);

        if IsThirdPartyTrade then
            exit('QV999999999999');

        exit('QV999999999999');
    end;

    local procedure IsCustomerPrivatePerson(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer."Partner Type" = Customer."Partner Type"::Person);
        exit(false);
    end;

    local procedure IsVendorPrivatePerson(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor."Partner Type" = Vendor."Partner Type"::Person);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCountryOfOriginCode(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var CountryOfOriginCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBatchIsNotReported(xIntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetItemDescription(var IsHandled: Boolean; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPartnerID(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var PartnerID: Text[50]; var IsHandled: Boolean)
    begin
    end;
}

