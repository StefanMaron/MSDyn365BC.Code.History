table 11761 "Electronically Govern. Setup"
{
    Caption = 'Electronically Govern. Setup';
    ReplicateData = false;
#if CLEAN17
    ObsoleteState = Removed;
#else
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(30; "Proxy Server"; Text[30])
        {
            Caption = 'Proxy Server';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31; "Proxy User"; Text[30])
        {
            Caption = 'Proxy User';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(32; "Proxy Password"; Text[30])
        {
            Caption = 'Proxy Password';
            ExtendedDatatype = Masked;
            ObsoleteReason = 'Moved to Service Password';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(33; "Proxy Password Key"; Guid)
        {
            Caption = 'Proxy Password Key';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(80; UncertaintyPayerWebService; Text[250])
        {
            Caption = 'UncertaintyPayerWebService';
            ExtendedDatatype = URL;
            InitValue = 'http://adisrws.mfcr.cz/adistc/axis2/services/rozhraniCRPDPH.rozhraniCRPDPHSOAP';
        }
        field(81; "Public Bank Acc.Chck.Star.Date"; Date)
        {
            Caption = 'Public Bank Acc.Chck.Star.Date';
        }
        field(82; "Public Bank Acc.Check Limit"; Decimal)
        {
            BlankZero = true;
            Caption = 'Public Bank Acc.Check Limit';
            MinValue = 0;
        }
        field(85; "Unc.Payer Request Record Limit"; Integer)
        {
            Caption = 'Unc.Payer Request Record Limit';
            InitValue = 99;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}

