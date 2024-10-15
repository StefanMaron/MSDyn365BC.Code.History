report 31070 "Package Tax Calculation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PackageTaxCalculation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Package Tax Calculation';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Packaging Material will be removed and this report should not be used. (Obsolete::Removed in release 01.2021)';

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = SORTING("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date") WHERE("Entry Type" = CONST(Sale));
            RequestFilterFields = "Posting Date", "Country/Region Code";

            trigger OnAfterGetRecord()
            begin
                if (ItemNo <> "Item No.") or (UnitOfMeasureCode <> "Unit of Measure Code") then begin
                    ItemNo := "Item No.";
                    UnitOfMeasureCode := "Unit of Measure Code";
                    ItemPackMaterialExists := FindPackMaterial("Item No.", "Unit of Measure Code");
                end;
                if ItemPackMaterialExists then
                    FillBuffer("Entry No.", ReportBuf, not PrintDetail);
            end;

            trigger OnPostDataItem()
            begin
                if ReportBuf.IsEmpty then
                    CurrReport.Quit;

                if PrintDetail then
                    FinalizeBuffer(ReportBuf);
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get;

                Title := ReportLbl;
                if PrintDetail then
                    Title += DetailedLbl;
            end;
        }
        dataitem(Total; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(> 0));
            column(ItemLedgerEntry__Item_No__Caption; ItemLedgerEntry__Item_No__CaptionLbl)
            {
            }
            column(ReportBuf_Quantity_Control1470008Caption; ReportBuf_Quantity_Control1470008CaptionLbl)
            {
            }
            column(DtldTaxAmountCaption; DtldTaxAmountCaptionLbl)
            {
            }
            column(ItemLedgerEntry__Posting_Date_Caption; ItemLedgerEntry__Posting_Date_CaptionLbl)
            {
            }
            column(ItemLedgerEntry__Source_No__Caption; ItemLedgerEntry__Source_No__CaptionLbl)
            {
            }
            column(GetCustName_ItemLedgerEntry__Source_No___Caption; GetCustName_ItemLedgerEntry__Source_No___CaptionLbl)
            {
            }
            column(ItemLedgerEntry__Unit_of_Measure_Code_Caption; ItemLedgerEntry__Unit_of_Measure_Code_CaptionLbl)
            {
            }
            column(ItemLedgerEntry__Entry_No__Caption; ItemLedgerEntry__Entry_No__CaptionLbl)
            {
            }
            column(TODAY; Today)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ItemLedgerEntry_GETFILTER__Posting_Date__; ItemLedgerEntry.GetFilter("Posting Date"))
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(ItemLedgerEntry_GETFILTERS; ItemLedgerEntry.GetFilters)
            {
            }
            column(Title; Title)
            {
            }
            column(PackMaterial__Tax_Rate__LCY__Caption; PackMaterial__Tax_Rate__LCY__CaptionLbl)
            {
            }
            column(TaxAmountCaption; TaxAmountCaptionLbl)
            {
            }
            column(PackMaterial_CodeCaption; PackMaterial_CodeCaptionLbl)
            {
            }
            column(PackMaterial__Discount___Caption; PackMaterial__Discount___CaptionLbl)
            {
            }
            column(ReportBuf_QuantityCaption; ReportBuf_QuantityCaptionLbl)
            {
            }
            column(PackMaterial_DescriptionCaption; PackMaterial_DescriptionCaptionLbl)
            {
            }
            column(DiscAmountCaption; DiscAmountCaptionLbl)
            {
            }
            column(PackMaterial__Exemption___Caption; PackMaterial__Exemption___CaptionLbl)
            {
            }
            column(ExmpAmountCaption; ExmpAmountCaptionLbl)
            {
            }
            column(PayAmountCaption; PayAmountCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ItemLedgerEntry_GETFILTER__Posting_Date__Caption; ItemLedgerEntry_GETFILTER__Posting_Date__CaptionLbl)
            {
            }
            column(ItemLedgerEntry_GETFILTERSCaption; ItemLedgerEntry_GETFILTERSCaptionLbl)
            {
            }
            column(PackMaterial__Tax_Rate__LCY__; PackMaterial."Tax Rate (LCY)")
            {
            }
            column(TaxAmount; TaxAmount)
            {
            }
            column(PackMaterial_Code; PackMaterial.Code)
            {
            }
            column(PackMaterial__Discount___; PackMaterial."Discount %")
            {
            }
            column(ReportBuf_Quantity; ReportBuf.Quantity)
            {
            }
            column(PackMaterial_Description; PackMaterial.Description)
            {
            }
            column(DiscAmount; DiscAmount)
            {
            }
            column(PackMaterial__Exemption___; PackMaterial."Exemption %")
            {
            }
            column(ExmpAmount; ExmpAmount)
            {
            }
            column(PayAmount; PayAmount)
            {
            }
            column(TaxAmount_Control1470048; TaxAmount)
            {
            }
            column(DiscAmount_Control1470049; DiscAmount)
            {
            }
            column(ExmpAmount_Control1470050; ExmpAmount)
            {
            }
            column(PayAmount_Control1470051; PayAmount)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(Total_Number; Number)
            {
            }
            dataitem(Detail; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(> 0));
                column(CurrReport_PAGENO_Control1470057; CurrReport.PageNo)
                {
                }
                column(TODAY_Control1470058; Today)
                {
                }
                column(ItemLedgerEntry_GETFILTER__Posting_Date___Control1470061; ItemLedgerEntry.GetFilter("Posting Date"))
                {
                }
                column(Title_Control1470062; Title)
                {
                }
                column(ItemLedgerEntry__Item_No__; ItemLedgerEntry."Item No.")
                {
                }
                column(ItemLedgerEntry_Quantity___ItemLedgerEntry__Qty__per_Unit_of_Measure_; -ItemLedgerEntry.Quantity / ItemLedgerEntry."Qty. per Unit of Measure")
                {
                }
                column(ReportBuf_Quantity_Control1470008; ReportBuf.Quantity)
                {
                }
                column(DtldTaxAmount; DtldTaxAmount)
                {
                }
                column(ItemLedgerEntry__Posting_Date_; Format(ItemLedgerEntry."Posting Date"))
                {
                }
                column(ItemLedgerEntry__Source_No__; ItemLedgerEntry."Source No.")
                {
                }
                column(GetCustName_ItemLedgerEntry__Source_No___; GetCustName(ItemLedgerEntry."Source No."))
                {
                }
                column(ItemLedgerEntry__Unit_of_Measure_Code_; ItemLedgerEntry."Unit of Measure Code")
                {
                }
                column(ItemLedgerEntry__Entry_No__; ItemLedgerEntry."Entry No.")
                {
                }
                column(PackMaterial_CodeCaption_Control1470002; PackMaterial_CodeCaption_Control1470002Lbl)
                {
                }
                column(PackMaterial_DescriptionCaption_Control1470006; PackMaterial_DescriptionCaption_Control1470006Lbl)
                {
                }
                column(PackMaterial__Tax_Rate__LCY__Caption_Control1470010; PackMaterial__Tax_Rate__LCY__Caption_Control1470010Lbl)
                {
                }
                column(ReportBuf_QuantityCaption_Control1470014; ReportBuf_QuantityCaption_Control1470014Lbl)
                {
                }
                column(TaxAmountCaption_Control1470018; TaxAmountCaption_Control1470018Lbl)
                {
                }
                column(PackMaterial__Discount___Caption_Control1470021; PackMaterial__Discount___Caption_Control1470021Lbl)
                {
                }
                column(DiscAmountCaption_Control1470023; DiscAmountCaption_Control1470023Lbl)
                {
                }
                column(PackMaterial__Exemption___Caption_Control1470040; PackMaterial__Exemption___Caption_Control1470040Lbl)
                {
                }
                column(ExmpAmountCaption_Control1470086; ExmpAmountCaption_Control1470086Lbl)
                {
                }
                column(PayAmountCaption_Control1470087; PayAmountCaption_Control1470087Lbl)
                {
                }
                column(ItemLedgerEntry__Item_No__Caption_Control1470089; ItemLedgerEntry__Item_No__Caption_Control1470089Lbl)
                {
                }
                column(ItemLedgerEntry_Quantity___ItemLedgerEntry__Qty__per_Unit_of_Measure_Caption; ItemLedgerEntry_Quantity___ItemLedgerEntry__Qty__per_Unit_of_Measure_CaptionLbl)
                {
                }
                column(ReportBuf_Quantity_Control1470008Caption_Control1470091; ReportBuf_Quantity_Control1470008Caption_Control1470091Lbl)
                {
                }
                column(DtldTaxAmountCaption_Control1470092; DtldTaxAmountCaption_Control1470092Lbl)
                {
                }
                column(ItemLedgerEntry__Posting_Date_Caption_Control1470093; ItemLedgerEntry__Posting_Date_Caption_Control1470093Lbl)
                {
                }
                column(ItemLedgerEntry__Source_No__Caption_Control1470094; ItemLedgerEntry__Source_No__Caption_Control1470094Lbl)
                {
                }
                column(GetCustName_ItemLedgerEntry__Source_No___Caption_Control1470095; GetCustName_ItemLedgerEntry__Source_No___Caption_Control1470095Lbl)
                {
                }
                column(CurrReport_PAGENO_Control1470057Caption; CurrReport_PAGENO_Control1470057CaptionLbl)
                {
                }
                column(ItemLedgerEntry_GETFILTER__Posting_Date___Control1470061Caption; ItemLedgerEntry_GETFILTER__Posting_Date___Control1470061CaptionLbl)
                {
                }
                column(ItemLedgerEntry__Unit_of_Measure_Code_Caption_Control1470065; ItemLedgerEntry__Unit_of_Measure_Code_Caption_Control1470065Lbl)
                {
                }
                column(ItemLedgerEntry__Entry_No__Caption_Control1470067; ItemLedgerEntry__Entry_No__Caption_Control1470067Lbl)
                {
                }
                column(gdeTaxAmount2; TaxAmount2)
                {
                }
                column(gdeDiscAmount2; DiscAmount2)
                {
                }
                column(gdeExmpAmount2; ExmpAmount2)
                {
                }
                column(gdePayAmount2; PayAmount2)
                {
                }
                column(Detail_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then
                        if ReportBuf.Next = 0 then
                            CurrReport.Break;

                    ItemLedgerEntry.Get(ReportBuf."Dimension Entry No.");
                    ItemPackMaterial.Get(ItemLedgerEntry."Item No.", ItemLedgerEntry."Unit of Measure Code", PackMaterial.Code);
                    DtldTaxAmount := ReportBuf.Quantity * PackMaterial."Tax Rate (LCY)";

                    if Number > 1 then begin
                        TaxAmount2 := 0;
                        DiscAmount2 := 0;
                        ExmpAmount2 := 0;
                        PayAmount2 := 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    ReportBuf.SetCurrentKey("Location Code", "Variant Code");
                    ReportBuf.SetRange("Variant Code", PackMaterial.Code);
                    ReportBuf.SetFilter("Dimension Entry No.", '<>%1', 0);
                    if not ReportBuf.FindSet then
                        CurrReport.Break;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ReportBuf.Copy(TotalReportBuf);
                if Number > 1 then
                    if ReportBuf.Next = 0 then
                        CurrReport.Break;
                TotalReportBuf.Copy(ReportBuf);

                PackMaterial.Get(ReportBuf."Variant Code");

                TaxAmount := ReportBuf.Quantity * PackMaterial."Tax Rate (LCY)";
                DiscAmount := Round(TaxAmount * PackMaterial."Discount %" / 100, 0.01);
                ExmpAmount := Round(TaxAmount * PackMaterial."Exemption %" / 100, 0.01);
                PayAmount := TaxAmount - DiscAmount - ExmpAmount;

                TaxAmount2 := TaxAmount;
                DiscAmount2 := DiscAmount;
                ExmpAmount2 := ExmpAmount;
                PayAmount2 := PayAmount;
            end;

            trigger OnPostDataItem()
            begin
                ReportBuf.Reset;
                ReportBuf.DeleteAll;
            end;

            trigger OnPreDataItem()
            begin
                ReportBuf.SetCurrentKey("Location Code", "Variant Code");
                ReportBuf.SetRange("Dimension Entry No.", 0);
                if not ReportBuf.FindSet then
                    CurrReport.Break;
                TotalReportBuf.Copy(ReportBuf);
                Clear(PayAmount);
                Clear(TaxAmount);
                Clear(DiscAmount);
                Clear(ExmpAmount);
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
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies to indicate that detailed documents will print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ReportBuf: Record "Inventory Buffer" temporary;
        ItemPackMaterial: Record "Item Package Material";
        PackMaterial: Record "Package Material";
        CompanyInfo: Record "Company Information";
        TotalReportBuf: Record "Inventory Buffer";
        PrintDetail: Boolean;
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        ItemPackMaterialExists: Boolean;
        DiscAmount: Decimal;
        ExmpAmount: Decimal;
        PayAmount: Decimal;
        TaxAmount: Decimal;
        DtldTaxAmount: Decimal;
        Title: Text[100];
        TaxAmount2: Decimal;
        DiscAmount2: Decimal;
        ExmpAmount2: Decimal;
        PayAmount2: Decimal;
        ReportLbl: Label 'Package Tax Calculation Report';
        DetailedLbl: Label ' (detailed)';
        PackMaterial__Tax_Rate__LCY__CaptionLbl: Label 'Tax Rate (LCY)';
        TaxAmountCaptionLbl: Label 'Tax Amount (LCY)';
        PackMaterial_CodeCaptionLbl: Label 'Code';
        PackMaterial__Discount___CaptionLbl: Label 'Discount %';
        ReportBuf_QuantityCaptionLbl: Label 'Sales (Weight)';
        PackMaterial_DescriptionCaptionLbl: Label 'Description';
        DiscAmountCaptionLbl: Label 'Discount Amount';
        PackMaterial__Exemption___CaptionLbl: Label 'Exemption %';
        ExmpAmountCaptionLbl: Label 'Exemption Amount';
        PayAmountCaptionLbl: Label 'Amount to pay';
        CurrReport_PAGENOCaptionLbl: Label 'Page No.';
        ItemLedgerEntry_GETFILTER__Posting_Date__CaptionLbl: Label 'Period:';
        ItemLedgerEntry_GETFILTERSCaptionLbl: Label 'Filters:';
        ItemLedgerEntry__Item_No__CaptionLbl: Label 'Item No.';
        ReportBuf_Quantity_Control1470008CaptionLbl: Label 'Sales (Weight)';
        DtldTaxAmountCaptionLbl: Label 'Tax Amount (LCY)';
        ItemLedgerEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        ItemLedgerEntry__Source_No__CaptionLbl: Label 'Customer No.';
        GetCustName_ItemLedgerEntry__Source_No___CaptionLbl: Label 'Customer Name';
        ItemLedgerEntry__Unit_of_Measure_Code_CaptionLbl: Label 'Unit Of Measure';
        ItemLedgerEntry__Entry_No__CaptionLbl: Label 'Entry No.';
        TotalCaptionLbl: Label 'Total';
        PackMaterial_CodeCaption_Control1470002Lbl: Label 'Code';
        PackMaterial_DescriptionCaption_Control1470006Lbl: Label 'Description';
        PackMaterial__Tax_Rate__LCY__Caption_Control1470010Lbl: Label 'Tax Rate (LCY)';
        ReportBuf_QuantityCaption_Control1470014Lbl: Label 'Sales (Weight)';
        TaxAmountCaption_Control1470018Lbl: Label 'Tax Amount (LCY)';
        PackMaterial__Discount___Caption_Control1470021Lbl: Label 'Discount %';
        DiscAmountCaption_Control1470023Lbl: Label 'Discount Amount';
        PackMaterial__Exemption___Caption_Control1470040Lbl: Label 'Exemption %';
        ExmpAmountCaption_Control1470086Lbl: Label 'Exemption Amount';
        PayAmountCaption_Control1470087Lbl: Label 'Amount to pay';
        ItemLedgerEntry__Item_No__Caption_Control1470089Lbl: Label 'Item No.';
        ItemLedgerEntry_Quantity___ItemLedgerEntry__Qty__per_Unit_of_Measure_CaptionLbl: Label 'Quantity';
        ReportBuf_Quantity_Control1470008Caption_Control1470091Lbl: Label 'Sales (Weight)';
        DtldTaxAmountCaption_Control1470092Lbl: Label 'Tax Amount (LCY)';
        ItemLedgerEntry__Posting_Date_Caption_Control1470093Lbl: Label 'Posting Date';
        ItemLedgerEntry__Source_No__Caption_Control1470094Lbl: Label 'Customer No.';
        GetCustName_ItemLedgerEntry__Source_No___Caption_Control1470095Lbl: Label 'Customer Name';
        CurrReport_PAGENO_Control1470057CaptionLbl: Label 'Page No.';
        ItemLedgerEntry_GETFILTER__Posting_Date___Control1470061CaptionLbl: Label 'Period:';
        ItemLedgerEntry__Unit_of_Measure_Code_Caption_Control1470065Lbl: Label 'Unit Of Measure';
        ItemLedgerEntry__Entry_No__Caption_Control1470067Lbl: Label 'Entry No.';

    [Scope('OnPrem')]
    procedure FillBuffer(EntryNo: Integer; var InvBuf: Record "Inventory Buffer"; Group: Boolean)
    var
        ItemPackMaterial: Record "Item Package Material";
        ItemLedgEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        ItemLedgEntry.Get(EntryNo);
        ItemPackMaterial.SetFilter("Item No.", ItemLedgEntry."Item No.");
        ItemPackMaterial.SetFilter("Item Unit Of Measure Code", ItemLedgEntry."Unit of Measure Code");
        if ItemPackMaterial.FindSet then
            repeat
                Qty := -ItemLedgEntry.Quantity / ItemLedgEntry."Qty. per Unit of Measure" * ItemPackMaterial.Weight;
                if Group then begin
                    InvBuf."Variant Code" := ItemPackMaterial."Package Material Code";
                    InvBuf."Dimension Entry No." := 0;
                    InvBuf."Item No." := '';
                    if InvBuf.Find then begin
                        InvBuf.Quantity += Qty;
                        InvBuf.Modify;
                    end else begin
                        InvBuf.Quantity := Qty;
                        InvBuf.Insert;
                    end;
                end else begin
                    InvBuf.Init;
                    InvBuf."Variant Code" := ItemPackMaterial."Package Material Code";
                    InvBuf."Item No." := ItemPackMaterial."Item No.";
                    InvBuf."Dimension Entry No." := EntryNo;
                    InvBuf.Quantity := Qty;
                    InvBuf.Insert;
                end;
            until ItemPackMaterial.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FindPackMaterial(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]): Boolean
    var
        ItemPackMaterial: Record "Item Package Material";
    begin
        ItemPackMaterial.SetFilter("Item No.", ItemNo);
        ItemPackMaterial.SetFilter("Item Unit Of Measure Code", UnitOfMeasureCode);
        exit(not ItemPackMaterial.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure FinalizeBuffer(var InvBuf: Record "Inventory Buffer")
    var
        PackMaterial: Record "Package Material";
        Qty: Decimal;
    begin
        if PackMaterial.FindSet then
            repeat
                InvBuf.SetRange("Variant Code", PackMaterial.Code);
                InvBuf.CalcSums(Quantity);
                Qty := InvBuf.Quantity;
                if InvBuf.FindFirst then begin
                    InvBuf."Dimension Entry No." := 0;
                    InvBuf.Quantity := Qty;
                    InvBuf.Insert;
                end;
            until PackMaterial.Next = 0;
        InvBuf.Reset;
    end;

    [Scope('OnPrem')]
    procedure GetCustName(CustNo: Code[20]): Text[50]
    var
        Cust: Record Customer;
    begin
        with Cust do
            if Get(CustNo) then
                exit(Name);
    end;
}

