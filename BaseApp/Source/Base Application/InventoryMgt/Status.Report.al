report 706 Status
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryMgt/Status.rdlc';
    ApplicationArea = Basic, Suite, Advanced;
    Caption = 'Status';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.") WHERE(Type = CONST(Inventory));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
            column(AsofStatusDate; StrSubstNo(Text000, Format(StatusDate)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(CostingMethod_Item; "Costing Method")
            {
                IncludeCaption = true;
            }
            column(InvtValue; InvtValue)
            {
                AutoFormatType = 1;
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
            }
            column(StatusCaption; StatusCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(InventoryValuationCaption; InventoryValuationCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(HereofPositiveCaption; HereofPositiveCaptionLbl)
            {
            }
            column(HereofNegativeCaption; HereofNegativeCaptionLbl)
            {
            }
            column(IsAverageCostItem; IsAverageCostItem)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = FIELD("No."), "Location Code" = FIELD("Location Filter"), "Variant Code" = FIELD("Variant Filter"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                DataItemTableView = SORTING("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                column(PostingDate_ItemLedgerEntry; Format("Posting Date"))
                {
                }
                column(EntryType_ItemLedgerEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }
                column(RemainingQty; RemainingQty)
                {
                    DecimalPlaces = 0 : 2;
                }
                column(UnitCost; UnitCost)
                {
                    AutoFormatType = 2;
                }
                column(InvtValue2; InvtValue)
                {
                    AutoFormatType = 1;
                }
                column(DocumentNo_ItemLedgerEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Description2_Item; Item.Description)
                {
                }
                column(AvgCost; AvgCost)
                {
                    AutoFormatType = 2;
                }

                trigger OnAfterGetRecord()
                begin
                    if Item."Costing Method" = Item."Costing Method"::Average then
                        RemainingQty := Quantity
                    else begin
                        CalcRemainingQty();
                        if RemainingQty = 0 then
                            CurrReport.Skip();
                    end;

                    CalcUnitCost();
                    InvtValue := UnitCost * Abs(RemainingQty);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, StatusDate);
                    SetRange("Drop Shipment", false);

                    Clear(RemainingQty);
                    Clear(InvtValue);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IsAverageCostItem := "Costing Method" = "Costing Method"::Average;
            end;

            trigger OnPreDataItem()
            begin
                Clear(RemainingQty);
                Clear(InvtValue);
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
                    field(StatusDate; StatusDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status Date';
                        ToolTip = 'Specifies the status date.';

                        trigger OnValidate()
                        begin
                            if StatusDate = 0D then
                                Error(Text001);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StatusDate = 0D then
                StatusDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();

        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Posting Date", 0D, StatusDate);
            SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            SetFilter("Location Code", Item.GetFilter("Location Filter"));
            SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        end;
    end;

    var
        ValueEntry: Record "Value Entry";
        StatusDate: Date;
        ItemFilter: Text;
        InvtValue: Decimal;
        UnitCost: Decimal;
        RemainingQty: Decimal;
        AvgCost: Decimal;
        StatusCaptionLbl: Label 'Status';
        PageCaptionLbl: Label 'Page';
        UnitCostCaptionLbl: Label 'Unit Cost';
        PostingDateCaptionLbl: Label 'Posting Date';
        QuantityCaptionLbl: Label 'Quantity';
        InventoryValuationCaptionLbl: Label 'Inventory Valuation';
        TotalCaptionLbl: Label 'Total';
        HereofPositiveCaptionLbl: Label 'Hereof Positive';
        HereofNegativeCaptionLbl: Label 'Hereof Negative';
        IsAverageCostItem: Boolean;

        Text000: Label 'As of %1';
        Text001: Label 'Enter the Status Date';

    local procedure CalcRemainingQty()
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        RemainingQty := "Item Ledger Entry".Quantity;

        with ItemApplnEntry do
            if "Item Ledger Entry".Positive then begin
                Reset();
                SetCurrentKey(
                  "Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
                SetRange("Inbound Item Entry No.", "Item Ledger Entry"."Entry No.");
                SetFilter("Outbound Item Entry No.", '<>%1', 0);
                SetRange("Posting Date", 0D, StatusDate);
                if Find('-') then
                    repeat
                        SumQty(RemainingQty, "Outbound Item Entry No.", Quantity);
                    until Next() = 0;
            end else begin
                Reset();
                SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                SetRange("Outbound Item Entry No.", "Item Ledger Entry"."Entry No.");
                SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
                SetRange("Posting Date", 0D, StatusDate);
                if Find('-') then
                    repeat
                        SumQty(RemainingQty, "Inbound Item Entry No.", -Quantity);
                    until Next() = 0;
            end;
    end;

    local procedure SumQty(var RemainingQty: Decimal; EntryNo: Integer; AppliedQty: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        if (ItemLedgEntry.Quantity * AppliedQty < 0) or
           (ItemLedgEntry."Posting Date" > StatusDate)
        then
            exit;

        RemainingQty := RemainingQty + AppliedQty;
    end;

    local procedure CalcUnitCost()
    begin
        with ValueEntry do begin
            SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            UnitCost := 0;

            if Find('-') then
                repeat
                    if "Partial Revaluation" then
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", "Valued Quantity")
                    else
                        SumUnitCost(UnitCost, "Cost Amount (Actual)" + "Cost Amount (Expected)", "Item Ledger Entry".Quantity);
                until Next() = 0;
        end;
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    procedure InitializeRequest(NewStatusDate: Date)
    begin
        StatusDate := NewStatusDate;
    end;
}

