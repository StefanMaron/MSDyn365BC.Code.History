table 5813 "Inventory Posting Setup"
{
    Caption = 'Inventory Posting Setup';

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(2; "Invt. Posting Group Code"; Code[20])
        {
            Caption = 'Invt. Posting Group Code';
            NotBlank = true;
            TableRelation = "Inventory Posting Group";
        }
        field(6; "Inventory Account"; Code[20])
        {
            Caption = 'Inventory Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Account")
                else
                    LookupGLAccount(
#if not CLEAN19
                      "Inventory Account", GLAccountCategory."Account Category"::Assets,
                      StrSubstNo('%1|%2|%3',
                        GLAccountCategoryMgt.GetCI1Material(),
                        GLAccountCategoryMgt.GetCI31FinishedProducts(),
                        GLAccountCategoryMgt.GetCI32Goods())); // NAVCZ
#else
                      "Inventory Account", GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory);
#endif

                Validate("Inventory Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Inventory Account", false, false)
                else
                    CheckGLAccount(
#if not CLEAN19
                      FieldNo("Inventory Account"), "Inventory Account", false, false, GLAccountCategory."Account Category"::Assets,
                      StrSubstNo('%1|%2|%3',
                        GLAccountCategoryMgt.GetCI1Material(),
                        GLAccountCategoryMgt.GetCI31FinishedProducts(),
                        GLAccountCategoryMgt.GetCI32Goods())); // NAVCZ
#else
                      FieldNo("Inventory Account"), "Inventory Account", false, false, GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory);
#endif
#if not CLEAN18
                CheckValueEntries(FieldCaption("Inventory Account")); // NAVCZ
#endif
            end;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "View All Accounts on Lookup"; Boolean)
        {
            Caption = 'View All Accounts on Lookup';
        }
        field(5800; "Inventory Account (Interim)"; Code[20])
        {
            Caption = 'Inventory Account (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Account (Interim)")
                else
                    LookupGLAccount(
#if not CLEAN19
                      "Inventory Account (Interim)", GLAccountCategory."Account Category"::Assets,
                      StrSubstNo('%1|%2|%3',
                        GLAccountCategoryMgt.GetCI1Material(),
                        GLAccountCategoryMgt.GetCI31FinishedProducts(),
                        GLAccountCategoryMgt.GetCI32Goods())); // NAVCZ
#else
                      "Inventory Account (Interim)", GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory);
#endif

                Validate("Inventory Account (Interim)");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Inventory Account (Interim)", false, false)
                else
                    CheckGLAccount(
#if not CLEAN19
                      FieldNo("Inventory Account (Interim)"), "Inventory Account (Interim)", false, false, GLAccountCategory."Account Category"::Assets,
                      StrSubstNo('%1|%2|%3',
                        GLAccountCategoryMgt.GetCI1Material(),
                        GLAccountCategoryMgt.GetCI31FinishedProducts(),
                        GLAccountCategoryMgt.GetCI32Goods())); // NAVCZ
#else
                      FieldNo("Inventory Account (Interim)"), "Inventory Account (Interim)", false, false, GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory);
#endif
#if not CLEAN18
                CheckValueEntries(FieldCaption("Inventory Account (Interim)")); // NAVCZ
#endif
            end;
        }
        field(11760; "Consumption Account"; Code[20])
        {
            Caption = 'Consumption Account';
            TableRelation = "G/L Account";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';

#if not CLEAN18
            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Consumption Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Consumption Account", GLAccountCategory."Account Category"::Expense,
                      GLAccountCategoryMgt.GetA2MaterialAndEnergyConsumption());

                Validate("Consumption Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Consumption Account", false, false)
                else
                    CheckGLAccount(
                      FieldNo("Consumption Account"), "Consumption Account", false, false, GLAccountCategory."Account Category"::Expense,
                      GLAccountCategoryMgt.GetA2MaterialAndEnergyConsumption());
            end;
#endif
        }

        field(11761; "Change In Inv.Of WIP Acc."; Code[20])
        {
            Caption = 'Change In Inv.Of WIP Acc.';
            TableRelation = "G/L Account";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18
            trigger OnValidate()
            begin
                CheckValueEntries(FieldCaption("Change In Inv.Of WIP Acc."));
            end;
#endif
        }
        field(11762; "Change In Inv.Of Product Acc."; Code[20])
        {
            Caption = 'Change In Inv.Of Product Acc.';
            TableRelation = "G/L Account";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(99000750; "WIP Account"; Code[20])
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'WIP Account';
            TableRelation = "G/L Account";
        }
        field(99000753; "Material Variance Account"; Code[20])
        {
            Caption = 'Material Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000754; "Capacity Variance Account"; Code[20])
        {
            Caption = 'Capacity Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000755; "Mfg. Overhead Variance Account"; Code[20])
        {
            Caption = 'Mfg. Overhead Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000756; "Cap. Overhead Variance Account"; Code[20])
        {
            Caption = 'Cap. Overhead Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000757; "Subcontracted Variance Account"; Code[20])
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Subcontracted Variance Account';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Location Code", "Invt. Posting Group Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckSetupUsage;
    end;

    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        YouCannotDeleteErr: Label 'You cannot delete %1 %2.', Comment = '%1 = Location Code; %2 = Posting Group';
        PostingSetupMgt: Codeunit PostingSetupManagement;

    local procedure CheckSetupUsage()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Location Code", "Location Code");
        ValueEntry.SetRange("Inventory Posting Group", "Invt. Posting Group Code");
        if not ValueEntry.IsEmpty() then
            Error(YouCannotDeleteErr, "Location Code", "Invt. Posting Group Code");
    end;

    procedure GetCapacityVarianceAccount(): Code[20]
    begin
        if "Capacity Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Capacity Variance Account"));

        exit("Capacity Variance Account");
    end;

    procedure GetCapOverheadVarianceAccount(): Code[20]
    begin
        if "Cap. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Cap. Overhead Variance Account"));

        exit("Cap. Overhead Variance Account");
    end;

    procedure GetInventoryAccount(): Code[20]
    begin
        if "Inventory Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Inventory Account"));

        exit("Inventory Account");
    end;

    procedure GetInventoryAccountInterim(): Code[20]
    begin
        if "Inventory Account (Interim)" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Inventory Account (Interim)"));

        exit("Inventory Account (Interim)");
    end;

    procedure GetMaterialVarianceAccount(): Code[20]
    begin
        if "Material Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Material Variance Account"));

        exit("Material Variance Account");
    end;

    procedure GetMfgOverheadVarianceAccount(): Code[20]
    begin
        if "Mfg. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Mfg. Overhead Variance Account"));

        exit("Mfg. Overhead Variance Account");
    end;

    procedure GetSubcontractedVarianceAccount(): Code[20]
    begin
        if "Subcontracted Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Subcontracted Variance Account"));

        exit("Subcontracted Variance Account");
    end;

    procedure GetWIPAccount(): Code[20]
    begin
        if "WIP Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("WIP Account"));

        exit("WIP Account");
    end;

    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        if "Inventory Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Account"));
        if "Inventory Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Account (Interim)"));
        if "WIP Account" = '' then
            SuggestAccount(RecRef, FieldNo("WIP Account"));
        if "Material Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Material Variance Account"));
        if "Capacity Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Capacity Variance Account"));
        if "Mfg. Overhead Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Mfg. Overhead Variance Account"));
        if "Cap. Overhead Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Cap. Overhead Variance Account"));
        if "Subcontracted Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Subcontracted Variance Account"));
        OnAfterSuggestSetupAccount(Rec, RecRef);
        RecRef.Modify();
    end;

    procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        InvtPostingSetupRecRef: RecordRef;
        InvtPostingSetupFieldRef: FieldRef;
    begin
        InvtPostingSetupRecRef.Open(DATABASE::"Inventory Posting Setup");

        InvtPostingSetupRecRef.Reset();
        InvtPostingSetupFieldRef := InvtPostingSetupRecRef.Field(FieldNo("Invt. Posting Group Code"));
        InvtPostingSetupFieldRef.SetRange("Invt. Posting Group Code", "Invt. Posting Group Code");
        InvtPostingSetupFieldRef := InvtPostingSetupRecRef.Field(FieldNo("Location Code"));
        InvtPostingSetupFieldRef.SetFilter('<>%1', "Location Code");
        TempAccountUseBuffer.UpdateBuffer(InvtPostingSetupRecRef, AccountFieldNo);

        InvtPostingSetupRecRef.Close;

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
        end;
    end;
#if not CLEAN18
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure CheckValueEntries(FieldCaption1: Text[250])
    var
        ValueEntry: Record "Value Entry";
        TextChange: Label 'Do you really want to change %1 although value entries exist?';
    begin
        // NAVCZ
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
        ValueEntry.SetRange("Location Code", "Location Code");
        ValueEntry.SetRange("Inventory Posting Group", "Invt. Posting Group Code");
        if not ValueEntry.IsEmpty() then
            if not Confirm(TextChange, false, FieldCaption1) then
                Error('');
    end;
#endif

    local procedure CheckGLAccount(ChangedFieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    begin
        GLAccountCategoryMgt.CheckGLAccount(Database::"Inventory Posting Group", ChangedFieldNo, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory);
    end;

    local procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        GLAccountCategoryMgt.LookupGLAccount(Database::"Inventory Posting Setup", CurrFieldNo, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestSetupAccount(var InventoryPostingSetup: Record "Inventory Posting Setup"; RecRef: RecordRef)
    begin
    end;
}

