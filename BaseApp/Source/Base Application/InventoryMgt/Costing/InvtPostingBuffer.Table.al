namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Dimension;

#pragma warning disable AS0109
table 48 "Invt. Posting Buffer"
#pragma warning restore AS0109
{
    Caption = 'Invt. Posting Buffer';
    ReplicateData = false;
#if CLEAN21
    TableType = Temporary;
#else
    ObsoleteReason = 'This table will be marked as temporary. Make sure you are not using this table to store records.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Account Type"; Enum "Invt. Posting Buffer Account Type")
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = SystemMetadata;
        }
        field(4; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(6; "Amount (ACY)"; Decimal)
        {
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(7; "Interim Account"; Boolean)
        {
            Caption = 'Interim Account';
            DataClassification = SystemMetadata;
        }
        field(8; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(11; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(12; Negative; Boolean)
        {
            Caption = 'Negative';
            DataClassification = SystemMetadata;
        }
        field(13; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(14; "Bal. Account Type"; Enum "Invt. Posting Buffer Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
        }
        field(15; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(11763; "G/L Correction"; Boolean)
        {
            Caption = 'G/L Correction';
            DataClassification = SystemMetadata;
#if CLEAN21
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#endif
            ObsoleteReason = 'The field is not used anymore.';
        }
    }

    keys
    {
#if CLEAN21
        key(Key1; "Posting Date", "Account Type", "Location Code", "Inventory Posting Group", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Dimension Set ID", Negative, "Bal. Account Type")
#else
        key(Key1; "Posting Date", "Account Type", "Location Code", "Inventory Posting Group", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Dimension Set ID", Negative, "Bal. Account Type", "G/L Correction")
#endif
        {
            Clustered = true;
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteReason = 'The obsoleted fields will be removed from primary key.';
            ObsoleteTag = '21.0';
#endif
        }
#if not CLEAN21
        key(Key2; "Interim Account")
        {
            ObsoleteReason = 'The key is not used anymore.';
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
        }
#endif
    }

    fieldgroups
    {
    }

    procedure UseInvtPostSetup(): Boolean
    var
        UseInventoryPostingSetup: Boolean;
    begin
        UseInventoryPostingSetup :=
          "Account Type" in
          ["Account Type"::Inventory,
           "Account Type"::"Inventory (Interim)",
           "Account Type"::"WIP Inventory",
           "Account Type"::"Material Variance",
           "Account Type"::"Capacity Variance",
           "Account Type"::"Subcontracted Variance",
           "Account Type"::"Cap. Overhead Variance",
#if not CLEAN21
           // NAVCZ
           "Account Type"::AccWIP,
           "Account Type"::"WIP Inventory (Interim)",
           "Account Type"::"AccWIPChange (Interim)",
           "Account Type"::"AccProdChange (Interim)",
        // NAVCZ
#endif
            "Account Type"::"Mfg. Overhead Variance"];

        OnUseInvtPostSetup(Rec, UseInventoryPostingSetup);

        exit(UseInventoryPostingSetup);
    end;

#if not CLEAN21
    [Obsolete('Use the Get function without the "G/L Correction" parameter instead. This field is obsolete and will be removed from primary key.', '21.0')]
    procedure Get(PostingDate: Date; AccountType: Enum "Invt. Posting Buffer Account Type"; LocationCode: Code[10]; InventoryPostingGroup: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; DimensionSetID: Integer; Negative2: Boolean; BalAccountType: Enum "Invt. Posting Buffer Account Type"; GLCorrection: Boolean) Result: Boolean
    var
        TempInvtPostingBuffer: Record "Invt. Posting Buffer" temporary;
    begin
        TempInvtPostingBuffer.CopyFilters(Rec);
        Reset();
        SetRange("Posting Date", PostingDate);
        SetRange("Account Type", AccountType);
        SetRange("Location Code", LocationCode);
        SetRange("Inventory Posting Group", InventoryPostingGroup);
        SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        SetRange("Dimension Set ID", DimensionSetID);
        SetRange(Negative, Negative2);
        SetRange("Bal. Account Type", BalAccountType);
        if Count() > 1 then
            SetRange("G/L Correction", GLCorrection);
        Result := FindFirst();
        CopyFilters(TempInvtPostingBuffer);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUseInvtPostSetup(var InvtPostingBuffer: Record "Invt. Posting Buffer"; var UseInventoryPostingSetup: Boolean)
    begin
    end;
}
