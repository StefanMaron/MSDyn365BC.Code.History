#if not CLEAN20
page 2823 "Native - Email Preview"
{
    Caption = 'nativeInvoicingEmailPreview', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ODataKeyFields = "Document Id";
    PageType = List;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(documentId; "Document Id")
                {
                    ApplicationArea = All;
                    Caption = 'documentId', Locked = true;
                }
                field(email; Email)
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;
                    ToolTip = 'Specifies email address.';

                    trigger OnValidate()
                    var
                        MailManagement: Codeunit "Mail Management";
                    begin
                        if Email = '' then
                            Error(EmptyEmailAddressErr);
                        if Email = PrevEmail then
                            exit;
                        MailManagement.ValidateEmailAddressField(Email);
                    end;
                }
                field(subject; Subject)
                {
                    ApplicationArea = All;
                    Caption = 'subject';
                    ToolTip = 'Specifies e-mail subject.';

                    trigger OnValidate()
                    begin
                        if Subject = '' then
                            Error(EmptyEmailSubjectErr);
                    end;
                }
                field(body; Content)
                {
                    ApplicationArea = All;
                    Caption = 'body';
                    Editable = false;
                    ToolTip = 'Specifies e-mail body.';
                }
                field(bodyText; BodyText)
                {
                    ApplicationArea = All;
                    Caption = 'bodyText', Locked = true;
                    ToolTip = 'Specifies the body text that will be set in the email body.';

                    trigger OnValidate()
                    var
                        EmailParameter: Record "Email Parameter";
                    begin
                        EmailParameter.SaveParameterValueWithReportUsage(
                          DocumentNo, ReportUsage, EmailParameter."Parameter Type"::Body.AsInteger(), BodyText);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        DocumentId: Guid;
        DocumentIdFilter: Text;
        FilterView: Text;
    begin
        if not IsGenerated then begin
            FilterView := GetView();
            DocumentIdFilter := GetFilter("Document Id");
            if DocumentIdFilter = '' then
                DocumentIdFilter := GetFilter(Id);
            SetView(FilterView);
            DocumentId := GetDocumentId(DocumentIdFilter);
            if IsNullGuid(DocumentId) then
                exit(false);
            GeneratePreview(DocumentId);
            IsGenerated := true;
        end;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        if xRec."Document Id" <> "Document Id" then
            Error(CannotChangeDocumentIdErr);

        O365SalesEmailManagement.SaveEmailParametersIfChanged(
          DocumentNo, ReportUsage, PrevEmail, Email, Subject);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
    end;

    var
        CannotChangeDocumentIdErr: Label 'The documentId cannot be changed.';
        DocumentIDNotSpecifiedErr: Label 'You must specify a document ID.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        IsGenerated: Boolean;
        PrevEmail: Text[250];
        Email: Text[250];
        Subject: Text[250];
        EmptyEmailAddressErr: Label 'The email address cannot be empty.';
        EmptyEmailSubjectErr: Label 'The email subject cannot be empty.';
        BodyText: Text;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ReportUsage: Integer;

    local procedure GetDocumentId(DocumentIdFilter: Text): Guid
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        DocumentIdFieldRef: FieldRef;
        DocumentId: Guid;
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        SalesHeader.SetFilter(SystemId, DocumentIdFilter);
        if SalesHeader.FindFirst() then
            DocumentRecordRef.GetTable(SalesHeader)
        else begin
            SalesInvoiceHeader.SetFilter(SystemId, DocumentIdFilter);
            if SalesInvoiceHeader.FindFirst() then
                DocumentRecordRef.GetTable(SalesInvoiceHeader)
            else
                Error(DocumentDoesNotExistErr);
        end;

        DataTypeManagement.FindFieldByName(DocumentRecordRef, DocumentIdFieldRef, SalesHeader.FieldName(SystemId));
        Evaluate(DocumentId, Format(DocumentIdFieldRef.Value));

        exit(DocumentId);
    end;

    local procedure GeneratePreview(DocumentId: Guid)
    var
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
        Body: Text;
    begin
        O365SalesEmailManagement.NativeAPIGetEmailParametersFromId(
          DocumentId, DocumentNo, CustomerNo, Email, Subject, Body, ReportUsage, BodyText);
        PrevEmail := Email;
        FillRecord(DocumentId, Subject, Body);
    end;

    local procedure FillRecord(DocumentId: Guid; Subject: Text[250]; Body: Text)
    begin
        Init();
        Id := DocumentId;
        "Document Id" := DocumentId;
        "File Name" := Subject;
        Type := Type::Email;
        SetTextContent(Body);

        Insert(true);
    end;
}
#endif
