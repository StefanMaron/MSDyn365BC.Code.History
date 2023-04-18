report 5848 "Cost Shares Breakdown"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/CostSharesBreakdown.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Cost Shares Breakdown';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = WHERE(Type = CONST(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group";
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = FIELD("No.");
                DataItemTableView = SORTING("Item No.");

                trigger OnAfterGetRecord()
                begin
                    CalcRemainingQty("Item Ledger Entry");
                    if RemainingQty = 0 then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate <> 0D then begin
                        SetRange("Posting Date", 0D, EndDate);
                        SetRange("Drop Shipment", false);
                    end;

                    if Find('-') then begin
                        SetRange("Posting Date");
                        SetRange("Drop Shipment");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Costing Method" = "Costing Method"::Average then
                    CurrReport.Skip();
            end;
        }
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = WHERE(Status = FILTER(Released ..));
            dataitem("Capacity Ledger Entry"; "Capacity Ledger Entry")
            {
                DataItemLink = "Order No." = FIELD("No.");
                DataItemTableView = SORTING("Order Type", "Order No.", "Order Line No.") WHERE("Order Type" = CONST(Production));

                trigger OnAfterGetRecord()
                begin
                    InsertCapLedgEntryCostShare("Capacity Ledger Entry");
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate <> 0D then
                        SetRange("Posting Date", StartDate, EndDate)
                    else
                        SetFilter("Posting Date", '>=%1', StartDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if CostSharePrint <> CostSharePrint::"WIP Inventory" then
                    CurrReport.Break();
            end;
        }
        dataitem(PrintHeader; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            PrintOnlyIfDetail = true;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CostSharePrint; CostSharePrint)
            {
                OptionCaption = 'Sales,Inventory,WIP Inventory';
                OptionMembers = Sales,Inventory,"WIP Inventory";
            }
            column(TableCaptionItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(TableCaptionProdOrderFilter; "Production Order".TableCaption + ': ' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Number_PrintHeader; Number)
            {
            }
            column(FdCaptSubcontracted; TempCostShareBuffer.FieldCaption(Subcontracted))
            {
            }
            column(CostShareBufNewMaterial; TempCostShareBuffer."New Material")
            {
            }
            column(CostShareBufNewCapacity; TempCostShareBuffer."New Capacity")
            {
            }
            column(CostShareBufNewCapOverhd; TempCostShareBuffer."New Capacity Overhead")
            {
            }
            column(CostShareBufNewMatrlOverhd; TempCostShareBuffer."New Material Overhead")
            {
            }
            column(Subcontracted; TempCostShareBuffer."New Subcontracted")
            {
            }
            column(CostShareBufNewVar; TempCostShareBuffer."New Variance")
            {
            }
            column(CostShareBufNewRevaluation; TempCostShareBuffer."New Revaluation")
            {
            }
            column(CostShareBufNewRounding; TempCostShareBuffer."New Rounding")
            {
            }
            column(Total; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
            {
            }
            column(CostShareBufNewPurchaseVar; TempCostShareBuffer."New Purchase Variance")
            {
            }
            column(CostShareBufNewMaterialVar; TempCostShareBuffer."New Material Variance")
            {
            }
            column(CostShareBufNewCpctyVar; TempCostShareBuffer."New Capacity Variance")
            {
            }
            column(CostShareBufNewCapOverHdVar; TempCostShareBuffer."New Capacity Overhead Variance")
            {
            }
            column(CostShareBufNewMfgOverheadVar; TempCostShareBuffer."New Mfg. Overhead Variance")
            {
            }
            column(NewSubcontracted; TempCostShareBuffer."New Subcontracted Variance")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CostShareBufDocumentNoCaption; CostShareBufDocumentNoCaptionLbl)
            {
            }
            column(CostShareBufDescriptionCaption; CostShareBufDescriptionCaptionLbl)
            {
            }
            column(CostShareBufNewQuantityCaption; CostShareBufNewQuantityCaptionLbl)
            {
            }
            column(CostShareBufNewMatrlCaption; CostShareBufNewMatrlCaptionLbl)
            {
            }
            column(CapacityDirCostAppCaption; CapacityDirCostAppCaptionLbl)
            {
            }
            column(CapacityOverheadCaption; CapacityOverheadCaptionLbl)
            {
            }
            column(MaterialOverheadCaption; MaterialOverheadCaptionLbl)
            {
            }
            column(VarianceCaption; VarianceCaptionLbl)
            {
            }
            column(RevaluationCaption; RevaluationCaptionLbl)
            {
            }
            column(RoundingCaption; RoundingCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(VarBreakdownCaption; VarBreakdownCaptionLbl)
            {
            }
            dataitem(PrintInvtCostShareBuf; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CostShareBufDescription; TempCostShareBuffer.Description)
                {
                }
                column(CostShareBufItemNo; TempCostShareBuffer."Item No.")
                {
                }
                column(Number_PrntInvtCostSharBufNo; Number)
                {
                }
                column(ShowDetails; ShowDetails)
                {
                }
                column(TotalPrintInvtCostShareBuf; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
                {
                }
                column(CostShareBufDocumentNo; TempCostShareBuffer."Document No.")
                {
                }
                column(NewMatrl_PrintInvCstShrBuf; TempCostShareBuffer."New Material")
                {
                }
                column(NewCap_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity")
                {
                }
                column(NewCapOvrHd_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Overhead")
                {
                }
                column(NewMatOvrHd_PrintInvCstShrBuf; TempCostShareBuffer."New Material Overhead")
                {
                }
                column(Subcontrt_PrintInvCstShrBuf; TempCostShareBuffer."New Subcontracted")
                {
                }
                column(NewVar_PrintInvCstShrBuf; TempCostShareBuffer."New Variance")
                {
                }
                column(NewReval_PrintInvCstShrBuf; TempCostShareBuffer."New Revaluation")
                {
                }
                column(NewRounding_PrintInvCstShrBuf; TempCostShareBuffer."New Rounding")
                {
                }
                column(CostShareBufNewQuantity; TempCostShareBuffer."New Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(NewPurchVar_PrintInvCstShrBuf; TempCostShareBuffer."New Purchase Variance")
                {
                }
                column(NewMatrlVar_PrintInvCstShrBuf; TempCostShareBuffer."New Material Variance")
                {
                }
                column(NewCapVar_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Variance")
                {
                }
                column(NwCapOvHdVar_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Overhead Variance")
                {
                }
                column(NwMfgOvrhdVar_PrintInvCstShrBuf; TempCostShareBuffer."New Mfg. Overhead Variance")
                {
                }
                column(CostShareBufNewSubcontractedVar; TempCostShareBuffer."New Subcontracted Variance")
                {
                }
                column(TotalCostVariance; TempCostShareBuffer."New Purchase Variance" + TempCostShareBuffer."New Material Variance" + TempCostShareBuffer."New Capacity Variance" + TempCostShareBuffer."New Capacity Overhead Variance" + TempCostShareBuffer."New Mfg. Overhead Variance" + TempCostShareBuffer."New Subcontracted Variance")
                {
                }
                column(TotalCost; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
                {
                }
                column(SrvTrPrintInvtCostShareBufFtr4; SrvTrPrintInvtCostShareBufFtr4())
                {
                }
                column(SrvTrPrintInvtCostShareBufFtr5; SrvTrPrintInvtCostShareBufFtr5())
                {
                }

                trigger OnAfterGetRecord()
                var
                    TempItem: Record Item temporary;
                    InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
                begin
                    if Number = 1 then begin
                        if not TempCostShareBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempCostShareBuffer.Next() = 0 then
                            CurrReport.Break();

                    if TempCostShareBuffer."Posting Date" > EndDate then
                        CurrReport.Skip();

                    case CostSharePrint of
                        CostSharePrint::Sales:
                            begin
                                TempCostShareBuffer."New Revaluation" := TempCostShareBuffer."New Revaluation" - TempCostShareBuffer.Revaluation;
                                TempCostShareBuffer."New Quantity" := TempCostShareBuffer.Quantity;
                            end;
                        CostSharePrint::Inventory:
                            if TempCostShareBuffer."New Quantity" = 0 then
                                CurrReport.Skip();
                        CostSharePrint::"WIP Inventory":
                            begin
                                if InvtAdjmtEntryOrder.Get(TempCostShareBuffer."Order Type", TempCostShareBuffer."Order No.", TempCostShareBuffer."Order Line No.") then begin
                                    Item.Get(InvtAdjmtEntryOrder."Item No.");
                                    TempItem := Item;
                                    TempItem.Insert();
                                    TempItem.CopyFilters(Item);
                                    if TempItem.IsEmpty() then
                                        CurrReport.Skip();
                                end;

                                if TempCostShareBuffer."Entry Type" = TempCostShareBuffer."Entry Type"::" " then begin
                                    TempCostShareBuffer."New Direct Cost" := -TempCostShareBuffer."New Direct Cost";
                                    TempCostShareBuffer."New Indirect Cost" := -TempCostShareBuffer."New Indirect Cost";
                                    TempCostShareBuffer."New Revaluation" := -TempCostShareBuffer."New Revaluation";
                                    TempCostShareBuffer."New Rounding" := -TempCostShareBuffer."New Rounding";
                                    TempCostShareBuffer."New Variance" := -TempCostShareBuffer."New Variance";
                                    TempCostShareBuffer."New Purchase Variance" := -TempCostShareBuffer."New Purchase Variance";
                                    TempCostShareBuffer."New Material Variance" := -TempCostShareBuffer."New Material Variance";
                                    TempCostShareBuffer."New Capacity Variance" := -TempCostShareBuffer."New Capacity Variance";
                                    TempCostShareBuffer."New Capacity Overhead Variance" := -TempCostShareBuffer."New Capacity Overhead Variance";
                                    TempCostShareBuffer."New Mfg. Overhead Variance" := -TempCostShareBuffer."New Mfg. Overhead Variance";
                                    TempCostShareBuffer."New Subcontracted Variance" := -TempCostShareBuffer."New Subcontracted Variance";
                                    TempCostShareBuffer."New Material" := -TempCostShareBuffer."New Material";
                                    TempCostShareBuffer."New Capacity" := -TempCostShareBuffer."New Capacity";
                                    TempCostShareBuffer."New Capacity Overhead" := -TempCostShareBuffer."New Capacity Overhead";
                                    TempCostShareBuffer."New Material Overhead" := -TempCostShareBuffer."New Material Overhead";
                                    TempCostShareBuffer."New Subcontracted" := -TempCostShareBuffer."New Subcontracted";
                                end;
                                TempCostShareBuffer."New Variance" := TempCostShareBuffer."New Variance" - TempCostShareBuffer.Variance;
                                TempCostShareBuffer."New Purchase Variance" := TempCostShareBuffer."New Purchase Variance" - TempCostShareBuffer."Purchase Variance";
                                TempCostShareBuffer."New Material Variance" := TempCostShareBuffer."New Material Variance" - TempCostShareBuffer."Material Variance";
                                TempCostShareBuffer."New Capacity Variance" := TempCostShareBuffer."New Capacity Variance" - TempCostShareBuffer."Capacity Variance";
                                TempCostShareBuffer."New Capacity Overhead Variance" :=
                                  TempCostShareBuffer."New Capacity Overhead Variance" - TempCostShareBuffer."Capacity Overhead Variance";
                                TempCostShareBuffer."New Mfg. Overhead Variance" := TempCostShareBuffer."New Mfg. Overhead Variance" -
                                  TempCostShareBuffer."Mfg. Overhead Variance";
                                TempCostShareBuffer."New Subcontracted Variance" := TempCostShareBuffer."New Subcontracted Variance" -
                                  TempCostShareBuffer."Subcontracted Variance";
                            end;
                    end;

                    if Number = 1 then
                        if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                            if ItemPrint.Get(TempCostShareBuffer."Item No.") then begin
                                TempCostShareBuffer."Item No." := ItemPrint."No.";
                                TempCostShareBuffer.Description := ItemPrint.Description;
                            end;
                        end else
                            if (TempCostShareBuffer."Order Type" = TempCostShareBuffer."Order Type"::Production) and
                               (ProdOrderPrint.Get(ProdOrderPrint.Status::Finished, TempCostShareBuffer."Order No.") or
                                ProdOrderPrint.Get(ProdOrderPrint.Status::Released, TempCostShareBuffer."Order No."))
                            then begin
                                TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
                                TempCostShareBuffer.Description := ProdOrderPrint.Description;
                                TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
                            end;
                end;

                trigger OnPreDataItem()
                begin
                    if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                        TempCostShareBuffer.SetCurrentKey("Item No.");
                        TempCostShareBuffer.SetRange("Item No.", ItemPrint."No.");
                        if CostSharePrint = CostSharePrint::Sales then begin
                            TempCostShareBuffer.SetRange("Entry Type", TempCostShareBuffer."Entry Type"::Sale);
                            if EndDate = 0D then
                                EndDate := DMY2Date(31, 12, 9998);
                            TempCostShareBuffer.SetRange("Posting Date", StartDate, EndDate)
                        end;
                    end else begin
                        TempCostShareBuffer.SetCurrentKey("Order Type", "Order No.");
                        TempCostShareBuffer.SetRange("Order Type", TempCostShareBuffer."Order Type"::Production);
                        TempCostShareBuffer.SetRange("Order No.", ProdOrderPrint."No.");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                case CostSharePrint of
                    CostSharePrint::Sales, CostSharePrint::Inventory:
                        if Number = 1 then begin
                            if not ItemPrint.Find('-') then
                                CurrReport.Break();
                        end else
                            if ItemPrint.Next() = 0 then
                                CurrReport.Break();
                    CostSharePrint::"WIP Inventory":
                        if Number = 1 then begin
                            if not ProdOrderPrint.Find('-') then
                                CurrReport.Break();
                        end else
                            if ProdOrderPrint.Next() = 0 then
                                CurrReport.Break();
                end;

                TempCostShareBuffer.Reset();
                if not TempCostShareBuffer.Find('-') then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                    ItemPrint.CopyFilters(Item);
                    ItemPrint.SetCurrentKey("Inventory Posting Group");
                end else
                    ProdOrderPrint.CopyFilters("Production Order");
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date from which you want the information in the report to be taken. If you leave this field blank, the program includes all information up to the ending date that you specify in the Ending Date field.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date from which you want the information in the report to be taken. If left blank, the program includes all information from the starting date to the present time.';
                    }
                    field(CostSharePrint; CostSharePrint)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Print Cost Share ';
                        OptionCaption = 'Sales,Inventory,WIP Inventory';
                        ToolTip = 'Specifies that cost share information is included on printouts of the report. ';
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want to see a detailed breakdown of where the cost comes from for each item.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) and (EndDate = 0D) then
                EndDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (StartDate = 0D) and (EndDate = 0D) then
            EndDate := WorkDate();

        case true of
            (StartDate <> 0D) and (EndDate <> 0D):
                Item.SetRange("Date Filter", StartDate, EndDate);
            (StartDate <> 0D):
                Item.SetFilter("Date Filter", '%1..', StartDate);
            else
                Item.SetRange("Date Filter", 0D, EndDate);
        end;

        ItemFilter := Item.GetFilters();
        ProdOrderFilter := "Production Order".GetFilters();

        TempCostShareBuffer.Reset();
        TempCostShareBuffer.DeleteAll();
    end;

    var
        ItemPrint: Record Item;
        ProdOrderPrint: Record "Production Order";
        TempCostShareBuffer: Record "Cost Share Buffer" temporary;
        ItemFilter: Text;
        ProdOrderFilter: Text;
        RemainingQty: Decimal;
        CostSharePrint: Option Sales,Inventory,"WIP Inventory";
        StartDate: Date;
        EndDate: Date;
        ShowDetails: Boolean;
        CurrReportPageNoCaptionLbl: Label 'Page';
        CostShareBufDocumentNoCaptionLbl: Label 'No.';
        CostShareBufDescriptionCaptionLbl: Label 'Description';
        CostShareBufNewQuantityCaptionLbl: Label 'Quantity';
        CostShareBufNewMatrlCaptionLbl: Label 'Material Direct Cost Applied';
        CapacityDirCostAppCaptionLbl: Label 'Capacity Direct Cost Applied';
        CapacityOverheadCaptionLbl: Label 'Capacity Overhead';
        MaterialOverheadCaptionLbl: Label 'Material Overhead';
        VarianceCaptionLbl: Label 'Variance';
        RevaluationCaptionLbl: Label 'Revaluation';
        RoundingCaptionLbl: Label 'Rounding';
        TotalCaptionLbl: Label 'Total';
        VarBreakdownCaptionLbl: Label 'Variance Breakdown';

    local procedure CalcRemainingQty(FromItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        RemainingQty := FromItemLedgEntry.Quantity;

        with ItemApplnEntry do
            if FromItemLedgEntry.Positive then begin
                if TempCostShareBuffer.Get(FromItemLedgEntry."Entry No.") then
                    exit;
                if not AppliedFromEntryExists(FromItemLedgEntry."Entry No.") then
                    if ForwardToAppliedOutbndEntry(FromItemLedgEntry."Entry No.") then
                        exit;
            end;

        if (FromItemLedgEntry."Posting Date" > EndDate) and (EndDate <> 0D) then
            exit;

        if not TempCostShareBuffer.Get(FromItemLedgEntry."Entry No.") then
            InsertItemLedgEntryCostShare(FromItemLedgEntry);
    end;

    local procedure ForwardToAppliedOutbndEntry(EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with ItemApplnEntry do
            if AppliedOutbndEntryExists(EntryNo, true, false) then begin
                ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, false);
                exit(true);
            end;
        exit(false);
    end;

    local procedure ForwardToAppliedInbndEntry(EntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with ItemApplnEntry do
            if AppliedInbndEntryExists(EntryNo, true) then
                ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, true);
    end;

    local procedure ForwardToInbndTranEntry(EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with ItemApplnEntry do
            if AppliedInbndTransEntryExists(EntryNo, true) then begin
                ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, true);
                exit(true);
            end;
        exit(false);
    end;

    local procedure ForwardItemLedgEntryCostShare(var ItemApplnEntry: Record "Item Application Entry"; EntryNo: Integer; IsInBound: Boolean)
    var
        FromItemLedgEntry: Record "Item Ledger Entry";
        ToItemLedgEntry: Record "Item Ledger Entry";
        FromCostShareBuffer: Record "Cost Share Buffer";
        ToCostShareBuffer: Record "Cost Share Buffer";
        ToEntryNo: Integer;
        CostShare: Decimal;
        AppliedQty: Decimal;
    begin
        repeat
            if not TempCostShareBuffer.Get(EntryNo) then begin
                FromItemLedgEntry.Get(EntryNo);
                if FromItemLedgEntry."Posting Date" > EndDate then
                    exit;
                InsertItemLedgEntryCostShare(FromItemLedgEntry);
            end;
            FromCostShareBuffer := TempCostShareBuffer;
            if IsInBound then
                ToEntryNo := ItemApplnEntry."Inbound Item Entry No."
            else
                ToEntryNo := ItemApplnEntry."Outbound Item Entry No.";

            ToItemLedgEntry.Get(ToEntryNo);
            if not TempCostShareBuffer.Get(ToEntryNo) then
                InsertItemLedgEntryCostShare(ToItemLedgEntry);

            ToCostShareBuffer := TempCostShareBuffer;
            if (ToCostShareBuffer."Posting Date" <= EndDate) or (EndDate = 0D) then begin
                if (EndDate = 0D) or (ToItemLedgEntry."Posting Date" <= EndDate) and
                   (FromCostShareBuffer.Quantity * ItemApplnEntry.Quantity < 0)
                then
                    AppliedQty := AppliedQty + ItemApplnEntry.Quantity;

                with ToCostShareBuffer do begin
                    if Quantity < 0 then
                        "New Quantity" := "New Quantity" - ItemApplnEntry.Quantity;

                    CostShare := ItemApplnEntry.Quantity / FromCostShareBuffer.Quantity;
                    UpdateCosts(FromCostShareBuffer, ToCostShareBuffer, CostShare, true);

                    TempCostShareBuffer := ToCostShareBuffer;
                    TempCostShareBuffer.Modify();

                    ForwardToAppliedOutbndEntry("Item Ledger Entry No.");
                    if "New Quantity" - ToItemLedgEntry."Remaining Quantity" = 0 then
                        ForwardToAppliedInbndEntry("Item Ledger Entry No.");

                    if (Quantity < 0) and
                       (CostSharePrint in [CostSharePrint::Inventory, CostSharePrint::"WIP Inventory"])
                    then begin
                        TempCostShareBuffer.Find();
                        ToCostShareBuffer := TempCostShareBuffer;
                        CostShare := -CostShare;
                        UpdateCosts(FromCostShareBuffer, ToCostShareBuffer, CostShare, false);
                        TempCostShareBuffer := ToCostShareBuffer;
                        TempCostShareBuffer.Modify();
                    end;
                end;
            end;
        until ItemApplnEntry.Next() = 0;

        if ToItemLedgEntry."Entry Type" = ToItemLedgEntry."Entry Type"::Transfer then
            if not ToItemLedgEntry.Positive then begin
                if EndDate in [0D .. ToItemLedgEntry."Posting Date"] then
                    ForwardToInbndTranEntry(EntryNo)
            end else
                exit;

        with FromCostShareBuffer do begin
            if (CostSharePrint = CostSharePrint::Inventory) and (Quantity > 0) then begin
                "New Quantity" := "New Quantity" + AppliedQty;
                CostShare := AppliedQty / Quantity;
                UpdateCosts(FromCostShareBuffer, FromCostShareBuffer, CostShare, false);
            end;
            TempCostShareBuffer := FromCostShareBuffer;
            TempCostShareBuffer.Modify();
        end;
    end;

    local procedure UpdateCosts(FromCostShareBuffer: Record "Cost Share Buffer"; var ToCostShareBuffer: Record "Cost Share Buffer"; CostShare: Decimal; DirCostIsDiff: Boolean)
    begin
        with ToCostShareBuffer do begin
            "New Indirect Cost" := "New Indirect Cost" + CostShare * FromCostShareBuffer."New Indirect Cost";
            if CostSharePrint = CostSharePrint::Sales then
                "New Revaluation" := "New Revaluation" + CostShare * FromCostShareBuffer."New Revaluation";
            "New Rounding" := "New Rounding" + CostShare * FromCostShareBuffer."New Rounding";
            "New Variance" := "New Variance" + CostShare * FromCostShareBuffer."New Variance";
            "New Purchase Variance" := "New Purchase Variance" + CostShare * FromCostShareBuffer."New Purchase Variance";
            "New Material Variance" := "New Material Variance" + CostShare * FromCostShareBuffer."New Material Variance";
            "New Capacity Variance" := "New Capacity Variance" + CostShare * FromCostShareBuffer."New Capacity Variance";
            "New Capacity Overhead Variance" :=
              "New Capacity Overhead Variance" + CostShare * FromCostShareBuffer."New Capacity Overhead Variance";
            "New Mfg. Overhead Variance" :=
              "New Mfg. Overhead Variance" + CostShare * FromCostShareBuffer."New Mfg. Overhead Variance";
            "New Subcontracted Variance" :=
              "New Subcontracted Variance" + CostShare * FromCostShareBuffer."New Subcontracted Variance";
            if DirCostIsDiff then
                "New Direct Cost" := "New Direct Cost" - CostShare *
                  (FromCostShareBuffer."New Indirect Cost" +
                   FromCostShareBuffer."New Revaluation" +
                   FromCostShareBuffer."New Variance" +
                   FromCostShareBuffer."New Rounding")
            else
                "New Direct Cost" := "New Direct Cost" + CostShare * FromCostShareBuffer."New Direct Cost";
            "New Capacity" := "New Capacity" + CostShare * FromCostShareBuffer."New Capacity";
            "New Capacity Overhead" := "New Capacity Overhead" + CostShare * FromCostShareBuffer."New Capacity Overhead";
            "New Material Overhead" := "New Material Overhead" + CostShare * FromCostShareBuffer."New Material Overhead";
            "New Subcontracted" := "New Subcontracted" + CostShare * FromCostShareBuffer."New Subcontracted";
            "New Material" := "New Direct Cost" - ("New Capacity" + "New Capacity Overhead" + "New Subcontracted");
        end;
    end;

    local procedure InsertItemLedgEntryCostShare(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        CostInPeriod: Decimal;
        TotalCost: Decimal;
        DirectCostInPeriod: Decimal;
        TotalDirectCost: Decimal;
    begin
        with TempCostShareBuffer do begin
            Init();
            "Item Ledger Entry No." := ItemLedgEntry."Entry No.";
            "Item No." := ItemLedgEntry."Item No.";
            Quantity := ItemLedgEntry.Quantity;
            "Entry Type" := ItemLedgEntry."Entry Type";
            "Location Code" := ItemLedgEntry."Location Code";
            "Variant Code" := ItemLedgEntry."Variant Code";
            "Order Type" := ItemLedgEntry."Order Type";
            "Order No." := ItemLedgEntry."Order No.";
            "Order Line No." := ItemLedgEntry."Order Line No.";
            "Document No." := ItemLedgEntry."Document No.";
            Description := ItemLedgEntry.Description;
            "Posting Date" := ItemLedgEntry."Posting Date";

            TotalCost := 0;
            CostInPeriod := 0;
            DirectCostInPeriod := 0;
            TotalDirectCost := 0;
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
            if EndDate <> 0D then
                ValueEntry.SetRange("Posting Date", 0D, EndDate);
            if ValueEntry.Find('-') then
                repeat
                    GetValueEntryCostAmts(TempCostShareBuffer, ValueEntry);

                    if IsInCostingPeriod(ValueEntry."Posting Date") then begin
                        CostInPeriod := CostInPeriod + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
                            DirectCostInPeriod := DirectCostInPeriod + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                    end;
                    TotalCost := TotalCost + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
                        TotalDirectCost := TotalDirectCost + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                until ValueEntry.Next() = 0;

            if ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output,
                                              ItemLedgEntry."Entry Type"::"Assembly Output"]
            then
                UpdateCostShareBufFromInvAdjmtEntryOrder(ItemLedgEntry, TempCostShareBuffer)
            else
                "Material Overhead" := "Indirect Cost";

            Material := "Direct Cost" - (Capacity + "Capacity Overhead" + Subcontracted);

            if TotalCost <> 0 then
                "Share of Cost in Period" := CostInPeriod / TotalCost;

            "New Quantity" := Quantity;
            "New Direct Cost" := "Direct Cost";
            "New Indirect Cost" := "Indirect Cost";
            "New Revaluation" := Revaluation;
            "New Variance" := Variance;
            "New Rounding" := Rounding;

            "New Purchase Variance" := "Purchase Variance";
            "New Material Variance" := "Material Variance";
            "New Capacity Variance" := "Capacity Variance";
            "New Capacity Overhead Variance" := "Capacity Overhead Variance";
            "New Mfg. Overhead Variance" := "Mfg. Overhead Variance";
            "New Subcontracted Variance" := "Subcontracted Variance";

            "New Material" := Material;
            "New Capacity" := Capacity;
            "New Capacity Overhead" := "Capacity Overhead";
            "New Material Overhead" := "Material Overhead";
            "New Subcontracted" := Subcontracted;
            Insert();
        end;
    end;

    local procedure UpdateCostShareBufFromInvAdjmtEntryOrder(ItemLedgEntry: Record "Item Ledger Entry"; var CostShareBuffer: Record "Cost Share Buffer")
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        ShareOfCost: Decimal;
        OutputQty: Decimal;
    begin
        if not InvtAdjmtEntryOrder.Get(ItemLedgEntry."Order Type", ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.") then
            exit;

        OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(InvtAdjmtEntryOrder, false);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(InvtAdjmtEntryOrder, OutputQty, InvtAdjmtEntryOrder);

        with CostShareBuffer do begin
            Capacity += InvtAdjmtEntryOrder."Single-Level Capacity Cost";
            "Capacity Overhead" += InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
            "Material Overhead" += InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
            Subcontracted += InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";

            if OutputQty <> 0 then begin
                ShareOfCost := ItemLedgEntry.Quantity / OutputQty;
                Capacity *= ShareOfCost;
                "Capacity Overhead" *= ShareOfCost;
                "Material Overhead" *= ShareOfCost;
                Subcontracted *= ShareOfCost;
            end;
        end;
    end;

    local procedure InsertCapLedgEntryCostShare(CapLedgEntry: Record "Capacity Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        CostInPeriod: Decimal;
        TotalCost: Decimal;
    begin
        with TempCostShareBuffer do begin
            Init();
            "Capacity Ledger Entry No." := CapLedgEntry."Entry No.";
            "Item No." := CapLedgEntry."Item No.";
            Quantity := CapLedgEntry.Quantity;
            "Entry Type" := "Entry Type"::" ";
            "Order Type" := CapLedgEntry."Order Type";
            "Order No." := CapLedgEntry."Order No.";
            "Order Line No." := CapLedgEntry."Order Line No.";
            "Document No." := CapLedgEntry."Document No.";
            Description := CapLedgEntry.Description;

            TotalCost := 0;
            CostInPeriod := 0;
            ValueEntry.SetCurrentKey("Capacity Ledger Entry No.", "Entry Type");
            ValueEntry.SetRange("Capacity Ledger Entry No.", CapLedgEntry."Entry No.");
            if EndDate <> 0D then
                ValueEntry.SetRange("Posting Date", 0D, EndDate);
            if ValueEntry.Find('-') then
                repeat
                    GetValueEntryCostAmts(TempCostShareBuffer, ValueEntry);

                    if IsInCostingPeriod(ValueEntry."Posting Date") then
                        CostInPeriod := CostInPeriod + ValueEntry."Cost Amount (Actual)";
                    TotalCost := TotalCost + ValueEntry."Cost Amount (Actual)";
                until ValueEntry.Next() = 0;

            if TotalCost <> 0 then
                "Share of Cost in Period" := CostInPeriod / TotalCost;

            if CapLedgEntry.Subcontracting then
                Subcontracted := "Direct Cost"
            else
                Capacity := "Direct Cost";
            "Capacity Overhead" := "Indirect Cost";

            "New Quantity" := Quantity;
            "New Direct Cost" := "Direct Cost";
            "New Indirect Cost" := "Indirect Cost";
            "New Revaluation" := Revaluation;
            "New Variance" := Variance;
            "New Rounding" := Rounding;

            "New Purchase Variance" := "Purchase Variance";
            "New Material Variance" := "Material Variance";
            "New Capacity Variance" := "Capacity Variance";
            "New Capacity Overhead Variance" := "Capacity Overhead Variance";
            "New Mfg. Overhead Variance" := "Mfg. Overhead Variance";
            "New Subcontracted Variance" := "Subcontracted Variance";

            "New Material" := Material;
            "New Capacity" := Capacity;
            "New Capacity Overhead" := "Capacity Overhead";
            "New Material Overhead" := "Material Overhead";
            "New Subcontracted" := Subcontracted;
            Insert();
        end;
    end;

    local procedure GetValueEntryCostAmts(var CostShareBuf: Record "Cost Share Buffer"; ValueEntry: Record "Value Entry")
    begin
        with CostShareBuf do
            case ValueEntry."Entry Type" of
                ValueEntry."Entry Type"::"Direct Cost":
                    "Direct Cost" := "Direct Cost" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                ValueEntry."Entry Type"::"Indirect Cost":
                    "Indirect Cost" := "Indirect Cost" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                ValueEntry."Entry Type"::Variance:
                    begin
                        Variance := Variance + ValueEntry."Cost Amount (Actual)";
                        case ValueEntry."Variance Type" of
                            ValueEntry."Variance Type"::Purchase:
                                "Purchase Variance" := "Purchase Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                            ValueEntry."Variance Type"::Material:
                                "Material Variance" := "Material Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                            ValueEntry."Variance Type"::Capacity:
                                "Capacity Variance" := "Capacity Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                            ValueEntry."Variance Type"::"Capacity Overhead":
                                "Capacity Overhead Variance" :=
                                  "Capacity Overhead Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                            ValueEntry."Variance Type"::"Manufacturing Overhead":
                                "Mfg. Overhead Variance" :=
                                  "Mfg. Overhead Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                            ValueEntry."Variance Type"::Subcontracted:
                                "Subcontracted Variance" :=
                                  "Subcontracted Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        end;
                    end;
                ValueEntry."Entry Type"::Revaluation:
                    Revaluation := Revaluation + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                ValueEntry."Entry Type"::Rounding:
                    Rounding := Rounding + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
            end;
    end;

    local procedure IsInCostingPeriod(PostingDate: Date): Boolean
    begin
        if EndDate <> 0D then
            exit(PostingDate in [StartDate .. EndDate]);
        exit(PostingDate >= StartDate);
    end;

    local procedure SrvTrPrintInvtCostShareBufFtr4(): Boolean
    begin
        if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
            TempCostShareBuffer."Item No." := ItemPrint."No.";
            TempCostShareBuffer.Description := ItemPrint.Description;
        end else begin
            TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
            TempCostShareBuffer.Description := ProdOrderPrint.Description;
            TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
        end;
        exit(ShowDetails);
    end;

    local procedure SrvTrPrintInvtCostShareBufFtr5(): Boolean
    begin
        if CostSharePrint = CostSharePrint::"WIP Inventory" then begin
            TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
            TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
        end;
        exit(not ShowDetails);
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPrintCostShare: Option; NewShowDetails: Boolean)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        CostSharePrint := NewPrintCostShare;
        ShowDetails := NewShowDetails;
    end;
}

