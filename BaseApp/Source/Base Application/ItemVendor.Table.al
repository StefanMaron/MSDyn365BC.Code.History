table 99 "Item Vendor"
{
    Caption = 'Item Vendor';
    LookupPageID = "Item Vendor Catalog";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                Vend.Get("Vendor No.");
                "Lead Time Calculation" := Vend."Lead Time Calculation";
            end;
        }
        field(6; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(7; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Vendor No.")
        {
        }
        key(Key3; "Vendor No.", "Vendor Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Vendor No.", "Item No.", "Variant Code")
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteItemCrossReference;
    end;

    trigger OnInsert()
    begin
        InsertItemCrossReference;
    end;

    trigger OnModify()
    begin
        UpdateItemCrossReference;
    end;

    trigger OnRename()
    begin
        UpdateItemCrossReference;
    end;

    var
        Vend: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
        DistIntegration: Codeunit "Dist. Integration";
        LeadTimeMgt: Codeunit "Lead-Time Management";

    local procedure InsertItemCrossReference()
    begin
        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                DistIntegration.InsertItemCrossReference(Rec);
    end;

    local procedure DeleteItemCrossReference()
    begin
        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                DistIntegration.DeleteItemCrossReference(Rec);
    end;

    local procedure UpdateItemCrossReference()
    begin
        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                if ("Vendor No." <> xRec."Vendor No.") or ("Item No." <> xRec."Item No.") or
                   ("Variant Code" <> xRec."Variant Code") or ("Vendor Item No." <> xRec."Vendor Item No.")
                then
                    DistIntegration.UpdateItemCrossReference(Rec, xRec);
    end;
}

