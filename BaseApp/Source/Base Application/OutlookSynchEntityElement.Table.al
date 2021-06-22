table 5301 "Outlook Synch. Entity Element"
{
    Caption = 'Outlook Synch. Entity Element';
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
            TableRelation = "Outlook Synch. Entity".Code;
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
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
                CheckMasterTableNo;
                TableNo := OSynchSetupMgt.ShowTablesList;

                if TableNo <> 0 then
                    Validate("Table No.", TableNo);
            end;

            trigger OnValidate()
            begin
                if "Table No." <> xRec."Table No." then begin
                    CheckUserSetup;
                    CheckMasterTableNo;
                    TestField("Table No.");

                    if not OSynchSetupMgt.CheckPKFieldsQuantity("Table No.") then
                        exit;

                    if "Element No." <> 0 then begin
                        if not
                           Confirm(
                             StrSubstNo(
                               Text003,
                               OSynchField.TableCaption,
                               OSynchFilter.TableCaption,
                               OSynchDependency.TableCaption))
                        then begin
                            "Table No." := xRec."Table No.";
                            exit;
                        end;

                        OSynchField.SetRange("Synch. Entity Code", "Synch. Entity Code");
                        OSynchField.SetRange("Element No.", "Element No.");
                        OSynchField.DeleteAll(true);

                        OSynchFilter.Reset();
                        OSynchFilter.SetRange("Record GUID", "Record GUID");
                        OSynchFilter.DeleteAll();

                        OSynchDependency.Reset();
                        OSynchDependency.SetRange("Synch. Entity Code", "Synch. Entity Code");
                        OSynchDependency.SetRange("Element No.", "Element No.");
                        OSynchDependency.DeleteAll(true);

                        "Table Relation" := '';
                    end;
                end;

                CalcFields("Table Caption", "No. of Dependencies");
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
        field(5; "Table Relation"; Text[250])
        {
            Caption = 'Table Relation';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Table Relation");
            end;
        }
        field(6; "Outlook Collection"; Text[80])
        {
            Caption = 'Outlook Collection';

            trigger OnLookup()
            var
                CollectionName: Text[80];
            begin
                CheckMasterTableNo;
                OSynchEntity.Get("Synch. Entity Code");

                OSynchEntity.TestField("Outlook Item");

                CollectionName := OSynchSetupMgt.ShowOCollectionsList(OSynchEntity."Outlook Item");

                if CollectionName <> '' then
                    Validate("Outlook Collection", CollectionName);
            end;

            trigger OnValidate()
            begin
                if "Outlook Collection" <> '' then begin
                    OSynchEntity.Get("Synch. Entity Code");
                    if not OSynchSetupMgt.ValidateOutlookCollectionName("Outlook Collection", OSynchEntity."Outlook Item") then
                        Error(Text002);
                    CheckCollectionName;
                end;

                if "Outlook Collection" = xRec."Outlook Collection" then
                    exit;

                CheckUserSetup;
                CheckMasterTableNo;

                if "Element No." = 0 then
                    exit;

                if xRec."Outlook Collection" <> '' then
                    if not
                       Confirm(
                         StrSubstNo(
                           Text003,
                           OSynchField.TableCaption,
                           OSynchFilter.TableCaption,
                           OSynchDependency.TableCaption))
                    then begin
                        "Outlook Collection" := xRec."Outlook Collection";
                        exit;
                    end;

                OSynchField.Reset();
                OSynchField.SetRange("Synch. Entity Code", "Synch. Entity Code");
                OSynchField.SetRange("Element No.", "Element No.");
                OSynchField.DeleteAll(true);

                OSynchDependency.Reset();
                OSynchDependency.SetRange("Synch. Entity Code", "Synch. Entity Code");
                OSynchDependency.SetRange("Element No.", "Element No.");
                OSynchDependency.DeleteAll(true);
            end;
        }
        field(7; "Master Table No."; Integer)
        {
            CalcFormula = Lookup ("Outlook Synch. Entity"."Table No." WHERE(Code = FIELD("Synch. Entity Code")));
            Caption = 'Master Table No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "No. of Dependencies"; Integer)
        {
            CalcFormula = Count ("Outlook Synch. Dependency" WHERE("Synch. Entity Code" = FIELD("Synch. Entity Code"),
                                                                   "Element No." = FIELD("Element No.")));
            Caption = 'No. of Dependencies';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.")
        {
        }
        key(Key3; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchSetupDetail.SetRange("Element No.", "Element No.");
        if not OSynchSetupDetail.IsEmpty then
            Error(Text001);

        OSynchSetupDetail.DeleteAll(true);

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchField.SetRange("Element No.", "Element No.");
        OSynchField.DeleteAll(true);

        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchDependency.SetRange("Element No.", "Element No.");
        OSynchDependency.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestField("Table No.");

        if IsNullGuid("Record GUID") then
            "Record GUID" := CreateGuid;
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchField: Record "Outlook Synch. Field";
        OSynchDependency: Record "Outlook Synch. Dependency";
        OSynchSetupDetail: Record "Outlook Synch. Setup Detail";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        Text001: Label 'You cannot delete this collection because it is used with synchronization.';
        Text002: Label 'The Outlook item collection with this name does not exist.\Click the AssistButton to see a list of valid collections for this Outlook item.';
        Text003: Label 'If you change the value in this field, the %1, %2, and %3 records related to this collection will be deleted.\Do you want to change it anyway?';
        Text004: Label 'You cannot change this collection because it is used with synchronization for user %1.';
        Text005: Label 'An Outlook item collection with this name already exists.\Identification fields and values:\%1=''''%2'''',%3=''''%4''''.';

    procedure ShowElementFields()
    begin
        TestField("Synch. Entity Code");
        TestField("Element No.");
        TestField("Table No.");
        TestField("Table Relation");
        TestField("Outlook Collection");

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchField.SetRange("Element No.", "Element No.");

        PAGE.RunModal(PAGE::"Outlook Synch. Fields", OSynchField);
    end;

    procedure ShowDependencies()
    begin
        TestField("Synch. Entity Code");
        TestField("Element No.");
        TestField("Table No.");
        TestField("Table Relation");
        TestField("Outlook Collection");

        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchDependency.SetRange("Element No.", "Element No.");

        PAGE.RunModal(PAGE::"Outlook Synch. Dependencies", OSynchDependency);
        CalcFields("No. of Dependencies");
    end;

    procedure CheckMasterTableNo()
    begin
        CalcFields("Master Table No.");
        if "Master Table No." = 0 then begin
            OSynchEntity.Get("Synch. Entity Code");
            OSynchEntity.TestField("Table No.");
        end;
    end;

    procedure CheckUserSetup()
    var
        OSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        OSynchUserSetup.Reset();
        OSynchUserSetup.SetRange("Synch. Entity Code", "Synch. Entity Code");
        if not OSynchUserSetup.FindSet then
            exit;

        repeat
            OSynchUserSetup.CalcFields("No. of Elements");
            if OSynchUserSetup."No. of Elements" > 0 then
                if OSynchSetupDetail.Get(OSynchUserSetup."User ID", "Synch. Entity Code", "Element No.") then
                    Error(Text004, OSynchUserSetup."User ID");
        until OSynchUserSetup.Next = 0;
    end;

    procedure CheckCollectionName()
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
    begin
        OSynchEntityElement.Reset();
        OSynchEntityElement.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchEntityElement.SetRange("Outlook Collection", "Outlook Collection");
        if OSynchEntityElement.FindFirst then
            Error(
              Text005,
              OSynchEntityElement.FieldCaption("Synch. Entity Code"),
              OSynchEntityElement."Synch. Entity Code",
              OSynchEntityElement.FieldCaption("Element No."),
              OSynchEntityElement."Element No.");
    end;
}

