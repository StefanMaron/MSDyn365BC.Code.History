table 31130 "Certificate CZ Code"
{
    Caption = 'Certificate Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Certificates CZ Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure LoadValidCertificate(var CertificateCZ: Record "Certificate CZ"): Boolean
    begin
        if LoadValidCertificateForUser(CertificateCZ, UserId) then
            exit(true);
        exit(LoadValidCertificateForAll(CertificateCZ));
    end;

    local procedure LoadValidCertificateForAll(var CertificateCZ: Record "Certificate CZ"): Boolean
    begin
        exit(LoadValidCertificateForUser(CertificateCZ, ''));
    end;

    local procedure LoadValidCertificateForUser(var CertificateCZ: Record "Certificate CZ"; UserCode: Code[50]): Boolean
    begin
        Clear(CertificateCZ);
        CertificateCZ.SetRange("Certificate Code", Code);
        CertificateCZ.SetFilter("Valid From", '%1|<=%2', 0DT, CurrentDateTime);
        CertificateCZ.SetFilter("Valid To", '%1|>=%2', 0DT, CurrentDateTime);
        CertificateCZ.SetFilter("User ID", '%1', UserCode);
        if not CertificateCZ.FindFirst then
            exit(false);
        exit(CertificateCZ.IsValid);
    end;
}

