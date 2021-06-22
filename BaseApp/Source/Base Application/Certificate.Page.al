page 1263 Certificate
{
    Caption = 'Certificate';
    PageType = Card;
    SourceTable = "Isolated Certificate";

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the certificate.';
                }
                group(Control16)
                {
                    ShowCaption = false;
                    Visible = IsPasswordRequired;
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the password for the certificate.';

                        trigger OnValidate()
                        begin
                            PasswordNotification.Recall;
                            if CertificateManagement.VerifyCert(Rec) then begin
                                if IsCertificateExpired then
                                    HandleExpiredCert
                                else begin
                                    IsShowCertInfo := true;
                                    IsUploadedCertValid := not IsNewRecord;
                                end;

                                CurrPage.Update;
                            end else
                                Error(CertWrongPasswordErr);
                        end;
                    }
                }
                field(Scope; Scope)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsNewRecord;
                    ToolTip = 'Specifies the availability of the certificate. Company gives all users in this specific company access to the certificate. User gives access to a specific user in any company. Company and User gives access to a specific user in the specific company.';
                }
            }
            group("Certificate Information")
            {
                Visible = IsShowCertInfo;
                field("Has Private Key"; "Has Private Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the certificate has a private key.';
                }
                field(ThumbPrint; ThumbPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Thumbprint';
                    ToolTip = 'Specifies the certificate thumbprint.';
                }
                field("Expiry Date"; "Expiry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the certificate will expire.';
                }
                field("Issued By"; "Issued By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the certificate authority that issued the certificate.';
                }
                field("Issued To"; "Issued To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person, organization, or domain that the certificate was issued to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Upload Cerificate")
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Upload a new certificate file for the certificate. Typically, you use this when a certificate will expire soon.';

                trigger OnAction()
                begin
                    RecallNotifications;
                    IsolatedCertificate := Rec;
                    Password := '';

                    CheckEncryption;

                    if not CertificateManagement.UploadAndVerifyCert(Rec) then begin
                        IsShowCertInfo := false;
                        HandleRequirePassword;
                    end else begin
                        IsPasswordRequired := false;
                        IsShowCertInfo := true;
                        if IsCertificateExpired then begin
                            HandleExpiredCert;

                            Rec := IsolatedCertificate;
                            if ThumbPrint = '' then
                                IsShowCertInfo := false;
                        end;
                    end;

                    CurrPage.Update;
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec := IsolatedCertificate;
    end;

    trigger OnOpenPage()
    begin
        if Code = '' then begin
            IsNewRecord := true;
            CheckEncryption;
            if not CertificateManagement.UploadAndVerifyCert(Rec) then
                HandleRequirePassword
            else begin
                IsShowCertInfo := true;
                if IsCertificateExpired then
                    HandleExpiredCert;
            end;

            IsolatedCertificate := Rec;
        end else
            if ThumbPrint <> '' then begin
                IsShowCertInfo := true;
                if IsCertificateExpired then
                    NotfiyExpiredCert(CertHasExpiredMsg);
            end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Code <> '' then
            TestField(Name);

        if IsNewRecord then
            SetScope;

        if (IsNewRecord or IsUploadedCertValid) and not IsExpired then
            SaveCertToIsolatedStorage;
    end;

    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        PasswordNotification: Notification;
        ExpiredNotification: Notification;
        IsNewRecord: Boolean;
        CertWrongPasswordErr: Label 'The password is not correct.';
        PasswordNotificationMsg: Label 'You must enter the password for this certificate.';
        ExpiredNewCertMsg: Label 'You cannot upload the certificate%1 because it is past its expiration date.', Comment = '%1=file name, e.g. Certfile.pfx';
        IsPasswordRequired: Boolean;
        CertHasExpiredMsg: Label 'The certificate has expired. To use the certificate you must upload a new certificate file.';
        IsExpired: Boolean;
        IsUploadedCertValid: Boolean;
        IsShowCertInfo: Boolean;

    local procedure ClearCertInfoFields()
    begin
        with Rec do begin
            Clear("Expiry Date");
            ThumbPrint := '';
            "Issued By" := '';
            "Issued To" := '';
            "Has Private Key" := false;
        end;
    end;

    local procedure SaveCertToIsolatedStorage()
    begin
        if IsUploadedCertValid then
            CertificateManagement.DeleteCertAndPasswordFromIsolatedStorage(Rec);
        CertificateManagement.SaveCertToIsolatedStorage(Rec);
        CertificateManagement.SavePasswordToIsolatedStorage(Rec);
    end;

    local procedure HandleRequirePassword()
    begin
        IsPasswordRequired := true;
        PasswordNotification.Message(PasswordNotificationMsg);
        PasswordNotification.Send;
    end;

    local procedure HandleExpiredCert()
    begin
        NotfiyExpiredCert(StrSubstNo(ExpiredNewCertMsg, ' ' + CertificateManagement.GetUploadedCertFileName));
        if IsNewRecord then
            ClearCertInfoFields
        else
            Rec := IsolatedCertificate;

        IsShowCertInfo := ThumbPrint <> '';
        IsPasswordRequired := false;
    end;

    local procedure NotfiyExpiredCert(Message: Text)
    begin
        IsExpired := true;
        ExpiredNotification.Message(Message);
        ExpiredNotification.Send;
    end;

    local procedure RecallNotifications()
    begin
        if ExpiredNotification.Recall then;
        if PasswordNotification.Recall then;
    end;

    local procedure CheckEncryption()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        if not CryptographyManagement.IsEncryptionEnabled then
            if Confirm(CryptographyManagement.GetEncryptionIsNotActivatedQst) then
                PAGE.RunModal(PAGE::"Data Encryption Management");
    end;
}

