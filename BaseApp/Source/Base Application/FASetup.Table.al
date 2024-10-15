table 5603 "FA Setup"
{
    Caption = 'FA Setup';
    Permissions = TableData "Ins. Coverage Ledger Entry" = r;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(3; "Allow Posting to Main Assets"; Boolean)
        {
            Caption = 'Allow Posting to Main Assets';
        }
        field(4; "Default Depr. Book"; Code[10])
        {
            Caption = 'Default Depr. Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                if "Insurance Depr. Book" = '' then
                    Validate("Insurance Depr. Book", "Default Depr. Book");
            end;
        }
        field(5; "Allow FA Posting From"; Date)
        {
            Caption = 'Allow FA Posting From';
        }
        field(6; "Allow FA Posting To"; Date)
        {
            Caption = 'Allow FA Posting To';
        }
        field(7; "Insurance Depr. Book"; Code[10])
        {
            Caption = 'Insurance Depr. Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            var
                InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
                MakeInsCoverageLedgEntry: Codeunit "Make Ins. Coverage Ledg. Entry";
            begin
                if InsCoverageLedgEntry.IsEmpty() then
                    exit;

                if "Insurance Depr. Book" <> xRec."Insurance Depr. Book" then
                    MakeInsCoverageLedgEntry.UpdateInsCoverageLedgerEntryFromFASetup("Insurance Depr. Book");
            end;
        }
        field(8; "Automatic Insurance Posting"; Boolean)
        {
            Caption = 'Automatic Insurance Posting';
            InitValue = true;
        }
        field(9; "Fixed Asset Nos."; Code[20])
        {
            Caption = 'Fixed Asset Nos.';
            TableRelation = "No. Series";
        }
        field(10; "Insurance Nos."; Code[20])
        {
            AccessByPermission = TableData Insurance = R;
            Caption = 'Insurance Nos.';
            TableRelation = "No. Series";
        }
        field(31040; "Tax Depr. Book"; Code[10])
        {
            Caption = 'Tax Depr. Book';
            TableRelation = "Depreciation Book";
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
            ObsoleteTag = '18.0';

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "Tax Depr. Book" <> xRec."Tax Depr. Book" then begin
                    if FixedAsset.FindSet(true) then
                        repeat
                            if FADeprBook.Get(FixedAsset."No.", "Tax Depr. Book") then begin
                                FixedAsset."Tax Depreciation Group Code" := FADeprBook."Depreciation Group Code";
                                FixedAsset.Modify();
                            end else begin
                                FixedAsset."Tax Depreciation Group Code" := '';
                                FixedAsset.Modify();
                            end;
                        until FixedAsset.Next() = 0;
                end;
            end;
        }
        field(31042; "Fixed Asset History"; Boolean)
        {
            Caption = 'Fixed Asset History';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
            ObsoleteTag = '18.0';

            trigger OnValidate()
            var
                InitFAHistory: Report "Initialize FA History";
            begin
                if "Fixed Asset History" then begin
                    Clear(InitFAHistory);
                    InitFAHistory.RunModal;
                end;
            end;
        }
        field(31043; "FA Maintenance By Maint. Code"; Boolean)
        {
            Caption = 'FA Maintenance By Maint. Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Maintenance Posting was changed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31044; "FA Acquisition As Custom 2"; Boolean)
        {
            Caption = 'FA Acquisition As Custom 2';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
            ObsoleteTag = '18.0';
        }
        field(31045; "FA Disposal By Reason Code"; Boolean)
        {
            Caption = 'FA Disposal By Reason Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Disposal Posting was changed and this field should not be used. (Obsolete::Removed in release 01.2021))';
            ObsoleteTag = '18.0';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

