table 5451 "Graph Integration Record"
{
    ObsoleteState = Removed;
    ReplicateData = false;
    ObsoleteReason = 'This functionality will be removed. The API that it was integrating to was discontinued.';
    ObsoleteTag = '20.0';
    Caption = 'Graph Integration Record';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Graph ID"; Text[250])
        {
            Caption = 'Graph ID';
        }
        field(3; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';
            TableRelation = "Integration Record"."Integration ID";
        }
        field(4; "Last Synch. Modified On"; DateTime)
        {
            Caption = 'Last Synch. Modified On';
        }
        field(5; "Last Synch. Graph Modified On"; DateTime)
        {
            Caption = 'Last Synch. Graph Modified On';
        }
        field(6; "Table ID"; Integer)
        {
            CalcFormula = lookup("Integration Record"."Table ID" where("Integration ID" = field("Integration ID")));
            Caption = 'Table ID';
            FieldClass = FlowField;
        }
        field(7; ChangeKey; Text[250])
        {
            Caption = 'ChangeKey';
        }
        field(8; XRMId; Guid)
        {
            Caption = 'XRMId';
        }
    }

    keys
    {
        key(Key1; "Graph ID", "Integration ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration ID")
        {
        }
        key(Key3; "Last Synch. Modified On", "Integration ID")
        {
        }
        key(Key4; "Last Synch. Graph Modified On", "Graph ID")
        {
        }
    }

    fieldgroups
    {
    }
}

