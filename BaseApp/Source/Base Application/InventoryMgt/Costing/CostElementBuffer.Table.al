namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

table 5820 "Cost Element Buffer"
{
    Caption = 'Cost Element Buffer';
    ReplicateData = false;

    fields
    {
        field(1; Type; Enum "Cost Entry Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(2; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Actual Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Actual Cost';
            DataClassification = SystemMetadata;
        }
        field(4; "Actual Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Actual Cost (ACY)';
            DataClassification = SystemMetadata;
        }
        field(5; "Rounding Residual"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding Residual';
            DataClassification = SystemMetadata;
        }
        field(6; "Rounding Residual (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding Residual (ACY)';
            DataClassification = SystemMetadata;
        }
        field(7; "Expected Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Cost';
            DataClassification = SystemMetadata;
        }
        field(8; "Expected Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Cost (ACY)';
            DataClassification = SystemMetadata;
        }
        field(9; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DataClassification = SystemMetadata;
        }
        field(10; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = SystemMetadata;
        }
        field(11; "Inbound Completely Invoiced"; Boolean)
        {
            Caption = 'Inbound Completely Invoiced';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Valid Value Entry No"; Integer)
        {
            Caption = 'Last Valid Value Entry No';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "Variance Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Initialize(KeepRoundingResidual: Boolean)
    var
        CostElementBuffer: Record "Cost Element Buffer";
    begin
        if KeepRoundingResidual then begin
            CostElementBuffer := Rec;
            Init();
            "Rounding Residual" := CostElementBuffer."Rounding Residual";
            "Rounding Residual (ACY)" := CostElementBuffer."Rounding Residual (ACY)";
        end else
            Init();
    end;

    procedure AddActualCost(NewType: Option; NewVarianceType: Option; NewActualCost: Decimal; NewActualCostACY: Decimal)
    begin
        AddActualCostElement("Cost Entry Type".FromInteger(NewType), "Cost Variance Type".FromInteger(NewVarianceType), NewActualCost, NewActualCostACY);
    end;

    procedure AddActualCostElement(NewEntryType: Enum "Cost Entry Type"; NewVarianceType: Enum "Cost Variance Type"; NewActualCost: Decimal; NewActualCostACY: Decimal)
    begin
        if not HasNewCost(NewActualCost, NewActualCostACY) then begin
            GetElement(NewEntryType, NewVarianceType);
            exit;
        end;
        if GetElement(NewEntryType, NewVarianceType) then begin
            "Actual Cost" := "Actual Cost" + NewActualCost;
            "Actual Cost (ACY)" := "Actual Cost (ACY)" + NewActualCostACY;
            Modify();
        end else begin
            "Actual Cost" := NewActualCost;
            "Actual Cost (ACY)" := NewActualCostACY;
            Insert();
        end;
    end;

    procedure AddExpectedCostElement(NewEntryType: Enum "Cost Entry Type"; NewVarianceType: Enum "Cost Variance Type"; NewExpectedCost: Decimal; NewExpectedCostACY: Decimal)
    begin
        if not HasNewCost(NewExpectedCost, NewExpectedCostACY) then begin
            GetElement(NewEntryType, NewVarianceType);
            exit;
        end;
        if GetElement(NewEntryType, NewVarianceType) then begin
            "Expected Cost" := "Expected Cost" + NewExpectedCost;
            "Expected Cost (ACY)" := "Expected Cost (ACY)" + NewExpectedCostACY;
            Modify();
        end else begin
            "Expected Cost" := NewExpectedCost;
            "Expected Cost (ACY)" := NewExpectedCostACY;
            Insert();
        end;
    end;

    procedure RoundActualCost(ShareOfTotalCost: Decimal; AmtRndgPrec: Decimal; AmtRndgPrecACY: Decimal)
    begin
        "Actual Cost" := Round("Actual Cost" * ShareOfTotalCost, AmtRndgPrec);
        "Actual Cost (ACY)" := Round("Actual Cost (ACY)" * ShareOfTotalCost, AmtRndgPrecACY);

        OnAfterRoundActualCost(Rec, ShareOfTotalCost, AmtRndgPrec, AmtRndgPrecACY);
    end;

    procedure ExcludeEntryFromAvgCostCalc(ValueEntry: Record "Value Entry")
    begin
        "Remaining Quantity" := "Remaining Quantity" - ValueEntry."Item Ledger Entry Quantity";
        "Actual Cost" := "Actual Cost" - ValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Expected)";
        "Actual Cost (ACY)" :=
          "Actual Cost (ACY)" - ValueEntry."Cost Amount (Actual) (ACY)" - ValueEntry."Cost Amount (Expected) (ACY)";

        OnAfterExcludeEntryFromAvgCostCalc(Rec, ValueEntry);
    end;

    procedure ExcludeBufFromAvgCostCalc(InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
        "Remaining Quantity" := "Remaining Quantity" - InvtAdjmtBuffer."Item Ledger Entry Quantity";
        "Actual Cost" := "Actual Cost" - InvtAdjmtBuffer."Cost Amount (Actual)" - InvtAdjmtBuffer."Cost Amount (Expected)";
        "Actual Cost (ACY)" :=
          "Actual Cost (ACY)" - InvtAdjmtBuffer."Cost Amount (Actual) (ACY)" - InvtAdjmtBuffer."Cost Amount (Expected) (ACY)";

        OnAfterExcludeBufFromAvgCostCalc(Rec, InvtAdjmtBuffer);
    end;

    procedure GetElement(NewEntryType: Enum "Cost Entry Type"; NewVarianceType: Enum "Cost Variance Type"): Boolean
    begin
        Reset();
        Type := NewEntryType;
        "Variance Type" := NewVarianceType;
        if not Find() then begin
            Init();
            exit(false);
        end;
        exit(true);
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;

    procedure DeductOutbndValueEntryFromBuf(OutbndValueEntry: Record "Value Entry"; CostElementBuf: Record "Cost Element Buffer"; IsAvgCostCalcTypeItem: Boolean)
    begin
        if "Remaining Quantity" + OutbndValueEntry."Valued Quantity" <= 0 then
            exit;

        if (OutbndValueEntry."Item Ledger Entry Type" = OutbndValueEntry."Item Ledger Entry Type"::Transfer) and
           IsAvgCostCalcTypeItem
        then
            exit;

        "Remaining Quantity" += OutbndValueEntry."Valued Quantity";
        "Actual Cost" += CostElementBuf."Actual Cost";
        "Actual Cost (ACY)" += CostElementBuf."Actual Cost (ACY)";
        "Rounding Residual" := 0;
        "Rounding Residual (ACY)" := 0;

        OnAfterDeductOutbndValueEntryFromBuf(Rec, OutbndValueEntry, CostElementBuf, IsAvgCostCalcTypeItem);
    end;

    procedure UpdateAvgCostBuffer(CostElementBuf: Record "Cost Element Buffer"; LastValidEntryNo: Integer)
    begin
        "Actual Cost" := CostElementBuf."Actual Cost";
        "Actual Cost (ACY)" := CostElementBuf."Actual Cost (ACY)";
        "Last Valid Value Entry No" := LastValidEntryNo;
        "Remaining Quantity" := CostElementBuf."Remaining Quantity";

        OnAfterUpdateAvgCostBuffer(Rec, CostElementBuf, LastValidEntryNo);
    end;

    procedure UpdateCostElementBuffer(AvgCostBuf: Record "Cost Element Buffer")
    begin
        "Remaining Quantity" := AvgCostBuf."Remaining Quantity";
        "Actual Cost" := AvgCostBuf."Actual Cost";
        "Actual Cost (ACY)" := AvgCostBuf."Actual Cost (ACY)";
        "Rounding Residual" := AvgCostBuf."Rounding Residual";
        "Rounding Residual (ACY)" := AvgCostBuf."Rounding Residual (ACY)";

        OnAfterUpdateCostElementBuffer(Rec, AvgCostBuf);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAvgCostBuffer(var CostElementBuffer: Record "Cost Element Buffer"; CostElementBuf: Record "Cost Element Buffer"; LastValidEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCostElementBuffer(var CostElementBuffer: Record "Cost Element Buffer"; AvgCostBuf: Record "Cost Element Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExcludeBufFromAvgCostCalc(var CostElementBuffer: Record "Cost Element Buffer"; InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundActualCost(var CostElementBuffer: Record "Cost Element Buffer"; ShareOfTotalCost: Decimal; AmtRndgPrec: Decimal; AmtRndgPrecACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeductOutbndValueEntryFromBuf(var CostElementBuffer: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; CostElementBuf: Record "Cost Element Buffer"; IsAvgCostCalcTypeItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExcludeEntryFromAvgCostCalc(var CostElementBuffer: Record "Cost Element Buffer"; ValueEntry: Record "Value Entry")
    begin
    end;
}

