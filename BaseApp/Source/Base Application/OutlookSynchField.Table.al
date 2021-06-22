table 5304 "Outlook Synch. Field"
{
    Caption = 'Outlook Synch. Field';
    DataCaptionFields = "Synch. Entity Code";
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
            TableRelation = "Outlook Synch. Entity".Code;

            trigger OnValidate()
            begin
                GetMasterInformation;
            end;
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
            TableRelation = "Outlook Synch. Entity Element"."Element No." WHERE("Synch. Entity Code" = FIELD("Synch. Entity Code"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Master Table No."; Integer)
        {
            Caption = 'Master Table No.';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(5; "Outlook Object"; Text[80])
        {
            Caption = 'Outlook Object';
            Editable = false;
        }
        field(6; "Outlook Property"; Text[80])
        {
            Caption = 'Outlook Property';

            trigger OnLookup()
            var
                PropertyName: Text[80];
            begin
                if "Outlook Object" = '' then begin
                    if "Element No." = 0 then
                        Error(
                          Text009,
                          FieldCaption("Outlook Property"),
                          OSynchEntity.FieldCaption("Outlook Item"));
                    Error(
                      Text009,
                      FieldCaption("Outlook Property"),
                      OSynchEntityElement.FieldCaption("Outlook Collection"));
                end;

                if "User-Defined" then
                    Error(Text001);

                if "Element No." = 0 then
                    PropertyName := OSynchSetupMgt.ShowOItemProperties("Outlook Object")
                else begin
                    OSynchEntity.Get("Synch. Entity Code");
                    PropertyName := OSynchSetupMgt.ShowOCollectionProperties(OSynchEntity."Outlook Item", "Outlook Object");
                end;

                if PropertyName <> '' then
                    Validate("Outlook Property", PropertyName);
            end;

            trigger OnValidate()
            begin
                CheckReadOnlyStatus;

                if "Outlook Property" = xRec."Outlook Property" then
                    exit;

                if not "User-Defined" and ("Outlook Object" = '') then begin
                    if "Element No." = 0 then
                        Error(
                          Text009,
                          FieldCaption("Outlook Property"),
                          OSynchEntity.FieldCaption("Outlook Item"));
                    Error(
                      Text009,
                      FieldCaption("Outlook Property"),
                      OSynchEntityElement.FieldCaption("Outlook Collection"));
                end;
                if SetOSynchOptionCorrelFilter(OSynchOptionCorrel) then begin
                    if not Confirm(StrSubstNo(Text008, OSynchOptionCorrel.TableCaption, OSynchFilter.TableCaption)) then begin
                        "Outlook Property" := xRec."Outlook Property";
                        "User-Defined" := xRec."User-Defined";
                        exit;
                    end;

                    OSynchOptionCorrel.DeleteAll();
                end;

                if "Outlook Property" <> '' then
                    "Field Default Value" := '';
            end;
        }
        field(7; "User-Defined"; Boolean)
        {
            Caption = 'User-Defined';

            trigger OnValidate()
            begin
                "Outlook Property" := '';
                if not "User-Defined" then
                    exit;

                Validate("Outlook Property");
            end;
        }
        field(8; "Search Field"; Boolean)
        {
            Caption = 'Search Field';
        }
        field(9; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
        }
        field(10; "Table No."; Integer)
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
                CalcFields("Table Caption");

                if "Table No." = xRec."Table No." then
                    exit;

                if not OSynchSetupMgt.CheckPKFieldsQuantity("Table No.") then
                    exit;

                if ("Table Relation" <> '') or SetOSynchOptionCorrelFilter(OSynchOptionCorrel) then begin
                    if not Confirm(StrSubstNo(Text008, OSynchOptionCorrel.TableCaption, OSynchFilter.TableCaption)) then begin
                        "Table No." := xRec."Table No.";
                        exit;
                    end;

                    OSynchOptionCorrel.DeleteAll();

                    OSynchFilter.Reset();
                    OSynchFilter.SetRange("Record GUID", "Record GUID");
                    OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                    OSynchFilter.DeleteAll();

                    "Table Relation" := '';
                end;

                "Field No." := 0;
                "Field Default Value" := '';
            end;
        }
        field(11; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Table Relation"; Text[250])
        {
            Caption = 'Table Relation';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Table Relation");
                CheckReadOnlyStatus;
            end;
        }
        field(13; "Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Field No.';

            trigger OnLookup()
            var
                FieldNo: Integer;
            begin
                if "Table No." = 0 then
                    FieldNo := OSynchSetupMgt.ShowTableFieldsList("Master Table No.")
                else
                    FieldNo := OSynchSetupMgt.ShowTableFieldsList("Table No.");

                if FieldNo <> 0 then
                    Validate("Field No.", FieldNo);
            end;

            trigger OnValidate()
            begin
                TestField("Field No.");
                CheckReadOnlyStatus;

                if "Field No." = xRec."Field No." then
                    exit;

                if "Table No." = 0 then
                    Field.Get("Master Table No.", "Field No.")
                else
                    Field.Get("Table No.", "Field No.");

                TypeHelper.TestFieldIsNotObsolete(Field);

                if Field.Class = Field.Class::FlowFilter then
                    Error(Text002, Field.Class);

                if not Field.Enabled then
                    Error(Text012, Field.FieldName);

                if "User-Defined" then
                    Validate("Outlook Property", Field."Field Caption");

                if SetOSynchOptionCorrelFilter(OSynchOptionCorrel) then begin
                    if not Confirm(StrSubstNo(Text008, OSynchOptionCorrel.TableCaption, OSynchFilter.TableCaption)) then begin
                        "Field No." := xRec."Field No.";
                        exit;
                    end;

                    OSynchOptionCorrel.DeleteAll();
                end;

                "Field Default Value" := '';
            end;
        }
        field(15; "Read-Only Status"; Option)
        {
            Caption = 'Read-Only Status';
            Editable = false;
            OptionCaption = ' ,Read-Only in Microsoft Dynamics NAV,Read-Only in Outlook';
            OptionMembers = " ","Read-Only in Microsoft Dynamics NAV","Read-Only in Outlook";

            trigger OnValidate()
            begin
                CheckReadOnlyStatus;
            end;
        }
        field(16; "Field Default Value"; Text[250])
        {
            Caption = 'Field Default Value';

            trigger OnValidate()
            var
                RecRef: RecordRef;
                FldRef: FieldRef;
                BooleanValue: Boolean;
            begin
                TestField("Master Table No.");
                TestField("Field No.");

                if "Field Default Value" = xRec."Field Default Value" then
                    exit;

                if "Outlook Property" <> '' then
                    Error(Text005, FieldCaption("Field Default Value"), FieldCaption("Outlook Property"));

                Clear(RecRef);
                Clear(FldRef);

                if "Table No." = 0 then begin
                    Field.Get("Master Table No.", "Field No.");
                    TypeHelper.TestFieldIsNotObsolete(Field);
                    RecRef.Open("Master Table No.", true);
                end else begin
                    Field.Get("Table No.", "Field No.");
                    TypeHelper.TestFieldIsNotObsolete(Field);
                    RecRef.Open("Table No.", true);
                end;

                if Field.Class = Field.Class::FlowField then
                    Error(Text010, Field.Class);

                FldRef := RecRef.Field("Field No.");

                if Field.Type = Field.Type::Option then begin
                    if not OSynchTypeConversion.EvaluateOptionField(FldRef, "Field Default Value") then
                        Error(Text004, "Field Default Value", FldRef.Type, FldRef.OptionCaption);
                    DefaultValueExpression := Format(OSynchTypeConversion.TextToOptionValue("Field Default Value", FldRef.OptionCaption))
                end else begin
                    if not Evaluate(FldRef, "Field Default Value") then
                        Error(Text003, FieldCaption("Field Default Value"), FldRef.Type);

                    if Field.Type = Field.Type::Boolean then begin
                        Evaluate(BooleanValue, "Field Default Value");
                        if BooleanValue then
                            DefaultValueExpression := '1'
                        else
                            DefaultValueExpression := '0';
                    end;
                end;

                RecRef.Close;
            end;
        }
        field(17; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(99; DefaultValueExpression; Text[250])
        {
            Caption = 'DefaultValueExpression';
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.", "Line No.")
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
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
    begin
        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();

        OSynchOptionCorrel.Reset();
        OSynchOptionCorrel.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchOptionCorrel.SetRange("Element No.", "Element No.");
        OSynchOptionCorrel.SetRange("Field Line No.", "Line No.");
        OSynchOptionCorrel.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestField("Field No.");

        if "Table No." <> 0 then
            TestField("Table Relation");

        CheckDuplicatedRecords;

        if IsNullGuid("Record GUID") then
            "Record GUID" := CreateGuid;
    end;

    trigger OnModify()
    begin
        TestField("Field No.");
        CheckDuplicatedRecords;

        if "Table No." <> 0 then
            TestField("Table Relation");
    end;

    var
        "Field": Record "Field";
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        Text001: Label 'You cannot choose from a list of Outlook item collections for user-defined fields.';
        Text002: Label 'You cannot use a %1 field for synchronization.';
        Text003: Label 'The value of the %1 field cannot be converted to the %2 datatype.';
        Text004: Label 'The value of the %1 field cannot be converted to the %2 datatype.\The possible option values are: ''%3''.';
        Text005: Label 'The %1 field should be blank when the %2 field is used.';
        Text006: Label 'This is not a valid Outlook property name.';
        Text007: Label 'You cannot synchronize the %1 and the %2 fields because they are both write protected.';
        Text008: Label 'If you change the value of this field, %1 and %2 records related to this entry will be removed.\Do you want to change this field anyway?';
        Text009: Label 'You cannot change the %1 field if the %2 is not specified for this entity.';
        Text010: Label 'You cannot use this field for %1 fields.', Comment = '%1: Field.Class::FlowField';
        Text011: Label 'The %1 table cannot be open, because the %2 or %3 fields are empty.\Fill in these fields with the appropriate values and try again.';
        Text012: Label 'You cannot select the %1 field because it is disabled.';
        Text013: Label 'You cannot use this value because an Outlook property with this name exists.';
        Text014: Label 'The entry you are trying to create already exists.';
        TypeHelper: Codeunit "Type Helper";

    local procedure GetMasterInformation()
    begin
        if "Element No." = 0 then begin
            OSynchEntity.Get("Synch. Entity Code");
            "Master Table No." := OSynchEntity."Table No.";
            "Outlook Object" := OSynchEntity."Outlook Item";
        end else begin
            OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
            "Master Table No." := OSynchEntityElement."Table No.";
            "Outlook Object" := OSynchEntityElement."Outlook Collection";
        end;
    end;

    local procedure CheckReadOnlyStatus()
    var
        OSynchProcessLine: Codeunit "Outlook Synch. Process Line";
        IsReadOnlyOutlook: Boolean;
        IsReadOnlyNavision: Boolean;
    begin
        IsReadOnlyOutlook := CheckOtlookPropertyName;

        if ("Outlook Property" <> '') and ("Field No." <> 0) then begin
            if "Table No." = 0 then begin
                Field.Get("Master Table No.", "Field No.");
                TypeHelper.TestFieldIsNotObsolete(Field);
                if OSynchProcessLine.CheckKeyField("Master Table No.", "Field No.") or (Field.Class = Field.Class::FlowField) then
                    IsReadOnlyNavision := true;
            end else begin
                OSynchFilter.Reset();
                OSynchFilter.SetRange("Record GUID", "Record GUID");
                OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                if OSynchFilter.Find('-') then
                    repeat
                        Field.Get(OSynchFilter."Master Table No.", OSynchFilter."Master Table Field No.");
                        TypeHelper.TestFieldIsNotObsolete(Field);
                        if OSynchProcessLine.CheckKeyField("Master Table No.", OSynchFilter."Master Table Field No.") or
                           (Field.Class = Field.Class::FlowField)
                        then
                            IsReadOnlyNavision := true;
                    until OSynchFilter.Next = 0;
            end;

            if IsReadOnlyOutlook then begin
                if IsReadOnlyNavision then
                    Error(Text007, "Outlook Property", GetFieldCaption);
                "Read-Only Status" := "Read-Only Status"::"Read-Only in Outlook";
            end else begin
                if IsReadOnlyNavision then
                    "Read-Only Status" := "Read-Only Status"::"Read-Only in Microsoft Dynamics NAV"
                else
                    "Read-Only Status" := "Read-Only Status"::" ";
            end;
        end else begin
            if "Field No." = 0 then
                "Read-Only Status" := "Read-Only Status"::"Read-Only in Outlook"
            else
                "Read-Only Status" := "Read-Only Status"::"Read-Only in Microsoft Dynamics NAV";
        end;
    end;

    local procedure CheckOtlookPropertyName(): Boolean
    var
        IsReadOnly: Boolean;
    begin
        if "Outlook Property" = '' then
            exit(false);

        if "User-Defined" then
            if "Element No." = 0 then begin
                if OSynchSetupMgt.ValidateOItemPropertyName("Outlook Property", "Outlook Object", IsReadOnly, true) then
                    Error(Text013);
            end else begin
                OSynchEntity.Get("Synch. Entity Code");
                if OSynchSetupMgt.ValidateOCollectPropertyName(
                     "Outlook Property",
                     OSynchEntity."Outlook Item",
                     "Outlook Object",
                     IsReadOnly,
                     true)
                then
                    Error(Text013);
            end
        else
            if "Element No." = 0 then begin
                if not OSynchSetupMgt.ValidateOItemPropertyName("Outlook Property", "Outlook Object", IsReadOnly, false) then
                    Error(Text006);
            end else begin
                OSynchEntity.Get("Synch. Entity Code");
                if not
                   OSynchSetupMgt.ValidateOCollectPropertyName(
                     "Outlook Property",
                     OSynchEntity."Outlook Item",
                     "Outlook Object",
                     IsReadOnly,
                     false)
                then
                    Error(Text006);
            end;

        exit(IsReadOnly);
    end;

    local procedure CheckDuplicatedRecords()
    var
        OSynchField: Record "Outlook Synch. Field";
    begin
        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchField.SetRange("Element No.", "Element No.");
        OSynchField.SetFilter("Line No.", '<>%1', "Line No.");
        OSynchField.SetRange("Outlook Property", "Outlook Property");
        OSynchField.SetRange("Table No.", "Table No.");
        OSynchField.SetRange("Field No.", "Field No.");
        if not OSynchField.IsEmpty then
            Error(Text014);
    end;

    [Scope('OnPrem')]
    procedure ShowOOptionCorrelForm()
    begin
        if ("Field No." = 0) or ("Outlook Property" = '') then
            Error(Text011,
              OSynchOptionCorrel.TableCaption,
              FieldCaption("Field No."),
              FieldCaption("Outlook Property"));
        OSynchSetupMgt.ShowOOptionCorrelForm(Rec);
    end;

    local procedure SetOSynchOptionCorrelFilter(var outlookSynchOptionCorrel: Record "Outlook Synch. Option Correl."): Boolean
    begin
        outlookSynchOptionCorrel.Reset();
        outlookSynchOptionCorrel.SetRange("Synch. Entity Code", "Synch. Entity Code");
        outlookSynchOptionCorrel.SetRange("Element No.", "Element No.");
        outlookSynchOptionCorrel.SetRange("Field Line No.", "Line No.");
        exit(not outlookSynchOptionCorrel.IsEmpty);
    end;

    procedure GetFieldCaption(): Text
    begin
        if "Table No." <> 0 then begin
            if TypeHelper.GetField("Table No.", "Field No.", Field) then
                exit(Field."Field Caption")
        end else
            if TypeHelper.GetField("Master Table No.", "Field No.", Field) then
                exit(Field."Field Caption");

        exit('');
    end;
}

