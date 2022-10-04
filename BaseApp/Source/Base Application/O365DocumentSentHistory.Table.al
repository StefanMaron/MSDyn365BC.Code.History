table 2158 "O365 Document Sent History"
{
    Caption = 'O365 Document Sent History';
    Permissions = TableData "O365 Document Sent History" = rimd;
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(4; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(7; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor;
        }
        field(11; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
        }
        field(12; "Job Last Status"; Option)
        {
            Caption = 'Job Last Status';
            OptionCaption = ',In Process,Finished,Error';
            OptionMembers = ,"In Process",Finished,Error;
            trigger OnValidate()
            var
                JobQueueLogEntry: Record "Job Queue Log Entry";
            begin
                if "Job Last Status" = "Job Last Status"::"In Process" then
                    Clear("Job Completed")
                else
                    if IsNullGuid("Job Queue Entry ID") then
                        "Job Completed" := CurrentDateTime
                    else begin
                        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
                        JobQueueLogEntry.SetCurrentKey("Entry No.");

                        if JobQueueLogEntry.FindLast() then
                            "Job Completed" := JobQueueLogEntry."End Date/Time"
                        else
                            "Job Completed" := CurrentDateTime;
                    end;
            end;
        }
        field(13; "Job Completed"; DateTime)
        {
            Caption = 'Job Completed';
        }
        field(14; Notified; Boolean)
        {
            Caption = 'Notified';
        }
        field(15; NotificationCleared; Boolean)
        {
            Caption = 'NotificationCleared';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", Posted, "Created Date-Time")
        {
            Clustered = true;
        }
        key(Key2; "Job Queue Entry ID")
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21
    var
        DocSentHistoryCategoryTxt: Label 'AL Doc Sent History', Locked = true;
        FailedToSetStatusTelemetryErr: Label 'Failed to set Document Sent History status to %1 because of error %2.', Locked = true;
        UnrecognizedParentRecordErr: Label 'Unsupported parent record: Table %1', Locked = true;
        StatusSetTelemetryMsg: Label 'Document Sent History status set to %1.', Locked = true;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure NewInProgressFromJobQueue(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        RecRef: RecordRef;
    begin
        SetRange("Job Queue Entry ID", JobQueueEntry.ID);
        if FindFirst() then begin
            Validate("Job Last Status", "Job Last Status"::"In Process");
            exit(Modify(true));
        end;
        SetRange("Job Queue Entry ID");

        if not RecRef.Get(JobQueueEntry."Record ID to Process") then
            exit(false);

        if not NewInProgressFromRecRef(RecRef) then
            exit(false);

        Validate("Job Queue Entry ID", JobQueueEntry.ID);
        Validate("Job Last Status", "Job Last Status"::"In Process");

        exit(Modify(true));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure DeleteSentHistoryForDocument(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; DocPosted: Boolean)
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
    begin
        O365DocumentSentHistory.SetRange("Document Type", DocType);
        O365DocumentSentHistory.SetRange("Document No.", DocNo);
        O365DocumentSentHistory.SetRange(Posted, DocPosted);

        O365DocumentSentHistory.DeleteAll();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowJobQueueErrorMessage()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
        if not JobQueueLogEntry.FindFirst() then
            exit;

        JobQueueLogEntry.ShowErrorMessage();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetJobQueueErrorMessage(): Text
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
        if not JobQueueLogEntry.FindFirst() then
            exit;

        exit(JobQueueLogEntry."Error Message");
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure NewInProgressFromSalesHeader(SalesHeader: Record "Sales Header"): Boolean
    begin
        SetHistoryForDocumentAsNotified(SalesHeader."Document Type", SalesHeader."No.", false);

        "Document Type" := SalesHeader."Document Type";
        "Document No." := SalesHeader."No.";
        Posted := false;
        "Created Date-Time" := CurrentDateTime;
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        Validate("Job Last Status", "Job Last Status"::"In Process");

        exit(Insert(true));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure NewInProgressFromSalesInvoiceHeader(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SetHistoryForDocumentAsNotified("Document Type"::Invoice, SalesInvoiceHeader."No.", true);

        "Document Type" := "Document Type"::Invoice;
        "Document No." := SalesInvoiceHeader."No.";
        Posted := true;
        "Created Date-Time" := CurrentDateTime;
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesInvoiceHeader."Bill-to Customer No.";
        Validate("Job Last Status", "Job Last Status"::"In Process");

        exit(Insert(true));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure NewInProgressFromRecRef(RecRef: RecordRef) Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNewInProgressFromRecRef(RecRef, Result, IsHandled, Rec);
        if IsHandled then
            exit(Result);

        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    exit(NewInProgressFromSalesHeader(SalesHeader));
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    exit(NewInProgressFromSalesInvoiceHeader(SalesInvoiceHeader));
                end;
            else begin
                    Session.LogMessage('000028D', StrSubstNo(UnrecognizedParentRecordErr, RecRef.Number), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocSentHistoryCategoryTxt);
                    exit(false);
                end;
        end;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetHistoryForDocumentAsNotified(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; IsPosted: Boolean)
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
    begin
        O365DocumentSentHistory.SetRange("Document Type", DocumentType);
        O365DocumentSentHistory.SetRange("Document No.", DocumentNo);
        O365DocumentSentHistory.SetRange(Posted, IsPosted);

        O365DocumentSentHistory.ModifyAll(Notified, true);
        O365DocumentSentHistory.ModifyAll(NotificationCleared, true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetStatusAsFailed(): Boolean
    begin
        Validate("Job Last Status", "Job Last Status"::Error);

        if Modify(true) then begin
            Session.LogMessage('00001ZM', StrSubstNo(StatusSetTelemetryMsg, "Job Last Status"::Error), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocSentHistoryCategoryTxt);
            exit(true);
        end;

        Session.LogMessage('00001ZN', StrSubstNo(FailedToSetStatusTelemetryErr, "Job Last Status"::Error, GetLastErrorText), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', DocSentHistoryCategoryTxt);
        exit(false);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetStatusAsSuccessfullyFinished(): Boolean
    begin
        Validate("Job Last Status", "Job Last Status"::Finished);

        if Modify(true) then begin
            Session.LogMessage('00001ZO', StrSubstNo(StatusSetTelemetryMsg, "Job Last Status"::Finished), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocSentHistoryCategoryTxt);
            exit(true);
        end;

        Session.LogMessage('00001ZP', StrSubstNo(FailedToSetStatusTelemetryErr, "Job Last Status"::Finished, GetLastErrorText), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', DocSentHistoryCategoryTxt);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewInProgressFromRecRef(RecRef: RecordRef; var Result: Boolean; var IsHandled: Boolean; var O365DocumentSentHistory: Record "O365 Document Sent History")
    begin
    end;
#endif
}

