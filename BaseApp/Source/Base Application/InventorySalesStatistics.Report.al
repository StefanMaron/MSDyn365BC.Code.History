report 712 "Inventory - Sales Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventorySalesStatistics.rdlc';
    ApplicationArea = Suite;
    Caption = 'Inventory Sales Statistics';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("Inventory Posting Group");
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Base Unit of Measure", "Date Filter";
            column(PeriodTextCaption; StrSubstNo(Text000, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PrintAlsoWithoutSale; PrintAlsoWithoutSale)
            {
            }
            column(ItemFilterCaption; StrSubstNo('%1: %2', TableCaption, ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(InventoryPostingGrp_Item; "Inventory Posting Group")
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(UnitCost; UnitCost)
            {
            }
            column(UnitPrice; UnitPrice)
            {
            }
            column(SalesQty; SalesQty)
            {
            }
            column(SalesAmount; SalesAmount)
            {
            }
            column(ItemProfit; ItemProfit)
            {
                AutoFormatType = 1;
            }
            column(ItemProfitPct; ItemProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(InvSalesStatisticsCapt; InvSalesStatisticsCaptLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(IncludeNotSoldItemsCaption; IncludeNotSoldItemsCaptionLbl)
            {
            }
            column(ItemAssemblyBOMCaption; ItemAssemblyBOMCaptionLbl)
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            column(UnitPriceCaption; UnitPriceCaptionLbl)
            {
            }
            column(SalesQtyCaption; SalesQtyCaptionLbl)
            {
            }
            column(SalesAmountCaption; SalesAmountCaptionLbl)
            {
            }
            column(ItemProfitCaption; ItemProfitCaptionLbl)
            {
            }
            column(ItemProfitPctCaption; ItemProfitPctCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Assembly BOM");

                SetFilters;
                Calculate;

                if (SalesAmount = 0) and not PrintAlsoWithoutSale then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Clear(SalesQty);
                Clear(SalesAmount);
                Clear(COGSAmount);
                Clear(ItemProfit);
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
                    field(PrintAlsoWithoutSale; PrintAlsoWithoutSale)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Items Not Sold';
                        MultiLine = true;
                        ToolTip = 'Specifies if items that have not yet been sold are also included in the report.';
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

    trigger OnPreReport()
    begin
        GLSetup.Get();

        ItemFilter := Item.GetFilters;
        PeriodText := Item.GetFilter("Date Filter");

        with ItemStatisticsBuf do begin
            if Item.GetFilter("Date Filter") <> '' then
                SetFilter("Date Filter", PeriodText);
            if Item.GetFilter("Location Filter") <> '' then
                SetFilter("Location Filter", Item.GetFilter("Location Filter"));
            if Item.GetFilter("Variant Filter") <> '' then
                SetFilter("Variant Filter", Item.GetFilter("Variant Filter"));
            if Item.GetFilter("Global Dimension 1 Filter") <> '' then
                SetFilter("Global Dimension 1 Filter", Item.GetFilter("Global Dimension 1 Filter"));
            if Item.GetFilter("Global Dimension 2 Filter") <> '' then
                SetFilter("Global Dimension 2 Filter", Item.GetFilter("Global Dimension 2 Filter"));
        end;
    end;

    var
        Text000: Label 'Period: %1';
        ItemStatisticsBuf: Record "Item Statistics Buffer";
        GLSetup: Record "General Ledger Setup";
        ItemFilter: Text;
        PeriodText: Text;
        SalesQty: Decimal;
        SalesAmount: Decimal;
        COGSAmount: Decimal;
        ItemProfit: Decimal;
        ItemProfitPct: Decimal;
        UnitPrice: Decimal;
        UnitCost: Decimal;
        PrintAlsoWithoutSale: Boolean;
        InvSalesStatisticsCaptLbl: Label 'Inventory - Sales Statistics';
        PageCaptionLbl: Label 'Page';
        IncludeNotSoldItemsCaptionLbl: Label 'This report also includes items that are not sold.';
        ItemAssemblyBOMCaptionLbl: Label 'BOM';
        UnitCostCaptionLbl: Label 'Unit Cost';
        UnitPriceCaptionLbl: Label 'Unit Price';
        SalesQtyCaptionLbl: Label 'Sales (Qty.)';
        SalesAmountCaptionLbl: Label 'Sales (LCY)';
        ItemProfitCaptionLbl: Label 'Profit';
        ItemProfitPctCaptionLbl: Label 'Profit %';
        TotalCaptionLbl: Label 'Total';

    local procedure Calculate()
    begin
        SalesQty := -CalcInvoicedQty;
        SalesAmount := CalcSalesAmount;
        COGSAmount := CalcCostAmount + CalcCostAmountNonInvnt;
        ItemProfit := SalesAmount + COGSAmount;

        if SalesAmount <> 0 then
            ItemProfitPct := Round(100 * ItemProfit / SalesAmount, 0.1)
        else
            ItemProfitPct := 0;

        UnitPrice := CalcPerUnit(SalesAmount, SalesQty);
        UnitCost := -CalcPerUnit(COGSAmount, SalesQty);
    end;

    local procedure SetFilters()
    begin
        with ItemStatisticsBuf do begin
            SetRange("Item Filter", Item."No.");
            SetRange("Item Ledger Entry Type Filter", "Item Ledger Entry Type Filter"::Sale);
            SetFilter("Entry Type Filter", '<>%1', "Entry Type Filter"::Revaluation);
        end;
    end;

    local procedure CalcSalesAmount(): Decimal
    begin
        with ItemStatisticsBuf do begin
            CalcFields("Sales Amount (Actual)");
            exit("Sales Amount (Actual)");
        end;
    end;

    local procedure CalcCostAmount(): Decimal
    begin
        with ItemStatisticsBuf do begin
            CalcFields("Cost Amount (Actual)");
            exit("Cost Amount (Actual)");
        end;
    end;

    local procedure CalcCostAmountNonInvnt(): Decimal
    begin
        with ItemStatisticsBuf do begin
            SetRange("Item Ledger Entry Type Filter");
            CalcFields("Cost Amount (Non-Invtbl.)");
            exit("Cost Amount (Non-Invtbl.)");
        end;
    end;

    local procedure CalcInvoicedQty(): Decimal
    begin
        with ItemStatisticsBuf do begin
            SetRange("Entry Type Filter");
            CalcFields("Invoiced Quantity");
            exit("Invoiced Quantity");
        end;
    end;

    local procedure CalcPerUnit(Amount: Decimal; Qty: Decimal): Decimal
    begin
        if Qty <> 0 then
            exit(Round(Amount / Abs(Qty), GLSetup."Unit-Amount Rounding Precision"));
        exit(0);
    end;
}

