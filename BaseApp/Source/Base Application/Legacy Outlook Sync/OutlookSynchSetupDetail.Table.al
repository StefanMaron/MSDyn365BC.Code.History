table 5310 "Outlook Synch. Setup Detail"
{
    Caption = 'Outlook Synch. Setup Detail';
#if not CLEAN19
    DrillDownPageID = "Outlook Synch. Setup Details";
    LookupPageID = "Outlook Synch. Setup Details";
#endif
    ReplicateData = false;
#if CLEAN19
    ObsoleteState = Removed;
#else
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            NotBlank = true;
#if not CLEAN19
            TableRelation = "Outlook Synch. User Setup"."User ID";
#endif
        }
        field(2; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            Editable = false;
#if not CLEAN19
            TableRelation = "Outlook Synch. Entity Element"."Synch. Entity Code";
#endif
        }
        field(3; "Element No."; Integer)
        {
            Caption = 'Element No.';
            Editable = false;
#if not CLEAN19
            TableRelation = "Outlook Synch. Entity Element"."Element No.";
#endif

            trigger OnValidate()
            begin
                CalcFields("Outlook Collection");
            end;
        }
        field(4; "Outlook Collection"; Text[80])
        {
#if not CLEAN19
            CalcFormula = Lookup("Outlook Synch. Entity Element"."Outlook Collection" WHERE("Synch. Entity Code" = FIELD("Synch. Entity Code"),
                                                                                             "Element No." = FIELD("Element No.")));
#endif
            Caption = 'Outlook Collection';
            Editable = false;
            FieldClass = FlowField;

#if not CLEAN19
            trigger OnLookup()
            var
                ElementNo: Integer;
            begin
                ElementNo := OSynchSetupMgt.ShowOEntityCollections("User ID", "Synch. Entity Code");

                if (ElementNo <> 0) and ("Element No." <> ElementNo) then
                    Validate("Element No.", ElementNo);
            end;
#endif
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

#if not CLEAN19
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
            until OSynchDependency.Next() = 0;
    end;

    procedure SetTableNo()
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
    begin
        OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
        "Table No." := OSynchEntityElement."Table No.";
    end;
#endif
}
