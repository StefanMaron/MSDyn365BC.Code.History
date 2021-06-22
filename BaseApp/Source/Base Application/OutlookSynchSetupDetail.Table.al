table 5310 "Outlook Synch. Setup Detail"
{
    Caption = 'Outlook Synch. Setup Detail';
    DrillDownPageID = "Outlook Synch. Setup Details";
    LookupPageID = "Outlook Synch. Setup Details";
    ReplicateData = false;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            NotBlank = true;
            TableRelation = "Outlook Synch. User Setup"."User ID";
        }
        field(2; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            Editable = false;
            TableRelation = "Outlook Synch. Entity Element"."Synch. Entity Code";
        }
        field(3; "Element No."; Integer)
        {
            Caption = 'Element No.';
            Editable = false;
            TableRelation = "Outlook Synch. Entity Element"."Element No.";

            trigger OnValidate()
            begin
                CalcFields("Outlook Collection");
            end;
        }
        field(4; "Outlook Collection"; Text[80])
        {
            CalcFormula = Lookup ("Outlook Synch. Entity Element"."Outlook Collection" WHERE("Synch. Entity Code" = FIELD("Synch. Entity Code"),
                                                                                             "Element No." = FIELD("Element No.")));
            Caption = 'Outlook Collection';
            Editable = false;
            FieldClass = FlowField;

            trigger OnLookup()
            var
                ElementNo: Integer;
            begin
                ElementNo := OSynchSetupMgt.ShowOEntityCollections("User ID", "Synch. Entity Code");

                if (ElementNo <> 0) and ("Element No." <> ElementNo) then
                    Validate("Element No.", ElementNo);
            end;
        }
        field(5; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
    }

    keys
    {
        key(Key1; "User ID", "Synch. Entity Code", "Element No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckOSynchEntity;
        SetTableNo;
    end;

    trigger OnModify()
    begin
        CheckOSynchEntity;
        SetTableNo;
    end;

    var
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        Text001: Label 'This collection cannot be synchronized because the relation between this collection and the dependent entity %1 was not defined.';

    procedure CheckOSynchEntity()
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchDependency: Record "Outlook Synch. Dependency";
    begin
        OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
        OSynchEntityElement.TestField("Table No.");
        OSynchEntityElement.TestField("Outlook Collection");
        OSynchEntityElement.TestField("Table Relation");

        OSynchEntityElement.CalcFields("No. of Dependencies");
        if OSynchEntityElement."No. of Dependencies" = 0 then
            exit;

        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", OSynchEntityElement."Synch. Entity Code");
        OSynchDependency.SetRange("Element No.", OSynchEntityElement."Element No.");
        if OSynchDependency.Find('-') then
            repeat
                if OSynchDependency."Table Relation" = '' then
                    Error(Text001, OSynchDependency."Depend. Synch. Entity Code");
            until OSynchDependency.Next = 0;
    end;

    procedure SetTableNo()
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
    begin
        OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
        "Table No." := OSynchEntityElement."Table No.";
    end;
}

