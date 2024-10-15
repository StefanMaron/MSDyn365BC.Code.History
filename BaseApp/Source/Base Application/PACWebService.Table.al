table 10000 "PAC Web Service"
{
    Caption = 'PAC Web Service';
    LookupPageID = "PAC Web Services";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(21; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(22; "Certificate Thumbprint"; Text[250])
        {
            Caption = 'Certificate Thumbprint';
            ObsoleteReason = 'Using Local Certificate store is deprecated. Use Certificate field instead that are linked to certificate table.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(23; Certificate; Code[20])
        {
            Caption = 'Certificate';
            TableRelation = "Isolated Certificate";
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

    trigger OnDelete()
    begin
        ValidateUsage;
        DeleteSubTables;
    end;

    var
        Text000: Label 'You cannot delete the code %1 because it is used in the %2 window.';
        PACWebServiceDetail: Record "PAC Web Service Detail";

    procedure ValidateUsage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if (GeneralLedgerSetup."PAC Code" <> '') and (GeneralLedgerSetup."PAC Code" = Code) then
            Error(Text000, Code, GeneralLedgerSetup.TableCaption);
    end;

    procedure DeleteSubTables()
    begin
        PACWebServiceDetail.SetRange("PAC Code", Code);
        if not PACWebServiceDetail.IsEmpty then
            PACWebServiceDetail.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CheckIfMissingMXEInvRequiredFields(): Boolean
    var
        PACWebService: Record "PAC Web Service";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if PACWebService.Get(GeneralLedgerSetup."PAC Code") then
            exit(PACWebService.Certificate = '');
    end;
}

