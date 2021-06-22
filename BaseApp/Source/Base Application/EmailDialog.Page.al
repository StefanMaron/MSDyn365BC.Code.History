page 9700 "Email Dialog"
{
    Caption = 'Send Email';
    PageType = StandardDialog;
    SourceTable = "Email Item";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality has been replaced by the Email module.';
    ObsoleteTag = '17.2';

    layout
    {
        area(content)
        {
            field(FromAddress; ShownFromEmail)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'From';
                Enabled = false;
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the sender of the email.';
                Visible = false;
            }
            field(SendTo; SendToText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'To';
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the recipient of the email.';

                trigger OnValidate()
                begin
                    EmailItem.Validate("Send to", SendToText);
                    SendToText := EmailItem."Send to";
                end;
            }
            field(CcText; CcText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cc';
                ToolTip = 'Specifies one or more additional recipients.';

                trigger OnValidate()
                begin
                    EmailItem.Validate("Send CC", CcText);
                    CcText := EmailItem."Send CC";
                end;
            }
            field(BccText; BccText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bcc';
                ToolTip = 'Specifies one or more additional recipients.';

                trigger OnValidate()
                begin
                    EmailItem.Validate("Send BCC", BccText);
                    BccText := EmailItem."Send BCC";
                end;
            }
            field(Subject; EmailItem.Subject)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Subject';
                ToolTip = 'Specifies the text that will display as the subject of the email.';
            }
            field("Attachment Name"; AttachmentName)
            {
                ApplicationArea = All;
                Caption = 'Attachment Name';
                Editable = IsOfficeAddin;
                Enabled = NOT IsOfficeAddin;
                ToolTip = 'Specifies the name of the attached document.';
                Visible = HasAttachment;

                trigger OnAssistEdit()
                var
                    MailManagement: Codeunit "Mail Management";
                begin
                    MailManagement.DownloadPdfAttachment(EmailItem);
                end;
            }
            field(MessageContents; EmailItem."Message Type")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Message Content';
                Visible = NOT PlainTextVisible;
                ToolTip = ' ';

                trigger OnValidate()
                begin
                    UpdatePlainTextVisible();

                    case EmailItem."Message Type" of
                        EmailItem."Message Type"::"From Email Body Template":
                            begin
                                EmailItem.Body.Import(EmailItem."Body File Path");
                                BodyText := EmailItem.GetBodyText();
                            end;
                        EmailItem."Message Type"::"Custom Message":
                            begin
                                BodyText := PreviousBodyText;
                                EmailItem.SetBodyText(BodyText);
                            end;
                    end;
                end;
            }
            group(Control14)
            {
                ShowCaption = false;
                group(Control12)
                {
                    ShowCaption = false;
                    Visible = NOT PlainTextVisible;
                    usercontrol(BodyHTMLMessage; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger ControlAddInReady(callbackUrl: Text)
                        begin
                            CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                            CurrPage.BodyHTMLMessage.SetContent(BodyText);
                        end;

                        trigger DocumentReady()
                        begin
                        end;

                        trigger Callback(data: Text)
                        begin
                        end;

                        trigger Refresh(CallbackUrl: Text)
                        begin
                            CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                            CurrPage.BodyHTMLMessage.SetContent(BodyText);
                        end;
                    }
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = PlainTextVisible;
                    field(BodyText; BodyText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Message';
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the body of the email.';

                        trigger OnValidate()
                        begin
                            EmailItem.SetBodyText(BodyText);

                            if "Message Type" = "Message Type"::"Custom Message" then
                                PreviousBodyText := BodyText;
                        end;
                    }
                }
            }
            field(OutlookEdit; LocalEdit)
            {
                ApplicationArea = All;
                Caption = 'Edit in Outlook';
                MultiLine = true;
                ToolTip = 'Specifies that Microsoft Outlook will open so you can complete the email there.';
                Visible = IsEditEnabled;

                trigger OnValidate()
                begin
                    if LocalEdit = true then
                        ShownFromEmail := ''
                    else
                        ShownFromEmail := OriginalFromEmail;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnClosePage()
    begin
        Rec := EmailItem;
    end;

    trigger OnOpenPage()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OfficeMgt: Codeunit "Office Management";
        Attachments: Codeunit "Temp Blob List";
        RecordRef: RecordRef;
        OrigMailBodyText: Text;
        AttachmentNames: List of [Text];
    begin
        EmailItem.GetAttachments(Attachments, AttachmentNames);
        HasAttachment := AttachmentNames.Count() > 0;
        if HasAttachment then
            AttachmentName := AttachmentNames.Get(1);
        OriginalFromEmail := OrigEmailItem."From Address";

        if not IsEditEnabled then
            LocalEdit := false;
        if ForceOutlook then
            LocalEdit := true;
        if not LocalEdit then
            ShownFromEmail := OriginalFromEmail
        else
            ShownFromEmail := '';

        OnOnOpenPageOnAfterSetShownFromEmail(Rec, xRec, OrigEmailItem, EmailItem, ShownFromEmail, OriginalFromEmail);

        EmailItem.Subject := OrigEmailItem.Subject;
        EmailItem."Attachment Name" := OrigEmailItem."Attachment Name";

        InitBccCcText();
        SendToText := OrigEmailItem."Send to";
        if OrigEmailItem."Send CC" <> '' then
            CcText := OrigEmailItem."Send CC"
        else
            EmailItem."Send CC" := CcText;
        if OrigEmailItem."Send BCC" <> '' then
            BccText := OrigEmailItem."Send BCC"
        else
            EmailItem."Send BCC" := BccText;

        BodyText := '';

        if EmailItem."Plaintext Formatted" then
            EmailItem."Message Type" := EmailItem."Message Type"::"Custom Message"
        else begin
            EmailItem."Body File Path" := OrigEmailItem."Body File Path";
            FileManagement.BLOBImportFromServerFile(TempBlob, EmailItem."Body File Path");
            RecordRef.GetTable(EmailItem);
            TempBlob.ToRecordRef(RecordRef, EmailItem.FieldNo(Body));
            RecordRef.SetTable(EmailItem);
            EmailItem."Message Type" := EmailItem."Message Type"::"From Email Body Template";
        end;

        OrigMailBodyText := EmailItem.GetBodyText();
        if OrigMailBodyText <> '' then
            BodyText := OrigMailBodyText
        else
            EmailItem.SetBodyText(BodyText);

        UpdatePlainTextVisible();
        IsOfficeAddin := OfficeMgt.IsAvailable();
    end;

    var
        OrigEmailItem: Record "Email Item";
        LocalEdit: Boolean;
        IsEditEnabled: Boolean;
        HasAttachment: Boolean;
        ForceOutlook: Boolean;
        PlainTextVisible: Boolean;
        IsOfficeAddin: Boolean;
        OriginalFromEmail: Text[250];
        BodyText: Text;
        SendToText: Text[250];
        BccText: Text[250];
        CcText: Text[250];
        ShownFromEmail: Text;
        PreviousBodyText: Text;
        AttachmentName: Text;

    protected var
        EmailItem: Record "Email Item";

    // Email Item needs to be passed by var so the attachments are available
    procedure SetValues(var ParmEmailItem: Record "Email Item"; ParmOutlookSupported: Boolean; ParmSmtpSupported: Boolean)
    var
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
    begin
        ParmEmailItem.GetAttachments(Attachments, AttachmentNames);
        HasAttachment := Attachments.Count() > 0;
        EmailItem := ParmEmailItem;
        EmailItem.SetAttachments(Attachments, AttachmentNames);

        OrigEmailItem.Copy(ParmEmailItem);

        ForceOutlook := ParmOutlookSupported and not ParmSmtpSupported;
        IsEditEnabled := false;
        LocalEdit := false;
    end;

    procedure GetDoEdit(): Boolean
    begin
        exit(LocalEdit);
    end;

    local procedure UpdatePlainTextVisible()
    begin
        PlainTextVisible := EmailItem."Message Type" = EmailItem."Message Type"::"Custom Message";
    end;

    local procedure InitBccCcText()
    begin
        BccText := '';
        CcText := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnOpenPageOnAfterSetShownFromEmail(var RecEmailItem: Record "Email Item"; xRecEmailItem: Record "Email Item"; var OrigEmailItem: Record "Email Item"; var EmailItem: Record "Email Item"; var ShownFromEmail: Text; var OriginalFromEmail: Text[250])
    begin
    end;
}

