codeunit 30 "Error Context Element"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        ContextRecordID: RecordID;
        ContextFieldNo: Integer;
        Description: Text[250];
        ElementID: Integer;

    procedure GetID(): Integer
    begin
        exit(ElementID);
    end;

    procedure Set(ID: Integer; ContextRecID: RecordID; ContextFldNo: Integer; AdditionalInfo: Text[250])
    begin
        ContextRecordID := ContextRecID;
        ContextFieldNo := ContextFldNo;
        Description := AdditionalInfo;
        ElementID := ID;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnGetTopElement', '', false, false)]
    local procedure OnGetTopElementHandler(var TopElementID: Integer)
    begin
        if TopElementID < ElementID then
            TopElementID := ElementID;
    end;

    [EventSubscriber(ObjectType::Codeunit, 28, 'OnGetTopContext', '', false, false)]
    local procedure OnGetTopContextHandler(var ErrorMessage: Record "Error Message")
    begin
        if ErrorMessage.ID < ElementID then begin
            ErrorMessage.ID := ElementID;
            ErrorMessage.Validate("Context Record ID", ContextRecordID);
            ErrorMessage.Validate("Context Field Number", ContextFieldNo);
            ErrorMessage."Additional Information" := Description;
        end;
    end;
}

