table 9500 "Email Item"
{
    Caption = 'Email Item';

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "From Name"; Text[100])
        {
            Caption = 'From Name';
        }
        field(3; "From Address"; Text[250])
        {
            Caption = 'From Address';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "From Address" <> '' then
                    MailManagement.CheckValidEmailAddresses("From Address");
            end;
        }
        field(4; "Send to"; Text[250])
        {
            Caption = 'Send to';

            trigger OnValidate()
            begin
                if "Send to" <> '' then
                    CorrectAndValidateEmailList("Send to");
            end;
        }
        field(5; "Send CC"; Text[250])
        {
            Caption = 'Send CC';

            trigger OnValidate()
            begin
                if "Send CC" <> '' then
                    CorrectAndValidateEmailList("Send CC");
            end;
        }
        field(6; "Send BCC"; Text[250])
        {
            Caption = 'Send BCC';

            trigger OnValidate()
            begin
                if "Send BCC" <> '' then
                    CorrectAndValidateEmailList("Send BCC");
            end;
        }
        field(7; Subject; Text[250])
        {
            Caption = 'Subject';
        }
        field(8; Body; BLOB)
        {
            Caption = 'Body';
        }
        field(9; "Attachment File Path"; Text[250])
        {
            Caption = 'Attachment File Path';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(10; "Attachment Name"; Text[250])
        {
            Caption = 'Attachment Name';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(11; "Plaintext Formatted"; Boolean)
        {
            Caption = 'Plaintext Formatted';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Plaintext Formatted" then
                    Validate("Body File Path", '')
                else
                    SetBodyText('');
            end;
        }
        field(12; "Body File Path"; Text[250])
        {
            Caption = 'Body File Path';

            trigger OnValidate()
            begin
                if "Body File Path" <> '' then
                    TestField("Plaintext Formatted", false);
            end;
        }
        field(13; "Message Type"; Option)
        {
            Caption = 'Message Type';
            OptionCaption = 'Custom Message,From Email Body Template';
            OptionMembers = "Custom Message","From Email Body Template";
        }
        field(14; "Send as HTML"; Boolean)
        {
            Caption = 'Send as HTML';
            InitValue = true;
        }
        field(21; "Attachment File Path 2"; Text[250])
        {
            Caption = 'Attachment File Path 2';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(22; "Attachment Name 2"; Text[50])
        {
            Caption = 'Attachment Name 2';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(23; "Attachment File Path 3"; Text[250])
        {
            Caption = 'Attachment File Path 3';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(24; "Attachment Name 3"; Text[50])
        {
            Caption = 'Attachment Name 3';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(25; "Attachment File Path 4"; Text[250])
        {
            Caption = 'Attachment File Path 4';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(26; "Attachment Name 4"; Text[50])
        {
            Caption = 'Attachment Name 4';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(27; "Attachment File Path 5"; Text[250])
        {
            Caption = 'Attachment File Path 5';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(28; "Attachment Name 5"; Text[50])
        {
            Caption = 'Attachment Name 5';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(29; "Attachment File Path 6"; Text[250])
        {
            Caption = 'Attachment File Path 6';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(30; "Attachment Name 6"; Text[50])
        {
            Caption = 'Attachment Name 6';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(31; "Attachment File Path 7"; Text[250])
        {
            Caption = 'Attachment File Path 7';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(32; "Attachment Name 7"; Text[50])
        {
            Caption = 'Attachment Name 7';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
            ObsoleteTag = '17.2';
        }
        field(33; "Source Table"; Integer)
        {
            Access = Internal;
            Caption = 'Email Source Table';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced with method AddSourceDocument.';
            ObsoleteTag = '18.1';
        }
        field(34; "Source System Id"; Guid)
        {
            Access = Internal;
            Caption = 'The system id of the source record';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced with method AddSourceDocument.';
            ObsoleteTag = '18.1';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#if not CLEAN21
        O365EmailSetup: Record "O365 Email Setup";
#endif
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
        SourceTables: List of [Integer];
        SourceIDs: List of [Guid];
        SourceRelationTypes: List of [Integer];
        TargetEmailAddressErr: Label 'The target email address has not been specified.';

    procedure HasAttachments(): Boolean
    begin
        exit(Attachments.Count() > 0);
    end;

    procedure GetAttachments(var TempBlobList: Codeunit "Temp Blob List"; var Names: List of [Text])
    begin
        TempBlobList := Attachments;
        Names := AttachmentNames;
    end;

    procedure SetAttachments(TempBlobList: Codeunit "Temp Blob List"; Names: List of [Text])
    begin
        OnBeforeSetAttachments(Rec, TempBlobList, Names);
        Attachments := TempBlobList;
        AttachmentNames := Names;
    end;

    procedure AddAttachment(AttachmentStream: Instream; AttachmentName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if AttachmentStream.EOS() then
            exit;
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachmentStream);
        Attachments.Add(TempBlob);
        AttachmentNames.Add(AttachmentName);
    end;

#if not CLEAN20
    [Obsolete('Automatically added when calling AddSourceDocument', '20.0')]
    procedure AddRelatedSourceDocuments(TableID: Integer; SourceID: Guid)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        RelatedRecord: Dictionary of [Integer, List of [Guid]];
        RelatedRecordTableIds: List of [Integer];
        RelatedRecordSystemIds: List of [Guid];
        RelatedRecordTableId: Integer;
        TableIdCount, SystemIdCount : Integer;
    begin
        ContactBusinessRelation.GetBusinessRelatedSystemIds(TableID, SourceID, RelatedRecord);
        RelatedRecordTableIds := RelatedRecord.Keys();
        for TableIdCount := 1 to RelatedRecordTableIds.Count() do begin
            RelatedRecordTableId := RelatedRecordTableIds.Get(TableIdCount);
            RelatedRecordSystemIds := RelatedRecord.Get(RelatedRecordTableId);
            for SystemIdCount := 1 to RelatedRecordSystemIds.Count() do
                AddSourceDocument(RelatedRecordTableId, RelatedRecordSystemIds.Get(SystemIdCount), Enum::"Email Relation Type"::"Related Entity");
        end;
    end;
#endif

    procedure AddSourceDocument(TableID: Integer; SourceID: Guid)
    begin
        AddSourceDocument(TableID, SourceID, Enum::"Email Relation Type"::"Primary Source");
    end;

    procedure AddSourceDocument(TableID: Integer; SourceID: Guid; RelationType: Enum "Email Relation Type")
    begin
        SourceTables.Add(TableID);
        SourceIDs.Add(SourceID);
        SourceRelationTypes.Add(RelationType.AsInteger());
    end;

    procedure GetSourceDocuments(var SourceTableList: List of [Integer]; var SourceIDList: List of [Guid]; var SourceRelationTypeList: List of [Integer])
    begin
        SourceTableList := SourceTables;
        SourceIDList := SourceIDs;
        SourceRelationTypeList := SourceRelationTypes;
    end;

    procedure SetSourceDocuments(NewSourceTables: List of [Integer]; NewSourceIDs: List of [Guid]; NewSourceRelationTypes: List of [Integer])
    begin
        SourceTables := NewSourceTables;
        SourceIDs := NewSourceIDs;
        SourceRelationTypes := NewSourceRelationTypes;
    end;

    procedure Initialize()
    begin
        ID := CreateGuid();
    end;

    [Obsolete('Replaced with the overload containing Email Scenario', '17.0')]
    procedure Send(HideMailDialog: Boolean): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(Send(HideMailDialog, Enum::"Email Scenario"::Default));
    end;

    procedure Send(HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario"): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        OnBeforeSend(Rec, HideMailDialog, MailManagement);
        MailManagement.SendMailOrDownload(Rec, HideMailDialog, EmailScenario);
        exit(MailManagement.IsSent());
    end;

    procedure SetBodyText(Value: Text)
    var
        BodyText: BigText;
        DataStream: OutStream;
    begin
        Clear(Body);
        BodyText.AddText(Value);
        Body.CreateOutStream(DataStream, TEXTENCODING::UTF8);
        BodyText.Write(DataStream);
    end;

    [Scope('OnPrem')]
    procedure GetBodyText() Value: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        BlobInStream: InStream;
        BodyOutStream: OutStream;
        IsHandled: Boolean;
    begin
        // Note this is intended only to get the body in memory - not from the database.
        Value := '';

        IsHandled := false;
        OnBeforeGetBodyText(Rec, Value, IsHandled);
        if IsHandled then
            exit(Value);

        // If the body doesn't have a value, attempt to import the value from the file path, otherwise exit.
        if not Body.HasValue() and not (("Body File Path" <> '') and Exists("Body File Path")) then
            exit;
        if not Body.HasValue() and ("Body File Path" <> '') and Exists("Body File Path") then begin
            FileManagement.BLOBImportFromServerFile(TempBlob, "Body File Path");
            TempBlob.CreateInStream(BlobInStream, TextEncoding::UTF8);
            Body.CreateOutStream(BodyOutStream);
            CopyStream(BodyOutStream, BlobInStream);
        end;

        Value := GetBodyTextFromBlob();

        exit(Value);
    end;

    procedure GetBodyTextFromBlob() Value: Text
    var
        BodyText: BigText;
        DataStream: InStream;
    begin
        if "Plaintext Formatted" then begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            BodyText.Read(DataStream);
            BodyText.GetSubText(Value, 1);
        end else begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            DataStream.Read(Value);
        end;
    end;

    local procedure CorrectAndValidateEmailList(var EmailAddresses: Text[250])
    var
        MailManagement: Codeunit "Mail Management";
    begin
        EmailAddresses := ConvertStr(EmailAddresses, ',', ';');
        EmailAddresses := DelChr(EmailAddresses, '<>');
        MailManagement.CheckValidEmailAddresses(EmailAddresses);
    end;

#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure AddCcBcc()
    begin
        "Send CC" := O365EmailSetup.GetCCAddressesFromO365EmailSetup();
        "Send BCC" := O365EmailSetup.GetBCCAddressesFromO365EmailSetup();
    end;
#endif
    procedure SendAsHTML(SendAsHTML: Boolean)
    begin
        Rec."Send As HTML" := SendAsHTML;
    end;

    [Scope('OnPrem')]
    procedure AttachIncomingDocuments(SalesInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        InStr: InStream;
        IsPostedDocument: Boolean;
        CorrectAttachment: Boolean;
    begin
        if SalesInvoiceNo = '' then
            exit;
        IsPostedDocument := true;
        if not SalesInvoiceHeader.Get(SalesInvoiceNo) then begin
            SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Invoice);
            SalesHeader.SetRange("No.", SalesInvoiceNo);
            if not SalesHeader.FindFirst() then
                exit;
            if SalesHeader."Incoming Document Entry No." = 0 then
                exit;
            IsPostedDocument := false;
        end;

        if IsPostedDocument then begin
            IncomingDocumentAttachment.SetRange("Document No.", SalesInvoiceNo);
            IncomingDocumentAttachment.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        end else
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", SalesHeader."Incoming Document Entry No.");

        OnAttachIncomingDocumentsOnAfterSetFilter(IncomingDocumentAttachment);

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        if IncomingDocumentAttachment.FindSet() then
            repeat
                CorrectAttachment := true;
                if IsPostedDocument then begin
                    CorrectAttachment := false;
                    if IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
                        if (IncomingDocument."Document Type" = IncomingDocument."Document Type"::"Sales Invoice") and IncomingDocument.Posted then
                            CorrectAttachment := true;
                end;
                if CorrectAttachment then
                    if IncomingDocumentAttachment.Content.HasValue() then begin
                        IncomingDocumentAttachment.Content.CreateInStream(InStr);
                        // To ensure that Attachment file name has . followed by extension in the email item
                        Rec.AddAttachment(InStr, StrSubstNo('%1.%2', IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension"));
                    end;
            until IncomingDocumentAttachment.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ValidateTarget()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
    begin
        if ("Send to" = '') and ("Send CC" = '') and ("Send BCC" = '') then
            ErrorMessageManagement.LogSimpleErrorMessage(TargetEmailAddressErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAttachIncomingDocumentsOnAfterSetFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBodyText(var EmailItem: Record "Email Item"; var Value: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSend(var EmailItem: Record "Email Item"; var HideMailDialog: Boolean; var MailManagement: Codeunit "Mail Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAttachments(var EmailItem: Record "Email Item"; var TempBlobList: Codeunit "Temp Blob List"; var Names: List of [Text])
    begin
    end;
}

