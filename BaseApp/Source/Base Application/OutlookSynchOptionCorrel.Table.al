table 5307 "Outlook Synch. Option Correl."
{
    Caption = 'Outlook Synch. Option Correl.';
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
                SetDefaults;
            end;
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
        }
        field(3; "Field Line No."; Integer)
        {
            Caption = 'Field Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Outlook Object"; Text[80])
        {
            Caption = 'Outlook Object';
        }
        field(6; "Outlook Property"; Text[80])
        {
            Caption = 'Outlook Property';
        }
        field(7; "Outlook Value"; Text[80])
        {
            Caption = 'Outlook Value';

            trigger OnLookup()
            var
                OutlookValue: Text[80];
                EnumerationNo: Integer;
            begin
                OSynchField.Reset();
                OSynchField.Get("Synch. Entity Code", "Element No.", "Field Line No.");
                if not OSynchSetupMgt.CheckOEnumeration(OSynchField) then
                    Error(Text003);

                if "Element No." = 0 then
                    OutlookValue := OSynchSetupMgt.ShowEnumerationsLookup("Outlook Object", '', "Outlook Property", EnumerationNo)
                else begin
                    OSynchEntity.Get("Synch. Entity Code");
                    OutlookValue :=
                      OSynchSetupMgt.ShowEnumerationsLookup(
                        OSynchEntity."Outlook Item",
                        "Outlook Object",
                        "Outlook Property",
                        EnumerationNo);
                end;

                if OutlookValue = '' then
                    exit;

                "Outlook Value" := OutlookValue;
                "Enumeration No." := EnumerationNo;
            end;

            trigger OnValidate()
            var
                IntVar: Integer;
            begin
                OSynchField.Reset();
                OSynchField.Get("Synch. Entity Code", "Element No.", "Field Line No.");

                if OSynchSetupMgt.CheckOEnumeration(OSynchField) then begin
                    if "Element No." = 0 then
                        OSynchSetupMgt.ValidateEnumerationValue(
                          "Outlook Value",
                          "Enumeration No.",
                          OSynchField."Outlook Object",
                          '',
                          OSynchField."Outlook Property")
                    else begin
                        OSynchEntity.Get("Synch. Entity Code");
                        OSynchSetupMgt.ValidateEnumerationValue(
                          "Outlook Value",
                          "Enumeration No.",
                          OSynchEntity."Outlook Item",
                          OSynchField."Outlook Object",
                          OSynchField."Outlook Property");
                    end;
                end else begin
                    if not Evaluate(IntVar, "Outlook Value") then
                        Error(Text002);

                    "Enumeration No." := IntVar;
                end;
            end;
        }
        field(8; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(9; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."));
        }
        field(11; "Option No."; Integer)
        {
            Caption = 'Option No.';
            Editable = false;
        }
        field(12; "Enumeration No."; Integer)
        {
            Caption = 'Enumeration No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.", "Field Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Outlook Value");

        CheckDuplicatedRecords;
    end;

    trigger OnModify()
    begin
        CheckDuplicatedRecords;
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchField: Record "Outlook Synch. Field";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        Text001: Label 'The line you are trying to create already exists.';
        Text002: Label 'This value is not valid. It must be either an integer or an enumeration element.';
        Text003: Label 'The look up window table cannot be opened because this Outlook property is not of the enumeration type.';

    procedure SetDefaults()
    begin
        if "Element No." = 0 then begin
            OSynchEntity.Get("Synch. Entity Code");
            "Outlook Object" := OSynchEntity."Outlook Item";
        end else begin
            OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
            "Outlook Object" := OSynchEntityElement."Outlook Collection";
        end;

        OSynchField.Get("Synch. Entity Code", "Element No.", "Field Line No.");
        "Outlook Property" := OSynchField."Outlook Property";
        "Field No." := OSynchField."Field No.";

        if OSynchField."Table No." = 0 then
            "Table No." := OSynchField."Master Table No."
        else
            "Table No." := OSynchField."Table No.";
    end;

    local procedure CheckDuplicatedRecords()
    var
        OSynchOptionCorrel: Record "Outlook Synch. Option Correl.";
    begin
        OSynchOptionCorrel.Reset();
        OSynchOptionCorrel.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchOptionCorrel.SetRange("Element No.", "Element No.");
        OSynchOptionCorrel.SetRange("Field Line No.", "Field Line No.");
        OSynchOptionCorrel.SetFilter("Line No.", '<>%1', "Line No.");
        OSynchOptionCorrel.SetRange("Option No.", "Option No.");
        OSynchOptionCorrel.SetRange("Enumeration No.", "Enumeration No.");
        if not OSynchOptionCorrel.IsEmpty then
            Error(Text001);
    end;

    procedure GetFieldValue() FieldValue: Text
    var
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        LookupRecRef: RecordRef;
        LookupFieldRef: FieldRef;
    begin
        LookupRecRef.Open("Table No.");
        LookupFieldRef := LookupRecRef.Field("Field No.");
        FieldValue := OutlookSynchTypeConv.OptionValueToText("Option No.", LookupFieldRef.OptionCaption);
        LookupRecRef.Close;
    end;
}

