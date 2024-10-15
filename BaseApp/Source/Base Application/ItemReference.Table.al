table 5777 "Item Reference"
{
    Caption = 'Item Reference';
    LookupPageID = "Item Reference List";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(3; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(4; "Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Reference Type';

            trigger OnValidate()
            begin
                if ("Reference Type" <> xRec."Reference Type") and (xRec."Reference Type" <> xRec."Reference Type"::" ") then
                    "Reference Type No." := '';
            end;
        }
        field(5; "Reference Type No."; Code[20])
        {
            Caption = 'Reference Type No.';
            TableRelation = IF ("Reference Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Reference Type" = CONST(Vendor)) Vendor."No.";
        }
        field(6; "Reference No."; Code[50])
        {
            Caption = 'Reference No.';
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Discontinue Bar Code"; Boolean)
        {
            Caption = 'Discontinue Bar Code';
            ObsoleteReason = 'Not used in base application.';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference Type No.", "Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Reference No.")
        {
        }
        key(Key3; "Reference No.", "Reference Type", "Reference Type No.")
        {
        }
        key(Key4; "Reference Type", "Reference No.")
        {
        }
        key(Key5; "Item No.", "Variant Code", "Unit of Measure", "Reference Type", "Reference No.")
        {
        }
        key(Key6; "Reference Type", "Reference Type No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Reference Type" = "Reference Type"::Vendor then
            DeleteItemVendor(Rec)
    end;

    trigger OnInsert()
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);

        Item.Get("Item No.");
        if "Unit of Measure" = '' then
            Validate("Unit of Measure", Item."Base Unit of Measure");

        CreateItemVendor();
    end;

    trigger OnRename()
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);

        if ("Reference Type" = "Reference Type"::Vendor) and not ItemVendorResetRequired(xRec, Rec) then
            UpdateItemVendorNo(xRec, "Reference No.")
        else begin
            if xRec."Reference Type" = "Reference Type"::Vendor then
                DeleteItemVendor(xRec);
            if "Reference Type" = "Reference Type"::Vendor then
                CreateItemVendor();
        end;
    end;

    var
        Item: Record Item;
        ItemVend: Record "Item Vendor";
        BlankReferenceTypeErr: Label 'You cannot enter a Reference Type No. for a blank Reference Type.';

    procedure CreateItemVendor()
    begin
        if ("Reference Type" = "Reference Type"::Vendor) and
           ItemVend.WritePermission()
        then begin
            ItemVend.Reset();
            ItemVend.SetRange("Item No.", "Item No.");
            ItemVend.SetRange("Vendor No.", "Reference Type No.");
            ItemVend.SetRange("Variant Code", "Variant Code");
            if ItemVend.IsEmpty() then begin
                ItemVend.Init();
                ItemVend."Item No." := "Item No.";
                ItemVend."Vendor No." := "Reference Type No.";
                ItemVend.Validate("Vendor No.");
                ItemVend."Variant Code" := "Variant Code";
                ItemVend."Vendor Item No." := "Reference No.";
                ItemVend.Insert();
                OnAfterCreateItemVendor(Rec, ItemVend);
            end;
        end;
    end;

    local procedure DeleteItemVendor(ItemReference: Record "Item Reference")
    begin
        if not MultipleItemReferencesExist(ItemReference) then
            if ItemVend.Get(ItemReference."Reference Type No.", ItemReference."Item No.", ItemReference."Variant Code") then
                if UpperCase(DelChr(ItemVend."Vendor Item No.", '<', ' ')) = ItemReference."Reference No." then begin
                    OnBeforeItemVendorDelete(ItemVend, ItemReference);
                    ItemVend.Delete();
                end;
    end;

    local procedure UpdateItemVendorNo(ItemReference: Record "Item Reference"; NewItemRefNo: Code[50])
    begin
        if not MultipleItemReferencesExist(ItemReference) then
            if ItemVend.Get(ItemReference."Reference Type No.", ItemReference."Item No.", ItemReference."Variant Code") then begin
                ItemVend.Validate("Vendor Item No.", NewItemRefNo);
                ItemVend.Modify();
            end;
    end;

    local procedure ItemVendorResetRequired(OldItemReference: Record "Item Reference"; NewItemReference: Record "Item Reference"): Boolean
    begin
        exit(
          (OldItemReference."Item No." <> NewItemReference."Item No.") or
          (OldItemReference."Variant Code" <> NewItemReference."Variant Code") or
          (OldItemReference."Reference Type" <> NewItemReference."Reference Type") or
          (OldItemReference."Reference Type No." <> NewItemReference."Reference Type No."));
    end;

    local procedure MultipleItemReferencesExist(ItemReference: Record "Item Reference"): Boolean
    var
        ItemReference2: Record "Item Reference";
    begin
        ItemReference2.SetRange("Item No.", ItemReference."Item No.");
        ItemReference2.SetRange("Variant Code", ItemReference."Variant Code");
        ItemReference2.SetRange("Reference Type", ItemReference."Reference Type");
        ItemReference2.SetRange("Reference Type No.", ItemReference."Reference Type No.");
        ItemReference2.SetRange("Reference No.", ItemReference."Reference No.");
        ItemReference2.SetFilter("Unit of Measure", '<>%1', ItemReference."Unit of Measure");

        exit(not ItemReference2.IsEmpty);
    end;

    procedure FindItemDescription(var ItemDescription: Text[100]; var ItemDescription2: Text[50]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]) Result: Boolean
    var
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemDescription(ItemDescription, ItemDescription2, ItemNo, VariantCode, UnitOfMeasureCode, ReferenceType, ReferenceTypeNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ItemReference.SetRange("Item No.", ItemNo);
        ItemReference.SetRange("Variant Code", VariantCode);
        ItemReference.SetRange("Unit of Measure", UnitOfMeasureCode);
        ItemReference.SetRange("Reference Type", ReferenceType);
        ItemReference.SetRange("Reference Type No.", ReferenceTypeNo);
        if ItemReference.FindFirst() then begin
            if (ItemReference.Description = '') and (ItemReference."Description 2" = '') then
                exit(false);
            ItemDescription := ItemReference.Description;
            ItemDescription2 := ItemReference."Description 2";
            exit(true);
        end;

        exit(false);
    end;

    procedure HasValidUnitOfMeasure(): Boolean
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if "Unit of Measure" = '' then
            exit(true);

        ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
        ItemUnitOfMeasure.SetRange(Code, "Unit of Measure");
        exit(not ItemUnitOfMeasure.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemVendor(var ItemReference: Record "Item Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemDescription(var ItemDescription: Text[100]; var ItemDescription2: Text[50]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemVendorDelete(ItemVendor: Record "Item Vendor"; ItemReference: Record "Item Reference")
    begin
    end;
}

