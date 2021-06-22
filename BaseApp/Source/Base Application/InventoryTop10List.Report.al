report 711 "Inventory - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryTop10List.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Top 10 List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                CalcFields("Sales (LCY)", Inventory);
                if ("Sales (LCY)" = 0) and (Inventory = 0) and not PrintAlsoIfZero then
                    CurrReport.Skip();

                ItemAmount.Init();
                ItemAmount."Item No." := "No.";
                if ShowType = ShowType::"Sales (LCY)" then begin
                    ItemAmount.Amount := "Sales (LCY)";
                    ItemAmount."Amount 2" := Inventory;
                end else begin
                    ItemAmount.Amount := Inventory;
                    ItemAmount."Amount 2" := "Sales (LCY)";
                end;
                if ShowSorting = ShowSorting::Largest then begin
                    ItemAmount.Amount := -ItemAmount.Amount;
                    ItemAmount."Amount 2" := -ItemAmount."Amount 2";
                end;
                ItemAmount.Insert();
                if (NoOfRecordsToPrint = 0) or (i < NoOfRecordsToPrint) then
                    i := i + 1
                else begin
                    ItemAmount.Find('+');
                    ItemAmount.Delete();
                end;

                TotalItemSales += "Sales (LCY)";
                TotalItemBalance += Inventory;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
                ItemAmount.DeleteAll();
                i := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(STRSUBSTNO_Text001_ItemDateFilter_; StrSubstNo(Text001, ItemDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text002_Sequence_Heading_; StrSubstNo(Text002, Sequence, Heading))
            {
            }
            column(PrintAlsoIfZero; PrintAlsoIfZero)
            {
            }
            column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo('%1: %2', Item.TableCaption, ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(STRSUBSTNO_Text003_Heading_; StrSubstNo(Text003, Heading))
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Item__No__; Item."No.")
            {
            }
            column(Item_Description; Item.Description)
            {
            }
            column(Item__Sales__LCY__; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
            }
            column(Item_Inventory; Item.Inventory)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BarText; BarText)
            {
            }
            column(Item__Sales__LCY___Control24; Item."Sales (LCY)")
            {
                AutoFormatType = 1;
            }
            column(ItemSales; ItemSales)
            {
                AutoFormatType = 1;
            }
            column(QtyOnHand; QtyOnHand)
            {
                DecimalPlaces = 0 : 5;
            }
            column(SalesAmountPct; SalesAmountPct)
            {
                AutoFormatType = 1;
                DecimalPlaces = 1 : 1;
            }
            column(QtyOnHandPct; QtyOnHandPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(TotalItemBalance; TotalItemBalance)
            {
            }
            column(TotalItemSales; TotalItemSales)
            {
            }
            column(Inventory___Top_10_ListCaption; Inventory___Top_10_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_Caption; This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl)
            {
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
            }
            column(Item__No__Caption; Item.FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; Item.FieldCaption(Description))
            {
            }
            column(Item__Sales__LCY__Caption; Item.FieldCaption("Sales (LCY)"))
            {
            }
            column(Item_InventoryCaption; Item_InventoryCaptionLbl)
            {
            }
            column(Item__Sales__LCY___Control24Caption; Item__Sales__LCY___Control24CaptionLbl)
            {
            }
            column(ItemSalesCaption; ItemSalesCaptionLbl)
            {
            }
            column(SalesAmountPctCaption; SalesAmountPctCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not ItemAmount.Find('-') then
                        CurrReport.Break();
                    if ShowSorting = ShowSorting::Largest then
                        MaxAmount := -ItemAmount.Amount
                    else begin
                        ItemAmount2 := ItemAmount;
                        if ItemAmount.Next(NoOfRecordsToPrint - 1) > 0 then;
                        MaxAmount := ItemAmount.Amount;
                        ItemAmount := ItemAmount2;
                    end;
                end else
                    if ItemAmount.Next = 0 then
                        CurrReport.Break();
                Item.Get(ItemAmount."Item No.");
                Item.CalcFields("Sales (LCY)", Inventory);
                if ShowSorting = ShowSorting::Largest then begin
                    ItemAmount.Amount := -ItemAmount.Amount;
                    ItemAmount."Amount 2" := -ItemAmount."Amount 2";
                end;
                if (MaxAmount > 0) and (ItemAmount.Amount > 0) then
                    BarText := PadStr('', Round(ItemAmount.Amount / MaxAmount * 45, 1), '*')
                else
                    BarText := '';
                if ShowSorting = ShowSorting::Largest then begin
                    ItemAmount.Amount := -ItemAmount.Amount;
                    ItemAmount."Amount 2" := -ItemAmount."Amount 2";
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Close;
                ItemSales := Item."Sales (LCY)";
                QtyOnHand := Item.Inventory;
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
                    field(ShowSorting; ShowSorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Largest,Smallest';
                        ToolTip = 'Specifies if you want a report on the items that have the highest sales; select the Smallest option if you want a report on the items that have the lowest sales.';
                    }
                    field(ShowType; ShowType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Sales (LCY),Inventory';
                        ToolTip = 'Specifies if you want a report on item sales; select the Inventory option if you want a report on the items'' inventory.';
                    }
                    field(NoOfRecordsToPrint; NoOfRecordsToPrint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the number of items to be shown in the report.';
                    }
                    field(PrintAlsoIfZero; PrintAlsoIfZero)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Items Not on Inventory or Not Sold';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want items that are not on hand or have not been sold to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrint = 0 then
                NoOfRecordsToPrint := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters;
        ItemDateFilter := Item.GetFilter("Date Filter");
        Sequence := LowerCase(Format(SelectStr(ShowSorting + 1, Text004)));
        Heading := Format(SelectStr(ShowType + 1, Text005));
    end;

    var
        Text000: Label 'Sorting items    #1##########';
        Text001: Label 'Period: %1';
        Text002: Label 'Ranked according to %1 %2';
        Text003: Label 'Portion of %1';
        ItemAmount: Record "Item Amount" temporary;
        ItemAmount2: Record "Item Amount";
        Window: Dialog;
        ItemFilter: Text;
        ItemDateFilter: Text;
        Sequence: Text[30];
        Heading: Text[30];
        ShowSorting: Option Largest,Smallest;
        ShowType: Option "Sales (LCY)",Inventory;
        NoOfRecordsToPrint: Integer;
        PrintAlsoIfZero: Boolean;
        ItemSales: Decimal;
        QtyOnHand: Decimal;
        SalesAmountPct: Decimal;
        QtyOnHandPct: Decimal;
        MaxAmount: Decimal;
        BarText: Text[50];
        i: Integer;
        Text004: Label 'Largest,Smallest';
        Text005: Label 'Sales (LCY),Inventory';
        TotalItemSales: Decimal;
        TotalItemBalance: Decimal;
        Inventory___Top_10_ListCaptionLbl: Label 'Inventory - Top 10 List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_also_includes_items_not_on_inventory_or_that_are_not_sold_CaptionLbl: Label 'This report also includes items not on inventory or that are not sold.';
        Integer_NumberCaptionLbl: Label 'Rank';
        Item_InventoryCaptionLbl: Label 'Inventory';
        Item__Sales__LCY___Control24CaptionLbl: Label 'Total';
        ItemSalesCaptionLbl: Label 'Total Sales';
        SalesAmountPctCaptionLbl: Label '% of Total Sales';

    procedure InitializeRequest(NewShowSorting: Option; NewShowType: Option; NewNoOfRecordsToPrint: Integer; NewPrintAlsoIfZero: Boolean)
    begin
        ShowSorting := NewShowSorting;
        ShowType := NewShowType;
        NoOfRecordsToPrint := NewNoOfRecordsToPrint;
        PrintAlsoIfZero := NewPrintAlsoIfZero;
    end;
}

