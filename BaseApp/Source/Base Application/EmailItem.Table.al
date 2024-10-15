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
        O365EmailSetup: Record "O365 Email Setup";
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
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
        Attachments := TempBlobList;
        AttachmentNames := Names;
    end;

    procedure AddAttachment(AttachementStream: Instream; AttachementName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if AttachementStream.EOS() then
            exit;
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachementStream);
        Attachments.Add(TempBlob);
        AttachmentNames.Add(AttachementName);
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

    [Obsolete('Function scope will be changed to OnPrem', '15.1')]
    procedure GetBodyText() Value: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        BodyText: BigText;
        DataStream: InStream;
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

        if "Plaintext Formatted" then begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            BodyText.Read(DataStream);
            BodyText.GetSubText(Value, 1);
        end else begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            DataStream.Read(Value);
        end;

        exit(Value);
    end;

    local procedure CorrectAndValidateEmailList(var EmailAddresses: Text[250])
    var
        MailManagement: Codeunit "Mail Management";
    begin
        EmailAddresses := ConvertStr(EmailAddresses, ',', ';');
        EmailAddresses := DelChr(EmailAddresses, '<>');
        MailManagement.CheckValidEmailAddresses(EmailAddresses);
    end;

    procedure AddCcBcc()
    begin
        "Send CC" := O365EmailSetup.GetCCAddressesFromO365EmailSetup();
        "Send BCC" := O365EmailSetup.GetBCCAddressesFromO365EmailSetup();
    end;

    [Scope('OnPrem')]
    procedure AttachIncomingDocuments(SalesInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        InStr: InStream;
        IsPostedDocument: Boolean;
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
                if IncomingDocumentAttachment.Content.HasValue() then begin
                    IncomingDocumentAttachment.Content.CreateInStream(InStr);
                    // To ensure that attachement file name has . followed by extension in the email item
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
}

