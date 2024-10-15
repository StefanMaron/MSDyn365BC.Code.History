table 31131 "Certificate CZ"
{
    Caption = 'Certificate';
    DataCaptionFields = "Certificate Code", Description;
    LookupPageID = "Certificates CZ";
    Permissions = TableData "Service Password" = rimd;

    fields
    {
        field(1; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            NotBlank = true;
            TableRelation = "Certificate CZ Code";
        }
        field(2; "Valid From"; DateTime)
        {
            Caption = 'Valid From';

            trigger OnValidate()
            begin
                CheckDateTimeValid;
            end;
        }
        field(3; "Valid To"; DateTime)
        {
            Caption = 'Valid To';

            trigger OnValidate()
            begin
                CheckDateTimeValid;
            end;
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Store Type"; Option)
        {
            Caption = 'Store Type';
            OptionCaption = 'Server,Client,Database';
            OptionMembers = Server,Client,Database;

            trigger OnValidate()
            var
                TempCertificateCZ: Record "Certificate CZ" temporary;
            begin
                TempCertificateCZ := Rec;
                Init;
                "Valid From" := 0DT;
                "Store Type" := TempCertificateCZ."Store Type";
            end;
        }
        field(11; "Store Location"; Option)
        {
            Caption = 'Store Location';
            OptionCaption = ' ,Current User,Local Machine';
            OptionMembers = " ","Current User","Local Machine";

            trigger OnValidate()
            begin
                if "Store Type" = "Store Type"::Database then
                    FieldError("Store Type");

                UpdateCertificateInformation;
            end;
        }
        field(12; "Store Name"; Option)
        {
            Caption = 'Store Name';
            OptionCaption = ' ,Address Book,Authority Root,Certificate Authority,Disallowed,My,Root,Trusted People,Trusted Publisher';
            OptionMembers = " ","Address Book","Authority Root","Certificate Authority",Disallowed,My,Root,"Trusted People","Trusted Publisher";

            trigger OnValidate()
            begin
                if "Store Type" = "Store Type"::Database then
                    FieldError("Store Type");

                UpdateCertificateInformation;
            end;
        }
        field(13; Thumbprint; Text[80])
        {
            Caption = 'Thumbprint';

            trigger OnValidate()
            begin
                if "Store Type" = "Store Type"::Database then
                    FieldError("Store Type");

                Thumbprint := FormatThumbprint(Thumbprint);
                UpdateCertificateInformation;
            end;
        }
        field(15; "Certificate Key"; Guid)
        {
            Caption = 'Certificate Key';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Certificate Code", "User ID", "Valid From")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckCertificateUser;
        DeleteCertificate;
    end;

    trigger OnModify()
    begin
        CheckCertificateUser;
    end;

    var
        DateTimeValidErr: Label '%1 cannot be after %2.', Comment = '%1 = date of valid from, %2 = date of valid to';
        CertificateCZMgt: Codeunit "Certificate CZ Management";
        OutOfRangeErr: Label '%1 %2 is out of range of certificate validity.', Comment = '%1 = field name of datetime type; %2 = date time';
        CertificateExistQst: Label 'The certificate is already imported.\\Do you want to overwrite it?';
        NotCertificateUserErr: Label 'User %1 is not user of certificate %2 %3.', Comment = '%1 = user id; %2 = user id; %3 = valid from';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        SignatureIsValidMsg: Label 'Signature is valid.';
        SignatureIsNotValidMsg: Label 'Signature is not valid.';

    [Scope('OnPrem')]
    procedure SaveCertificate(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean): Boolean
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        TextCert: Text;
    begin
        if IsNull(X509Certificate2) then
            exit(false);

        if IsNullGuid("Certificate Key") or not IsolatedStorageManagement.Contains("Certificate Key", DATASCOPE::Company) then
            "Certificate Key" := Format(CreateGuid);

        TextCert := CertificateCZMgt.EncodeCertificateToBase64(X509Certificate2, WithPrivateKey);
        exit(ISOLATEDSTORAGE.Set("Certificate Key", TextCert, DATASCOPE::Company));
    end;

    [Scope('OnPrem')]
    procedure SaveCertificateFromStream(InputStream: InStream; Password: Text; WithPrivateKey: Boolean): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        CertificateCZMgt.LoadCertificateFromStream(InputStream, Password, X509Certificate2);
        exit(SaveCertificate(X509Certificate2, WithPrivateKey));
    end;

    [Scope('OnPrem')]
    procedure LoadCertificateFromDatabase(var X509Certificate2: DotNet X509Certificate2): Boolean
    var
        CertificateBase64: Text;
    begin
        CertificateBase64 := '';
        ISOLATEDSTORAGE.Get("Certificate Key", DATASCOPE::Company, CertificateBase64);
        CertificateCZMgt.DecodeCertificateFromBase64(CertificateBase64, X509Certificate2);
        exit(not IsNull(X509Certificate2));
    end;

    [Scope('OnPrem')]
    procedure LoadCertificateFromStore(var X509Certificate2: DotNet X509Certificate2): Boolean
    begin
        CheckCertificateUser;

        case "Store Type" of
            "Store Type"::Server:
                CertificateCZMgt.LoadCertificateFromServer("Store Location", "Store Name", Thumbprint, X509Certificate2);
            "Store Type"::Client:
                CertificateCZMgt.LoadCertificateFromClient("Store Location", "Store Name", Thumbprint, X509Certificate2);
            "Store Type"::Database:
                LoadCertificateFromDatabase(X509Certificate2);
        end;

        exit(not IsNull(X509Certificate2));
    end;

    local procedure DeleteCertificate()
    begin
        ISOLATEDSTORAGE.Delete("Certificate Key", DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure HasCertificate(): Boolean
    var
        CertificateValue: Text;
    begin
        CertificateValue := '';
        if not ISOLATEDSTORAGE.Get("Certificate Key", DATASCOPE::Company, CertificateValue) then
            exit(false);
        exit(CertificateValue <> '');
    end;

    [Scope('OnPrem')]
    procedure ImportCertificate()
    var
        ImportCertificateCZ: Report "Import Certificate CZ";
    begin
        TestField("Store Type", "Store Type"::Database);

        if HasCertificate then begin
            CheckCertificateUser;
            if not Confirm(CertificateExistQst, false) then
                exit;
        end;

        CheckEncryption;

        ImportCertificateCZ.SetCertificate(Rec);
        ImportCertificateCZ.RunModal;
    end;

    local procedure UpdateCertificateInformationFromCertificate(X509Certificate2: DotNet X509Certificate2)
    begin
        "Valid From" := X509Certificate2.NotBefore;
        "Valid To" := X509Certificate2.NotAfter;
        Description := X509Certificate2.FriendlyName;

        if Thumbprint <> X509Certificate2.Thumbprint then
            Thumbprint := X509Certificate2.Thumbprint;
    end;

    [Scope('OnPrem')]
    procedure UpdateCertificateInformation()
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            UpdateCertificateInformationFromCertificate(X509Certificate2);
    end;

    [Scope('OnPrem')]
    procedure SignUTF8Text(Data: Text; HashAlgorithm: Text; var Signature: DotNet Array)
    var
        Encoding: DotNet Encoding;
        X509Certificate2: DotNet X509Certificate2;
    begin
        LoadCertificateFromStore(X509Certificate2);
        CertificateCZMgt.SignTextByCertificate(Data, Encoding.UTF8, X509Certificate2, HashAlgorithm, Signature);
    end;

    [Scope('OnPrem')]
    procedure VerifySignedUTF8Text(SignedData: Text; HashAlgorithm: Text; Signature: DotNet Array; ShowMessage: Boolean): Boolean
    var
        Encoding: DotNet Encoding;
        X509Certificate2: DotNet X509Certificate2;
        IsValidSign: Boolean;
    begin
        LoadCertificateFromStore(X509Certificate2);
        IsValidSign :=
          CertificateCZMgt.VerifySignedTextByCertificate(
            SignedData, Encoding.UTF8, X509Certificate2, HashAlgorithm, Signature);

        if ShowMessage then
            if IsValidSign then
                Message(SignatureIsValidMsg)
            else
                Message(SignatureIsNotValidMsg);

        exit(IsValidSign);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateValidFrom(): DateTime
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            exit(X509Certificate2.NotBefore);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateValidTo(): DateTime
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            exit(X509Certificate2.NotAfter);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateFriendlyName(): Text
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            exit(X509Certificate2.FriendlyName);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateHasPrivateKey(): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            exit(X509Certificate2.HasPrivateKey);
    end;

    [Scope('OnPrem')]
    procedure Show()
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if LoadCertificateFromStore(X509Certificate2) then
            Message(Format(X509Certificate2));
    end;

    [Scope('OnPrem')]
    procedure IsValid(): Boolean
    begin
        exit(IsValidDateTime(CurrentDateTime));
    end;

    local procedure CheckEncryption()
    begin
        if not EncryptionEnabled then
            if Confirm(EncryptionIsNotActivatedQst) then
                PAGE.Run(PAGE::"Data Encryption Management");
    end;

    [Scope('OnPrem')]
    procedure CheckCertificateUser()
    begin
        CheckCertificateUser2(UserId);
    end;

    [Scope('OnPrem')]
    procedure CheckCertificateUser2(UserCode: Code[50])
    begin
        if ("User ID" <> '') and ("User ID" <> UserCode) then
            Error(NotCertificateUserErr, UserCode, "Certificate Code", "Valid From");
    end;

    local procedure CheckDateTimeValid()
    begin
        if ("Valid From" > "Valid To") and ("Valid To" <> 0DT) then
            Error(DateTimeValidErr, FieldCaption("Valid From"), FieldCaption("Valid To"));

        if not IsValidDateTimeForCertificateFromStore("Valid From") then
            Error(OutOfRangeErr, FieldCaption("Valid From"), "Valid From");

        if not IsValidDateTimeForCertificateFromStore("Valid To") then
            Error(OutOfRangeErr, FieldCaption("Valid To"), "Valid To");
    end;

    [Scope('OnPrem')]
    procedure IsValidDateTimeForCertificateFromStore(ValidateDateTime: DateTime): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if not LoadCertificateFromStore(X509Certificate2) then
            exit(true);

        exit(
          (ValidateDateTime >= X509Certificate2.NotBefore) and
          (ValidateDateTime <= X509Certificate2.NotAfter));
    end;

    [Scope('OnPrem')]
    procedure IsValidDateTime(ValidateDateTime: DateTime): Boolean
    var
        IsValidTemp: Boolean;
    begin
        IsValidTemp := true;

        if "Valid From" <> 0DT then
            IsValidTemp := IsValidTemp and (ValidateDateTime >= "Valid From");

        if "Valid To" <> 0DT then
            IsValidTemp := IsValidTemp and (ValidateDateTime <= "Valid To");

        exit(IsValidTemp);
    end;

    local procedure FormatThumbprint(OriginalThumbprint: Text): Text[80]
    var
        Encoding: DotNet Encoding;
    begin
        OriginalThumbprint :=
          Encoding.ASCII.GetString(
            Encoding.Convert(Encoding.Unicode, Encoding.ASCII, Encoding.Unicode.GetBytes(OriginalThumbprint)));
        exit(CopyStr(DelChr(OriginalThumbprint, '=', ' ?'), 1, MaxStrLen(Thumbprint)));
    end;

    [Scope('OnPrem')]
    procedure SaveCertificateToIsolatedStorage(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean)
    var
        CertificateCZMgt: Codeunit "Certificate CZ Management";
        CryptographyManagement: Codeunit "Cryptography Management";
        ValueTempBLOB: Codeunit "Temp Blob";
        OutStream: OutStream;
        TextCert: Text;
        EncryptedText: Text;
        Position: Integer;
    begin
        // NAVCZ
        TextCert := CertificateCZMgt.EncodeCertificateToBase64(X509Certificate2, WithPrivateKey);

        // NAVCZ
        ValueTempBLOB.CreateOutStream(OutStream);

        if not CryptographyManagement.IsEncryptionPossible then begin
            OutStream.Write(TextCert);
            exit;
        end;

        Position := 1;
        repeat
            EncryptedText += CryptographyManagement.Encrypt(CopyStr(TextCert, Position, BlockToEncryptLength));
            Position += BlockToEncryptLength;
        until Position >= StrLen(TextCert);

        OutStream.Write(EncryptedText);
    end;

    local procedure BlockToEncryptLength(): Integer
    begin
        // NAVCZ
        exit(214);
    end;
}

