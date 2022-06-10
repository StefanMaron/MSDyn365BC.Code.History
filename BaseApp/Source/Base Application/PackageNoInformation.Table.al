table 6515 "Package No. Information"
{
    Caption = 'Package No. Information';
    DataCaptionFields = "Item No.", "Variant Code", "Package No.", Description;
    DrillDownPageID = "Package No. Information List";
    LookupPageID = "Package No. Information List";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(3; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            NotBlank = true;
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
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
            CalcFormula = Exist("Item Tracking Comment" WHERE("Item No." = FIELD("Item No."),
                                                               "Variant Code" = FIELD("Variant Code"),
                                                               "Serial/Lot No." = FIELD("Package No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Inventory; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("Item No."),
                                                                  "Variant Code" = FIELD("Variant Code"),
                                                                  "Package No." = FIELD("Package No."),
                                                                  "Location Code" = FIELD("Location Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
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
        field(24; "Expired Inventory"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Remaining Quantity" WHERE("Item No." = FIELD("Item No."),
                                                                              "Variant Code" = FIELD("Variant Code"),
                                                                              "Package No." = FIELD("Package No."),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Expiration Date" = FIELD("Date Filter"),
                                                                              Open = CONST(true),
                                                                              Positive = CONST(true)));
            Caption = 'Expired Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Package No.")
        {
            Clustered = true;
        }
        key(Key2; "Package No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Variant Code", "Package No.")
        {
        }
    }

    trigger OnDelete()
    begin
        ItemTrackingComment.SetRange(Type, ItemTrackingComment.Type::"Package No.");
        ItemTrackingComment.SetRange("Item No.", "Item No.");
        ItemTrackingComment.SetRange("Variant Code", "Variant Code");
        ItemTrackingComment.SetRange("Serial/Lot No.", "Package No.");
        ItemTrackingComment.DeleteAll();
    end;

    var
        ItemTrackingComment: Record "Item Tracking Comment";


    procedure GetCountryName(): Text[50]
    var
        Country: Record "Country/Region";
    begin
        if not Country.Get("Country/Region Code") then
            exit('');

        exit(Country.Name);
    end;

    procedure GetCountryLocalCode(): Code[10]
    var
        Country: Record "Country/Region";
    begin
        if not Country.Get("Country/Region Code") then
            exit('');

        exit('');
    end;

    procedure ShowCard(PackageNo: Code[50]; TrackingSpecification: Record "Tracking Specification")
    var
        PackageNoInfoNew: Record "Package No. Information";
        PackageNoInfoCard: Page "Package No. Information Card";
    begin
        Clear(PackageNoInfoCard);
        PackageNoInfoCard.Init(TrackingSpecification);

        PackageNoInfoNew.SetRange("Item No.", TrackingSpecification."Item No.");
        PackageNoInfoNew.SetRange("Variant Code", TrackingSpecification."Variant Code");
        PackageNoInfoNew.SetRange("Package No.", PackageNo);

        PackageNoInfoCard.SetTableView(PackageNoInfoNew);
        PackageNoInfoCard.Run();
    end;

    procedure ShowCard(PackageNo: Code[50]; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        PackageNoInfoNew: Record "Package No. Information";
        PackageNoInfoCard: Page "Package No. Information Card";
    begin
        Clear(PackageNoInfoCard);
        PackageNoInfoCard.InitWhse(WhseItemTrackingLine);

        PackageNoInfoNew.SetRange("Item No.", WhseItemTrackingLine."Item No.");
        PackageNoInfoNew.SetRange("Variant Code", WhseItemTrackingLine."Variant Code");
        PackageNoInfoNew.SetRange("Package No.", PackageNo);

        PackageNoInfoCard.SetTableView(PackageNoInfoNew);
        PackageNoInfoCard.Run();
    end;
}
