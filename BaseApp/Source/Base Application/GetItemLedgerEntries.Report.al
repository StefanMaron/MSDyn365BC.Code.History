report 594 "Get Item Ledger Entries"
{
    Caption = 'Get Item Ledger Entries';
    Permissions = TableData "General Posting Setup" = imd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = SORTING("Intrastat Code") WHERE("Intrastat Code" = FILTER(<> ''));
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemTableView = SORTING("Country/Region Code", "Entry Type", "Posting Date") WHERE("Entry Type" = FILTER(Purchase | Sale | Transfer), Correction = CONST(false), "Intrastat Transaction" = CONST(true));

                trigger OnAfterGetRecord()
                var
                    ItemLedgEntry: Record "Item Ledger Entry";
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst then
                        CurrReport.Skip;

                    if "Entry Type" in ["Entry Type"::Sale, "Entry Type"::Purchase] then begin
                        ItemLedgEntry.Reset;
                        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type");
                        ItemLedgEntry.SetRange("Document No.", "Document No.");
                        ItemLedgEntry.SetRange("Item No.", "Item No.");
                        ItemLedgEntry.SetRange(Correction, true);
                        if "Document Type" in ["Document Type"::"Sales Shipment", "Document Type"::"Sales Return Receipt",
                                               "Document Type"::"Purchase Receipt", "Document Type"::"Purchase Return Shipment"]
                        then begin
                            ItemLedgEntry.SetRange("Document Type", "Document Type");
                            if ItemLedgEntry.FindSet then
                                repeat
                                    if IsItemLedgerEntryCorrected(ItemLedgEntry, "Entry No.") then
                                        CurrReport.Skip;
                                until ItemLedgEntry.Next = 0;
                        end;
                    end;

                    if not HasCrossedBorder("Item Ledger Entry") or IsService("Item Ledger Entry") or IsServiceItem("Item No.") then
                        CurrReport.Skip;

                    CalculateTotals("Item Ledger Entry");

                    if (TotalAmt = 0) and SkipZeroAmounts then
                        CurrReport.Skip;

                    InsertItemJnlLine;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartDate, EndDate);

                    if ("Country/Region".Code = CompanyInfo."Country/Region Code") or
                       ((CompanyInfo."Country/Region Code" = '') and not ShowBlank)
                    then begin
                        ShowBlank := true;
                        SetFilter("Country/Region Code", '%1|%2', "Country/Region".Code, '');
                    end else
                        SetRange("Country/Region Code", "Country/Region".Code);
                    SetRange("Perform. Country/Region Code", IntrastatJnlBatch."Perform. Country/Region Code"); // NAVCZ

                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Item Entry");

                    with ValueEntry do begin
                        SetCurrentKey("Item Ledger Entry No.");
                        SetRange("Entry Type", "Entry Type"::"Direct Cost");
                        SetFilter(
                          "Item Ledger Entry Type", '%1|%2|%3',
                          "Item Ledger Entry Type"::Sale,
                          "Item Ledger Entry Type"::Purchase,
                          "Item Ledger Entry Type"::Transfer);
                    end;
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Country/Region Code" = FIELD(Code);
                DataItemTableView = SORTING(Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date") WHERE(Type = CONST(Item), "Source Code" = FILTER(<> ''), "Entry Type" = CONST(Usage));

                trigger OnAfterGetRecord()
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst or (CompanyInfo."Country/Region Code" = "Country/Region Code") then
                        CurrReport.Skip;

                    if IsJobService("Job Ledger Entry") then
                        CurrReport.Skip;

                    InsertJobLedgerLine;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartDate, EndDate);
                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Job Entry");
                end;
            }
        }
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = SORTING("Entry No.");

            trigger OnAfterGetRecord()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if ShowItemCharges then begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Item Ledger Entry No.");
                    if IntrastatJnlLine2.FindFirst then
                        CurrReport.Skip;

                    if "Item Ledger Entry".Get("Item Ledger Entry No.")
                    then begin
                        if "Item Ledger Entry"."Posting Date" in [StartDate .. EndDate] then
                            CurrReport.Skip;
                        if "Country/Region".Get("Item Ledger Entry"."Country/Region Code") then
                            if "Country/Region"."Intrastat Code" = '' then
                                CurrReport.Skip;
                        // NAVCZ
                        if "Item Ledger Entry".Correction or
                           not "Item Ledger Entry"."Intrastat Transaction" or
                           not ("Item Ledger Entry"."Entry Type" in
                                ["Item Ledger Entry"."Entry Type"::Purchase,
                                 "Item Ledger Entry"."Entry Type"::Sale,
                                 "Item Ledger Entry"."Entry Type"::Transfer])
                        then
                            CurrReport.Skip;
                        if "Item Ledger Entry"."Entry Type" in
                           ["Item Ledger Entry"."Entry Type"::Sale,
                            "Item Ledger Entry"."Entry Type"::Purchase]
                        then begin
                            ItemLedgEntry.Reset;
                            ItemLedgEntry.SetCurrentKey("Document No.", "Document Type");
                            ItemLedgEntry.SetRange("Document No.", "Item Ledger Entry"."Document No.");
                            ItemLedgEntry.SetRange("Item No.", "Item Ledger Entry"."Item No.");
                            ItemLedgEntry.SetRange(Correction, true);
                            if "Item Ledger Entry"."Document Type" in
                               ["Item Ledger Entry"."Document Type"::"Sales Shipment",
                                "Item Ledger Entry"."Document Type"::"Sales Return Receipt",
                                "Item Ledger Entry"."Document Type"::"Purchase Receipt",
                                "Item Ledger Entry"."Document Type"::"Purchase Return Shipment"]
                            then begin
                                ItemLedgEntry.SetRange("Document Type", "Item Ledger Entry"."Document Type");
                                if ItemLedgEntry.FindSet then
                                    repeat
                                        if IsItemLedgerEntryCorrected(ItemLedgEntry, "Item Ledger Entry"."Entry No.") then
                                            CurrReport.Skip;
                                    until ItemLedgEntry.Next = 0;
                            end;
                        end;
                        // NAVCZ
                        if not HasCrossedBorder("Item Ledger Entry") or IsService("Item Ledger Entry") then // NAVCZ
                            CurrReport.Skip;
                        CalculateTotals2("Value Entry");  // NAVCZ
                        InsertValueEntryLine;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                // NAVCZ
                if not StatReportingSetup."Include other Period add.Costs" then
                    CurrReport.Break;
                // NAVCZ

                SetRange("Posting Date", StartDate, EndDate);
                SetFilter("Item Charge No.", '<> %1', '');
                "Item Ledger Entry".SetRange("Posting Date");

                IntrastatJnlLine2.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
                IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Item Entry");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(IndirectCostPctReq; IndirectCostPctReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cost Regulation %';
                        DecimalPlaces = 0 : 5;
                        Enabled = false;
                        ToolTip = 'Specifies the cost regulation percentage to cover freight and insurance. The statistical value of every line in the journal is increased by this percentage.';
                        Visible = false;
                    }
                }
                group(Additional)
                {
                    Caption = 'Additional';
                    field(SkipRecalcForZeros; SkipRecalcZeroAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Recalculation for Zero Amounts';
                        ToolTip = 'Specifies that lines without amounts will not be recalculated during the batch job.';
                    }
                    field(SkipZeros; SkipZeroAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Zero Amounts';
                        ToolTip = 'Specifies that item ledger entries without amounts will not be included in the batch job.';
                    }
                    field(ShowingItemCharges; ShowItemCharges)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Item Charge Entries';
                        ToolTip = 'Specifies if you want to show direct costs that your company has assigned and posted as item charges.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            IntraJnlTemplate.Get(IntrastatJnlLine."Journal Template Name");
            IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
            StartDate := IntrastatJnlBatch.GetStatisticsStartDate;
            EndDate := CalcDate('<+1M-1D>', StartDate);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.FindFirst;
    end;

    trigger OnPreReport()
    var
        RegCountry: Record "Registration Country/Region";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlLine.LockTable;
        if IntrastatJnlLine.FindLast then;

        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, false);

        GetGLSetup();
        if IntrastatJnlBatch."Amounts in Add. Currency" then begin
            GLSetup.TestField("Additional Reporting Currency");
            AddCurrencyFactor :=
              CurrExchRate.ExchangeRate(EndDate, GLSetup."Additional Reporting Currency");
        end;

        // NAVCZ
        GetStatReportingSetup;
        StatReportingSetup.TestField("Ignore Intrastat Ex.Rate From");
        case StatReportingSetup."Intrastat Rounding Type" of
            StatReportingSetup."Intrastat Rounding Type"::Nearest:
                Direction := '=';
            StatReportingSetup."Intrastat Rounding Type"::Up:
                Direction := '>';
            StatReportingSetup."Intrastat Rounding Type"::Down:
                Direction := '<';
        end;
        IndirectCostPctReq := StatReportingSetup."Cost Regulation %";
        IntrExchRateMandatory := StatReportingSetup."Intrastat Exch.Rate Mandatory";
        if IntrastatJnlBatch."Perform. Country/Region Code" <> '' then
            if RegCountry.Get(RegCountry."Account Type"::"Company Information", '', IntrastatJnlBatch."Perform. Country/Region Code") then
                IntrExchRateMandatory := RegCountry."Intrastat Exch.Rate Mandatory";
        // NAVCZ
    end;

    var
        Text000: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        CompanyInfo: Record "Company Information";
        Currency: Record Currency;
        StatReportingSetup: Record "Stat. Reporting Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        StartDate: Date;
        EndDate: Date;
        IndirectCostPctReq: Decimal;
        TotalAmt: Decimal;
        AddCurrencyFactor: Decimal;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        GLSetupRead: Boolean;
        StatReportingSetupRead: Boolean;
        ShowBlank: Boolean;
        SkipRecalcZeroAmounts: Boolean;
        SkipZeroAmounts: Boolean;
        Direction: Text[1];
        IntrExchRateMandatory: Boolean;
        TotalICAmt: array[2] of Decimal;
        TotalICCostAmt: array[2] of Decimal;
        TotalICAmtExpected: array[2] of Decimal;
        TotalICCostAmtExpected: array[2] of Decimal;
        TotalCostAmt2: Decimal;
        ShowItemCharges: Boolean;

    procedure SetIntrastatJnlLine(NewIntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine := NewIntrastatJnlLine;
    end;

    local procedure InsertItemJnlLine()
    var
        TempSalesHeader: Record "Sales Header" temporary;
        DocumentCurrencyFactor: Decimal;
        IntrastatCurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        GetGLSetup();
        // NAVCZ
        GetDocumentFromItemLedgEntry("Item Ledger Entry", TempSalesHeader);
        DocumentCurrencyFactor := TempSalesHeader."Currency Factor";
        IntrastatCurrencyFactor := CalculateExchangeRateFromDocument(TempSalesHeader);
        // NAVCZ

        with IntrastatJnlLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Date := "Item Ledger Entry"."Posting Date";
            "Country/Region Code" := "Item Ledger Entry"."Country/Region Code";
            "Transaction Type" := "Item Ledger Entry"."Transaction Type";
            "Transport Method" := "Item Ledger Entry"."Transport Method";
            "Source Entry No." := "Item Ledger Entry"."Entry No.";
            Quantity := "Item Ledger Entry".Quantity;
            "Document No." := "Item Ledger Entry"."Document No.";
            Validate("Item No.", "Item Ledger Entry"."Item No."); // NAVCZ
            "Entry/Exit Point" := "Item Ledger Entry"."Entry/Exit Point";
            Area := "Item Ledger Entry".Area;
            "Transaction Specification" := "Item Ledger Entry"."Transaction Specification";
            "Shpt. Method Code" := "Item Ledger Entry"."Shpt. Method Code";

            // NAVCZ
            CalcDataForItemJnlLine;
            "Source Type" := "Source Type"::"Item Entry";
            case "Item Ledger Entry"."Entry Type" of
                "Item Ledger Entry"."Entry Type"::Purchase:
                    if "Item Ledger Entry"."Physical Transfer" then begin
                        Type := Type::Shipment;
                        Amount := Round(Abs(TotalCostAmt2 + TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end else
                        if "Item Ledger Entry".Quantity > 0 then begin
                            Type := Type::Receipt;
                            Amount := Round(Abs(TotalCostAmt2 + TotalICCostAmt[1]), 1, Direction);
                            Validate(Quantity, Abs(Quantity));
                        end else begin
                            Type := Type::Receipt;
                            Amount := -Round(Abs(TotalCostAmt2 + TotalICCostAmt[1]), 1, Direction);
                            Validate(Quantity, -Abs(Quantity));
                        end;
                "Item Ledger Entry"."Entry Type"::Sale:
                    if "Item Ledger Entry"."Physical Transfer" then begin
                        Type := Type::Receipt;
                        Amount := Round(Abs(TotalAmt + TotalICAmt[1]), 1, Direction);
                        Validate(Quantity, RoundValue(Abs(Quantity)));
                    end else
                        if "Item Ledger Entry".Quantity < 0 then begin
                            Type := Type::Shipment;
                            Amount := Round(Abs(TotalAmt + TotalICAmt[1]), 1, Direction);
                            Validate(Quantity, Abs(Quantity));
                        end else begin
                            Type := Type::Shipment;
                            Amount := -Round(Abs(TotalAmt + TotalICAmt[1]), 1, Direction);
                            Validate(Quantity, -Abs(Quantity));
                        end;
                "Item Ledger Entry"."Entry Type"::Transfer:
                    if "Item Ledger Entry".Quantity < 0 then begin
                        Type := Type::Shipment;
                        Amount := Round(Abs(TotalCostAmt2 + TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end else begin
                        Type := Type::Receipt;
                        Amount := Round(Abs(TotalCostAmt2 + TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end;
            end;
            "Cost Regulation %" := IndirectCostPctReq;
            CalcStatValue;

            Amount := Round(CalculateExchangeAmount(Amount, DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);
            "Statistical Value" :=
              Round(CalculateExchangeAmount("Statistical Value", DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);
            "Indirect Cost" :=
              Round(CalculateExchangeAmount("Indirect Cost", DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);
            "Source Entry Date" := "Item Ledger Entry"."Posting Date";
            // NAVCZ

            IsHandled := false;
            OnBeforeInsertItemJnlLine(IntrastatJnlLine, "Item Ledger Entry", IsHandled);
            if not IsHandled then
                Insert();
        end;
    end;

    local procedure InsertJobLedgerLine()
    var
        IsCorrection: Boolean;
        IsHandled: Boolean;
    begin
        with IntrastatJnlLine do begin
            Init;
            "Line No." := "Line No." + 10000;

            Date := "Job Ledger Entry"."Posting Date";
            "Country/Region Code" := "Job Ledger Entry"."Country/Region Code";
            "Transaction Type" := "Job Ledger Entry"."Transaction Type";
            "Transport Method" := "Job Ledger Entry"."Transport Method";
            Quantity := "Job Ledger Entry"."Quantity (Base)";

            // NAVCZ
            CalcDataForJobJnlLine;
            IsCorrection := "Job Ledger Entry".Correction;
            if (Quantity > 0) xor IsCorrection then
                Type := Type::Shipment
            else
                Type := Type::Receipt;
            if IntrastatJnlBatch."Amounts in Add. Currency" then
                Amount := "Job Ledger Entry"."Add.-Currency Line Amount"
            else
                Amount := "Job Ledger Entry"."Line Amount (LCY)";
            "Source Entry No." := "Job Ledger Entry"."Entry No.";
            "Document No." := "Job Ledger Entry"."Document No.";
            "Item No." := "Job Ledger Entry"."No.";
            "Entry/Exit Point" := "Job Ledger Entry"."Entry/Exit Point";
            Area := "Job Ledger Entry".Area;
            "Transaction Specification" := "Job Ledger Entry"."Transaction Specification";
            "Shpt. Method Code" := "Job Ledger Entry"."Shpt. Method Code";

            if IntrastatJnlBatch."Amounts in Add. Currency" then
                Amount := Round(Abs(Amount), Currency."Amount Rounding Precision", Direction) // NAVCZ
            else
                Amount := Round(Abs(Amount), GLSetup."Amount Rounding Precision", Direction); // NAVCZ
            Validate("Item No.");
            "Source Type" := "Source Type"::"Job Entry";
            Validate(Quantity, Round(Abs(Quantity), 0.00001));

            Validate("Cost Regulation %", IndirectCostPctReq);

            // NAVCZ
            if IsCorrection then begin
                Quantity := -Quantity;
                Amount := -Amount;
                "Statistical Value" := -"Statistical Value";
            end;
            "Source Entry Date" := "Job Ledger Entry"."Posting Date";
            // NAVCZ

            IsHandled := false;
            OnBeforeInsertJobLedgerLine(IntrastatJnlLine, "Job Ledger Entry", IsHandled);
            if not IsHandled then
                Insert();
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get;
            if GLSetup."Additional Reporting Currency" <> '' then
                Currency.Get(GLSetup."Additional Reporting Currency");
        end;
        GLSetupRead := true;
    end;

    local procedure GetStatReportingSetup()
    begin
        // NAVCZ
        if not StatReportingSetupRead then
            StatReportingSetup.Get;
        StatReportingSetupRead := true;
    end;

    local procedure CalculateAverageCost(var AverageCost: Decimal; var AverageCostACY: Decimal): Boolean
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        AverageQty: Decimal;
    begin
        with ItemLedgEntry do begin
            SetCurrentKey("Item No.", "Entry Type");
            SetRange("Item No.", "Item Ledger Entry"."Item No.");
            SetRange("Entry Type", "Item Ledger Entry"."Entry Type");
            CalcSums(Quantity);
        end;

        with ValueEntry do begin
            SetCurrentKey("Item No.", "Posting Date", "Item Ledger Entry Type");
            SetRange("Item No.", "Item Ledger Entry"."Item No.");
            SetRange("Item Ledger Entry Type", "Item Ledger Entry"."Entry Type");
            CalcSums(
              "Cost Amount (Actual)",
              "Cost Amount (Expected)");
            "Cost Amount (Actual) (ACY)" :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                EndDate, GLSetup."Additional Reporting Currency", "Cost Amount (Actual)", AddCurrencyFactor);
            "Cost Amount (Expected) (ACY)" :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                EndDate, GLSetup."Additional Reporting Currency", "Cost Amount (Expected)", AddCurrencyFactor);
            AverageQty := ItemLedgEntry.Quantity;
            AverageCost := "Cost Amount (Actual)" + "Cost Amount (Expected)";
            AverageCostACY := "Cost Amount (Actual) (ACY)" + "Cost Amount (Expected) (ACY)";
        end;
        if AverageQty <> 0 then begin
            AverageCost := AverageCost / AverageQty;
            AverageCostACY := AverageCostACY / AverageQty;
            if (AverageCost < 0) or (AverageCostACY < 0) then begin
                AverageCost := 0;
                AverageCostACY := 0;
            end;
        end else begin
            AverageCost := 0;
            AverageCostACY := 0;
        end;

        exit(AverageQty >= 0);
    end;

    local procedure CountryOfOrigin(CountryRegionCode: Code[20]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if ("Item Ledger Entry"."Country/Region Code" in [CompanyInfo."Country/Region Code", '']) =
           (CountryRegionCode in [CompanyInfo."Country/Region Code", ''])
        then
            exit(false);

        if CountryRegionCode <> '' then begin
            CountryRegion.Get(CountryRegionCode);
            if CountryRegion."Intrastat Code" = '' then
                exit(false);
        end;
        exit(true);
    end;

    local procedure HasCrossedBorder(ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        Location: Record Location;
        Include: Boolean;
    begin
        with ItemLedgEntry do
            case true of
                "Drop Shipment":
                    begin
                        if ("Country/Region Code" = CompanyInfo."Country/Region Code") or
                           ("Country/Region Code" = '')
                        then
                            exit(false);
                        if "Applies-to Entry" = 0 then begin
                            ItemLedgEntry2.SetCurrentKey("Item No.", "Posting Date");
                            ItemLedgEntry2.SetRange("Item No.", "Item No.");
                            ItemLedgEntry2.SetRange("Posting Date", "Posting Date");
                            ItemLedgEntry2.SetRange("Applies-to Entry", "Entry No.");
                            ItemLedgEntry2.FindFirst;
                        end else
                            ItemLedgEntry2.Get("Applies-to Entry");
                        if (ItemLedgEntry2."Country/Region Code" <> CompanyInfo."Country/Region Code") and
                           (ItemLedgEntry2."Country/Region Code" <> '')
                        then
                            exit(false);
                    end;
                "Entry Type" = "Entry Type"::Transfer:
                    begin
                        if ("Country/Region Code" = CompanyInfo."Country/Region Code") or
                           ("Country/Region Code" = '')
                        then
                            exit(false);
                        if ("Order Type" <> "Order Type"::Transfer) or ("Order No." = '') then begin
                            Location.Get("Location Code");
                            if (Location."Country/Region Code" <> '') and
                               (Location."Country/Region Code" <> CompanyInfo."Country/Region Code")
                            then
                                exit(false);
                        end else begin
                            ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.");
                            ItemLedgEntry2.SetRange("Order Type", "Order Type"::Transfer);
                            ItemLedgEntry2.SetRange("Order No.", "Order No.");
                            ItemLedgEntry2.SetFilter("Country/Region Code", '%1 | %2', '', CompanyInfo."Country/Region Code");
                            ItemLedgEntry2.SetFilter("Location Code", '<>%1', '');
                            if ItemLedgEntry2.FindSet then
                                repeat
                                    Location.Get(ItemLedgEntry2."Location Code");
                                    if Location."Use As In-Transit" then
                                        Include := true;
                                until Include or (ItemLedgEntry2.Next = 0);
                            if not Include then
                                exit(false);
                        end;
                    end;
                "Location Code" <> '':
                    begin
                        Location.Get("Location Code");
                        if not CountryOfOrigin(Location."Country/Region Code") then
                            exit(false);
                    end;
                else begin
                        if "Entry Type" = "Entry Type"::Purchase then
                            if not CountryOfOrigin(CompanyInfo."Ship-to Country/Region Code") then
                                exit(false);
                        if "Entry Type" = "Entry Type"::Sale then
                            if not CountryOfOrigin(CompanyInfo."Country/Region Code") then
                                exit(false);
                    end;
            end;
        exit(true);
    end;

    local procedure InsertValueEntryLine()
    var
        TempSalesHeader: Record "Sales Header" temporary;
        DocumentCurrencyFactor: Decimal;
        IntrastatCurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        GetGLSetup();
        GetDocumentFromValueEntry("Value Entry", TempSalesHeader);
        DocumentCurrencyFactor := TempSalesHeader."Currency Factor";
        IntrastatCurrencyFactor := CalculateExchangeRateFromDocument(TempSalesHeader);
        // NAVCZ

        with IntrastatJnlLine do begin
            Init;
            "Line No." := "Line No." + 10000;
            Date := "Value Entry"."Posting Date";
            "Country/Region Code" := "Item Ledger Entry"."Country/Region Code";
            "Transaction Type" := "Item Ledger Entry"."Transaction Type";
            "Transport Method" := "Item Ledger Entry"."Transport Method";
            "Source Entry No." := "Item Ledger Entry"."Entry No.";
            Quantity := "Item Ledger Entry".Quantity;
            "Document No." := "Value Entry"."Document No.";
            Validate("Item No.", "Item Ledger Entry"."Item No."); // NAVCZ
            "Entry/Exit Point" := "Item Ledger Entry"."Entry/Exit Point";
            Area := "Item Ledger Entry".Area;
            "Transaction Specification" := "Item Ledger Entry"."Transaction Specification";
            // NAVCZ
            CalcDataForItemJnlLine;
            "Source Type" := "Source Type"::"Item Entry";
            case "Item Ledger Entry"."Entry Type" of
                "Item Ledger Entry"."Entry Type"::Purchase:
                    if "Item Ledger Entry"."Physical Transfer" then begin
                        Type := Type::Shipment;
                        Amount := Round(Abs(TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end else
                        if "Item Ledger Entry".Quantity > 0 then begin
                            Type := Type::Receipt;
                            Amount := Round(Abs(TotalICCostAmt[1]), 1, Direction);
                            Validate(Quantity, Abs(Quantity));
                        end else begin
                            Type := Type::Receipt;
                            Amount := -Round(Abs(TotalICCostAmt[1]), 1, Direction);
                            Validate(Quantity, -Abs(Quantity));
                        end;
                "Item Ledger Entry"."Entry Type"::Sale:
                    if "Item Ledger Entry"."Physical Transfer" then begin
                        Type := Type::Receipt;
                        Amount := Round(Abs(TotalAmt + TotalICAmt[1]), 1, Direction);
                        Validate(Quantity, RoundValue(Abs(Quantity)));
                    end else
                        if "Item Ledger Entry".Quantity < 0 then begin
                            Type := Type::Shipment;
                            Amount := Round(Abs(TotalICAmt[1]), 1, Direction);
                            Validate(Quantity, Abs(Quantity));
                        end else begin
                            Type := Type::Shipment;
                            Amount := -Round(Abs(TotalICAmt[1]), 1, Direction);
                            Validate(Quantity, -Abs(Quantity));
                        end;
                "Item Ledger Entry"."Entry Type"::Transfer:
                    if "Item Ledger Entry".Quantity < 0 then begin
                        Type := Type::Shipment;
                        Amount := Round(Abs(TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end else begin
                        Type := Type::Receipt;
                        Amount := Round(Abs(TotalICCostAmt[1]), 1, Direction);
                        Validate(Quantity, Abs(Quantity));
                    end;
            end;
            "Cost Regulation %" := IndirectCostPctReq;
            CalcStatValue;

            Amount := Round(CalculateExchangeAmount(Amount, DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);
            "Statistical Value" :=
              Round(CalculateExchangeAmount("Statistical Value", DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);
            "Indirect Cost" :=
              Round(CalculateExchangeAmount("Indirect Cost", DocumentCurrencyFactor, IntrastatCurrencyFactor), 1, Direction);

            "Additional Costs" := true;
            "Source Entry Date" := "Item Ledger Entry"."Posting Date";
            // NAVCZ

            IsHandled := false;
            OnBeforeInsertValueEntryLine(IntrastatJnlLine, "Item Ledger Entry", IsHandled);
            if not IsHandled then
                Insert();
        end;
    end;

    local procedure IsService(ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvLine: Record "Sales Invoice Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceInvLine: Record "Service Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with ItemLedgEntry do begin
            case true of
                "Document Type" = "Document Type"::"Sales Shipment":
                    if SalesShipmentLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(SalesShipmentLine."VAT Bus. Posting Group", SalesShipmentLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Sales Return Receipt":
                    if ReturnReceiptLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(ReturnReceiptLine."VAT Bus. Posting Group", ReturnReceiptLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Sales Invoice":
                    if SalesInvLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Sales Credit Memo":
                    if SalesCrMemoLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Purchase Receipt":
                    if PurchRcptLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(PurchRcptLine."VAT Bus. Posting Group", PurchRcptLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Purchase Return Shipment":
                    if ReturnShipmentLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(ReturnShipmentLine."VAT Bus. Posting Group", ReturnShipmentLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Purchase Invoice":
                    if PurchInvLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Purchase Credit Memo":
                    if PurchCrMemoLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(PurchCrMemoLine."VAT Bus. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Service Shipment":
                    if ServiceShipmentLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(ServiceShipmentLine."VAT Bus. Posting Group", ServiceShipmentLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Service Credit Memo":
                    if ServiceCrMemoLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(ServiceCrMemoLine."VAT Bus. Posting Group", ServiceCrMemoLine."VAT Prod. Posting Group") then;
                "Document Type" = "Document Type"::"Service Invoice":
                    if ServiceInvLine.Get("Document No.", "Document Line No.") then
                        if VATPostingSetup.Get(ServiceInvLine."VAT Bus. Posting Group", ServiceInvLine."VAT Prod. Posting Group") then;
            end;
            exit(VATPostingSetup."Intrastat Service"); // NAVCZ
        end;
    end;

    local procedure CalculateTotals(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TotalInvoicedQty: Decimal;
        TotalCostAmt: Decimal;
        TotalAmtExpected: Decimal;
        TotalCostAmtExpected: Decimal;
    begin
        with ItemLedgerEntry do begin
            TotalInvoicedQty := 0;
            TotalAmt := 0;
            TotalAmtExpected := 0;
            TotalCostAmt := 0;
            TotalCostAmtExpected := 0;
            // NAVCZ
            Clear(TotalICAmt);
            Clear(TotalICCostAmt);
            TotalCostAmt2 := 0;
            // NAVCZ

            ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
            ValueEntry.SetRange("Posting Date", StartDate, EndDate); // NAVCZ
            if ValueEntry.Find('-') then
                repeat
                    // NAVCZ
                    if ValueEntry."Item Charge No." = '' // Calculate item amount
                                                         // NAVCZ
                    then begin
                        TotalInvoicedQty := TotalInvoicedQty + ValueEntry."Invoiced Quantity";
                        if not IntrastatJnlBatch."Amounts in Add. Currency" then begin
                            TotalAmt := TotalAmt + ValueEntry."Sales Amount (Actual)";
                            TotalCostAmt := TotalCostAmt + ValueEntry."Cost Amount (Actual)";
                            TotalAmtExpected := TotalAmtExpected + ValueEntry."Sales Amount (Expected)";
                            TotalCostAmtExpected := TotalCostAmtExpected + ValueEntry."Cost Amount (Expected)";
                        end else begin
                            TotalCostAmt := TotalCostAmt + ValueEntry."Cost Amount (Actual) (ACY)";
                            TotalCostAmtExpected := TotalCostAmtExpected + ValueEntry."Cost Amount (Expected) (ACY)";
                            if ValueEntry."Cost per Unit" <> 0 then begin
                                TotalAmt :=
                                  TotalAmt +
                                  ValueEntry."Sales Amount (Actual)" * ValueEntry."Cost per Unit (ACY)" / ValueEntry."Cost per Unit";
                                TotalAmtExpected :=
                                  TotalAmtExpected +
                                  ValueEntry."Sales Amount (Expected)" * ValueEntry."Cost per Unit (ACY)" / ValueEntry."Cost per Unit";
                            end else begin
                                TotalAmt :=
                                  TotalAmt +
                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                                    ValueEntry."Sales Amount (Actual)", AddCurrencyFactor);
                                TotalAmtExpected :=
                                  TotalAmtExpected +
                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                                    ValueEntry."Sales Amount (Expected)", AddCurrencyFactor);
                            end;
                        end;
                        // NAVCZ
                    end else begin // Item charge processing
                        if ValueEntry."Incl. in Intrastat Amount" then
                            CalcTotalsForItemCharge(TotalICAmt[1], TotalICCostAmt[1], TotalICAmtExpected[1], TotalICCostAmtExpected[1]);
                        if ValueEntry."Incl. in Intrastat Stat. Value" then
                            CalcTotalsForItemCharge(TotalICAmt[2], TotalICCostAmt[2], TotalICAmtExpected[2], TotalICCostAmtExpected[2]);
                    end;
                    // NAVCZ
                until ValueEntry.Next = 0;

            if Quantity <> TotalInvoicedQty then begin
                TotalAmt := TotalAmt + TotalAmtExpected;
                TotalCostAmt := TotalCostAmt + TotalCostAmtExpected;
                // NAVCZ
                TotalICAmt[1] := TotalICAmtExpected[1];
                TotalICCostAmt[1] := TotalICCostAmtExpected[1];
                TotalICAmt[2] := TotalICAmtExpected[2];
                TotalICCostAmt[2] := TotalICCostAmtExpected[2];
                // NAVCZ
            end;

            OnCalculateTotalsOnAfterSumTotals(ItemLedgerEntry, IntrastatJnlBatch, TotalAmt, TotalCostAmt);

            if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::Transfer] then begin
                if TotalCostAmt = 0 then begin
                    CalculateAverageCost(AverageCost, AverageCostACY);
                    if IntrastatJnlBatch."Amounts in Add. Currency" then
                        TotalCostAmt :=
                          TotalCostAmt + Quantity * AverageCostACY
                    else
                        TotalCostAmt :=
                          TotalCostAmt + Quantity * AverageCost;
                end;
                TotalAmt := TotalCostAmt;
            end;

            if (TotalAmt = 0) and ("Entry Type" = "Entry Type"::Sale) and (not SkipRecalcZeroAmounts) then begin
                if Item."No." <> "Item No." then
                    Item.Get("Item No.");
                if IntrastatJnlBatch."Amounts in Add. Currency" then
                    Item."Unit Price" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        EndDate, GLSetup."Additional Reporting Currency",
                        Item."Unit Price", AddCurrencyFactor);
                if Item."Price Includes VAT" then begin
                    VATPostingSetup.Get(Item."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group");
                    case VATPostingSetup."VAT Calculation Type" of
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            VATPostingSetup."VAT %" := 0;
                        VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            Error(
                              Text000,
                              VATPostingSetup.FieldCaption("VAT Calculation Type"),
                              VATPostingSetup."VAT Calculation Type");
                    end;
                    TotalAmt :=
                      TotalAmt + Quantity *
                      (Item."Unit Price" / (1 + (VATPostingSetup."VAT %" / 100)));
                end else
                    TotalAmt := TotalAmt + Quantity * Item."Unit Price";
            end;
            TotalCostAmt2 := TotalCostAmt; // NAVCZ
        end;

        OnAfterCalculateTotals(ItemLedgerEntry, IntrastatJnlBatch, TotalAmt, TotalCostAmt);
    end;

    local procedure IsJobService(JobLedgEntry: Record "Job Ledger Entry"): Boolean
    var
        Job: Record Job;
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if Job.Get(JobLedgEntry."Job No.") then
            if Customer.Get(Job."Bill-to Customer No.") then;
        if Item.Get(JobLedgEntry."No.") then
            if VATPostingSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
                if VATPostingSetup."Intrastat Service" then // NAVCZ
                    exit(true);
        exit(false);
    end;

    local procedure IsServiceItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        exit(Item.Get(ItemNo) and (Item.Type = Item.Type::Service));
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewIndirectCostPctReq: Decimal)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        IndirectCostPctReq := NewIndirectCostPctReq;
    end;

    [Scope('OnPrem')]
    procedure CalcTotalsForItemCharge(var TotalICAmt1: Decimal; var TotalICCostAmt1: Decimal; var TotalICAmtExpected1: Decimal; var TotalICCostAmtExpected1: Decimal)
    begin
        // NAVCZ
        if not IntrastatJnlBatch."Amounts in Add. Currency" then begin
            TotalICAmt1 := TotalICAmt1 + ValueEntry."Sales Amount (Actual)";
            TotalICCostAmt1 := TotalICCostAmt1 + ValueEntry."Cost Amount (Actual)";
            TotalICAmtExpected1 := TotalICAmtExpected1 + ValueEntry."Sales Amount (Expected)";
            TotalICCostAmtExpected1 := TotalICCostAmtExpected1 + ValueEntry."Cost Amount (Expected)";
        end else begin
            TotalICCostAmt1 := TotalICCostAmt1 + ValueEntry."Cost Amount (Actual) (ACY)";
            TotalICCostAmtExpected1 := TotalICCostAmtExpected1 + ValueEntry."Cost Amount (Expected) (ACY)";
            if ValueEntry."Cost per Unit" <> 0 then begin
                TotalICAmt1 += ValueEntry."Sales Amount (Actual)" * ValueEntry."Cost per Unit (ACY)" / ValueEntry."Cost per Unit";
                TotalICAmtExpected1 += ValueEntry."Sales Amount (Expected)" * ValueEntry."Cost per Unit (ACY)" / ValueEntry."Cost per Unit";
            end else begin
                TotalICAmt1 += CurrExchRate.ExchangeAmtLCYToFCY(
                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                    ValueEntry."Sales Amount (Actual)", AddCurrencyFactor);
                TotalICAmtExpected1 += CurrExchRate.ExchangeAmtLCYToFCY(
                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                    ValueEntry."Sales Amount (Expected)", AddCurrencyFactor);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcDataForItemJnlLine()
    begin
        // NAVCZ
        with IntrastatJnlLine do begin
            "Shpt. Method Code" := "Item Ledger Entry"."Shpt. Method Code";
            Item.Get("Item Ledger Entry"."Item No.");
            Name := Item.Description;
            if (StatReportingSetup."Get Net Weight From" = StatReportingSetup."Get Net Weight From"::"Item Card") and
               (Item."Net Weight" <> 0)
            then
                Validate("Net Weight", Item."Net Weight")
            else
                Validate("Net Weight", "Item Ledger Entry"."Net Weight");
            if (StatReportingSetup."Get Tariff No. From" = StatReportingSetup."Get Tariff No. From"::"Item Card") and
               (Item."Tariff No." <> '')
            then begin
                Validate("Tariff No.", Item."Tariff No.");
                "Statistic Indication" := Item."Statistic Indication";
            end else begin
                Validate("Tariff No.", "Item Ledger Entry"."Tariff No.");
                "Statistic Indication" := "Item Ledger Entry"."Statistic Indication";
            end;
            if (StatReportingSetup."Get Country/Region of Origin" = StatReportingSetup."Get Country/Region of Origin"::"Item Card") and
               (Item."Country/Region of Origin Code" <> '')
            then
                Validate("Country/Region of Origin Code", Item."Country/Region of Origin Code")
            else
                Validate("Country/Region of Origin Code", "Item Ledger Entry"."Country/Region of Origin Code");

            "Base Unit of Measure" := Item."Base Unit of Measure";
            if "Supplementary Units" then begin
                "Supplem. UoM Quantity" := Quantity /
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                "Supplem. UoM Net Weight" := "Net Weight" *
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
            end;
            TestField(Quantity);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcDataForJobJnlLine()
    begin
        // NAVCZ
        with IntrastatJnlLine do begin
            "Shpt. Method Code" := "Job Ledger Entry"."Shipment Method Code";
            Item.Get("Job Ledger Entry"."No.");
            Name := Item.Description;
            if (StatReportingSetup."Get Net Weight From" = StatReportingSetup."Get Net Weight From"::"Item Card") and
               (Item."Net Weight" <> 0)
            then
                Validate("Net Weight", Item."Net Weight")
            else
                Validate("Net Weight", "Job Ledger Entry"."Net Weight");
            if (StatReportingSetup."Get Tariff No. From" = StatReportingSetup."Get Tariff No. From"::"Item Card") and
               (Item."Tariff No." <> '')
            then begin
                Validate("Tariff No.", Item."Tariff No.");
                "Statistic Indication" := Item."Statistic Indication";
            end else begin
                Validate("Tariff No.", "Job Ledger Entry"."Tariff No.");
                "Statistic Indication" := "Job Ledger Entry"."Statistic Indication";
            end;
            if (StatReportingSetup."Get Country/Region of Origin" = StatReportingSetup."Get Country/Region of Origin"::"Item Card") and
               (Item."Country/Region of Origin Code" <> '')
            then
                Validate("Country/Region of Origin Code", Item."Country/Region of Origin Code")
            else
                Validate("Country/Region of Origin Code", "Job Ledger Entry"."Country/Region of Origin Code");

            "Base Unit of Measure" := Item."Base Unit of Measure";
            if "Supplementary Units" then begin
                "Supplem. UoM Quantity" := Quantity /
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                "Supplem. UoM Net Weight" := "Net Weight" *
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
            end;
            TestField(Quantity);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcStatValue()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // NAVCZ
        with IntrastatJnlLine do begin
            case StatReportingSetup."Stat. Value Reporting" of
                StatReportingSetup."Stat. Value Reporting"::None:
                    begin
                        "Cost Regulation %" := 0;
                        "Indirect Cost" := 0;
                    end;
                StatReportingSetup."Stat. Value Reporting"::Percentage:
                    "Indirect Cost" := Round(Amount * "Cost Regulation %" / 100, 1, Direction);
                StatReportingSetup."Stat. Value Reporting"::"Shipment Method":
                    begin
                        TestField("Shpt. Method Code");
                        ShipmentMethod.Get("Shpt. Method Code");
                        if ShipmentMethod."Incl. Item Charges (Stat.Val.)" then begin
                            "Cost Regulation %" := 0;
                            if Type = Type::Shipment then
                                "Indirect Cost" := TotalICAmt[2];
                            if Type = Type::Receipt then
                                "Indirect Cost" := TotalICCostAmt[2];
                        end else begin
                            "Cost Regulation %" := ShipmentMethod."Adjustment %";
                            "Indirect Cost" := Round(Amount * "Cost Regulation %" / 100, 1, Direction);
                        end;
                    end;
            end;
            "Statistical Value" := Round(Abs(Amount) + "Indirect Cost", 1, Direction);
        end;
    end;

    local procedure GetDocument(DocumentType: Option " ","Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo","Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo","Transfer Shipment","Transfer Receipt","Service Shipment","Service Invoice","Service Credit Memo","Posted Assembly"; DocumentNo: Code[20]; var TempSalesHeader: Record "Sales Header" temporary): Boolean
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // NAVCZ
        Clear(TempSalesHeader);

        case DocumentType of
            DocumentType::"Sales Shipment":
                if SalesShptHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := SalesShptHeader."Posting Date";
                    TempSalesHeader."Currency Code" := SalesShptHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := SalesShptHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := SalesShptHeader."Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := SalesShptHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Sales Invoice":
                if SalesInvoiceHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := SalesInvoiceHeader."Posting Date";
                    TempSalesHeader."Currency Code" := SalesInvoiceHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := SalesInvoiceHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := SalesInvoiceHeader."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := SalesInvoiceHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := SalesCrMemoHeader."Posting Date";
                    TempSalesHeader."Currency Code" := SalesCrMemoHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := SalesCrMemoHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := SalesCrMemoHeader."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := SalesCrMemoHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Sales Return Receipt":
                if ReturnRcptHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := ReturnRcptHeader."Posting Date";
                    TempSalesHeader."Currency Code" := ReturnRcptHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := ReturnRcptHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := ReturnRcptHeader."Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := ReturnRcptHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Service Shipment":
                if ServiceShptHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := ServiceShptHeader."Posting Date";
                    TempSalesHeader."Currency Code" := ServiceShptHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := ServiceShptHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := ServiceShptHeader."Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := ServiceShptHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Service Invoice":
                if ServiceInvHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := ServiceInvHeader."Posting Date";
                    TempSalesHeader."Currency Code" := ServiceInvHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := ServiceInvHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := ServiceInvHeader."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := ServiceInvHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := ServiceCrMemoHeader."Posting Date";
                    TempSalesHeader."Currency Code" := ServiceCrMemoHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := ServiceCrMemoHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := ServiceCrMemoHeader."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := ServiceCrMemoHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Purchase Receipt":
                if PurchRcptHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := PurchRcptHeader."Posting Date";
                    TempSalesHeader."Currency Code" := PurchRcptHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := PurchRcptHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := PurchRcptHeader."Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := PurchRcptHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Purchase Invoice":
                if PurchInvHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := PurchInvHeader."Posting Date";
                    TempSalesHeader."Currency Code" := PurchInvHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := PurchInvHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := PurchInvHeader."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := PurchInvHeader."Perform. Country/Region Code";
                end;
            DocumentType::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := PurchCrMemoHdr."Posting Date";
                    TempSalesHeader."Currency Code" := PurchCrMemoHdr."Currency Code";
                    TempSalesHeader."Currency Factor" := PurchCrMemoHdr."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := PurchCrMemoHdr."VAT Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := PurchCrMemoHdr."Perform. Country/Region Code";
                end;
            DocumentType::"Purchase Return Shipment":
                if ReturnShptHeader.Get(DocumentNo) then begin
                    TempSalesHeader."Posting Date" := ReturnShptHeader."Posting Date";
                    TempSalesHeader."Currency Code" := ReturnShptHeader."Currency Code";
                    TempSalesHeader."Currency Factor" := ReturnShptHeader."Currency Factor";
                    TempSalesHeader."VAT Currency Factor" := ReturnShptHeader."Currency Factor";
                    TempSalesHeader."Perform. Country/Region Code" := ReturnShptHeader."Perform. Country/Region Code";
                end;
            else
                exit(false);
        end;

        exit(
          (TempSalesHeader."Posting Date" <> 0D) or
          (TempSalesHeader."Currency Code" <> '') or
          (TempSalesHeader."Currency Factor" <> 0) or
          (TempSalesHeader."VAT Currency Factor" <> 0) or
          (TempSalesHeader."Perform. Country/Region Code" <> ''));
    end;

    local procedure GetDocumentFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry"; var TempSalesHeader: Record "Sales Header" temporary): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        // NAVCZ
        with ItemLedgerEntry do begin
            if FindValueEntryFromItemLedgEntry(ItemLedgerEntry, ValueEntry) then
                exit(GetDocumentFromValueEntry(ValueEntry, TempSalesHeader));
            exit(GetDocument("Document Type", "Document No.", TempSalesHeader));
        end;
    end;

    local procedure GetDocumentFromValueEntry(ValueEntry: Record "Value Entry"; var TempSalesHeader: Record "Sales Header" temporary): Boolean
    begin
        // NAVCZ
        with ValueEntry do
            exit(GetDocument("Document Type", "Document No.", TempSalesHeader));
    end;

    local procedure CalculateExchangeRate(PostingDate: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]; VATCurrencyFactor: Decimal): Decimal
    var
        IntrastatCurrExchRate: Record "Intrastat Currency Exch. Rate";
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
    begin
        // NAVCZ
        if PerformCountryCode <> '' then
            exit(PerfCountryCurrExchRate.ExchangeRateIntrastat(StartDate, PostingDate, PerformCountryCode, CurrencyCode));

        if not IgnoreInstrastatExchangeRate(PostingDate) then begin
            if IntrExchRateMandatory then
                exit(1 / IntrastatCurrExchRate.xExchangeRateMandatory(StartDate, PostingDate, CurrencyCode));
            exit(1 / IntrastatCurrExchRate.ExchangeRate(PostingDate, CurrencyCode));
        end;

        if VATCurrencyFactor <> 0 then
            exit(VATCurrencyFactor);

        exit(0);
    end;

    local procedure CalculateExchangeRateFromDocument(TempSalesHeader: Record "Sales Header" temporary): Decimal
    begin
        // NAVCZ
        with TempSalesHeader do
            exit(CalculateExchangeRate(
                "Posting Date", "Perform. Country/Region Code", "Currency Code", "VAT Currency Factor"));
    end;

    local procedure CalculateExchangeAmount(Amount: Decimal; DocumentCurrencyFactor: Decimal; IntrastatCurrencyFactor: Decimal): Decimal
    begin
        // NAVCZ
        if IntrastatCurrencyFactor <> 0 then
            exit(Amount * DocumentCurrencyFactor / IntrastatCurrencyFactor);
        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure CalculateTotals2(ValueEntry2: Record "Value Entry")
    begin
        // NAVCZ
        with ValueEntry2 do begin
            Clear(TotalAmt);
            Clear(TotalICAmt);
            Clear(TotalICCostAmt);
            Clear(TotalCostAmt2);

            ValueEntry.Get("Entry No.");

            if ValueEntry."Incl. in Intrastat Amount" then
                CalcTotalsForItemCharge(TotalICAmt[1], TotalICCostAmt[1], TotalICAmtExpected[1], TotalICCostAmtExpected[1]);
            if ValueEntry."Incl. in Intrastat Stat. Value" then
                CalcTotalsForItemCharge(TotalICAmt[2], TotalICCostAmt[2], TotalICAmtExpected[2], TotalICCostAmtExpected[2]);
        end;
    end;

    local procedure IsItemLedgerEntryCorrected(ItemLedgerEntryCorrection: Record "Item Ledger Entry"; ItemLedgerEntryNo: Integer): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryCorrection."Entry No.");
        case ItemLedgerEntryCorrection."Document Type" of
            ItemLedgerEntryCorrection."Document Type"::"Sales Shipment",
          ItemLedgerEntryCorrection."Document Type"::"Purchase Return Shipment":
                ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntryNo);
            ItemLedgerEntryCorrection."Document Type"::"Purchase Receipt",
          ItemLedgerEntryCorrection."Document Type"::"Sales Return Receipt":
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntryNo);
        end;
        exit(not ItemApplicationEntry.IsEmpty);
    end;

    local procedure IgnoreInstrastatExchangeRate(PostingDate: Date): Boolean
    begin
        // NAVCZ
        GetStatReportingSetup;
        exit(PostingDate >= StatReportingSetup."Ignore Intrastat Ex.Rate From")
    end;

    local procedure FindValueEntryFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"): Boolean
    begin
        // NAVCZ
        if not ItemLedgerEntry."Completely Invoiced" then
            exit(false);

        ValueEntry.Reset;
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetFilter("Invoiced Quantity", '<>%1', 0);
        exit(ValueEntry.FindFirst);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotals(var ItemLedgerEntry: Record "Item Ledger Entry"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var TotalAmt: Decimal; var TotalCostAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertJobLedgerLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JobLedgerEntry: Record "Job Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntryLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterSumTotals(var ItemLedgerEntry: Record "Item Ledger Entry"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var TotalAmt: Decimal; var TotalCostAmt: Decimal)
    begin
    end;
}

