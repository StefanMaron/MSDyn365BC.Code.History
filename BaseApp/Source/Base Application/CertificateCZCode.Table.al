table 31130 "Certificate CZ Code"
{
    Caption = 'Certificate Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Certificate Code List";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

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
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure LoadValidCertificate(var IsolatedCertificate: Record "Isolated Certificate"): Boolean
    var
        User: Record User;
    begin
        if not User.Get(UserSecurityId()) then
            User.Init();
        exit(LoadValidCertificate(IsolatedCertificate, User."User Name"));
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure LoadValidCertificate(var IsolatedCertificate: Record "Isolated Certificate"; UserName: Code[50]): Boolean
    begin
        Clear(IsolatedCertificate);
        IsolatedCertificate.SetRange("Certificate Code", Code);
        IsolatedCertificate.SetFilter("Expiry Date", '%1|>=%2', 0DT, CurrentDateTime);
        IsolatedCertificate.SetRange("Company ID", CompanyName);
        if UserName = '' then
            exit(IsolatedCertificate.FindFirst());

        IsolatedCertificate.SetRange("User ID", UserName);
        if IsolatedCertificate.FindFirst() then
            exit(true);

        IsolatedCertificate.SetRange("Company ID");
        if IsolatedCertificate.FindFirst() then
            exit(true);

        IsolatedCertificate.SetRange("User ID");
        IsolatedCertificate.SetRange("Company ID", CompanyName);
        exit(IsolatedCertificate.FindFirst());
    end;
}