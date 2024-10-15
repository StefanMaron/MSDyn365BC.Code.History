#if not CLEAN22
// variables are moved to protected var via !106447
report 594 "Get Item Ledger Entries"
{
    Caption = 'Get Item Ledger Entries';
    Permissions = TableData "General Posting Setup" = rimd;
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = SORTING("Intrastat Code") WHERE("Intrastat Code" = FILTER(<> ''));
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemTableView = SORTING("Country/Region Code", "Entry Type", "Posting Date") WHERE("Entry Type" = FILTER(Purchase | Sale | Transfer), Correction = CONST(false));

                trigger OnAfterGetRecord()
                var
                    SalesShipmentHeader: Record "Sales Shipment Header";
                    ItemLedgEntry: Record "Item Ledger Entry";
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst() then
                        CurrReport.Skip();

                    if "Entry Type" in ["Entry Type"::Sale, "Entry Type"::Purchase] then begin
                        ItemLedgEntry.Reset();
                        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type");
                        ItemLedgEntry.SetRange("Document No.", "Document No.");
                        ItemLedgEntry.SetRange("Item No.", "Item No.");
                        ItemLedgEntry.SetRange(Correction, true);
                        if "Document Type" in ["Document Type"::"Sales Shipment", "Document Type"::"Sales Return Receipt",
                                               "Document Type"::"Purchase Receipt", "Document Type"::"Purchase Return Shipment"]
                        then begin
                            ItemLedgEntry.SetRange("Document Type", "Document Type");
                            if ItemLedgEntry.FindSet() then
                                repeat
                                    if IsItemLedgerEntryCorrected(ItemLedgEntry, "Entry No.") then
                                        CurrReport.Skip();
                                until ItemLedgEntry.Next() = 0;
                        end;
                    end;

                    if ("Entry Type" = "Entry Type"::Sale) and
                       SalesShipmentHeader.Get("Document No.") and
                       (CompanyInfo."Country/Region Code" = SalesShipmentHeader."Bill-to Country/Region Code")
                    then
                        CurrReport.Skip();

                    if not HasCrossedBorder("Item Ledger Entry") or IsService("Item Ledger Entry") or IsServiceItem("Item No.") then
                        CurrReport.Skip();

                    ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                    if ValueEntry.FindSet(false, false) then
                        repeat
                            CalculateTotals("Item Ledger Entry");

                            if (TotalAmt <> 0) or (not SkipZeroAmounts) then
                                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then
                                    InsertItemJnlLine()
                                else begin
                                    IntrastatJnlLine2.Reset();
                                    IntrastatJnlLine2.SetRange("Item No.", "Item No.");
                                    IntrastatJnlLine2.SetRange("Document No.", ValueEntry."Document No.");
                                    if not IntrastatJnlLine2.FindFirst() then
                                        InsertItemJnlLine();
                                end;
                        until ValueEntry.Next() = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if IntrastatJnlBatch."EU Service" then
                        CurrReport.Break();

                    SetRange("Last Invoice Date", StartDate, EndDate);

                    if IntrastatJnlBatch.Type = IntrastatJnlBatch.Type::Purchases then
                        SetFilter("Entry Type", '%1|%2', "Entry Type"::Purchase, "Entry Type"::Transfer)
                    else
                        SetFilter("Entry Type", '%1|%2', "Entry Type"::Sale, "Entry Type"::Transfer);

                    if not IntrastatJnlBatch."Corrective Entry" then
                        "Item Ledger Entry".SetFilter("Document Type", '<>%1&<>%2&<>%3&<>%4&<>%5',
                          "Item Ledger Entry"."Document Type"::"Sales Return Receipt", "Item Ledger Entry"."Document Type"::"Sales Credit Memo",
                          "Item Ledger Entry"."Document Type"::"Purchase Return Shipment", "Item Ledger Entry"."Document Type"::"Purchase Credit Memo",
                          "Item Ledger Entry"."Document Type"::"Service Credit Memo")
                    else
                        "Item Ledger Entry".SetFilter("Document Type", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7&<>%8',
                          "Item Ledger Entry"."Document Type"::"Sales Shipment", "Item Ledger Entry"."Document Type"::"Sales Invoice",
                          "Item Ledger Entry"."Document Type"::"Purchase Receipt", "Item Ledger Entry"."Document Type"::"Purchase Invoice",
                          "Item Ledger Entry"."Document Type"::"Transfer Shipment", "Item Ledger Entry"."Document Type"::"Transfer Receipt",
                          "Item Ledger Entry"."Document Type"::"Service Shipment", "Item Ledger Entry"."Document Type"::"Service Invoice");

                    if ("Country/Region".Code = CompanyInfo."Country/Region Code") or
                       ((CompanyInfo."Country/Region Code" = '') and not ShowBlank)
                    then begin
                        ShowBlank := true;
                        SetFilter("Country/Region Code", '%1|%2', "Country/Region".Code, '');
                    end else
                        SetRange("Country/Region Code", "Country/Region".Code);

                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Item Entry");

                    "Item Ledger Entry".SetFilter("Invoiced Quantity", '<>%1', 0);

                    with ValueEntry do begin
                        SetCurrentKey("Item Ledger Entry No.");
                        SetRange("Posting Date", StartDate, EndDate);
                        SetRange("Entry Type", "Entry Type"::"Direct Cost");
                        SetFilter("Invoiced Quantity", '<>%1', 0);
                        SetFilter(
                          "Item Ledger Entry Type", '%1|%2|%3',
                          "Item Ledger Entry Type"::Sale,
                          "Item Ledger Entry Type"::Purchase,
                          "Item Ledger Entry Type"::Transfer);
                    end;
                    OnAfterItemLedgerEntryOnPreDataItem("Item Ledger Entry");
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Country/Region Code" = FIELD(Code);
                DataItemTableView = SORTING(Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date") WHERE(Type = CONST(Item), "Source Code" = FILTER(<> ''), "Entry Type" = CONST(Usage));

                trigger OnAfterGetRecord()
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst() or (CompanyInfo."Country/Region Code" = "Country/Region Code") then
                        CurrReport.Skip();

                    if IsJobService("Job Ledger Entry") then
                        CurrReport.Skip();

                    InsertJobLedgerLine();
                end;

                trigger OnPreDataItem()
                begin
                    if IntrastatJnlBatch."EU Service" then
                        CurrReport.Break();

                    SetRange("Posting Date", StartDate, EndDate);
                    IntrastatJnlLine2.Reset();
                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Job Entry");
                end;
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemLink = "Country/Region Code" = FIELD(Code);
                DataItemTableView = SORTING(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date") WHERE("EU Service" = CONST(true), Type = FILTER(Purchase | Sale));

                trigger OnAfterGetRecord()
                var
                    VATEntry: Record "VAT Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                    TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
                    EntryNo: Integer;
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst() or ("Country/Region Code" = CompanyInfo."Country/Region Code") then
                        CurrReport.Skip();

                    if IntrastatJnlBatch."Corrective Entry" then
                        case Type of
                            Type::Sale:
                                begin
                                    EntryNo := GetCustLedgEntryNo("VAT Entry");
                                    if EntryNo = 0 then
                                        CurrReport.Skip();
                                    if EntryNo = PrevEntryNo then
                                        CurrReport.Skip();
                                    PrevEntryNo := EntryNo;
                                    CustLedgEntry.Get(EntryNo);
                                    FindAppliedCustLedgEntries(CustLedgEntry, TempCustLedgEntry);

                                    TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::Invoice);
                                    TempCustLedgEntry.SetFilter("Posting Date", '<%1', StartDate);
                                    if TempCustLedgEntry.FindSet() then
                                        repeat
                                            FilterVATEntryOnCustLedgEntry(VATEntry, TempCustLedgEntry);
                                            if VATEntry.FindSet() then
                                                repeat
                                                    InsertEUServiceLine(VATEntry);
                                                until VATEntry.Next() = 0;
                                        until TempCustLedgEntry.Next() = 0;
                                end;
                            Type::Purchase:
                                begin
                                    EntryNo := GetVendLedgEntryNo("VAT Entry");
                                    if EntryNo = 0 then
                                        CurrReport.Skip();
                                    if EntryNo = PrevEntryNo then
                                        CurrReport.Skip();
                                    PrevEntryNo := EntryNo;
                                    VendLedgEntry.Get(EntryNo);
                                    FindAppliedVendLedgEntries(VendLedgEntry, TempVendLedgEntry);

                                    TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::Invoice);
                                    TempVendLedgEntry.SetFilter("Posting Date", '<%1', StartDate);
                                    if TempVendLedgEntry.FindSet() then
                                        repeat
                                            FilterVATEntryOnVendLedgEntry(VATEntry, TempVendLedgEntry);
                                            if VATEntry.FindSet() then
                                                repeat
                                                    InsertEUServiceLine(VATEntry);
                                                until VATEntry.Next() = 0;
                                        until TempVendLedgEntry.Next() = 0;
                                end;
                        end
                    else begin
                        if "Document Type" = "Document Type"::"Credit Memo" then
                            if DocumentHasApplications("VAT Entry") then
                                CurrReport.Skip();

                        InsertEUServiceLine("VAT Entry");
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not IntrastatJnlBatch."EU Service" then
                        CurrReport.Break();

                    if IntrastatJnlBatch.Type = IntrastatJnlBatch.Type::Purchases then
                        SetRange(Type, Type::Purchase)
                    else
                        SetRange(Type, Type::Sale);
                    if IntrastatJnlBatch."Corrective Entry" then
                        SetRange("Document Type", "Document Type"::"Credit Memo")
                    else
                        SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
                    SetRange("Operation Occurred Date", StartDate, EndDate);
                    SetRange("Reverse Sales VAT", false);

                    IntrastatJnlLine2.Reset();
                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"VAT Entry")
                end;
            }
        }
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = SORTING("Entry No.");

            trigger OnAfterGetRecord()
            begin
                if ShowItemCharges then begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Item Ledger Entry No.");
                    if IntrastatJnlLine2.FindFirst() then
                        CurrReport.Skip();

                    if "Item Ledger Entry".Get("Item Ledger Entry No.")
                    then begin
                        if ("Item Ledger Entry"."Posting Date" > StartDate) and ("Item Ledger Entry"."Posting Date" < EndDate) then
                            CurrReport.Skip();
                        if "Country/Region".Get("Item Ledger Entry"."Country/Region Code") then
                            if "Country/Region"."EU Country/Region Code" = '' then
                                CurrReport.Skip();
                        if not HasCrossedBorder("Item Ledger Entry") then
                            CurrReport.Skip();
                        InsertValueEntryLine();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", StartDate, EndDate);
                SetFilter("Item Charge No.", '<> %1', '');
                "Item Ledger Entry".SetRange("Posting Date");

                if not IntrastatJnlBatch."Corrective Entry" then
                    "Value Entry".SetFilter("Document Type", '<>%1&<>%2&<>%3&<>%4&<>%5',
                      "Value Entry"."Document Type"::"Sales Return Receipt", "Value Entry"."Document Type"::"Sales Credit Memo",
                      "Value Entry"."Document Type"::"Purchase Return Shipment", "Value Entry"."Document Type"::"Purchase Credit Memo",
                      "Value Entry"."Document Type"::"Service Credit Memo")
                else
                    "Value Entry".SetFilter("Document Type", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7&<>%8',
                      "Value Entry"."Document Type"::"Sales Shipment", "Value Entry"."Document Type"::"Sales Invoice",
                      "Value Entry"."Document Type"::"Purchase Receipt", "Value Entry"."Document Type"::"Purchase Invoice",
                      "Value Entry"."Document Type"::"Transfer Shipment", "Value Entry"."Document Type"::"Transfer Receipt",
                      "Value Entry"."Document Type"::"Service Shipment", "Value Entry"."Document Type"::"Service Invoice");

                if IntrastatJnlBatch.Type = IntrastatJnlBatch.Type::Purchases then
                    SetFilter("Item Ledger Entry Type", '%1|%2', "Item Ledger Entry Type"::Purchase, "Item Ledger Entry Type"::Transfer)
                else
                    SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Sale);

                IntrastatJnlLine2.Reset();
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
                    field(CostRegulationPct; IndirectCostPctReq)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Regulation %';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the regulation percent.';
                    }
                    field(CustomsOfficeNo; CustomsOfficeNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customs Office No.';
                        Enabled = CustomsOfficeNoEnable;
                        TableRelation = "Customs Office";
                        ToolTip = 'Specifies the customs office that the trade of goods or services passes through.';
                    }
                    field(CorrectedIntrastatRepNo; CorrectedIntrastatRepNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Corrected Intrastat Report No.';
                        Enabled = CorrectedIntrastatRepNoEnable;
                        ToolTip = 'Specifies the corrected report.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            IntrastatJnlBatch2: Record "Intrastat Jnl. Batch";
                        begin
                            SetIntrastatJnlBatchFilter(IntrastatJnlBatch2);
                            if PAGE.RunModal(0, IntrastatJnlBatch2) = ACTION::LookupOK then
                                CorrectedIntrastatRepNo := IntrastatJnlBatch2.Name;
                        end;

                        trigger OnValidate()
                        var
                            IntrastatJnlBatch2: Record "Intrastat Jnl. Batch";
                        begin
                            SetIntrastatJnlBatchFilter(IntrastatJnlBatch2);
                            IntrastatJnlBatch2.SetRange(Name, CorrectedIntrastatRepNo);
                            if not IntrastatJnlBatch2.FindFirst() then
                                Error(Text12100,
                                  CorrectedIntrastatRepNo, IntrastatJnlBatch2.GetFilters);
                        end;
                    }
                    field(IncludeIntraCommunityEntries; IncludeIntraCommunityEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Intra-Community Entries';
                        ToolTip = 'Specifies if you want the report to include intra-community entries from drop shipment documents to Intrastat Journal.';
                    }
                }
                group(Additional)
                {
                    Caption = 'Additional';
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

        trigger OnInit()
        begin
            CorrectedIntrastatRepNoEnable := true;
            CustomsOfficeNoEnable := true;
        end;

        trigger OnOpenPage()
        begin
            IntraJnlTemplate.Get(IntrastatJnlLine."Journal Template Name");
            IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
            IntrastatJnlLine.CalcStartEndDate(StartDate, EndDate);
            CustomsOfficeNoEnable := IntrastatJnlBatch."Corrective Entry";
            CorrectedIntrastatRepNoEnable := IntrastatJnlBatch."Corrective Entry";
            CorrectedIntrastatRepNo := '';
            CustomsOfficeNo := '';
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.FindFirst();
    end;

    trigger OnPreReport()
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlLine.LockTable();
        if IntrastatJnlLine.FindLast() then
            if not Confirm(LinesDeletionConfirmationTxt, true, IntrastatJnlLine."Journal Batch Name", IntrastatJnlLine."Journal Template Name") then
                CurrReport.Quit();

        IntrastatJnlLine.DeleteAll();

        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, false);

        GetGLSetup();
        if IntrastatJnlBatch."Amounts in Add. Currency" then begin
            GLSetup.TestField("Additional Reporting Currency");
            AddCurrencyFactor :=
              CurrExchRate.ExchangeRate(EndDate, GLSetup."Additional Reporting Currency");
        end;
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        CompanyInfo: Record "Company Information";
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        UOMMgt: Codeunit "Unit of Measure Management";
        TotalInvoicedQty: Decimal;
        TotalAmt: Decimal;
        AddCurrencyFactor: Decimal;
        GLSetupRead: Boolean;
        CustomsOfficeNo: Code[10];
        CorrectedIntrastatRepNo: Code[10];
        PrevEntryNo: Integer;
        [InDataSet]
        CustomsOfficeNoEnable: Boolean;
        [InDataSet]
        CorrectedIntrastatRepNoEnable: Boolean;

        Text12100: Label 'There is no %1 with in the filter.\\Filters: %2';
        LinesDeletionConfirmationTxt: Label 'The existing lines for Intrastat journal batch %1 of Intrastat journal template %2 will be deleted. Do you want to continue?', Comment = '%1 - Intrastat Journal Batch; %2 -  Intrastat Journal Template';

    protected var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        StartDate: Date;
        EndDate: Date;
        IndirectCostPctReq: Decimal;
        IncludeIntraCommunityEntries: Boolean;
        SkipZeroAmounts: Boolean;
        ShowBlank: Boolean;
        ShowItemCharges: Boolean;

    procedure SetIntrastatJnlLine(NewIntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine := NewIntrastatJnlLine;
    end;

    local procedure InsertItemJnlLine()
    var
        IsHandled: Boolean;
    begin
        Item.Get("Item Ledger Entry"."Item No.");
        GetGLSetup();
        with IntrastatJnlLine do begin
            Init();
            "Line No." := "Line No." + 10000;
            Date := "Item Ledger Entry"."Last Invoice Date";
            "Country/Region Code" := GetIntrastatCountryCode("Item Ledger Entry"."Country/Region Code");
            "Transaction Type" := "Item Ledger Entry"."Transaction Type";
            "Transport Method" := "Item Ledger Entry"."Transport Method";
            "Source Entry No." := "Item Ledger Entry"."Entry No.";
            Amount := TotalAmt;
            Quantity := TotalInvoicedQty;
            "Document No." := ValueEntry."Document No.";
            "Item No." := Item."No.";
            "Item Description" := Item.Description;
            "Entry/Exit Point" := "Item Ledger Entry"."Entry/Exit Point";
            Area := "Item Ledger Entry".Area;
            "Transaction Specification" := "Item Ledger Entry"."Transaction Specification";
            "Shpt. Method Code" := "Item Ledger Entry"."Shpt. Method Code";
            "Location Code" := "Item Ledger Entry"."Location Code";
            if "Entry/Exit Point" <> '' then
                Validate("Entry/Exit Point");
            "Statistics Period" := IntrastatJnlBatch."Statistics Period";
            "Reference Period" := "Statistics Period";

            if "Item Ledger Entry"."Entry Type" = "Item Ledger Entry"."Entry Type"::Sale then begin
                Type := Type::Shipment;
                FillVATRegNoAndCountryRegionCodeFromCustomer(IntrastatJnlLine, GetCustomerNoFromDocumentNo());
                Amount := Round(-Amount, GLSetup."Amount Rounding Precision");
                "Indirect Cost" := Round(-"Indirect Cost", GLSetup."Amount Rounding Precision");
                Validate(Quantity, Round(-Quantity, 0.00001));
            end else begin
                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then begin
                    if TotalInvoicedQty < 0 then
                        Type := Type::Receipt
                    else
                        Type := Type::Shipment
                end else
                    Type := Type::Receipt;

                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then begin
                    Amount := Round(Abs(Amount), GLSetup."Amount Rounding Precision");
                    Validate(Quantity, Round(Abs(Quantity), UOMMgt.QtyRndPrecision()));
                end else begin
                    Amount := Round(Amount, GLSetup."Amount Rounding Precision");
                    Validate(Quantity, Round(Quantity, UOMMgt.QtyRndPrecision()));
                end;
            end;

            SetCountryRegionCode(IntrastatJnlLine, "Item Ledger Entry");

            Validate("Item No.");

            FindSourceCurrency(
                "Item Ledger Entry"."Source No.", "Item Ledger Entry"."Document Date", "Item Ledger Entry"."Posting Date");

            "Source Type" := "Source Type"::"Item Entry";
            "Country/Region of Origin Code" := GetCountryOfOriginCode();
            "Partner VAT ID" := GetPartnerID();
            Validate("Cost Regulation %", IndirectCostPctReq);
            "Corrected Intrastat Report No." := CorrectedIntrastatRepNo;

            IsHandled := false;
            OnBeforeInsertItemJnlLine(IntrastatJnlLine, "Item Ledger Entry", IsHandled);
            if not IsHandled then
                Insert();
        end;
    end;

    local procedure InsertJobLedgerLine()
    var
        IsHandled: Boolean;
    begin
        with IntrastatJnlLine do begin
            Init();
            "Line No." := "Line No." + 10000;

            Date := "Job Ledger Entry"."Posting Date";
            "Country/Region Code" := GetIntrastatCountryCode("Job Ledger Entry"."Country/Region Code");
            "Transaction Type" := "Job Ledger Entry"."Transaction Type";
            "Transport Method" := "Job Ledger Entry"."Transport Method";
            Quantity := "Job Ledger Entry"."Quantity (Base)";
            if Quantity > 0 then
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
            "Location Code" := "Job Ledger Entry"."Location Code";

            if IntrastatJnlBatch."Amounts in Add. Currency" then
                Amount := Round(Abs(Amount), Currency."Amount Rounding Precision")
            else
                Amount := Round(Abs(Amount), GLSetup."Amount Rounding Precision");

            Validate("Item No.");
            "Source Type" := "Source Type"::"Job Entry";
            "Country/Region of Origin Code" := GetCountryOfOriginCode();
            "Partner VAT ID" := GetPartnerID();
            Validate(Quantity, Round(Abs(Quantity), 0.00001));

            Validate("Cost Regulation %", IndirectCostPctReq);
            "Corrected Intrastat Report No." := CorrectedIntrastatRepNo;

            IsHandled := false;
            OnBeforeInsertJobLedgerLine(IntrastatJnlLine, "Job Ledger Entry", IsHandled);
            if not IsHandled then
                Insert();
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then
                Currency.Get(GLSetup."Additional Reporting Currency");
        end;
        GLSetupRead := true;
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

    local procedure HasCrossedBorder(ItemLedgEntry: Record "Item Ledger Entry") Result: Boolean
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasCrossedBorder(ItemLedgEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with ItemLedgEntry do
            case true of
                "Drop Shipment":
                    begin
                        if ("Country/Region Code" = CompanyInfo."Country/Region Code") or
                           ("Country/Region Code" = '')
                        then
                            exit(IncludeIntraCommunityEntries);
                        if "Applies-to Entry" = 0 then begin
                            ItemLedgEntry2.SetCurrentKey("Item No.", "Posting Date");
                            ItemLedgEntry2.SetRange("Item No.", "Item No.");
                            ItemLedgEntry2.SetRange("Posting Date", "Posting Date");
                            ItemLedgEntry2.SetRange("Applies-to Entry", "Entry No.");
                            ItemLedgEntry2.FindFirst();
                        end else
                            ItemLedgEntry2.Get("Applies-to Entry");
                        if (ItemLedgEntry2."Country/Region Code" <> CompanyInfo."Country/Region Code") and
                           (ItemLedgEntry2."Country/Region Code" <> '')
                        then
                            exit(IncludeIntraCommunityEntries);
                    end;
                "Entry Type" = "Entry Type"::Transfer:
                    begin
                        if ("Country/Region Code" = CompanyInfo."Country/Region Code") or ("Country/Region Code" = '') then
                            exit(false);
                        case true of
                            (("Order Type" <> "Order Type"::Transfer) or ("Order No." = '')),
                            "Document Type" = "Document Type"::"Direct Transfer":
                                if Location.Get("Location Code") then
                                    if (Location."Country/Region Code" <> '') and (Location."Country/Region Code" <> CompanyInfo."Country/Region Code") then
                                        exit(false);
                            "Document Type" = "Document Type"::"Transfer Receipt":
                                begin
                                    ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.");
                                    ItemLedgEntry2.SetRange("Order Type", "Order Type"::Transfer);
                                    ItemLedgEntry2.SetRange("Order No.", "Order No.");
                                    ItemLedgEntry2.SetRange("Document Type", ItemLedgEntry2."Document Type"::"Transfer Shipment");
                                    ItemLedgEntry2.SetFilter("Country/Region Code", '%1 | %2', '', CompanyInfo."Country/Region Code");
                                    ItemLedgEntry2.SetRange(Positive, true);
                                    if ItemLedgEntry2.IsEmpty() then
                                        exit(false);
                                end;
                            "Document Type" = "Document Type"::"Transfer Shipment":
                                begin
                                    if not ItemLedgEntry.Positive then
                                        exit;
                                    ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.");
                                    ItemLedgEntry2.SetRange("Order Type", "Order Type"::Transfer);
                                    ItemLedgEntry2.SetRange("Order No.", "Order No.");
                                    ItemLedgEntry2.SetRange("Document Type", ItemLedgEntry2."Document Type"::"Transfer Receipt");
                                    ItemLedgEntry2.SetFilter("Country/Region Code", '%1 | %2', '', CompanyInfo."Country/Region Code");
                                    ItemLedgEntry2.SetRange(Positive, false);
                                    if ItemLedgEntry2.IsEmpty() then
                                        exit(false);
                                end;
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
        Location: Record Location;
        IsHandled: Boolean;
    begin
        GetGLSetup();
        with IntrastatJnlLine do begin
            Init();
            "Line No." := "Line No." + 10000;
            Date := "Value Entry"."Posting Date";
            "Country/Region Code" := "Item Ledger Entry"."Country/Region Code";
            "Transaction Type" := "Item Ledger Entry"."Transaction Type";
            "Transport Method" := "Item Ledger Entry"."Transport Method";
            "Source Entry No." := "Item Ledger Entry"."Entry No.";
            Quantity := "Item Ledger Entry".Quantity;
            "Document No." := "Value Entry"."Document No.";
            "Item No." := "Item Ledger Entry"."Item No.";
            "Entry/Exit Point" := "Item Ledger Entry"."Entry/Exit Point";
            Area := "Item Ledger Entry".Area;
            "Transaction Specification" := "Item Ledger Entry"."Transaction Specification";
            "Location Code" := "Item Ledger Entry"."Location Code";
            Amount := Round(Abs("Value Entry"."Sales Amount (Actual)"), 1);

            SetJnlLineType(IntrastatJnlLine, "Value Entry"."Document Type");

            if ("Country/Region Code" = '') or
               ("Country/Region Code" = CompanyInfo."Country/Region Code")
            then
                if "Item Ledger Entry"."Location Code" = '' then
                    "Country/Region Code" := CompanyInfo."Ship-to Country/Region Code"
                else begin
                    Location.Get("Item Ledger Entry"."Location Code");
                    "Country/Region Code" := Location."Country/Region Code"
                end;

            Validate("Item No.");
            "Source Type" := "Source Type"::"Item Entry";
            "Country/Region of Origin Code" := GetCountryOfOriginCode();
            "Partner VAT ID" := GetPartnerID();
            Validate(Quantity, Round(Abs(Quantity), 0.00001));
            Validate("Cost Regulation %", IndirectCostPctReq);

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
            exit(VATPostingSetup."EU Service");
        end;
    end;

    [Scope('OnPrem')]
    procedure FindSourceCurrency(UseItemLedgEntry: Boolean)
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        Vendor: Record Vendor;
        Country: Record "Country/Region";
        CurrencyDate: Date;
        Factor: Decimal;
        Purchase: Boolean;
    begin
        if UseItemLedgEntry then begin // Item
            if "Item Ledger Entry"."Document Date" <> 0D then
                CurrencyDate := "Item Ledger Entry"."Document Date"
            else
                CurrencyDate := "Item Ledger Entry"."Posting Date";
            Purchase := "Item Ledger Entry"."Entry Type" = "Item Ledger Entry"."Entry Type"::Purchase;
        end else begin // Job
            if "Job Ledger Entry"."Document Date" <> 0D then
                CurrencyDate := "Job Ledger Entry"."Document Date"
            else
                CurrencyDate := "Job Ledger Entry"."Posting Date";
            Purchase := "Job Ledger Entry"."Entry Type" <> "Job Ledger Entry"."Entry Type"::Sale;
        end;

        if Purchase then
            if Vendor.Get("Item Ledger Entry"."Source No.") then begin
                if Country.Get(Vendor."Country/Region Code") then
                    IntrastatJnlLine."Currency Code" := Country."Currency Code";
                if IntrastatJnlLine."Currency Code" <> '' then begin
                    Factor :=
                      CurrencyExchRate.ExchangeRate(ValueEntry."Document Date", IntrastatJnlLine."Currency Code");
                    IntrastatJnlLine."Source Currency Amount" :=
                      CurrencyExchRate.ExchangeAmtLCYToFCY(
                        ValueEntry."Document Date", IntrastatJnlLine."Currency Code",
                        IntrastatJnlLine.Amount, Factor);
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure CalculateTotals(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        DocItemSum: Decimal;
        CorrectionFound: Boolean;
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipLine: Record "Sales Shipment Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipLine: Record "Service Shipment Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TotalCostAmt: Decimal;
    begin
        with ItemLedgerEntry do begin
            TotalInvoicedQty := 0;
            TotalAmt := 0;
            DocItemSum := 0;
            CorrectionFound := false;

            if not ((ValueEntry."Item Charge No." <> '') and
                    ((ValueEntry."Posting Date" > EndDate) or (ValueEntry."Posting Date" < StartDate)))
            then
                case ValueEntry."Item Ledger Entry Type" of
                    ValueEntry."Item Ledger Entry Type"::Purchase:
                        begin
                            if ValueEntry."Invoiced Quantity" > 0 then begin
                                PurchInvLine.SetRange("Document No.", ValueEntry."Document No.");
                                PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
                                PurchInvLine.SetRange("No.", ValueEntry."Item No.");
                                if PurchInvLine.Find('-') then begin
                                    PurchInvHeader.Get(ValueEntry."Document No.");
                                    repeat
                                        TotalInvoicedQty := TotalInvoicedQty + PurchInvLine.Quantity;
                                        if PurchInvHeader."Currency Factor" <> 0 then
                                            TotalAmt := TotalAmt + (PurchInvLine.Amount / PurchInvHeader."Currency Factor")
                                        else
                                            TotalAmt := TotalAmt + PurchInvLine.Amount;
                                    until PurchInvLine.Next() = 0;
                                end else begin
                                    PurchRcptLine.SetRange("Document No.", ValueEntry."Document No.");
                                    PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
                                    PurchRcptLine.SetRange("No.", ValueEntry."Item No.");
                                    if PurchRcptLine.Find('-') then begin
                                        repeat
                                            if PurchRcptLine.Correction = true then
                                                CorrectionFound := true;
                                            DocItemSum += PurchRcptLine."Quantity Invoiced";
                                        until PurchRcptLine.Next() = 0;
                                        if (DocItemSum = 0) and CorrectionFound then
                                            CurrReport.Skip();
                                    end;
                                end;
                            end else begin
                                PurchCrMemoLine.SetRange("Document No.", ValueEntry."Document No.");
                                PurchCrMemoLine.SetRange(Type, PurchInvLine.Type::Item);
                                PurchCrMemoLine.SetRange("No.", ValueEntry."Item No.");
                                if PurchCrMemoLine.Find('-') then begin
                                    PurchCrMemoHdr.Get(ValueEntry."Document No.");
                                    repeat
                                        TotalInvoicedQty := TotalInvoicedQty - PurchCrMemoLine.Quantity;
                                        if PurchCrMemoHdr."Currency Factor" <> 0 then
                                            TotalAmt := TotalAmt - (PurchCrMemoLine.Amount / PurchCrMemoHdr."Currency Factor")
                                        else
                                            TotalAmt := TotalAmt - PurchCrMemoLine.Amount;
                                    until PurchCrMemoLine.Next() = 0;
                                end else begin
                                    PurchRcptLine.SetRange("Document No.", ValueEntry."Document No.");
                                    PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
                                    PurchRcptLine.SetRange("No.", ValueEntry."Item No.");
                                    if PurchRcptLine.Find('-') then begin
                                        repeat
                                            if PurchRcptLine.Correction = true then
                                                CorrectionFound := true;
                                            DocItemSum += PurchRcptLine."Quantity Invoiced";
                                        until PurchRcptLine.Next() = 0;
                                        if (DocItemSum = 0) and CorrectionFound then
                                            CurrReport.Skip();
                                    end;
                                end;
                            end;
                            if IntrastatJnlBatch."Amounts in Add. Currency" then
                                TotalAmt := CurrExchRate.ExchangeAmtLCYToFCY(
                                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                                    TotalAmt, AddCurrencyFactor);
                        end;
                    ValueEntry."Item Ledger Entry Type"::Sale:
                        begin
                            if (ValueEntry."Invoiced Quantity" < 0) and (ValueEntry."Order Type" = ValueEntry."Order Type"::" ") then begin
                                SalesInvoiceLine.SetRange("Document No.", ValueEntry."Document No.");
                                SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
                                SalesInvoiceLine.SetRange("No.", ValueEntry."Item No.");
                                if SalesInvoiceLine.Find('-') then begin
                                    SalesInvoiceHeader.Get(ValueEntry."Document No.");
                                    repeat
                                        TotalInvoicedQty := TotalInvoicedQty - SalesInvoiceLine.Quantity;
                                        if SalesInvoiceHeader."Currency Factor" <> 0 then
                                            TotalAmt := TotalAmt - (SalesInvoiceLine.Amount / SalesInvoiceHeader."Currency Factor")
                                        else
                                            TotalAmt := TotalAmt - SalesInvoiceLine.Amount;
                                    until SalesInvoiceLine.Next() = 0;
                                end else begin
                                    SalesShipLine.SetRange("Document No.", ValueEntry."Document No.");
                                    SalesShipLine.SetRange(Type, SalesShipLine.Type::Item);
                                    SalesShipLine.SetRange("No.", ValueEntry."Item No.");
                                    if SalesShipLine.Find('-') then begin
                                        repeat
                                            if SalesShipLine.Correction = true then
                                                CorrectionFound := true;
                                            DocItemSum += SalesShipLine."Quantity Invoiced";
                                        until SalesShipLine.Next() = 0;
                                        if (DocItemSum = 0) and CorrectionFound then
                                            CurrReport.Skip();
                                    end;
                                end;
                            end else
                                if (ValueEntry."Invoiced Quantity" >= 0) and (ValueEntry."Order Type" = ValueEntry."Order Type"::" ") then begin
                                    SalesCrMemoLine.SetRange("Document No.", ValueEntry."Document No.");
                                    SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
                                    SalesCrMemoLine.SetRange("No.", ValueEntry."Item No.");
                                    if SalesCrMemoLine.Find('-') then begin
                                        SalesCrMemoHeader.Get(ValueEntry."Document No.");
                                        repeat
                                            TotalInvoicedQty := TotalInvoicedQty + SalesCrMemoLine.Quantity;
                                            if SalesCrMemoHeader."Currency Factor" <> 0 then
                                                TotalAmt := TotalAmt + (SalesCrMemoLine.Amount / SalesCrMemoHeader."Currency Factor")
                                            else
                                                TotalAmt := TotalAmt + SalesCrMemoLine.Amount;
                                        until SalesCrMemoLine.Next() = 0;
                                    end else begin
                                        SalesShipLine.SetRange("Document No.", ValueEntry."Document No.");
                                        SalesShipLine.SetRange(Type, SalesShipLine.Type::Item);
                                        SalesShipLine.SetRange("No.", ValueEntry."Item No.");
                                        if SalesShipLine.Find('-') then begin
                                            repeat
                                                if SalesShipLine.Correction = true then
                                                    CorrectionFound := true;
                                                DocItemSum += SalesShipLine."Quantity Invoiced";
                                            until SalesShipLine.Next() = 0;
                                            if (DocItemSum = 0) and CorrectionFound then
                                                CurrReport.Skip();
                                        end;
                                    end;
                                end else
                                    if (ValueEntry."Invoiced Quantity" < 0) and (ValueEntry."Order Type" = ValueEntry."Order Type"::Service) then begin
                                        ServiceInvoiceLine.SetRange("Document No.", ValueEntry."Document No.");
                                        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Item);
                                        ServiceInvoiceLine.SetRange("No.", ValueEntry."Item No.");
                                        if ServiceInvoiceLine.Find('-') then begin
                                            ServiceInvoiceHeader.Get(ValueEntry."Document No.");
                                            repeat
                                                TotalInvoicedQty := TotalInvoicedQty - ServiceInvoiceLine.Quantity;
                                                if ServiceInvoiceHeader."Currency Factor" <> 0 then
                                                    TotalAmt := TotalAmt - (ServiceInvoiceLine.Amount / ServiceInvoiceHeader."Currency Factor")
                                                else
                                                    TotalAmt := TotalAmt - ServiceInvoiceLine.Amount;
                                            until ServiceInvoiceLine.Next() = 0;
                                        end else begin
                                            ServiceShipLine.SetRange("Document No.", ValueEntry."Document No.");
                                            ServiceShipLine.SetRange(Type, ServiceShipLine.Type::Item);
                                            ServiceShipLine.SetRange("No.", ValueEntry."Item No.");
                                            if ServiceShipLine.Find('-') then begin
                                                repeat
                                                    if ServiceShipLine.Correction = true then
                                                        CorrectionFound := true;
                                                    DocItemSum += ServiceShipLine."Quantity Invoiced";
                                                until ServiceShipLine.Next() = 0;
                                                if (DocItemSum = 0) and CorrectionFound then
                                                    CurrReport.Skip();
                                            end;
                                        end;
                                    end else
                                        if (ValueEntry."Invoiced Quantity" >= 0) and (ValueEntry."Order Type" = ValueEntry."Order Type"::Service) then begin
                                            ServiceCrMemoLine.SetRange("Document No.", ValueEntry."Document No.");
                                            ServiceCrMemoLine.SetRange(Type, ServiceCrMemoLine.Type::Item);
                                            ServiceCrMemoLine.SetRange("No.", ValueEntry."Item No.");
                                            if ServiceCrMemoLine.Find('-') then begin
                                                ServiceCrMemoHeader.Get(ValueEntry."Document No.");
                                                repeat
                                                    TotalInvoicedQty := TotalInvoicedQty + ServiceCrMemoLine.Quantity;
                                                    if ServiceCrMemoHeader."Currency Factor" <> 0 then
                                                        TotalAmt := TotalAmt + (ServiceCrMemoLine.Amount / ServiceCrMemoHeader."Currency Factor")
                                                    else
                                                        TotalAmt := TotalAmt + ServiceCrMemoLine.Amount;
                                                until ServiceCrMemoLine.Next() = 0;
                                            end else begin
                                                ServiceShipLine.SetRange("Document No.", ValueEntry."Document No.");
                                                ServiceShipLine.SetRange(Type, ServiceShipLine.Type::Item);
                                                ServiceShipLine.SetRange("No.", ValueEntry."Item No.");
                                                if ServiceShipLine.Find('-') then begin
                                                    repeat
                                                        if ServiceShipLine.Correction = true then
                                                            CorrectionFound := true;
                                                        DocItemSum += ServiceShipLine."Quantity Invoiced";
                                                    until ServiceShipLine.Next() = 0;
                                                    if (DocItemSum = 0) and CorrectionFound then
                                                        CurrReport.Skip();
                                                end;
                                            end;
                                        end;
                            if IntrastatJnlBatch."Amounts in Add. Currency" then
                                TotalAmt := CurrExchRate.ExchangeAmtLCYToFCY(
                                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                                    TotalAmt, AddCurrencyFactor);
                        end;
                    else begin
                            TotalInvoicedQty := TotalInvoicedQty + ValueEntry."Invoiced Quantity";
                            if not IntrastatJnlBatch."Amounts in Add. Currency" then
                                TotalAmt := TotalAmt + ValueEntry."Cost Amount (Actual)"
                            else
                                if ValueEntry."Cost per Unit" <> 0 then
                                    TotalAmt :=
                                      TotalAmt +
                                      ValueEntry."Cost Amount (Actual)" * ValueEntry."Cost per Unit (ACY)" / ValueEntry."Cost per Unit"
                                else
                                    TotalAmt :=
                                      TotalAmt +
                                      CurrExchRate.ExchangeAmtLCYToFCY(
                                        ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                                        ValueEntry."Cost Amount (Actual)", AddCurrencyFactor);
                        end;
                end;
            OnCalculateTotalsOnAfterSumTotals(ItemLedgerEntry, IntrastatJnlBatch, TotalAmt, TotalCostAmt);
            CalcTotalItemChargeAmt();
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
                if VATPostingSetup."EU Service" then
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
    procedure InsertEUServiceLine(VATEntry: Record "VAT Entry")
    var
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        HasApplications: Boolean;
    begin
        with IntrastatJnlLine do begin
            HasApplications := DocumentHasApplications(VATEntry);

            IntrastatJnlLine2.SetRange("Journal Template Name", "Journal Template Name");
            IntrastatJnlLine2.SetRange("Journal Batch Name", "Journal Batch Name");
            IntrastatJnlLine2.SetRange("Document No.", VATEntry."Document No.");
            if not HasApplications then
                IntrastatJnlLine2.SetRange("Service Tariff No.", VATEntry."Service Tariff No.");
            if not IntrastatJnlLine2.FindFirst() then begin
                Init();
                "Line No." := "Line No." + 10000;
                "Source Type" := "Source Type"::"VAT Entry";
                "Source Entry No." := VATEntry."Entry No.";
                ValidateSourceEntryNo("Source Entry No.");
                if not HasApplications then
                    Amount := GetVATEntryAmount(VATEntry)
                else
                    Amount -= GetAmountSign(Amount) * Abs(NonEUServiceLineAmount(IntrastatJnlBatch.Type));
                if IntrastatJnlBatch."Corrective Entry" then begin
                    "Custom Office No." := CustomsOfficeNo;
                    "Corrected Intrastat Report No." := CorrectedIntrastatRepNo;
                    "Corrective entry" := true;
                    Amount := Abs(Amount);
                end;

                if (Amount <> 0) or IntrastatJnlBatch."Corrective Entry" then
                    Insert();
            end else
                if not HasApplications then begin
                    IntrastatJnlLine2.Amount += GetVATEntryAmount(VATEntry);
                    IntrastatJnlLine2.Modify();
                end
        end;
    end;

    [Scope('OnPrem')]
    procedure SetIntrastatJnlBatchFilter(var IntrastatJnlBatch2: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlBatch2.SetRange(Reported, true);
        IntrastatJnlBatch2.SetRange("EU Service", IntrastatJnlBatch."EU Service");
        IntrastatJnlBatch2.SetRange("Corrective Entry", false);
        IntrastatJnlBatch2.SetRange(Type, IntrastatJnlBatch.Type);
        IntrastatJnlBatch2.SetRange(Periodicity, IntrastatJnlBatch.Periodicity);
    end;

    [Scope('OnPrem')]
    procedure CheckTransferEntry(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry2 do begin
            SetFilter("Item No.", '%1', ItemLedgerEntry."Item No.");
            SetFilter("Entry Type", '%1', ItemLedgerEntry."Entry Type"::Transfer);
            SetFilter("Document Type", '%1', ItemLedgerEntry."Document Type"::"Transfer Shipment");
            SetFilter("Order Type", '%1', ItemLedgerEntry."Order Type"::Production);
            SetFilter("Order No.", '%1', ItemLedgerEntry."Order No.");
            SetFilter("Order Line No.", '%1', ItemLedgerEntry."Order Line No.");
            SetFilter("Prod. Order Comp. Line No.", '%1', ItemLedgerEntry."Prod. Order Comp. Line No.");
            SetFilter("Subcontr. Purch. Order No.", '%1', ItemLedgerEntry."Subcontr. Purch. Order No.");
            SetFilter("Subcontr. Purch. Order Line", '%1', ItemLedgerEntry."Subcontr. Purch. Order Line");
            SetFilter(Positive, '%1', ItemLedgerEntry.Positive);
            FindFirst();
            exit("Entry No." = ItemLedgerEntry."Entry No.");
        end;
    end;

    local procedure CalcTotalItemChargeAmt()
    var
        ValueEntry2: Record "Value Entry";
        ActualAmount: Decimal;
    begin
        ValueEntry2.CopyFilters(ValueEntry);
        ValueEntry2.SetRange("Invoiced Quantity", 0);
        ValueEntry2.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type");
        ValueEntry2.SetRange("Item Ledger Entry No.");
        ValueEntry2.SetRange("Item No.", ValueEntry."Item No.");
        ValueEntry2.SetFilter("Item Charge No.", '<>%1', '');
        ValueEntry2.SetRange("Document No.", ValueEntry."Document No.");
        if ValueEntry2.FindSet() then begin
            repeat
                ActualAmount := GetActualAmount(ValueEntry2);
                if IntrastatJnlBatch."Amounts in Add. Currency" then
                    ActualAmount :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        ValueEntry2."Posting Date", GLSetup."Additional Reporting Currency",
                        ActualAmount, AddCurrencyFactor);
                TotalAmt := TotalAmt + ActualAmount;

            until ValueEntry2.Next() = 0;
        end;
    end;

    local procedure GetActualAmount(ValueEntry2: Record "Value Entry"): Decimal
    begin
        case ValueEntry2."Item Ledger Entry Type" of
            ValueEntry2."Item Ledger Entry Type"::Sale:
                exit(-ValueEntry2."Sales Amount (Actual)");
            ValueEntry2."Item Ledger Entry Type"::Purchase:
                exit(ValueEntry2."Cost Amount (Actual)");
        end;
    end;

    local procedure NonEUServiceLineAmount(BatchType: Option): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Document No.", IntrastatJnlLine."Document No.");
            SetRange("EU Service", false);
            case BatchType of
                IntrastatJnlBatch.Type::Purchases:
                    SetRange(Type, Type::Purchase);
                IntrastatJnlBatch.Type::Sales:
                    SetRange(Type, Type::Sale);
            end;
            CalcSums(Base);
            exit(Base);
        end;
    end;

    local procedure GetAmountSign(Amount: Decimal): Integer
    begin
        if Amount > 0 then
            exit(1);

        exit(-1);
    end;

    local procedure DocumentHasApplications(VATEntry: Record "VAT Entry"): Boolean
    begin
        case VATEntry.Type of
            VATEntry.Type::Purchase:
                exit(DocumentHasVendApplications(VATEntry));
            VATEntry.Type::Sale:
                exit(DocumentHasCustApplications(VATEntry));
        end;
    end;

    local procedure DocumentHasVendApplications(VATEntry: Record "VAT Entry"): Boolean
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
            SetRange("Vendor Ledger Entry No.", GetVendLedgEntryNo(VATEntry));
            SetFilter("Posting Date", '..%1', EndDate);
            SetFilter("Document Type", '%1|%2', "Document Type"::"Credit Memo", "Document Type"::Invoice);
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange(Unapplied, false);
            exit(not IsEmpty);
        end;
    end;

    local procedure DocumentHasCustApplications(VATEntry: Record "VAT Entry"): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
            SetRange("Cust. Ledger Entry No.", GetCustLedgEntryNo(VATEntry));
            SetFilter("Posting Date", '..%1', EndDate);
            SetFilter("Document Type", '%1|%2', "Document Type"::"Credit Memo", "Document Type"::Invoice);
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange(Unapplied, false);
            exit(not IsEmpty);
        end;
    end;

    local procedure FindAppliedCustLedgEntries(CustLedgerEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        TempAppliedCustLedgEntry.Reset();
        TempAppliedCustLedgEntry.DeleteAll();

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." = DtldCustLedgEntry."Applied Cust. Ledger Entry No." then begin
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    if DtldCustLedgEntry2.FindSet() then begin
                        repeat
                            if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry2."Applied Cust. Ledger Entry No." then begin
                                CustLedgEntry2.SetRange("Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                                if CustLedgEntry2.FindFirst() then begin
                                    TempAppliedCustLedgEntry := CustLedgEntry2;
                                    TempAppliedCustLedgEntry.Insert();
                                end;
                            end;
                        until DtldCustLedgEntry2.Next() = 0;
                    end;
                end else begin
                    CustLedgEntry2.SetRange("Entry No.", DtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    if CustLedgEntry2.FindFirst() then begin
                        TempAppliedCustLedgEntry := CustLedgEntry2;
                        TempAppliedCustLedgEntry.Insert();
                    end;
                end;
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure FindAppliedVendLedgEntries(VendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        TempAppliedVendLedgEntry.Reset();
        TempAppliedVendLedgEntry.DeleteAll();

        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if DtldVendLedgEntry."Vendor Ledger Entry No." = DtldVendLedgEntry."Applied Vend. Ledger Entry No." then begin
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgEntry2.FindSet() then begin
                        repeat
                            if DtldVendLedgEntry2."Vendor Ledger Entry No." <> DtldVendLedgEntry2."Applied Vend. Ledger Entry No." then begin
                                VendLedgEntry2.SetRange("Entry No.", DtldVendLedgEntry2."Vendor Ledger Entry No.");
                                if VendLedgEntry2.FindFirst() then begin
                                    TempAppliedVendLedgEntry := VendLedgEntry2;
                                    TempAppliedVendLedgEntry.Insert();
                                end;
                            end;
                        until DtldVendLedgEntry2.Next() = 0;
                    end;
                end else begin
                    VendLedgEntry2.SetRange("Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    if VendLedgEntry2.FindFirst() then begin
                        TempAppliedVendLedgEntry := VendLedgEntry2;
                        TempAppliedVendLedgEntry.Insert();
                    end;
                end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure FilterVATEntryOnCustLedgEntry(var VATEntry: Record "VAT Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", CustLedgEntry."Transaction No.");
        VATEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
    end;

    local procedure FilterVATEntryOnVendLedgEntry(var VATEntry: Record "VAT Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", VendLedgEntry."Transaction No.");
        VATEntry.SetRange("Document No.", VendLedgEntry."Document No.");
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
    end;

    local procedure GetVendLedgEntryNo(VATEntry: Record "VAT Entry"): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with VendorLedgerEntry do begin
            SetCurrentKey("Transaction No.");
            SetRange("Transaction No.", VATEntry."Transaction No.");
            SetRange("Document No.", VATEntry."Document No.");
            if FindFirst() then
                exit("Entry No.");
        end;
    end;

    local procedure GetCustLedgEntryNo(VATEntry: Record "VAT Entry"): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgerEntry do begin
            SetCurrentKey("Transaction No.");
            SetRange("Transaction No.", VATEntry."Transaction No.");
            SetRange("Document No.", VATEntry."Document No.");
            if FindFirst() then
                exit("Entry No.");
        end;
    end;

    local procedure GetVATEntryAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Base + VATEntry."Nondeductible Base");
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

    local procedure SetCountryRegionCode(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Location: Record Location;
    begin
        with IntrastatJnlLine do
            if ("Country/Region Code" = '') or
               ("Country/Region Code" = CompanyInfo."Country/Region Code")
            then
                if ItemLedgerEntry."Location Code" = '' then
                    "Country/Region Code" := CompanyInfo."Ship-to Country/Region Code"
                else begin
                    Location.Get(ItemLedgerEntry."Location Code");
                    "Country/Region Code" := Location."Country/Region Code"
                end;
    end;

    local procedure GetCustomerNoFromDocumentNo(): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesShipmentHeader.Get("Item Ledger Entry"."Document No.") then
            exit(SalesShipmentHeader."Sell-to Customer No.");
        SalesSetup.Get();
        if not SalesSetup."Shipment on Invoice" and SalesInvoiceHeader.Get("Item Ledger Entry"."Document No.") then
            exit(SalesInvoiceHeader."Sell-to Customer No.");
        if SalesCrMemoHeader.Get(ValueEntry."Document No.") then
            exit(SalesCrMemoHeader."Sell-to Customer No.");
        if ServiceShipmentHeader.Get("Item Ledger Entry"."Document No.") then
            exit(ServiceShipmentHeader."Customer No.");
    end;

    local procedure FillVATRegNoAndCountryRegionCodeFromCustomer(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then
            exit;
        IntrastatJnlLine."Partner VAT ID" := Customer."VAT Registration No.";
        IntrastatJnlLine."Country/Region Code" := IntrastatJnlLine.GetIntrastatCountryCode(Customer."Country/Region Code");
    end;

    local procedure SetJnlLineType(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ValueEntryDocumentType: Enum "Item Ledger Document Type")
    begin
        with IntrastatJnlLine do
            if Quantity < 0 then begin
                if ValueEntryDocumentType = "Value Entry"."Document Type"::"Sales Credit Memo" then
                    Type := Type::Receipt
                else
                    Type := Type::Shipment
            end else
                if ValueEntryDocumentType = "Value Entry"."Document Type"::"Purchase Credit Memo" then
                    Type := Type::Shipment
                else
                    Type := Type::Receipt;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTotals(var ItemLedgerEntry: Record "Item Ledger Entry"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var TotalAmt: Decimal; var TotalCostAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterItemLedgerEntryOnPreDataItem(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasCrossedBorder(ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
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
#endif