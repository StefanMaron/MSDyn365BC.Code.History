table 5311 "Outlook Synch. Dependency"
{
    Caption = 'Outlook Synch. Dependency';
    DataCaptionFields = "Synch. Entity Code";
    DrillDownPageID = "Outlook Synch. Dependencies";
    LookupPageID = "Outlook Synch. Dependencies";
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
            TableRelation = "Outlook Synch. Entity Element"."Synch. Entity Code";

            trigger OnValidate()
            begin
                TestField("Element No.");
            end;
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
        }
        field(3; "Depend. Synch. Entity Code"; Code[10])
        {
            Caption = 'Depend. Synch. Entity Code';
            TableRelation = "Outlook Synch. Entity".Code;

            trigger OnValidate()
            begin
                if "Synch. Entity Code" = "Depend. Synch. Entity Code" then
                    Error(Text001, "Synch. Entity Code");

                LoopCheck("Depend. Synch. Entity Code", "Synch. Entity Code");

                CalcFields(Description);
            end;
        }
        field(4; Description; Text[80])
        {
            CalcFormula = Lookup ("Outlook Synch. Entity".Description WHERE(Code = FIELD("Depend. Synch. Entity Code")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
        }
        field(6; "Table Relation"; Text[250])
        {
            Caption = 'Table Relation';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Table Relation");
            end;
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Depend. Synch. Entity Tab. No."; Integer)
        {
            CalcFormula = Lookup ("Outlook Synch. Entity"."Table No." WHERE(Code = FIELD("Depend. Synch. Entity Code")));
            Caption = 'Depend. Synch. Entity Tab. No.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.", "Depend. Synch. Entity Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckUserSetup;

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();
    end;

    trigger OnInsert()
    begin
        CheckUserSetup;

        if IsNullGuid("Record GUID") then
            "Record GUID" := CreateGuid;

        TestField("Table Relation");
    end;

    trigger OnRename()
    begin
        CheckUserSetup;

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();
        Condition := '';
        "Table Relation" := '';
    end;

    var
        Text001: Label 'The selected entity cannot be the same as the %1 entity.';
        Text002: Label 'You cannot add this entity because it is already setup as a dependency for one or more of its own dependencies.';
        OSynchFilter: Record "Outlook Synch. Filter";
        Text003: Label 'You cannot change this dependency for the %1 collection of the %2 entity because it is set up for synchronization.';

    procedure LoopCheck(DependSynchEntityCode: Code[10]; SynchEntityCode: Code[10])
    var
        OSynchDependency: Record "Outlook Synch. Dependency";
    begin
        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", DependSynchEntityCode);
        OSynchDependency.SetRange("Depend. Synch. Entity Code", SynchEntityCode);
        if OSynchDependency.Find('-') then
            Error(Text002);

        OSynchDependency.SetRange("Depend. Synch. Entity Code");
        if OSynchDependency.Find('-') then
            repeat
                if OSynchDependency."Depend. Synch. Entity Code" = "Synch. Entity Code" then
                    Error(Text002);

                LoopCheck(OSynchDependency."Depend. Synch. Entity Code", OSynchDependency."Synch. Entity Code");
            until OSynchDependency.Next = 0;
    end;

    procedure CheckUserSetup()
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        OSynchSetupDetail: Record "Outlook Synch. Setup Detail";
    begin
        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("Synch. Entity Code", "Synch. Entity Code");
        if not OSynchUserSetup.Find('-') then
            exit;

        repeat
            OSynchUserSetup.CalcFields("No. of Elements");
            if OSynchUserSetup."No. of Elements" > 0 then
                if OSynchSetupDetail.Get(OSynchUserSetup."User ID", "Synch. Entity Code", "Element No.") then begin
                    OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
                    Error(
                      Text003,
                      OSynchEntityElement."Outlook Collection",
                      OSynchEntityElement."Synch. Entity Code");
                end;
        until OSynchUserSetup.Next = 0;
    end;
}

