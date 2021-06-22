table 5300 "Outlook Synch. Entity"
{
    Caption = 'Outlook Synch. Entity';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Outlook Synch. Entity List";
    LookupPageID = "Outlook Synch. Entity List";
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';

            trigger OnValidate()
            var
                OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
            begin
                if Description <> '' then
                    exit;

                OutlookSynchUserSetup.SetRange("Synch. Entity Code", Code);
                if not OutlookSynchUserSetup.IsEmpty then
                    Error(Text005, FieldCaption(Description), Code);
            end;
        }
        field(3; "Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnLookup()
            var
                TableNo: Integer;
            begin
                TableNo := OSynchSetupMgt.ShowTablesList;

                if TableNo <> 0 then
                    Validate("Table No.", TableNo);
            end;

            trigger OnValidate()
            begin
                if "Table No." = xRec."Table No." then
                    exit;

                CheckUserSetup;
                TestField("Table No.");

                if not OSynchSetupMgt.CheckPKFieldsQuantity("Table No.") then
                    exit;

                if xRec."Table No." <> 0 then begin
                    if not
                       Confirm(
                         StrSubstNo(
                           Text001,
                           OSynchEntityElement.TableCaption,
                           OSynchField.TableCaption,
                           OSynchFilter.TableCaption,
                           OSynchDependency.TableCaption))
                    then begin
                        "Table No." := xRec."Table No.";
                        exit;
                    end;

                    Condition := '';
                    "Outlook Item" := '';

                    OSynchDependency.Reset();
                    OSynchDependency.SetRange("Depend. Synch. Entity Code", Code);
                    OSynchDependency.DeleteAll(true);

                    OSynchEntityElement.Reset();
                    OSynchEntityElement.SetRange("Synch. Entity Code", Code);
                    OSynchEntityElement.DeleteAll(true);

                    OSynchField.Reset();
                    OSynchField.SetRange("Synch. Entity Code", Code);
                    OSynchField.DeleteAll(true);

                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", "Record GUID");
                    OSynchFilter.DeleteAll();
                end;

                CalcFields("Table Caption");
            end;
        }
        field(4; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;

            trigger OnValidate()
            var
                RecordRef: RecordRef;
            begin
                RecordRef.Open("Table No.");
                RecordRef.SetView(Condition);
                Condition := RecordRef.GetView(false);
            end;
        }
        field(6; "Outlook Item"; Text[80])
        {
            Caption = 'Outlook Item';

            trigger OnLookup()
            var
                ItemName: Text[50];
            begin
                ItemName := OSynchSetupMgt.ShowOItemsList;

                if ItemName <> '' then
                    Validate("Outlook Item", ItemName);
            end;

            trigger OnValidate()
            begin
                TestField("Outlook Item");
                if not OSynchSetupMgt.ValidateOutlookItemName("Outlook Item") then
                    Error(Text002);

                if "Outlook Item" = xRec."Outlook Item" then
                    exit;

                CheckUserSetup;

                if xRec."Outlook Item" = '' then
                    exit;

                if not
                   Confirm(
                     StrSubstNo(
                       Text001,
                       OSynchEntityElement.TableCaption,
                       OSynchField.TableCaption,
                       OSynchFilter.TableCaption,
                       OSynchDependency.TableCaption))
                then begin
                    "Outlook Item" := xRec."Outlook Item";
                    exit;
                end;

                OSynchDependency.Reset();
                OSynchDependency.SetRange("Depend. Synch. Entity Code", Code);
                OSynchDependency.DeleteAll(true);

                OSynchEntityElement.Reset();
                OSynchEntityElement.SetRange("Synch. Entity Code", Code);
                OSynchEntityElement.DeleteAll(true);

                OSynchField.Reset();
                OSynchField.SetRange("Synch. Entity Code", Code);
                OSynchField.DeleteAll(true);
            end;
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        OSynchDependency.Reset();
        OSynchDependency.SetRange("Depend. Synch. Entity Code", Code);
        if not OSynchDependency.IsEmpty then
            if not Confirm(Text004) then
                Error('');

        OutlookSynchUserSetup.SetRange("Synch. Entity Code", Code);
        if not OutlookSynchUserSetup.IsEmpty then
            Error(Text003, OutlookSynchUserSetup.TableCaption);

        OSynchDependency.DeleteAll();
        OutlookSynchUserSetup.DeleteAll(true);

        OSynchEntityElement.Reset();
        OSynchEntityElement.SetRange("Synch. Entity Code", Code);
        OSynchEntityElement.DeleteAll(true);

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", Code);
        OSynchField.DeleteAll(true);

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if IsNullGuid("Record GUID") then
            "Record GUID" := CreateGuid;
    end;

    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        OSynchDependency: Record "Outlook Synch. Dependency";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        Text001: Label 'If you change the value in this field, the %1, %2, %3 and %4 records related to this entity will be deleted.\Do you want to change it anyway?';
        Text002: Label 'The Outlook item with this name does not exist.\Click the AssistButton to see a list of valid Outlook items';
        Text003: Label 'You cannot delete this entity because it is set up for synchronization. Please verify %1.';
        Text004: Label 'There are entities which depend on this entity. If you delete it, the relation to its dependencies will be removed.\Do you want to delete it anyway?';
        Text005: Label 'The %1 field cannot be blank because the %2 entity is used with synchronization.';
        Text006: Label 'You cannot change this entity because it is used with synchronization for the user %1.';

    procedure ShowEntityFields()
    begin
        TestField("Outlook Item");
        if "Table No." = 0 then
            FieldError("Table No.");

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", Code);
        OSynchField.SetRange("Element No.", 0);

        PAGE.RunModal(PAGE::"Outlook Synch. Fields", OSynchField);
    end;

    local procedure CheckUserSetup()
    var
        OSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("Synch. Entity Code", Code);
        if OSynchUserSetup.FindFirst then
            Error(Text006, OSynchUserSetup."User ID");
    end;
}

