table 5717 "Item Cross Reference"
{
    Caption = 'Item Cross Reference';
    LookupPageID = "Cross Reference List";

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
        field(4; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";

            trigger OnValidate()
            begin
                if ("Cross-Reference Type" <> xRec."Cross-Reference Type") and
                   (xRec."Cross-Reference Type" <> xRec."Cross-Reference Type"::" ") or
                   ("Cross-Reference Type" = "Cross-Reference Type"::"Bar Code")
                then
                    "Cross-Reference Type No." := '';
            end;
        }
        field(5; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
            TableRelation = IF ("Cross-Reference Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Cross-Reference Type" = CONST(Vendor)) Vendor."No.";
        }
        field(6; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Discontinue Bar Code"; Boolean)
        {
            Caption = 'Discontinue Bar Code';

            trigger OnValidate()
            begin
                if "Discontinue Bar Code" and
                   ("Cross-Reference Type" <> "Cross-Reference Type"::"Bar Code")
                then
                    Error(Text001, TableCaption);
            end;
        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference Type No.", "Cross-Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Cross-Reference No.")
        {
        }
        key(Key3; "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Discontinue Bar Code")
        {
        }
        key(Key4; "Cross-Reference Type", "Cross-Reference No.")
        {
        }
        key(Key5; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference No.", "Discontinue Bar Code")
        {
        }
        key(Key6; "Cross-Reference Type", "Cross-Reference Type No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Cross-Reference Type" = "Cross-Reference Type"::Vendor then
            DeleteItemVendor(Rec)
    end;

    trigger OnInsert()
    begin
        if ("Cross-Reference Type No." <> '') and
           ("Cross-Reference Type" = "Cross-Reference Type"::" ")
        then
            Error(Text000, FieldCaption("Cross-Reference Type No."));

        Item.Get("Item No.");
        if "Unit of Measure" = '' then
            Validate("Unit of Measure", Item."Base Unit of Measure");
        CreateItemVendor;
    end;

    trigger OnRename()
    begin
        if ("Cross-Reference Type No." <> '') and
           ("Cross-Reference Type" = "Cross-Reference Type"::" ")
        then
            Error(Text000, FieldCaption("Cross-Reference Type No."));

        if ("Cross-Reference Type" = "Cross-Reference Type"::Vendor) and not ItemVendorResetRequired(xRec, Rec) then
            UpdateItemVendorNo(xRec, "Cross-Reference No.")
        else begin
            if xRec."Cross-Reference Type" = "Cross-Reference Type"::Vendor then
                DeleteItemVendor(xRec);
            if "Cross-Reference Type" = "Cross-Reference Type"::Vendor then
                CreateItemVendor;
        end;
    end;

    var
        Text000: Label 'You cannot enter a %1 for a blank Cross-Reference Type.';
        Text001: Label 'This %1 is not a bar code.';
        Item: Record Item;
        ItemVend: Record "Item Vendor";

    local procedure CreateItemVendor()
    begin
        if ("Cross-Reference Type" = "Cross-Reference Type"::Vendor) and
           ItemVend.WritePermission
        then begin
            ItemVend.Reset();
            ItemVend.SetRange("Item No.", "Item No.");
            ItemVend.SetRange("Vendor No.", "Cross-Reference Type No.");
            ItemVend.SetRange("Variant Code", "Variant Code");
            if ItemVend.IsEmpty then begin
                ItemVend."Item No." := "Item No.";
                ItemVend."Vendor No." := "Cross-Reference Type No.";
                ItemVend.Validate("Vendor No.");
                ItemVend."Variant Code" := "Variant Code";
                ItemVend."Vendor Item No." := "Cross-Reference No.";
                ItemVend.Insert();
                OnAfterCreateItemVendor(Rec, ItemVend);
            end;
        end;
    end;

    local procedure DeleteItemVendor(ItemCrossReference: Record "Item Cross Reference")
    begin
        if not MultipleCrossReferencesExist(ItemCrossReference) then
            if ItemVend.Get(ItemCrossReference."Cross-Reference Type No.", ItemCrossReference."Item No.", ItemCrossReference."Variant Code") then
                if UpperCase(DelChr(ItemVend."Vendor Item No.", '<', ' ')) = ItemCrossReference."Cross-Reference No." then begin
                    OnBeforeItemVendorDelete(ItemVend, ItemCrossReference);
                    ItemVend.Delete();
                end;
    end;

    local procedure UpdateItemVendorNo(ItemCrossReference: Record "Item Cross Reference"; NewCrossRefNo: Code[20])
    begin
        if not MultipleCrossReferencesExist(ItemCrossReference) then
            if ItemVend.Get(ItemCrossReference."Cross-Reference Type No.", ItemCrossReference."Item No.", ItemCrossReference."Variant Code") then begin
                ItemVend.Validate("Vendor Item No.", NewCrossRefNo);
                ItemVend.Modify();
            end;
    end;

    local procedure ItemVendorResetRequired(OldItemCrossRef: Record "Item Cross Reference"; NewItemCrossRef: Record "Item Cross Reference"): Boolean
    begin
        exit(
          (OldItemCrossRef."Item No." <> NewItemCrossRef."Item No.") or
          (OldItemCrossRef."Variant Code" <> NewItemCrossRef."Variant Code") or
          (OldItemCrossRef."Cross-Reference Type" <> NewItemCrossRef."Cross-Reference Type") or
          (OldItemCrossRef."Cross-Reference Type No." <> NewItemCrossRef."Cross-Reference Type No."));
    end;

    local procedure MultipleCrossReferencesExist(ItemCrossReference: Record "Item Cross Reference"): Boolean
    var
        ItemCrossReference2: Record "Item Cross Reference";
    begin
        ItemCrossReference2.SetRange("Item No.", ItemCrossReference."Item No.");
        ItemCrossReference2.SetRange("Variant Code", ItemCrossReference."Variant Code");
        ItemCrossReference2.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type");
        ItemCrossReference2.SetRange("Cross-Reference Type No.", ItemCrossReference."Cross-Reference Type No.");
        ItemCrossReference2.SetRange("Cross-Reference No.", ItemCrossReference."Cross-Reference No.");
        ItemCrossReference2.SetFilter("Unit of Measure", '<>%1', ItemCrossReference."Unit of Measure");

        exit(not ItemCrossReference2.IsEmpty);
    end;

    procedure GetItemDescription(var ItemDescription: Text; var ItemDescription2: Text; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; CrossRefType: Option; CrossRefTypeNo: Code[20]): Boolean
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        ItemCrossReference.SetRange("Item No.", ItemNo);
        ItemCrossReference.SetRange("Variant Code", VariantCode);
        ItemCrossReference.SetRange("Unit of Measure", UnitOfMeasureCode);
        ItemCrossReference.SetRange("Cross-Reference Type", CrossRefType);
        ItemCrossReference.SetRange("Cross-Reference Type No.", CrossRefTypeNo);
        if ItemCrossReference.FindFirst then begin
            if (ItemCrossReference.Description = '') and (ItemCrossReference."Description 2" = '') then
                exit(false);
            ItemDescription := ItemCrossReference.Description;
            ItemDescription2 := ItemCrossReference."Description 2";
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
        exit(ItemUnitOfMeasure.FindFirst);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemVendor(var ItemCrossReference: Record "Item Cross Reference"; ItemVendor: Record "Item Vendor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemVendorDelete(ItemVendor: Record "Item Vendor"; ItemCrossReference: Record "Item Cross Reference")
    begin
    end;
}

