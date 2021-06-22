page 5337 "CRM Coupled Fields"
{
    Caption = 'Dynamics 365 Sales Coupled Fields';
    Editable = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Coupling Field Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the field''s name in Dynamics 365 Sales.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the field''s name in Dynamics 365 Sales.';
                }
                field("Integration Value"; "Integration Value")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the field''s value in Dynamics 365 Sales.';
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the direction of data integration.';
                }
                field("Validate Field"; "Validate Field")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether to validate the field''s value in Business Central.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetSourceRecord(CouplingRecordBuffer: Record "Coupling Record Buffer")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMRecordRef: RecordRef;
        NAVRecordRef: RecordRef;
        RecordID: RecordID;
        CRMRecordIsSet: Boolean;
    begin
        RecordID := CouplingRecordBuffer."NAV Record ID";
        NAVRecordRef := RecordID.GetRecord;
        NAVRecordRef.Find;

        CRMRecordIsSet := not IsNullGuid(CouplingRecordBuffer."CRM ID");
        if CRMRecordIsSet then begin
            CRMRecordRef.Open(CouplingRecordBuffer."CRM Table ID");
            FindCRMRecRefByPK(CRMRecordRef, CouplingRecordBuffer."CRM ID");
        end;

        DeleteAll();
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", CouplingRecordBuffer."CRM Table Name");
        if IntegrationFieldMapping.FindSet then
            repeat
                Init;
                case IntegrationFieldMapping.Direction of
                    IntegrationFieldMapping.Direction::Bidirectional,
                  IntegrationFieldMapping.Direction::ToIntegrationTable:
                        "Field Name" :=
                          GetFieldCaption(CouplingRecordBuffer."CRM Table ID", IntegrationFieldMapping."Integration Table Field No.");
                    IntegrationFieldMapping.Direction::FromIntegrationTable:
                        "Field Name" :=
                          GetFieldCaption(CouplingRecordBuffer."NAV Table ID", IntegrationFieldMapping."Field No.");
                end;
                if IntegrationFieldMapping."Field No." <> 0 then
                    Value := GetFieldValue(NAVRecordRef, IntegrationFieldMapping."Field No.");
                if CRMRecordIsSet and (IntegrationFieldMapping."Integration Table Field No." <> 0) then
                    "Integration Value" := GetFieldValue(CRMRecordRef, IntegrationFieldMapping."Integration Table Field No.");
                Direction := IntegrationFieldMapping.Direction;
                "Validate Field" := IntegrationFieldMapping."Validate Field";
                Insert;
            until IntegrationFieldMapping.Next = 0;
    end;

    local procedure GetFieldCaption(TableNo: Integer; FieldNo: Integer) FieldCaption: Text[50]
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        FieldCaption := CopyStr(FieldRef.Caption, 1, MaxStrLen(FieldCaption));
        RecRef.Close;
    end;

    local procedure GetFieldValue(RecordRef: RecordRef; FieldNo: Integer): Text[250]
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(FieldNo);
        exit(CopyStr(Format(FieldRef.Value), 1, 250));
    end;

    local procedure FindCRMRecRefByPK(var RecordRef: RecordRef; CRMId: Guid): Boolean
    var
        FieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        FieldRef := PrimaryKeyRef.FieldIndex(1);
        FieldRef.SetRange(CRMId);
        exit(RecordRef.FindFirst);
    end;
}

