table 7335 "Bin Template"
{
    Caption = 'Bin Template';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Bin Templates";
    ReplicateData = true;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location WHERE("Bin Mandatory" = CONST(true));
        }
        field(5; "Bin Description"; Text[50])
        {
            Caption = 'Bin Description';
        }
        field(6; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                SetUpNewLine;
            end;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(20; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
        }
        field(22; "Maximum Cubage"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Cubage';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(23; "Maximum Weight"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(24; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code")
        else
            TestField("Zone Code", '');
    end;

    trigger OnModify()
    begin
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code")
        else
            TestField("Zone Code", '');
    end;

    var
        Location: Record Location;
        Zone: Record Zone;

    procedure SetUpNewLine()
    begin
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then begin
            GetZone("Location Code", "Zone Code");
            "Bin Type Code" := Zone."Bin Type Code";
            "Warehouse Class Code" := Zone."Warehouse Class Code";
            "Special Equipment Code" := Zone."Special Equipment Code";
            "Bin Ranking" := Zone."Zone Ranking";
        end;
    end;

    local procedure GetZone(LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        TestField("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code")
        else
            TestField("Zone Code", '');
        if (Zone."Location Code" <> LocationCode) or
           (Zone.Code <> ZoneCode)
        then
            Zone.Get("Location Code", "Zone Code");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;
}

