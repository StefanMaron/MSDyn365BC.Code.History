table 5952 "Resource Location"
{
    Caption = 'Resource Location';
    DrillDownPageID = "Resource Locations";
    LookupPageID = "Resource Locations";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                CalcFields("Location Name");
            end;
        }
        field(2; "Location Name"; Text[100])
        {
            CalcFormula = Lookup (Location.Name WHERE(Code = FIELD("Location Code")));
            Caption = 'Location Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                CalcFields("Resource Name");
            end;
        }
        field(4; "Resource Name"; Text[100])
        {
            CalcFormula = Lookup (Resource.Name WHERE("No." = FIELD("Resource No.")));
            Caption = 'Resource Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
    }

    keys
    {
        key(Key1; "Location Code", "Resource No.", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

