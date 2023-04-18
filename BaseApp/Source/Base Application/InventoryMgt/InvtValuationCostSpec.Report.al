report 5801 "Invt. Valuation - Cost Spec."
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryMgt/InvtValuationCostSpec.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Invt. Valuation - Cost Spec.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = WHERE(Type = CONST(Inventory));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(AsOfValuationDate; StrSubstNo(Text000, Format(ValuationDate)))
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(TotalCost; ResultForTotalCost)
            {
                AutoFormatType = 1;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(= 0));
                column(AvgCost; ResultForAvgCost)
                {
                    AutoFormatType = 2;
                }
                column(RemainingQty; ResultForRemainingQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(UnitCost1; ResultForUnitCost[1])
                {
                    AutoFormatType = 2;
                }
                column(UnitCost2; ResultForUnitCost[2])
                {
                    AutoFormatType = 2;
                }
                column(UnitCost3; ResultForUnitCost[3])
                {
                    AutoFormatType = 2;
                }
                column(UnitCost4; ResultForUnitCost[4])
                {
                    AutoFormatType = 2;
                }
                column(UnitCost5; ResultForUnitCost[5])
                {
                    AutoFormatType = 2;
                }
                column(TotalCostTotal1; ResultForTotalCostTotal[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalCostTotal2; ResultForTotalCostTotal[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalCostTotal3; ResultForTotalCostTotal[3])
                {
                    AutoFormatType = 1;
                }
                column(TotalCostTotal4; ResultForTotalCostTotal[4])
                {
                    AutoFormatType = 1;
                }
                column(TotalCostTotal5; ResultForTotalCostTotal[5])
                {
                    AutoFormatType = 1;
                }
                column(NoOfEntries1; NoOfEntries[1])
                {
                }
                column(NoOfEntries2; NoOfEntries[2])
                {
                }
                column(NoOfEntries3; NoOfEntries[3])
                {
                }
                column(NoOfEntries4; NoOfEntries[4])
                {
                }
                column(NoOfEntries5; NoOfEntries[5])
                {
                }
                column(EntryTypeDescription1; EntryTypeDescription[1])
                {
                }
                column(EntryTypeDescription2; EntryTypeDescription[2])
                {
                }
                column(EntryTypeDescription3; EntryTypeDescription[3])
                {
                }
                column(EntryTypeDescription4; EntryTypeDescription[4])
                {
                }
                column(EntryTypeDescription5; EntryTypeDescription[5])
                {
                }

                trigger OnAfterGetRecord()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                begin
                    ClearTotals();

                    ItemLedgerEntry.SetFilter("Item No.", Item."No.");
                    ItemLedgerEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    ItemLedgerEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));

                    ItemLedgerEntry.SetRange("Posting Date", 0D, ValuationDate);
                    ItemLedgerEntry.SetRange("Drop Shipment", false);
                    if not ItemLedgerEntry.FindSet() then
                        CurrReport.Break();

                    repeat
                        ClearBufferVariables();

                        IsPositive := GetSign(ItemLedgerEntry);
                        CalcRemainingQty(ItemLedgerEntry);
                        CalcUnitCost(ItemLedgerEntry);
                        for i := 1 to ArrayLen(TotalCostTotal) do begin
                            TotalCostTotal[i] := TotalCostTotal[i] * Abs(RemainingQty);
                            TotalCost := TotalCost + TotalCostTotal[i];
                            TotalCostAvg[i] += TotalCostTotal[i];
                        end;
                        TotalRemAvg += RemainingQty;

                        IncrTotals();
                    until ItemLedgerEntry.Next() = 0;

                    CalcAvgCost();
                end;
            }
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
                    field(ValuationDate; ValuationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Valuation Date';
                        ToolTip = 'Specifies the valuation date from which the entry is included in the average cost calculation.';

                        trigger OnValidate()
                        begin
                            if ValuationDate = 0D then
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
            if ValuationDate = 0D then
                ValuationDate := WorkDate();
        end;
    }

    labels
    {
        InventoryValuationCostSpecificationCaption = 'Inventory Valuation - Cost Specification';
        PageCaption = 'Page';
        OfCaption = 'of';
        RemainingQtyCaption = 'Quantity';
        CostPerUnitCaption = 'Cost per Unit';
        AmountCaption = 'Amount';
        EntryTypeCaption = 'Entry Type';
        TotalCaption = 'Total';
        ItemCaption = 'Item';
        DescriptionCaption = 'Description';
    }

    trigger OnPreReport()
    begin
        if ValuationDate = 0D then
            ValuationDate := WorkDate();

        for i := 1 to ArrayLen(EntryTypeDescription) do begin
            ValueEntry."Entry Type" := "Cost Entry Type".FromInteger(i - 1);
            EntryTypeDescription[i] := Format(ValueEntry."Entry Type");
        end;

        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Posting Date", 0D, ValuationDate);
            SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            SetFilter("Location Code", Item.GetFilter("Location Filter"));
            SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        end;
    end;

    var
        ValueEntry: Record "Value Entry";
        EntryTypeDescription: array[5] of Text[30];
        i: Integer;
        NoOfEntries: array[5] of Decimal;
        PosQty: Decimal;
        RemainingQty: Decimal;
        TotalCostTotal: array[5] of Decimal;
        TotalRemAvg: Decimal;
        TotalCostAvg: array[5] of Decimal;
        TotalCost: Decimal;
        ValuationDate: Date;
        IsPositive: Boolean;
        ResultForTotalCostTotal: array[5] of Decimal;
        ResultForUnitCost: array[5] of Decimal;
        ResultForTotalCostAvg: array[5] of Decimal;
        ResultForTotalRemAvg: Decimal;
        ResultForTotalCost: Decimal;
        ResultForRemainingQty: Decimal;
        ResultForAvgCost: Decimal;

        Text000: Label 'As of %1';
        Text001: Label 'Enter the valuation date.';

    local procedure CalcRemainingQty(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        RemainingQty := ItemLedgerEntry.Quantity;
        if IsPositive then
            PosQty := ItemLedgerEntry.Quantity;

        with ItemApplnEntry do
            if ItemLedgerEntry.Positive then begin
                Reset();
                SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
                SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
                SetFilter("Outbound Item Entry No.", '<>%1', 0);
                SetRange("Posting Date", 0D, ValuationDate);
                if Find('-') then
                    repeat
                        SumQty(RemainingQty, PosQty, "Outbound Item Entry No.", Quantity);
                    until Next() = 0;
            end else begin
                Reset();
                SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
                SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                SetRange("Posting Date", 0D, ValuationDate);
                if Find('-') then
                    repeat
                        SumQty(RemainingQty, PosQty, "Inbound Item Entry No.", -Quantity);
                    until Next() = 0;
            end;

        if IsPositive then
            PosQty := RemainingQty;
    end;

    local procedure SumQty(var RemainingQty: Decimal; var PosQty: Decimal; EntryNo: Integer; AppliedQty: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        if (ItemLedgEntry.Quantity * AppliedQty < 0) or
           (ItemLedgEntry."Posting Date" > ValuationDate)
        then
            exit;

        RemainingQty := RemainingQty + AppliedQty;
        if IsPositive then
            PosQty := PosQty + AppliedQty;
    end;

    local procedure CalcUnitCost(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        with ValueEntry do begin
            SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            if Find('-') then
                repeat
                    if "Partial Revaluation" then
                        SumUnitCost(TotalCostTotal["Entry Type".AsInteger() + 1],
                          "Cost Amount (Actual)" + "Cost Amount (Expected)", "Valued Quantity")
                    else
                        SumUnitCost(TotalCostTotal["Entry Type".AsInteger() + 1],
                          "Cost Amount (Actual)" + "Cost Amount (Expected)", ItemLedgerEntry.Quantity);
                    NoOfEntries["Entry Type".AsInteger() + 1] := 1;
                until Next() = 0;
        end;
    end;

    local procedure CalcAvgCost()
    begin
        for i := 1 to ArrayLen(NoOfEntries) do begin
            if ResultForTotalRemAvg <> 0 then
                ResultForUnitCost[i] := ResultForTotalCostAvg[i] / Abs(ResultForTotalRemAvg)
            else
                ResultForUnitCost[i] := 0;
            ResultForAvgCost += ResultForUnitCost[i];
        end;
    end;

    local procedure GetSign(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do
            case "Entry Type" of
                "Entry Type"::Purchase,
              "Entry Type"::"Positive Adjmt.",
              "Entry Type"::Output,
              "Entry Type"::"Assembly Output":
                    exit(true);
                "Entry Type"::Transfer:
                    begin
                        if not Positive then
                            exit(false);
                        ItemLedgEntry.CopyFilters(ItemLedgerEntry);
                        ItemLedgEntry."Entry No." := "Entry No." - 1;
                        exit(ItemLedgEntry.IsEmpty());
                    end;
                else
                    exit(false)
            end;
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    procedure InitializeRequest(NewValuationDate: Date)
    begin
        ValuationDate := NewValuationDate;
    end;

    local procedure ClearTotals()
    begin
        Clear(NoOfEntries);
        Clear(ResultForTotalCostTotal);
        Clear(ResultForUnitCost);
        Clear(ResultForTotalCostAvg);
        ResultForTotalRemAvg := 0;
        ResultForTotalCost := 0;
        ResultForRemainingQty := 0;
        ResultForAvgCost := 0;
    end;

    local procedure ClearBufferVariables()
    begin
        Clear(TotalCostTotal);
        Clear(TotalCostAvg);
        TotalRemAvg := 0;
        TotalCost := 0;
        RemainingQty := 0;
    end;

    local procedure IncrTotals()
    begin
        for i := 1 to ArrayLen(TotalCostTotal) do begin
            ResultForTotalCostTotal[i] += TotalCostTotal[i];
            ResultForTotalCostAvg[i] += TotalCostAvg[i];
        end;

        ResultForTotalRemAvg += TotalRemAvg;
        ResultForTotalCost += TotalCost;
        ResultForRemainingQty += RemainingQty;
    end;
}

