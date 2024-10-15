table 1511 "Notification Entry"
{
    Caption = 'Notification Entry';
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(3; Type; Enum "Notification Entry Type")
        {
            Caption = 'Type';
        }
        field(4; "Recipient User ID"; Code[50])
        {
            Caption = 'Recipient User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
        }
        field(5; "Triggered By Record"; RecordID)
        {
            Caption = 'Triggered By Record';
            DataClassification = SystemMetadata;
        }
        field(6; "Link Target Page"; Integer)
        {
            Caption = 'Link Target Page';
            TableRelation = "Page Metadata".ID;
        }
        field(7; "Custom Link"; Text[250])
        {
            Caption = 'Custom Link';
            ExtendedDatatype = URL;
        }
        field(8; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            Editable = false;
        }
        field(9; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(10; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(15; "Error Message 2"; Text[250])
        {
            Caption = 'Error Message 2';
            ObsoleteReason = 'Error Message field size has been increased ';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(16; "Error Message 3"; Text[250])
        {
            Caption = 'Error Message 3';
            ObsoleteReason = 'Error Message field size has been increased ';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(17; "Error Message 4"; Text[250])
        {
            Caption = 'Error Message 4';
            ObsoleteReason = 'Error Message field size has been increased ';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(18; "Sender User ID"; Code[50])
        {
            Caption = 'Sender User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Created Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        "Created By" := UserId;
    end;

    var
        DataTypeManagement: Codeunit "Data Type Management";

    [Obsolete('Replaced by CreateNoficicationEntry().', '17.0')]
    procedure CreateNew(NewType: Option "New Record",Approval,Overdue; NewUserID: Code[50]; NewRecord: Variant; NewLinkTargetPage: Integer; NewCustomLink: Text[250])
    begin
        CreateNotificationEntry(
            "Notification Entry Type".FromInteger(NewType), NewUserID, NewRecord, NewLinkTargetPage, NewCustomLink, '');
    end;

    [Obsolete('Replaced by CreateNoficicationEntry().', '17.0')]
    procedure CreateNewEntry(NewType: Option "New Record",Approval,Overdue; RecipientUserID: Code[50]; NewRecord: Variant; NewLinkTargetPage: Integer; NewCustomLink: Text[250]; NewSenderUserID: Code[50])
    begin
        CreateNotificationEntry(
            "Notification Entry Type".FromInteger(NewType), RecipientUserID, NewRecord, NewLinkTargetPage, NewCustomLink, NewSenderUserID);
    end;

    procedure CreateNotificationEntry(NewType: Enum "Notification Entry Type"; RecipientUserID: Code[50]; NewRecord: Variant; NewLinkTargetPage: Integer; NewCustomLink: Text[250]; NewSenderUserID: Code[50])
    var
        NotificationSchedule: Record "Notification Schedule";
        UserSetup: Record "User Setup";
        NewRecRef: RecordRef;
    begin
        if RecipientUserID = '' then
            exit;
        if not UserSetup.Get(RecipientUserID) then
            exit;
        if not DataTypeManagement.GetRecordRef(NewRecord, NewRecRef) then
            exit;

        if InsertRec(NewType, RecipientUserID, NewRecRef.RecordId, NewLinkTargetPage, NewCustomLink, NewSenderUserID) then
            NotificationSchedule.ScheduleNotification(Rec);
    end;

    local procedure InsertRec(NewType: Enum "Notification Entry Type"; NewUserID: Code[50]; NewRecordID: RecordID; NewLinkTargetPage: Integer; NewCustomLink: Text[250]; NewSenderUserID: Code[50]): Boolean;
    begin
        if not DoesTableMatchType(NewType, NewRecordID.TableNo) then
            exit(false);

        Clear(Rec);
        Type := NewType;
        "Recipient User ID" := NewUserID;
        "Triggered By Record" := NewRecordID;
        "Link Target Page" := NewLinkTargetPage;
        "Custom Link" := NewCustomLink;
        "Sender User ID" := NewSenderUserID;
        exit(Insert(true));
    end;

    local procedure DoesTableMatchType(NewType: Enum "Notification Entry Type"; TableNo: Integer): Boolean;
    begin
        case NewType of
            "Notification Entry Type"::Approval:
                exit(TableNo = Database::"Approval Entry");
            "Notification Entry Type"::Overdue:
                exit(TableNo = Database::"Overdue Approval Entry");
        end;
        exit(true);
    end;
}

