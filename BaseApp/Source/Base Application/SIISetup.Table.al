table 10751 "SII Setup"
{
    Caption = 'SII VAT Setup';
    LookupPageID = "SII Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                if Enabled and not Certificate.HasValue then
                    Error(CannotEnableWithoutCertificateErr);
            end;
        }
        field(3; Certificate; BLOB)
        {
            ObsoleteReason = 'Will be replaced with the Certificate Code field in next version.';
            ObsoleteState = Pending;
            Caption = 'Certificate';
        }
        field(4; Password; Text[250])
        {
            ObsoleteReason = 'Will be replaced with the Certificate Code field in next version.';
            ObsoleteState = Pending;
            Caption = 'Password';

            trigger OnValidate()
            begin
                ValidateCertificatePassword;
            end;
        }
        field(5; InvoicesIssuedEndpointUrl; Text[250])
        {
            Caption = 'InvoicesIssuedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP';
            NotBlank = true;
        }
        field(6; InvoicesReceivedEndpointUrl; Text[250])
        {
            Caption = 'InvoicesReceivedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fr/SiiFactFRV1SOAP';
            NotBlank = true;
        }
        field(7; PaymentsIssuedEndpointUrl; Text[250])
        {
            Caption = 'PaymentsIssuedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fr/SiiFactPAGV1SOAP';
            NotBlank = true;
        }
        field(8; PaymentsReceivedEndpointUrl; Text[250])
        {
            Caption = 'PaymentsReceivedEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactCOBV1SOAP';
            NotBlank = true;
        }
        field(9; IntracommunityEndpointUrl; Text[250])
        {
            Caption = 'IntracommunityEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/oi/SiiFactOIV1SOAP';
            NotBlank = true;
            ObsoleteReason = 'Intracommunity feature was removed in scope of 222210';
            ObsoleteState = Pending;
        }
        field(10; "Enable Batch Submissions"; Boolean)
        {
            Caption = 'Enable Batch Submissions';
        }
        field(11; "Job Batch Submission Threshold"; Integer)
        {
            Caption = 'Job Batch Submission Threshold';
            MinValue = 0;
        }
        field(12; "Show Advanced Actions"; Boolean)
        {
            Caption = 'Show Advanced Actions';
        }
        field(13; CollectionInCashEndpointUrl; Text[250])
        {
            Caption = 'CollectionInCashEndpointUrl';
            InitValue = 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/pm/SiiFactCMV1SOAP';
            NotBlank = true;
        }
        field(20; "Invoice Amount Threshold"; Decimal)
        {
            Caption = 'Invoice Amount Threshold';
            InitValue = 100;
            MinValue = 0;
        }
        field(30; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(31; "Auto Missing Entries Check"; Option)
        {
            Caption = 'Auto Missing Entries Check';
            InitValue = Daily;
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                SIIJobManagement: Codeunit "SII Job Management";
            begin
                if "Auto Missing Entries Check" = xRec."Auto Missing Entries Check" then
                    exit;

                SIIJobManagement.RestartJobQueueEntryForMissingEntryCheck("Auto Missing Entries Check");
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Starting Date" := WorkDate;
    end;

    var
        CannotEnableWithoutCertificateErr: Label 'The setup cannot be enabled without a valid certificate.';
        TaxpayerCertificateImportedMsg: Label 'The taxpayer certificate has been successfully imported.';
        CertificatePasswordIncorrectErr: Label 'The certificate could not get loaded. The password for the certificate may be incorrect.';
        CerFileFilterExtensionTxt: Label 'All Files (*.*)|*.*';
        CerFileFilterTxt: Label 'cer p12 crt pfx', Locked = true;
        ImportFileTxt: Label 'Select a file to import';

    [Scope('OnPrem')]
    procedure ImportCertificate()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        if FileManagement.BLOBImportWithFilter(TempBlob, ImportFileTxt, '', CerFileFilterExtensionTxt, CerFileFilterTxt) = '' then
            exit;

        Clear(Certificate);

        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Certificate));
        RecordRef.SetTable(Rec);
        Validate(Enabled, true);
        Modify(true);

        Message(TaxpayerCertificateImportedMsg);
    end;

    [Scope('OnPrem')]
    procedure DeleteCertificate()
    begin
        Clear(Certificate);
        Password := '';
        Validate(Enabled, false);
        Modify(true);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadCertificateFromBlob(var Cert: DotNet X509Certificate2)
    var
        BlobIn: InStream;
        MemStream: DotNet MemoryStream;
    begin
        CalcFields(Certificate);
        if not Certificate.HasValue or (Password = '') then
            Error('');

        Certificate.CreateInStream(BlobIn);
        MemStream := MemStream.MemoryStream;
        CopyStream(MemStream, BlobIn);
        Cert := Cert.X509Certificate2(MemStream.ToArray, Password);
    end;

    [Scope('OnPrem')]
    procedure ValidateCertificatePassword()
    var
        Cert: DotNet X509Certificate2;
    begin
        if not LoadCertificateFromBlob(Cert) then
            Error(CertificatePasswordIncorrectErr);
    end;

    [Scope('OnPrem')]
    procedure IsEnabled(): Boolean
    begin
        if not Get then
            exit(false);
        exit(Enabled);
    end;
}

