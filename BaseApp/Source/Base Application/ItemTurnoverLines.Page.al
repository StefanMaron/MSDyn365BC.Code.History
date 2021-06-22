page 354 "Item Turnover Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Item Turnover Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the start date of the period defined on the line, related to year-to-date inventory turnover.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period defined on the line, related to year-to-date inventory turnover.';
                }
                field(PurchasesQty; "Purchases (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases (Qty.)';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item have been purchased. The program automatically calculates and updates the contents of the field, using the Invoiced Quantity field in the Item Ledger Entry table for those entries of the Purchase type.';

                    trigger OnDrillDown()
                    begin
                        ShowItemEntries(false);
                    end;
                }
                field(PurchasesLCY; "Purchases (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchases (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the total purchase amount, in LCY, of the item that has been purchased. The program automatically calculates and updates the contents of the field, using the Sales Amount (Actual) field in the Value Entry table for those entries that have been posted as purchases.';

                    trigger OnDrillDown()
                    begin
                        ShowValueEntries(false);
                    end;
                }
                field(SalesQty; "Sales (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales (Qty.)';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item have been sold. The program automatically calculates and updates the contents of the field, using the Invoiced Quantity field in the Item Ledger Entry table for those entries of the Sales type.';

                    trigger OnDrillDown()
                    begin
                        ShowItemEntries(true);
                    end;
                }
                field(SalesLCY; "Sales (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the sales amount, in LCY, of the item that has been sold. The program automatically calculates and updates the contents of the field, using the Sales Amount (Actual) field in the Value Entry table for those entries that have been posted as sales.';

                    trigger OnDrillDown()
                    begin
                        ShowValueEntries(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get("Period Type", "Period Start") then;
        SetDateFilter();
        CalcLine();
    end;

    local procedure CalcLine()
    begin
        Item.CalcFields("Purchases (Qty.)", "Purchases (LCY)", "Sales (Qty.)", "Sales (LCY)");
        "Purchases (Qty.)" := Item."Purchases (Qty.)";
        "Purchases (LCY)" := Item."Purchases (LCY)";
        "Sales (Qty.)" := Item."Sales (Qty.)";
        "Sales (LCY)" := Item."Sales (LCY)";

        OnAfterCalcLine(Item, Rec);
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Reset();
    end;

    var
        Item: Record Item;
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewItem: Record Item; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        Item.Copy(NewItem);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    procedure ShowItemEntries(ShowSales: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        SetDateFilter();
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ItemLedgEntry.SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        ItemLedgEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ItemLedgEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        ItemLedgEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        ItemLedgEntry.SetFilter("Posting Date", Item.GetFilter("Date Filter"));
        if ShowSales then
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale)
        else
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
        PAGE.Run(0, ItemLedgEntry);
    end;

    local procedure ShowValueEntries(ShowSales: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        SetDateFilter();
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey(
          "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type", "Item Charge No.",
          "Location Code", "Variant Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Source Type", "Source No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ValueEntry.SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        ValueEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetFilter("Posting Date", Item.GetFilter("Date Filter"));
        if ShowSales then
            ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale)
        else
            ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        PAGE.Run(0, ValueEntry);
    end;

    protected procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Item.SetRange("Date Filter", "Period Start", "Period End")
        else
            Item.SetRange("Date Filter", 0D, "Period End");
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcLine(var Item: Record Item; var ItemTurnoverBuffer: Record "Item Turnover Buffer")
    begin
    end;
}

