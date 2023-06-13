codeunit 397 Mail
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'No registered email addresses exist for this %1.', Comment = '%1 = Contact Table Caption (eg. No registered email addresses found for this Contact.)';
        [RunOnClient]
        OutlookMessageHelper: DotNet IOutlookMessage;

    [Scope('OnPrem')]
    procedure OpenNewMessage(ToName: Text)
    begin
        Initialize();
        NewMessage(ToName, '', '', '', '', '', true);
    end;

    [Scope('OnPrem')]
    procedure NewMessageAsync(ToAddresses: Text; CcAddresses: Text; BccAddresses: Text; Subject: Text; Body: Text; AttachFilename: Text; ShowNewMailDialogOnSend: Boolean): Boolean
    begin
        exit(CreateAndSendMessage(ToAddresses, CcAddresses, BccAddresses, Subject, Body, AttachFilename, ShowNewMailDialogOnSend, false));
    end;

    [Scope('OnPrem')]
    procedure NewMessage(ToAddresses: Text; CcAddresses: Text; BccAddresses: Text; Subject: Text; Body: Text; AttachFilename: Text; ShowNewMailDialogOnSend: Boolean): Boolean
    begin
        exit(CreateAndSendMessage(ToAddresses, CcAddresses, BccAddresses, Subject, Body, AttachFilename, ShowNewMailDialogOnSend, true));
    end;

    local procedure CreateAndSendMessage(ToAddresses: Text; CcAddresses: Text; BccAddresses: Text; Subject: Text; Body: Text; AttachFilename: Text; ShowNewMailDialogOnSend: Boolean; RunModal: Boolean): Boolean
    var
        MailSent: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAndSendMessage(
          ToAddresses, CcAddresses, BccAddresses, Subject, Body, AttachFilename, ShowNewMailDialogOnSend, MailSent, IsHandled);
        if IsHandled then
            exit(MailSent);

        Initialize();

        CreateMessage(ToAddresses, CcAddresses, BccAddresses, Subject, Body, ShowNewMailDialogOnSend, RunModal);
        AttachFile(AttachFilename);
        OnCreateAndSendMessageOnAfterAttachFile();

        exit(Send());
    end;

    procedure CreateMessage(ToAddresses: Text; CcAddresses: Text; BccAddresses: Text; Subject: Text; Body: Text; ShowNewMailDialogOnSend: Boolean; RunModal: Boolean)
    var
        IsHandled: Boolean;
    begin
        Initialize();

        IsHandled := false;
        OnBeforeCreateMessage(ToAddresses, CcAddresses, BccAddresses, Subject, Body, ShowNewMailDialogOnSend, RunModal, IsHandled);
        if IsHandled then
            exit;

        OutlookMessageHelper.Recipients := ToAddresses;
        OutlookMessageHelper.CarbonCopyRecipients := CcAddresses;
        OutlookMessageHelper.BlindCarbonCopyRecipients := BccAddresses;
        OutlookMessageHelper.Subject := Subject;
        OutlookMessageHelper.BodyFormat := 2;
        OutlookMessageHelper.ShowNewMailDialogOnSend := ShowNewMailDialogOnSend;
        OutlookMessageHelper.NewMailDialogIsModal := RunModal;
        OutlookMessageHelper.AttachmentFileNames.Clear();
        AddBodyline(Body);
    end;

    [Scope('OnPrem')]
    procedure AddBodyline(TextLine: Text): Boolean
    begin
        Initialize();

        if TextLine <> '' then
            OutlookMessageHelper.Body.Append(FormatTextForHtml(TextLine));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure AttachFile(Filename: Text)
    begin
        Initialize();

        if Filename <> '' then
            OutlookMessageHelper.AttachmentFileNames.Add(Filename);
    end;

    [Scope('OnPrem')]
    procedure Send(): Boolean
    begin
        Initialize();
        exit(OutlookMessageHelper.Send());
    end;

    [Scope('OnPrem')]
    procedure GetErrorDesc(): Text
    begin
        Initialize();
        if not IsNull(OutlookMessageHelper.LastException) then
            exit(OutlookMessageHelper.LastException.Message);
    end;

    procedure CollectAddresses(ContactNo: Code[20]; var ContactThrough: Record "Communication Method"; ShowAddresses: Boolean): Text[260]
    var
        Contact: Record Contact;
    begin
        ContactThrough.Reset();
        ContactThrough.DeleteAll();
        if not Contact.Get(ContactNo) then
            exit;

        CollectContactAddresses(ContactThrough, ContactNo);

        // Get linked Company Addresses
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            CollectContactAddresses(ContactThrough, Contact."Company No.");

        if ShowAddresses then
            if ContactThrough.Find('-') then begin
                if PAGE.RunModal(PAGE::"Contact Through", ContactThrough) = ACTION::LookupOK then
                    exit(ContactThrough."E-Mail");
            end else
                Error(Text001, Contact.TableCaption());
    end;

    local procedure TrimCode("Code": Code[20]) TrimString: Text[20]
    begin
        TrimString := CopyStr(Code, 1, 1) + LowerCase(CopyStr(Code, 2, StrLen(Code) - 1))
    end;

    procedure ValidateEmail(var ContactThrough: Record "Communication Method"; EMailToValidate: Text) EMailExists: Boolean
    begin
        ContactThrough.Reset();
        if ContactThrough.FindFirst() then begin
            ContactThrough.SetRange("E-Mail", CopyStr(EMailToValidate, 1, MaxStrLen(ContactThrough."E-Mail")));
            EMailExists := not ContactThrough.IsEmpty();
        end;
    end;

    local procedure CollectContactAddresses(var ContactThrough: Record "Communication Method"; ContactNo: Code[20])
    var
        Contact: Record Contact;
        ContAltAddr: Record "Contact Alt. Address";
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        KeyNo: Integer;
    begin
        if not Contact.Get(ContactNo) then
            exit;
        with ContactThrough do begin
            if FindLast() then
                KeyNo := Key + 1
            else
                KeyNo := 1;

            if Contact."E-Mail" <> '' then begin
                Key := KeyNo;
                "Contact No." := ContactNo;
                Name := Contact.Name;
                Description := CopyStr(Contact.FieldCaption("E-Mail"), 1, MaxStrLen(Description));
                "E-Mail" := Contact."E-Mail";
                Type := Contact.Type;
                Insert();
                KeyNo := KeyNo + 1;
            end;

            // Alternative address
            ContAltAddrDateRange.SetCurrentKey("Contact No.", "Starting Date");
            ContAltAddrDateRange.SetRange("Contact No.", ContactNo);
            ContAltAddrDateRange.SetRange("Starting Date", 0D, Today);
            ContAltAddrDateRange.SetFilter("Ending Date", '>=%1|%2', Today, 0D);
            if ContAltAddrDateRange.FindSet() then
                repeat
                    if ContAltAddr.Get(Contact."No.", ContAltAddrDateRange."Contact Alt. Address Code") then
                        if ContAltAddr."E-Mail" <> '' then begin
                            Key := KeyNo;
                            Description :=
                              CopyStr(TrimCode(ContAltAddr.Code) + ' - ' + ContAltAddr.FieldCaption("E-Mail"), 1, MaxStrLen(Description));
                            "E-Mail" := ContAltAddr."E-Mail";
                            Type := Contact.Type;
                            Insert();
                            KeyNo := KeyNo + 1;
                        end;
                until ContAltAddrDateRange.Next() = 0;
        end;
    end;

    local procedure Initialize()
    var
        OutlookMessageFactory: Codeunit "Outlook Message Factory";
    begin
        if IsNull(OutlookMessageHelper) then
            OutlookMessageFactory.CreateOutlookMessage(OutlookMessageHelper);
    end;

    [Scope('OnPrem')]
    procedure TryInitializeOutlook(): Boolean
    begin
        Initialize();
        exit(OutlookMessageHelper.CanInitializeOutlook);
    end;

    procedure CollectCurrentUserEmailAddresses(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        AddAddressToCollection('UserSetup', GetEmailFromUserSetupTable(), TempNameValueBuffer);
        AddAddressToCollection('ContactEmail', GetContactEmailFromUserTable(), TempNameValueBuffer);
        AddAddressToCollection('AuthEmail', GetAuthenticationEmailFromUserTable(), TempNameValueBuffer);
        if not EnvironmentInfo.IsSaaS() then
            AddAddressToCollection('AD', GetActiveDirectoryMailFromUser(), TempNameValueBuffer);

        AddAddressToCollection('DefaultEmailAccount', GetDefaultScenarioEmailAddress(), TempNameValueBuffer);
    end;

    local procedure AddAddressToCollection(EmailKey: Text; EmailAddress: Text; var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        NextID: Integer;
    begin
        if EmailAddress = '' then
            exit;

        with TempNameValueBuffer do begin
            Reset();
            if FindSet() then
                repeat
                    if UpperCase(Value) = UpperCase(EmailAddress) then
                        exit(false);
                until Next() = 0;
            if FindLast() then
                NextID := ID + 1
            else
                NextID := 1;

            Init();

            ID := NextID;
            Name := CopyStr(EmailKey, 1, MaxStrLen(Name));
            Value := CopyStr(EmailAddress, 1, MaxStrLen(Value));
            Insert();
        end;

        exit(true);
    end;

    local procedure GetDefaultScenarioEmailAddress(): Text
    var
        EmailAccount: Record "Email Account";
        EmailScenario: Codeunit "Email Scenario";
    begin
        if EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount) then
            exit(EmailAccount."Email Address");
    end;

    local procedure GetActiveDirectoryMailFromUser(): Text
    var
        Email: Text;
        Handled: Boolean;
    begin
        OnGetEmailAddressFromActiveDirectory(Email, Handled);
        if Handled then
            exit(Email);
        exit(GetEmailAddressFromActiveDirectory());
    end;

    local procedure GetEmailAddressFromActiveDirectory(): Text
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ActiveDirectoryEmailAddress: Text;
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows then
            if TryGetEmailAddressFromActiveDirectory(ActiveDirectoryEmailAddress) then;
        exit(ActiveDirectoryEmailAddress);
    end;

    local procedure GetAuthenticationEmailFromUserTable(): Text
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            exit(User."Authentication Email");
    end;

    local procedure GetContactEmailFromUserTable(): Text
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            exit(User."Contact Email");
    end;

    local procedure GetEmailFromUserSetupTable(): Text
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.SetRange("User ID", UserId);
        if UserSetup.FindFirst() then
            exit(UserSetup."E-Mail");
    end;

    [TryFunction]
    local procedure TryGetEmailAddressFromActiveDirectory(var ActiveDirectoryEmailAddress: Text)
    var
        [RunOnClient]
        MailHelpers: DotNet MailHelpers;
    begin
        if CanLoadType(MailHelpers) then
            ActiveDirectoryEmailAddress := MailHelpers.TryGetEmailAddressFromActiveDirectory();
    end;

    procedure FormatTextForHtml(Text: Text): Text
    var
        String: DotNet String;
        Char10: Char;
        Char13: Char;
    begin
        if Text <> '' then begin
            Char13 := 13;
            Char10 := 10;
            String := Text;
            exit(String.Replace(Format(Char13) + Format(Char10), '<br />'));
        end;

        exit('');
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnGetEmailAddressFromActiveDirectory(var Email: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateMessage(var ToAddresses: Text; var CcAddresses: Text; var BccAddresses: Text; var Subject: Text; var Body: Text; ShowNewMailDialogOnSend: Boolean; RunModal: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndSendMessage(ToAddresses: Text; CcAddresses: Text; BccAddresses: Text; Subject: Text; Body: Text; AttachFilename: Text; ShowNewMailDialogOnSend: Boolean; var MailSent: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateAndSendMessageOnAfterAttachFile()
    begin
    end;
}

