report 716 "Inventory Cost and Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryCostandPriceList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Cost and Price List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ItemFilterCopyCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(InventPostingGr_Item; "Inventory Posting Group")
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_Item; Description)
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(AverageCost; AverageCost)
            {
                AutoFormatType = 1;
            }
            column(StandardCost_Item; "Standard Cost")
            {
                IncludeCaption = true;
            }
            column(LastDirectCost_Item; "Last Direct Cost")
            {
                IncludeCaption = true;
            }
            column(UnitPrice_Item; "Unit Price")
            {
                IncludeCaption = true;
            }
            column(Profit_Item; "Profit %")
            {
                DecimalPlaces = 1 : 1;
                IncludeCaption = true;
            }
            column(UnitPriceUnitCost_Item; "Unit Price" - "Unit Cost")
            {
            }
            column(UseStockkeepingUnitBody; UseStockkeepingUnit)
            {
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(InvCostAndPriceListCaption; InvCostAndPriceListCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(BOMCaption; BOMCaptionLbl)
            {
            }
            column(AvgCostCaption; AvgCostCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(LastDirCostCaption; LastDirCostCaptionLbl)
            {
            }
            column(LocationCodeCaption; LocationCodeCaptionLbl)
            {
            }
            column(VariantCodeCaption; VariantCodeCaptionLbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = FIELD("No."), "Location Code" = FIELD("Location Filter"), "Variant Code" = FIELD("Variant Filter");
                DataItemTableView = SORTING("Item No.", "Location Code", "Variant Code");
                column(ItemUnitPriceUnitCostDiff; Item."Unit Price" - Item."Unit Cost")
                {
                }
                column(LastDirCost_StockKeepingUnit; "Last Direct Cost")
                {
                }
                column(StandardCost_StockKeepingUnit; "Standard Cost")
                {
                }
                column(AverageCost_StockKeepingUnit; AverageCost)
                {
                    AutoFormatType = 1;
                }
                column(ItemBaseUOM; Item."Base Unit of Measure")
                {
                }
                column(ItemAssemblyBOM; Format(Item."Assembly BOM"))
                {
                }
                column(LocationCode_StockKeepingUnit; "Location Code")
                {
                }
                column(VariantCode_StockKeepingUnit; "Variant Code")
                {
                }
                column(UseStockkeepingUnit; UseStockkeepingUnit)
                {
                }
                column(SKUPrintLoop; SKUPrintLoop)
                {
                }

                trigger OnAfterGetRecord()
                var
                    Item2: Record Item;
                begin
                    SKUPrintLoop := SKUPrintLoop + 1;
                    if Item2.Get("Item No.") then begin
                        Item2.SetFilter("Location Filter", "Location Code");
                        Item2.SetFilter("Variant Filter", "Variant Code");
                        ItemCostMgt.CalculateAverageCost(Item2, AverageCost, AverageCostACY);
                        AverageCost := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not UseStockkeepingUnit then
                        CurrReport.Break;

                    SKUPrintLoop := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemCostMgt.CalculateAverageCost(Item, AverageCost, AverageCostACY);
                AverageCost := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
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
                    field(UseStockkeepingUnit; UseStockkeepingUnit)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want the report to be based on stockkeeping units rather than items.';
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
        ItemFilter := Item.GetFilters;
        GetGLSetup;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemCostMgt: Codeunit ItemCostManagement;
        ItemFilter: Text;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        GLSetupRead: Boolean;
        UseStockkeepingUnit: Boolean;
        SKUPrintLoop: Integer;
        InvCostAndPriceListCaptionLbl: Label 'Inventory Cost and Price List';
        PageNoCaptionLbl: Label 'Page';
        BOMCaptionLbl: Label 'BOM';
        AvgCostCaptionLbl: Label 'Average Cost';
        ProfitCaptionLbl: Label 'Profit';
        LastDirCostCaptionLbl: Label 'Last Direct Cost';
        LocationCodeCaptionLbl: Label 'Location Code';
        VariantCodeCaptionLbl: Label 'Variant Code';

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    procedure InitializeRequest(NewUseStockkeepingUnit: Boolean)
    begin
        UseStockkeepingUnit := NewUseStockkeepingUnit;
    end;
}

