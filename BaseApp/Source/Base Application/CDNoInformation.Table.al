table 12408 "CD No. Information"
{
    Caption = 'CD No. Information';
    DataCaptionFields = Type, "No.", "Variant Code", "CD No.", Description;
    DrillDownPageID = "CD No. Information List";
    LookupPageID = "CD No. Information List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            var
                Item: Record Item;
                FA: Record "Fixed Asset";
            begin
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            Description := Item.Description;
                        end;
                    Type::"Fixed Asset":
                        begin
                            FA.Get("No.");
                            Description := FA.Description;
                        end;
                end;

                Validate("CD Header No.");
            end;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(3; "CD No."; Code[30])
        {
            Caption = 'CD No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                InvtSetup.Get();
                if InvtSetup."Check CD No. Format" then
                    "Temporary CD No." := not CDNoFormat.Check("CD No.", false);
            end;
        }
        field(4; "CD Line No."; Integer)
        {
            Caption = 'CD Line No.';
            Description = 'Not used';
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,Fixed Asset';
            OptionMembers = Item,"Fixed Asset";
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(9; "CD Header No."; Code[30])
        {
            Caption = 'CD Header No.';
            TableRelation = "CD No. Header";

            trigger OnValidate()
            begin
                if "CD Header No." <> '' then begin
                    CDNoHeader.Get("CD Header No.");
                    if CDNoHeader."Country/Region of Origin Code" <> '' then
                        "Country/Region Code" := CDNoHeader."Country/Region of Origin Code";
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Temporary CD No."; Boolean)
        {
            Caption = 'Temporary CD No.';

            trigger OnValidate()
            begin
                if not "Temporary CD No." then
                    CDNoFormat.Check("CD No.", true);
            end;
        }
        field(12; "Certificate Number"; Code[20])
        {
            Caption = 'Certificate Number';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = Exist ("Item Tracking Comment" WHERE(Type = CONST("Lot No."),
                                                               "Item No." = FIELD("No."),
                                                               "Variant Code" = FIELD("Variant Code"),
                                                               "Serial/Lot/CD No." = FIELD("CD No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            Description = 'Not used';
        }
        field(21; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(23; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Filter"));
        }
        field(30; Inventory; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                  "CD No." = FIELD("CD No."),
                                                                  "Location Code" = FIELD("Location Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Positive Adjmt."; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                  "CD No." = FIELD("CD No."),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Entry Type" = CONST("Positive Adjmt.")));
            Caption = 'Positive Adjmt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; Purchases; Decimal)
        {
            CalcFormula = Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                  "CD No." = FIELD("CD No."),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Entry Type" = CONST(Purchase)));
            Caption = 'Purchases';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Negative Adjmt."; Decimal)
        {
            CalcFormula = - Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                   "Variant Code" = FIELD("Variant Code"),
                                                                   "CD No." = FIELD("CD No."),
                                                                   "Location Code" = FIELD("Location Filter"),
                                                                   "Entry Type" = CONST("Negative Adjmt.")));
            Caption = 'Negative Adjmt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; Sales; Decimal)
        {
            CalcFormula = - Sum ("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                   "Variant Code" = FIELD("Variant Code"),
                                                                   "CD No." = FIELD("CD No."),
                                                                   "Location Code" = FIELD("Location Filter"),
                                                                   "Entry Type" = CONST(Sale)));
            Caption = 'Sales';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Current No."; Code[6])
        {
            Caption = 'Current No.';
            Description = 'Not used';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Variant Code", "CD No.")
        {
            Clustered = true;
        }
        key(Key2; "CD No.")
        {
            Enabled = false;
        }
        key(Key3; "CD Header No.", "CD No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Type = Type::Item then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetCurrentKey(
              "Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.", "CD No.");
            ItemLedgEntry.SetRange("Item No.", "No.");
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
            ItemLedgEntry.SetRange("CD No.", "CD No.");
            if not ItemLedgEntry.IsEmpty then
                Error(Text001, "CD No.");
        end;

        ItemTrackingComment.SetRange(Type, ItemTrackingComment.Type::"CD No.");
        ItemTrackingComment.SetRange("Item No.", "No.");
        ItemTrackingComment.SetRange("Variant Code", "Variant Code");
        ItemTrackingComment.SetRange("Serial/Lot/CD No.", "CD No.");
        ItemTrackingComment.DeleteAll();
    end;

    var
        ItemTrackingComment: Record "Item Tracking Comment";
        ItemLedgEntry: Record "Item Ledger Entry";
        Text001: Label 'You cannot change %1 because there are one or more ledger entries for this item.';
        CDNoFormat: Record "CD No. Format";
        CDNoHeader: Record "CD No. Header";
        InvtSetup: Record "Inventory Setup";

    [Scope('OnPrem')]
    procedure GetCountryName(): Text[50]
    var
        Country: Record "Country/Region";
    begin
        if not Country.Get("Country/Region Code") then
            exit('');

        if Country."Local Name" <> '' then
            exit(Country."Local Name");

        exit(Country.Name);
    end;

    [Scope('OnPrem')]
    procedure GetCountryLocalCode(): Code[10]
    var
        Country: Record "Country/Region";
    begin
        if not Country.Get("Country/Region Code") then
            exit('');

        if Country."Local Country/Region Code" <> '' then
            exit(Country."Local Country/Region Code");

        exit('');
    end;
}

