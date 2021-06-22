report 5872 "BOM Cost Share Distribution"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BOMCostShareDistribution.rdlc';
    AdditionalSearchTerms = 'cost breakdown,rolled-up cost';
    ApplicationArea = Assembly;
    Caption = 'BOM Cost Share Distribution';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ItemTABLECAPTION_ItemFilter; TableCaption + ': ' + ItemFilters)
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
            column(ReportCostShareDescription; StrSubstNo(Text000, SelectStr(ShowCostShareAs + 1, ShowCostShareAsTxt)))
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(ShowLevelAs; ShowLevelAs)
            {
                OptionCaption = 'First BOM Level,BOM Leaves';
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem(BOMBufferLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(TypeNo; StrSubstNo('%1 %2', TempBOMBuffer.Type, TempBOMBuffer."No."))
                {
                }
                column(Type; TempBOMBuffer.Type)
                {
                }
                column(No; TempBOMBuffer."No.")
                {
                }
                column(Description; TempBOMBuffer.Description)
                {
                }
                column(Indentation; TempBOMBuffer.Indentation)
                {
                }
                column(DirectCost; TempBOMBuffer.CalcDirectCost)
                {
                }
                column(IndirectCost; TempBOMBuffer.CalcIndirectCost)
                {
                }
                column(MaterialCost; MaterialCost)
                {
                }
                column(CapacityCost; CapacityCost)
                {
                }
                column(SubcontrdCost; SubcontrdCost)
                {
                }
                column(CapOvhdCost; CapOvhdCost)
                {
                }
                column(MfgOvhdCost; MfgOvhdCost)
                {
                }
                column(TotalCost; TempBOMBuffer."Total Cost")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FindNextRecord(TempBOMBuffer, Number) then
                        CurrReport.Break();

                    MaterialCost := TempBOMBuffer."Rolled-up Material Cost";
                    CapacityCost := TempBOMBuffer."Rolled-up Capacity Cost";
                    SubcontrdCost := TempBOMBuffer."Rolled-up Subcontracted Cost";
                    MfgOvhdCost := TempBOMBuffer."Rolled-up Mfg. Ovhd Cost";
                    CapOvhdCost := TempBOMBuffer."Rolled-up Capacity Ovhd. Cost";

                    if (MaterialCost = 0) and
                       (CapacityCost = 0) and
                       (SubcontrdCost = 0) and
                       (CapOvhdCost = 0) and
                       (MfgOvhdCost = 0)
                    then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not GenerateAvailTrend then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                ItemFilters := GetFilters;
                BOMBuffer.DeleteAll();
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
                    field(ShowCostShareAs; ShowCostShareAs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Cost Shares as';
                        OptionCaption = 'Single-level,Rolled-up';
                        ToolTip = 'Specifies the BOM cost shares as single-level costs or as rolled-up costs.';
                    }
                    field(ShowLevelAs; ShowLevelAs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only';
                        OptionCaption = 'First BOM Level,BOM Leaves';
                        ToolTip = 'Specifies the cost shares for items on the first BOM level only or for items on the lowest BOM levels, components, only.';
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Details';
                        ToolTip = 'Specifies that a table is added at the bottom of the report that provides a summary of the single-level or rolled-up values in the BOM Cost Shares window.';
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
        BOMCostSharesReportCaption = 'BOM Cost Share Distribution';
        TypeCaption = 'Type';
        QtyPerTopItemCaption = 'Qty. per Top Item';
        UnitPriceCaption = 'Unit Price';
        UnitCostCaption = 'Unit Cost';
        DirectCostCaption = 'Direct Cost';
        IndirectCostCaption = 'Indirect Cost';
        MaterialCostCaption = 'Material';
        CapacityCostCaption = 'Capacity';
        SubcontrdCostCaption = 'Subcontracted';
        CapOvhdCostCaption = 'Capacity Overhead';
        MfgOvhdCostCaption = 'Mfg. Overhead';
        CostDistributionByMaterialLaborCaption = 'By Material/Labor';
        CostDistributionByDirectIndirectCaption = 'By Direct/Indirect';
        CostDistributionByCostSharesCaption = 'By Cost Share';
        TotalCostCaption = 'Total Cost';
        MaterialCaption = 'Material';
        LaborCaption = 'Labor';
        OverheadCaption = 'Overhead';
    }

    var
        BOMBuffer: Record "BOM Buffer";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        ItemFilters: Text;
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowDetails: Boolean;
        ShowCostShareAs: Option "Single-level","Rolled-up";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        SubcontrdCost: Decimal;
        CapOvhdCost: Decimal;
        MfgOvhdCost: Decimal;
        Text000: Label '%1 cost shares only';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ShowCostShareAsTxt: Label 'Single-level,Rolled-up';

    local procedure GenerateAvailTrend(): Boolean
    var
        NewOvhdCost: Decimal;
        NewMaterialCost: Decimal;
        IsKeepOnlyMfgOvhd: Boolean;
        IsTransferCostToMaterial: Boolean;
    begin
        CalcBOMTree.GenerateTreeForItem(Item, TempBOMBuffer, WorkDate, 2);
        with TempBOMBuffer do begin
            if FindFirst then
                repeat
                    IsKeepOnlyMfgOvhd := KeepOnlyMfgOvhdCost;
                    IsTransferCostToMaterial := TransferCostToMaterial;
                    NewOvhdCost := 0;
                    NewMaterialCost := 0;

                    if IsKeepOnlyMfgOvhd then begin
                        Description := CopyStr(FieldCaption("Single-Level Mfg. Ovhd Cost"), 1, MaxStrLen(Description));
                        NewOvhdCost := "Single-Level Mfg. Ovhd Cost";
                        RoundCosts(0);
                        AddMfgOvhdCost(NewOvhdCost, NewOvhdCost);
                    end;

                    if IsTransferCostToMaterial then begin
                        NewMaterialCost := CalcDirectCost + CalcIndirectCost;
                        RoundCosts(0);
                        AddMaterialCost(NewMaterialCost, NewMaterialCost);
                    end;

                    if DeleteThisLine then
                        Delete
                    else
                        if IsKeepOnlyMfgOvhd or IsTransferCostToMaterial then begin
                            CalcIndirectCost;
                            CalcUnitCost;
                            Modify;
                        end;
                until Next = 0;
            MergeLinesWithSameTypeAndNo;

            exit(not IsEmpty);
        end;
    end;

    local procedure KeepOnlyMfgOvhdCost(): Boolean
    begin
        with TempBOMBuffer do begin
            if Indentation = 0 then
                exit(true);
            if ShowLevelAs = ShowLevelAs::"First BOM Level" then
                exit(false);
            exit(not "Is Leaf");
        end;
    end;

    local procedure TransferCostToMaterial(): Boolean
    begin
        with TempBOMBuffer do begin
            if ShowCostShareAs <> ShowCostShareAs::"Single-level" then
                exit(false);
            if Indentation = 0 then
                exit(false);
            if (Indentation = 1) and "Is Leaf" then
                exit(false);
            exit(true);
        end;
    end;

    local procedure DeleteThisLine(): Boolean
    begin
        with TempBOMBuffer do begin
            if Indentation = 0 then
                exit("Single-Level Mfg. Ovhd Cost" = 0);
            if ShowLevelAs = ShowLevelAs::"First BOM Level" then
                exit(Indentation > 1);
            if "Is Leaf" then
                exit(false);
            if ShowCostShareAs = ShowCostShareAs::"Single-level" then
                exit("Single-Level Material Cost" = 0);
            exit("Single-Level Mfg. Ovhd Cost" = 0);
        end;
    end;

    local procedure MergeLinesWithSameTypeAndNo()
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        with TempBOMBuffer do
            if FindFirst then
                repeat
                    if Indentation <> 0 then begin
                        CopyOfBOMBuffer.Copy(TempBOMBuffer);
                        SetRange(Type, Type);
                        SetRange("No.", "No.");
                        while Next <> 0 do begin
                            CopyOfBOMBuffer.AddMaterialCost("Single-Level Material Cost", "Rolled-up Material Cost");
                            CopyOfBOMBuffer.AddCapacityCost("Single-Level Capacity Cost", "Rolled-up Capacity Cost");
                            CopyOfBOMBuffer.AddSubcontrdCost("Single-Level Subcontrd. Cost", "Rolled-up Subcontracted Cost");
                            CopyOfBOMBuffer.AddCapOvhdCost("Single-Level Cap. Ovhd Cost", "Rolled-up Capacity Ovhd. Cost");
                            CopyOfBOMBuffer.AddMfgOvhdCost("Single-Level Mfg. Ovhd Cost", "Rolled-up Mfg. Ovhd Cost");
                            CopyOfBOMBuffer.AddScrapCost("Single-Level Scrap Cost", "Rolled-up Scrap Cost");
                            Delete;
                        end;
                        Copy(CopyOfBOMBuffer);
                        CalcDirectCost;
                        CalcIndirectCost;
                        CalcUnitCost;
                        Modify;
                    end;
                until Next = 0;
    end;

    local procedure FindNextRecord(var BOMBuffer: Record "BOM Buffer"; Position: Integer): Boolean
    begin
        if Position = 1 then begin
            BOMBuffer.SetCurrentKey("Total Cost");
            exit(BOMBuffer.Find('-'));
        end;
        exit(BOMBuffer.Next <> 0);
    end;

    procedure InitializeRequest(NewShowLevelAs: Option; NewShowDetails: Boolean; NewShowCostShareAs: Option)
    begin
        ShowLevelAs := NewShowLevelAs;
        ShowDetails := NewShowDetails;
        ShowCostShareAs := NewShowCostShareAs;
    end;
}

