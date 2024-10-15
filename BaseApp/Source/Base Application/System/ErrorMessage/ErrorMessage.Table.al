namespace System.Utilities;

using Microsoft.Finance.Dimension;
using Microsoft.Utilities;
using System.Reflection;

table 700 "Error Message"
{
    Caption = 'Error Message';
    DrillDownPageID = "Error Messages Part";
    LookupPageID = "Error Messages Part";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Table Number" := GetTableNo("Record ID");
            end;
        }
        field(3; "Field Number"; Integer)
        {
            Caption = 'Field Number';

            trigger OnValidate()
            begin
                if "Table Number" = 0 then
                    "Field Number" := 0;
            end;
        }
        field(4; "Message Type"; Option)
        {
            Caption = 'Message Type';
            Editable = false;
            OptionCaption = 'Error,Warning,Information';
            OptionMembers = Error,Warning,Information;
        }
        field(5; "Description"; Text[250])
        {
            Caption = 'Description';
            Editable = false;
#if not CLEAN22
            // Description and Message fields are sync'd with database events in "Error Message Management"
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
            ObsoleteReason = 'Replaced by "Message" which has an increase in field length.';
        }
        field(6; "Additional Information"; Text[250])
        {
            Caption = 'Additional Information';
            Editable = false;
        }
        field(7; "Support Url"; Text[250])
        {
            Caption = 'Support Url';
            Editable = false;
        }
        field(8; "Table Number"; Integer)
        {
            Caption = 'Table Number';
        }
        field(10; "Context Record ID"; RecordID)
        {
            Caption = 'Context Record ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Context Table Number" := GetTableNo("Context Record ID");
            end;
        }
        field(11; "Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table Number"),
                                                              "No." = field("Field Number")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Table Name"; Text[80])
        {
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Table Number")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Context Field Number"; Integer)
        {
            Caption = 'Context Field Number';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Context Table Number" = 0 then
                    "Context Field Number" := 0;
            end;
        }
        field(14; "Context Table Number"; Integer)
        {
            Caption = 'Context Table Number';
            DataClassification = SystemMetadata;
        }
        field(15; "Context Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Context Table Number"),
                                                              "No." = field("Context Field Number")));
            Caption = 'Context Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Register ID"; Guid)
        {
            Caption = 'Register ID';
            DataClassification = SystemMetadata;
            TableRelation = "Error Message Register".ID;
        }
        field(17; "Created On"; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
        }
        field(18; Context; Boolean)
        {
            Caption = 'Context';
            DataClassification = SystemMetadata;
        }
        field(20; Duplicate; Boolean)
        {
            Caption = 'Duplicate';
            DataClassification = SystemMetadata;
        }
        field(21; "Error Call Stack"; BLOB)
        {
            Caption = 'Error Call Stack';
            DataClassification = SystemMetadata;
        }
        field(22; "Message"; Text[2048])
        {
            Caption = 'Description';
            Editable = false;
#if not CLEAN22
            // Description and Message fields are sync'd with database events in "Error Message Management"
#endif
        }
        field(23; "Reg. Err. Msg. System ID"; Guid) // Link temporary error message with registered (committed) error message.
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Context Record ID", "Record ID")
        {
        }
        key(Key3; "Message Type", ID)
        {
        }
        key(Key4; "Created On")
        {
        }
        key(Key5; "Register ID", ID, Context)
        {
        }
        key(Key6; Context, "Context Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ContextErrorMessage: Record "Error Message";
        DataTypeManagement: Codeunit "Data Type Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        CachedLastID: Integer;
        CachedRegisterID: Guid;

        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        IfNotEmptyErr: Label '''%1'' in ''%2'' must be blank.', Comment = '%1=caption of a field, %2=key of record';
        IfLengthExceededErr: Label 'The maximum length of ''%1'' in ''%2'' is %3 characters. The actual length is %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfInvalidCharactersErr: Label '''%1'' in ''%2'' contains characters that are not valid.', Comment = '%1=caption of a field, %2=key of record';
        IfOutsideRangeErr: Label '''%1'' in ''%2'' is outside of the permitted range from %3 to %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfGreaterThanErr: Label '''%1'' in ''%2'' must be less than or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfLessThanErr: Label '''%1'' in ''%2'' must be greater than or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfEqualToErr: Label '''%1'' in ''%2'' must not be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfNotEqualToErr: Label '''%1'' in ''%2'' must be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        HasErrorsMsg: Label 'One or more errors were found. You must resolve all the errors before you can proceed.';
        ErrorContextNotFoundErr: Label 'Error context not found: %1', Comment = '%1 - Record Id';

    trigger OnInsert()
    begin
        Rec.Validate("Created On", CurrentDateTime());
        if not Context then begin
            CachedLastID := ID;
            CachedRegisterID := "Register ID";
        end;
    end;

    procedure HandleDrillDown(SourceFieldNo: Integer)
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnDrillDownSource(Rec, SourceFieldNo, IsHandled);
        if not IsHandled then
            case SourceFieldNo of
                FieldNo("Context Record ID"):
                    begin
                        if not RecRef.Get("Context Record ID") then
                            error(ErrorContextNotFoundErr, Format("Context Record ID"));
                        PageManagement.PageRunAtField("Context Record ID", "Context Field Number", false);
                    end;
                FieldNo("Record ID"):
                    if IsDimSetEntryInconsistency() then
                        RunDimSetEntriesPage()
                    else
                        PageManagement.PageRunAtField("Record ID", "Field Number", false);
            end
    end;

    local procedure IsDimSetEntryInconsistency(): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        RecId: RecordId;
    begin
        RecId := "Record ID";
        exit((RecId.TableNo = Database::"Dimension Set Entry") and ("Field Number" = DimensionSetEntry.FieldNo("Global Dimension No.")));
    end;

    local procedure RunDimSetEntriesPage()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntries: Page "Dimension Set Entries";
    begin
        DimensionSetEntry.Get("Record ID");
        DimensionSetEntries.SetRecord(DimensionSetEntry);
        DimensionSetEntries.SetUpdDimSetGlblDimNoVisible();
        DimensionSetEntries.Run();
    end;

    procedure LogIfEmpty(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option): Integer
    var
        RecordRef: RecordRef;
        TempRecordRef: RecordRef;
        FieldRef: FieldRef;
        EmptyFieldRef: FieldRef;
        NewDescription: Text;
        IsHandled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            exit(0);

        TempRecordRef.Open(RecordRef.Number, true);
        EmptyFieldRef := TempRecordRef.Field(FieldNumber);

        if FieldRef.Value <> EmptyFieldRef.Value then
            exit(0);

        IsHandled := false;
        OnLogIfEmptyOnAfterCheckEmptyValue(FieldRef, EmptyFieldRef, IsHandled);
        if IsHandled then
            exit(0);

        NewDescription := StrSubstNo(IfEmptyErr, FieldRef.Caption, Format(RecordRef.RecordId));

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfNotEmpty(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option): Integer
    var
        RecordRef: RecordRef;
        TempRecordRef: RecordRef;
        FieldRef: FieldRef;
        EmptyFieldRef: FieldRef;
        NewDescription: Text;
        IsHandled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            exit(0);

        TempRecordRef.Open(RecordRef.Number, true);
        EmptyFieldRef := TempRecordRef.Field(FieldNumber);

        if FieldRef.Value = EmptyFieldRef.Value then
            exit(0);

        IsHandled := false;
        OnLogIfNotEmptyOnAfterCheckEmptyValue(FieldRef, EmptyFieldRef, IsHandled);
        if IsHandled then
            exit(0);

        NewDescription := StrSubstNo(IfNotEmptyErr, FieldRef.Caption, Format(RecordRef.RecordId));

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfLengthExceeded(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; MaxLength: Integer): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
        StringLength: Integer;
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            exit(0);

        StringLength := StrLen(Format(FieldRef.Value));
        if StringLength <= MaxLength then
            exit(0);

        NewDescription := StrSubstNo(IfLengthExceededErr, FieldRef.Caption, Format(RecordRef.RecordId), MaxLength, StringLength);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfInvalidCharacters(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; ValidCharacters: Text): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            exit(0);

        if DelChr(Format(FieldRef.Value), '=', ValidCharacters) = '' then
            exit(0);

        NewDescription := StrSubstNo(IfInvalidCharactersErr, FieldRef.Caption, Format(RecordRef.RecordId));

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfOutsideRange(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; LowerBound: Variant; UpperBound: Variant): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if FieldValueIsWithinFilter(RecRelatedVariant, FieldNumber, RecordRef, FieldRef, '%1..%2', LowerBound, UpperBound) then
            exit(0);

        NewDescription := StrSubstNo(IfOutsideRangeErr, FieldRef.Caption, Format(RecordRef.RecordId), LowerBound, UpperBound);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfGreaterThan(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; LowerBound: Variant): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if FieldValueIsWithinFilter(RecRelatedVariant, FieldNumber, RecordRef, FieldRef, '<=%1', LowerBound, '') then
            exit(0);

        NewDescription := StrSubstNo(IfGreaterThanErr, FieldRef.Caption, Format(RecordRef.RecordId), LowerBound);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfLessThan(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; UpperBound: Variant): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if FieldValueIsWithinFilter(RecRelatedVariant, FieldNumber, RecordRef, FieldRef, '>=%1', UpperBound, '') then
            exit(0);

        NewDescription := StrSubstNo(IfLessThanErr, FieldRef.Caption, Format(RecordRef.RecordId), UpperBound);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfEqualTo(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; ValueVariant: Variant): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if FieldValueIsWithinFilter(RecRelatedVariant, FieldNumber, RecordRef, FieldRef, '<>%1', ValueVariant, '') then
            exit(0);

        NewDescription := StrSubstNo(IfEqualToErr, FieldRef.Caption, Format(RecordRef.RecordId), ValueVariant);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogIfNotEqualTo(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; ValueVariant: Variant): Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        NewDescription: Text;
    begin
        if FieldValueIsWithinFilter(RecRelatedVariant, FieldNumber, RecordRef, FieldRef, '=%1', ValueVariant, '') then
            exit(0);

        NewDescription := StrSubstNo(IfNotEqualToErr, FieldRef.Caption, Format(RecordRef.RecordId), ValueVariant);

        exit(LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription));
    end;

    procedure LogContextFieldError(ContextFieldNumber: Integer; NewDescription: Text; RecRelatedVariant: Variant; SourceFieldNumber: Integer; SupportURL: Text[250]): Integer
    var
        RecordRef: RecordRef;
    begin
        LogSimpleMessage("Message Type", NewDescription);
        Validate("Support Url", SupportURL);
        Validate("Context Field Number", ContextFieldNumber);
        case true of
            RecRelatedVariant.IsInteger:
                Validate("Table Number", RecRelatedVariant);
            DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef):
                Validate("Record ID", RecordRef.RecordId);
        end;
        Validate("Field Number", SourceFieldNumber);
        Modify(true);

        exit(ID);
    end;

    procedure LogSimpleMessage(MessageType: Option; NewDescription: Text): Integer
    begin
        exit(LogSimpleMessage(MessageType, NewDescription, ''));
    end;

    procedure LogSimpleMessage(MessageType: Option; NewDescription: Text; ErrorCallStack: Text): Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLogSimpleMessage(MessageType, NewDescription, IsHandled);
        if IsHandled then
            exit;

        AssertRecordTemporaryOrInContext();

        ID := FindLastMessageID() + 1;

        Init();
        Validate("Message Type", MessageType);
        Validate("Message", CopyStr(NewDescription, 1, MaxStrLen("Message")));
        Validate("Context Record ID", ContextErrorMessage."Context Record ID");
        Validate("Context Field Number", ContextErrorMessage."Context Field Number");
        Validate("Additional Information", ContextErrorMessage."Additional Information");
        if ErrorCallStack <> '' then
            SetErrorCallStack(ErrorCallStack)
        else
            if "Message Type" = "Message Type"::Error then
                SetErrorCallStack(ErrorMessageMgt.GetCurrCallStack());
        Insert(true);

        exit(ID);
    end;

    procedure LogMessage(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; NewDescription: Text): Integer
    var
        RecordRef: RecordRef;
        ErrorMessageID: Integer;
        TableNumber: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription, IsHandled);
        if IsHandled then
            exit;

        if RecRelatedVariant.IsInteger then
            TableNumber := RecRelatedVariant
        else begin
            if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef) then
                exit(0);

            ErrorMessageID := FindRecord(RecordRef.RecordId, FieldNumber, MessageType, NewDescription);
            if ErrorMessageID <> 0 then
                exit(ErrorMessageID);
        end;

        LogSimpleMessage(MessageType, NewDescription);
        if TableNumber = 0 then
            Validate("Record ID", RecordRef.RecordId)
        else
            Validate("Table Number", TableNumber);
        Validate("Field Number", FieldNumber);
        Modify(true);

        exit(ID);
    end;

    procedure LogDetailedMessage(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; NewDescription: Text; AdditionalInformation: Text[250]; SupportUrl: Text[250]): Integer
    begin
        LogMessage(RecRelatedVariant, FieldNumber, MessageType, NewDescription);
        Validate("Additional Information", AdditionalInformation);
        Validate("Support Url", SupportUrl);
        Modify(true);

        exit(ID);
    end;

    procedure LogLastError()
    begin
        LogLastError(true);
    end;

    internal procedure LogLastError(ClearError: Boolean)
    begin
        if (GetLastErrorCode <> '') and (GetLastErrorText <> '') then begin
            if ErrorMessageMgt.GetLastContext(Rec) then begin
                ID := FindLastMessageID() + 1;
                Validate("Message Type", "Message Type"::Error);
                Validate("Message", CopyStr(GetLastErrorText(), 1, MaxStrLen("Message")));
                SetErrorCallStack(GetLastErrorCallStack());
                Insert(true);
            end else
                LogSimpleMessage("Message Type"::Error, GetLastErrorText, GetLastErrorCallStack());

            if ClearError then
                ClearLastError();
        end;
    end;

    procedure AddMessageDetails(MessageID: Integer; AdditionalInformation: Text[250]; SupportUrl: Text[250])
    begin
        if MessageID = 0 then
            exit;

        Get(MessageID);
        Validate("Additional Information", AdditionalInformation);
        Validate("Support Url", SupportUrl);
        Modify(true);
    end;

    local procedure FindLastMessageID(): Integer
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if IsTemporary then begin
            TempErrorMessage.Copy(Rec, true);
            exit(TempErrorMessage.FindLastID());
        end;
        ErrorMessage.Copy(Rec);
        exit(ErrorMessage.FindLastID());
    end;

    procedure FindLastID(): Integer
    begin
        Reset();
        if FindLast() then
            exit(ID);
    end;

    procedure GetContext(var ErrorMessage: Record "Error Message") Result: Boolean
    begin
        Result := ErrorMessageMgt.GetTopContext(ErrorMessage);
        ContextErrorMessage := ErrorMessage;
    end;

    procedure GetLastID(): Integer
    begin
        ClearFilters();
        SetRange(Context, false);
        SetRange("Register ID", "Register ID");

        if not FindLast() then
            exit(0);

        CachedLastID := ID;
        CachedRegisterID := "Register ID";
        exit(ID);
    end;

    procedure GetCachedLastID(): Integer
    begin
        if CachedRegisterID <> "Register ID" then
            exit(GetLastID());

        exit(CachedLastID);
    end;

    local procedure GetTableNo(RecordID: RecordID): Integer
    begin
        exit(RecordID.TableNo);
    end;

    procedure SetContext(ContextRecordVariant: Variant)
    var
        RecordRef: RecordRef;
    begin
        Clear(ContextErrorMessage);
        case true of
            ContextRecordVariant.IsRecordId:
                ContextErrorMessage.Validate("Context Record ID", ContextRecordVariant);
            ContextRecordVariant.IsInteger:
                ContextErrorMessage."Context Table Number" := ContextRecordVariant;
            DataTypeManagement.GetRecordRef(ContextRecordVariant, RecordRef):
                ContextErrorMessage.Validate("Context Record ID", RecordRef.RecordId)
        end;
    end;

    procedure ClearLog()
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetContextFilter();
        DeleteAll(true);
    end;

    procedure ClearLogRec(RecordVariant: Variant)
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetContextFilter();
        SetRecordFilter(RecordVariant);
        DeleteAll(true);
    end;

    procedure HasErrorMessagesRelatedTo(RecRelatedVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
    begin
        AssertRecordTemporaryOrInContext();

        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecordRef) then
            exit(false);

        ClearFilters();
        SetContextFilter();
        SetRange("Record ID", RecordRef.RecordId);
        exit(not IsEmpty);
    end;

    procedure ErrorMessageCount(LowestSeverityMessageType: Option): Integer
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetContextFilter();
        SetRange(Context, false);
        SetRange("Message Type", "Message Type"::Error, LowestSeverityMessageType);
        exit(Count);
    end;

    procedure HasErrors(ShowMessage: Boolean): Boolean
    begin
        if ErrorMessageCount("Message Type"::Error) = 0 then
            exit(false);

        if ShowMessage and GuiAllowed then
            Message(HasErrorsMsg);

        exit(true);
    end;

    procedure ShowErrors() IsPageOpen: Boolean
    var
        ErrorMessages: Page "Error Messages";
        IsHandled: Boolean;
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetRange(Context, false);
        if IsEmpty() then
            Error(GetLastErrorText);

        IsHandled := false;
        OnShowErrorsOnBeforeErrorMessagesRun(Rec, IsPageOpen, IsHandled);
        if IsHandled then
            exit(IsPageOpen);

        if GuiAllowed then begin
            ErrorMessages.SetRecords(Rec);
            ErrorMessages.Run();
            IsPageOpen := true;
        end else begin
            SetRange("Message Type", "Message Type"::Error);
            if FindFirst() then
                Error("Message");
            IsPageOpen := false;
        end;
    end;

    procedure ShowErrorMessages(RollBackOnError: Boolean) ErrorString: Text
    var
        ErrorMessages: Page "Error Messages";
        IsHandled: Boolean;
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetContextFilter();
        SetRange(Context, false);
        if IsEmpty() then
            exit;

        IsHandled := false;
        OnShowErrorMessagesOnBeforeErrorMessagesRun(Rec, ErrorString, IsHandled);
        if IsHandled then
            exit(ErrorString);

        if GuiAllowed then begin
            ErrorMessages.SetRecords(Rec);
            ErrorMessages.Run();
        end;

        ErrorString := ToString();

        if RollBackOnError then
            if HasErrors(false) then
                Error('');

        exit;
    end;

    procedure ToString(): Text
    var
        ErrorString: Text;
    begin
        AssertRecordTemporaryOrInContext();

        ClearFilters();
        SetContextFilter();
        SetCurrentKey("Message Type", ID);
        SetRange(Context, false);
        if FindSet() then
            repeat
                if ErrorString <> '' then
                    ErrorString += '\';
                ErrorString += Format("Message Type") + ': ' + "Message";
            until Next() = 0;
        ClearFilters();
        exit(ErrorString);
    end;

    procedure ThrowError()
    begin
        AssertRecordTemporaryOrInContext();

        if HasErrors(false) then
            Error(ToString());
    end;

    local procedure FieldValueIsWithinFilter(RecRelatedVariant: Variant; FieldNumber: Integer; var RecordRef: RecordRef; var FieldRef: FieldRef; FilterString: Text; FilterValue1: Variant; FilterValue2: Variant): Boolean
    var
        TempRecordRef: RecordRef;
        TempFieldRef: FieldRef;
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            exit(false);

        TempRecordRef.Open(RecordRef.Number, true);
        TempRecordRef.Init();
        TempFieldRef := TempRecordRef.Field(FieldNumber);
        TempFieldRef.Value(FieldRef.Value);
        TempRecordRef.Insert();

        TempFieldRef.SetFilter(FilterString, FilterValue1, FilterValue2);

        exit(not TempRecordRef.IsEmpty);
    end;

    procedure FindRecord(RecordID: RecordID; FieldNumber: Integer; MessageType: Option; NewDescription: Text) FoundID: Integer
    begin
        ClearFilters();
        SetContextFilter();
        SetRange(Context, false);
        SetRange("Record ID", RecordID);
        SetRange("Field Number", FieldNumber);
        SetRange("Message Type", MessageType);
        SetRange("Message", CopyStr(NewDescription, 1, MaxStrLen("Message")));
        FoundID := 0;
        if FindFirst() then
            FoundID := ID;
        ClearFilters();
    end;

    local procedure AssertRecordTemporary()
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);
    end;

    local procedure AssertRecordTemporaryOrInContext()
    begin
        if (ContextErrorMessage.ID <> 0) or (ContextErrorMessage.ID = 0) and (ContextErrorMessage."Context Table Number" = 0) then begin
            Clear(ContextErrorMessage);
            if not ErrorMessageMgt.GetTopContext(ContextErrorMessage) then
                AssertRecordTemporary();
        end else
            if ContextErrorMessage."Context Table Number" = 0 then
                AssertRecordTemporary();
    end;

    procedure CopyToTemp(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempID: Integer;
    begin
        if not FindSet() then
            exit;

        TempID := TempErrorMessage.FindLastID();
        repeat
            if TempErrorMessage.FindRecord("Record ID", "Field Number", "Message Type", "Message") = 0 then begin
                TempID += 1;
                TempErrorMessage := Rec;
                TempErrorMessage.ID := TempID;
                TempErrorMessage."Reg. Err. Msg. System ID" := Rec.SystemId;
                TempErrorMessage.Insert();
            end;
        until Next() = 0;
        TempErrorMessage.Reset();
    end;

    procedure CopyFromTemp(var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorMessage: Record "Error Message";
    begin
        if not TempErrorMessage.FindSet() then
            exit;

        repeat
            ErrorMessage := TempErrorMessage;
            ErrorMessage.ID := 0;
            ErrorMessage.Insert(true);
        until TempErrorMessage.Next() = 0;
    end;

    procedure CopyFromContext(ContextRecordVariant: Variant)
    var
        ErrorMessage: Record "Error Message";
        RecordRef: RecordRef;
    begin
        AssertRecordTemporary();

        if not DataTypeManagement.GetRecordRef(ContextRecordVariant, RecordRef) then
            exit;

        ErrorMessage.SetRange("Context Record ID", RecordRef.RecordId);
        ErrorMessage.CopyToTemp(Rec);
    end;

    local procedure ClearFilters()
    var
        LocalContextErrorMessage: Record "Error Message";
    begin
        LocalContextErrorMessage := ContextErrorMessage;
        Reset();
        ContextErrorMessage := LocalContextErrorMessage;
    end;

    local procedure SetContextFilter()
    begin
        if ContextErrorMessage."Context Table Number" = 0 then
            SetRange("Context Record ID")
        else
            SetRange("Context Record ID", ContextErrorMessage."Context Record ID");
    end;

    local procedure SetRecordFilter(RecordVariant: Variant)
    var
        RecordRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
        SetRange("Record ID", RecordRef.RecordId);
    end;

    procedure GetErrorCallStack(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "Error Call Stack".HasValue() then
            exit('');
        CalcFields("Error Call Stack");
        "Error Call Stack".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetErrorCallStack(NewCallStack: Text)
    var
        OutStream: OutStream;
    begin
        "Error Call Stack".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.Write(NewCallStack);
    end;

    procedure ShowErrorCallStack()
    var
        CallStack: Text;
    begin
        CallStack := GetErrorCallStack();
        if CallStack <> '' then
            Message(CallStack);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogMessage(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; NewDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogSimpleMessage(MessageType: Option; NewDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogIfEmptyOnAfterCheckEmptyValue(FieldRef: FieldRef; EmptyFieldRef: FieldRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogIfNotEmptyOnAfterCheckEmptyValue(FieldRef: FieldRef; EmptyFieldRef: FieldRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownSource(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowErrorMessagesOnBeforeErrorMessagesRun(var ErrorMessage: Record "Error Message"; var ErrorString: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowErrorsOnBeforeErrorMessagesRun(var ErrorMessage: Record "Error Message"; var IsPageOpen: Boolean; var IsHandled: Boolean)
    begin
    end;
}
