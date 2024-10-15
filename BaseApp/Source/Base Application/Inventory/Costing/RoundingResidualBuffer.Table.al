namespace Microsoft.Inventory.Costing;

table 5810 "Rounding Residual Buffer"
{
    Caption = 'Rounding Residual Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Adjusted Cost"; Decimal)
        {
            Caption = 'Adjusted Cost';
            DataClassification = SystemMetadata;
        }
        field(3; "Adjusted Cost (ACY)"; Decimal)
        {
            Caption = 'Adjusted Cost (ACY)';
            DataClassification = SystemMetadata;
        }
        field(4; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
            DataClassification = SystemMetadata;
        }
        field(5; "No. of Hits"; Integer)
        {
            Caption = 'No. of Hits';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Item Ledger Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure AddAdjustedCost(NewInboundEntryNo: Integer; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; NewCompletelyInvoiced: Boolean)
    begin
        if not HasNewCost(NewAdjustedCost, NewAdjustedCostACY) and NewCompletelyInvoiced then begin
            Retrieve(NewInboundEntryNo);
            exit;
        end;

        if Retrieve(NewInboundEntryNo) then begin
            "Adjusted Cost" := "Adjusted Cost" + NewAdjustedCost;
            "Adjusted Cost (ACY)" := "Adjusted Cost (ACY)" + NewAdjustedCostACY;
            if not NewCompletelyInvoiced then
                "Completely Invoiced" := false;
            Modify();
        end else begin
            Init();
            "Adjusted Cost" := NewAdjustedCost;
            "Adjusted Cost (ACY)" := NewAdjustedCostACY;
            "Completely Invoiced" := NewCompletelyInvoiced;
            Insert();
        end;
    end;

    procedure UpdRoundingCheck(NewInboundEntryNo: Integer; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; RdngPrecision: Decimal; RndngPrecisionACY: Decimal)
    begin
        if not HasNewCost(NewAdjustedCost, NewAdjustedCostACY) then begin
            Retrieve(NewInboundEntryNo);
            exit;
        end;

        if Retrieve(NewInboundEntryNo) then begin
            if ((RdngPrecision >= NewAdjustedCost) or
                (RndngPrecisionACY >= NewAdjustedCostACY)) and
               (("Adjusted Cost" * NewAdjustedCost <= 0) and
                ("Adjusted Cost (ACY)" * NewAdjustedCostACY <= 0))
            then
                "No. of Hits" := "No. of Hits" + 1
            else
                "No. of Hits" := 0;

            "Adjusted Cost" := NewAdjustedCost;
            "Adjusted Cost (ACY)" := NewAdjustedCostACY;
            Modify();
        end else begin
            Init();
            "Adjusted Cost" := NewAdjustedCost;
            "Adjusted Cost (ACY)" := NewAdjustedCostACY;
            Insert();
        end;
    end;

    local procedure Retrieve(NewInboundEntryNo: Integer): Boolean
    begin
        Reset();
        "Item Ledger Entry No." := NewInboundEntryNo;
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
}

