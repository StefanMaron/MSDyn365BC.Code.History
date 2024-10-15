report 11517 "Inventory Value (Help Report)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryValueHelpReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Value (Help Report)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(HeaderData; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(DateToday; Format(Today, 0, 4))
            {
            }
            column(DateStatus; Format(StatusDate))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ItemFilterInfo; Item.TableCaption + ': ' + ItemFilter)
            {
            }
        }
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
            column(CostAmountTotal; ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)")
            {
            }
            column(CostAmountExpected; ValueEntry."Cost Amount (Expected)")
            {
            }
            column(CostAmountActual; ValueEntry."Cost Amount (Actual)")
            {
            }
            column(InvoicedQuantity; ValueEntry."Invoiced Quantity")
            {
            }
            column(CostPostedtoGL; ValueEntry."Cost Posted to G/L")
            {
            }
            column(ItemNo; "No.")
            {
                IncludeCaption = true;
            }
            column(ItemDescription; Description)
            {
                IncludeCaption = true;
            }
            column(ItemNetChange; "Net Change")
            {
                IncludeCaption = true;
            }

            trigger OnAfterGetRecord()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                SetRange("Date Filter", 0D, StatusDate);
                CalcFields("Net Change");
                ValueEntry.Init();

                ItemLedgEntry.SetRange("Item No.", "No.");
                ItemLedgEntry.SetFilter("Variant Code", GetFilter("Variant Filter"));
                ItemLedgEntry.SetFilter("Location Code", GetFilter("Location Filter"));
                ItemLedgEntry.SetFilter("Global Dimension 1 Code", GetFilter("Global Dimension 1 Filter"));
                ItemLedgEntry.SetFilter("Global Dimension 2 Code", GetFilter("Global Dimension 2 Filter"));

                if ItemLedgEntry.IsEmpty() then
                    CurrReport.Skip();

                if ItemLedgEntry.FindSet then
                    repeat
                        CalcInventoryValue(ItemLedgEntry);
                    until ItemLedgEntry.Next() = 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(PostingGroupCode; TempItemStatisticsBuffer.Code)
            {
            }
            column(PostingGroupInvValuationActual; TempItemStatisticsBuffer."Inv. Valuation Actual")
            {
            }
            column(PostingGroupInvValuationExp; TempItemStatisticsBuffer."Inv. Valuation Exp.")
            {
            }
            column(PostingGroupInvValuationTotal; TempItemStatisticsBuffer."Inv. Valuation Exp." + TempItemStatisticsBuffer."Inv. Valuation Actual")
            {
            }
            column(PostingGroupInvPostedtoGL; TempItemStatisticsBuffer."Inv. Posted to GL")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not FirstLoop then
                    if TempItemStatisticsBuffer.Next() = 0 then
                        CurrReport.Break();

                FirstLoop := false;
            end;

            trigger OnPreDataItem()
            begin
                FirstLoop := true;
                if not TempItemStatisticsBuffer.FindSet then
                    CurrReport.Break();
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
                        ToolTip = 'Specifies the last date inventory was counted.';

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
                StatusDate := WorkDate;
        end;
    }

    labels
    {
        StatusCaptionLbl = 'Status';
        PageNoCaptionLbl = 'Page %1 of %2';
        CostExpectedCaptionLbl = 'Cost Amount (Expected)';
        CostActualCaptionLbl = 'Cost Amount (Actual)';
        CostTotalCaptionLbl = 'Cost Amount (Total)';
        InvoicedQuantityCaptionLbl = 'Invoiced Quantity';
        CostPostedToGLCaptionLbl = 'Cost Posted to G/L';
        TotalCaptionLbl = 'Total';
        RecapitulationPerInventoryPostingGroupCaptionLbl = 'Recapitulation per Inventory Posting Group';
        AsOfCaptionLbl = 'As of %1';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters;
    end;

    var
        Text001: Label 'Enter the Status Date';
        ValueEntry: Record "Value Entry";
        TempItemStatisticsBuffer: Record "Item Statistics Buffer" temporary;
        StatusDate: Date;
        ItemFilter: Text[250];
        FirstLoop: Boolean;

    [Scope('OnPrem')]
    procedure CalcInventoryValue(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry2: Record "Value Entry";
        BufferRecExists: Boolean;
    begin
        with ValueEntry2 do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
            SetRange("Posting Date", 0D, StatusDate);

            if FindLast then begin
                CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)", "Invoiced Quantity", "Cost Posted to G/L");

                BufferRecExists := TempItemStatisticsBuffer.Get("Inventory Posting Group");
                if not BufferRecExists then begin
                    TempItemStatisticsBuffer.Init();
                    TempItemStatisticsBuffer.Code := "Inventory Posting Group";
                end;

                TempItemStatisticsBuffer."Inv. Valuation Actual" += "Cost Amount (Actual)";
                TempItemStatisticsBuffer."Inv. Posted to GL" += "Cost Posted to G/L";
                TempItemStatisticsBuffer."Inv. Valuation Exp." += "Cost Amount (Expected)";
                ValueEntry."Cost Amount (Actual)" += "Cost Amount (Actual)";
                ValueEntry."Cost Amount (Expected)" += "Cost Amount (Expected)";
                ValueEntry."Cost Posted to G/L" += "Cost Posted to G/L";
                ValueEntry."Invoiced Quantity" += "Invoiced Quantity";

                OnBeforeUpdateTempItemStatisticsBuffer(TempItemStatisticsBuffer, ValueEntry, ValueEntry2, ItemLedgEntry);

                if BufferRecExists then
                    TempItemStatisticsBuffer.Modify
                else
                    TempItemStatisticsBuffer.Insert();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTempItemStatisticsBuffer(var TempItemStatisticsBuffer: Record "Item Statistics Buffer"; var ValueEntry: Record "Value Entry"; var ValueEntry2: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry");
    begin
    end;
}

