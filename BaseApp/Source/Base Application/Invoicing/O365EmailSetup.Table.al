table 2118 "O365 Email Setup"
{
    Caption = 'O365 Email Setup';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[80])
        {
            Caption = 'Code';
#if not CLEAN21
            trigger OnValidate()
            var
                GuidVar: Guid;
            begin
                if not Evaluate(GuidVar, Code) then
                    Error(CodeFormatErr);

                if IsNullGuid(GuidVar) then
                    Error(CodeEmptyErr);
            end;
#endif
        }
        field(2; Email; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
#if not CLEAN21
            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if DelChr(Email, '=', ' ') = '' then
                    if Delete() then
                        exit;

                MailManagement.CheckValidEmailAddress(Email);
            end;
#endif
        }
        field(3; RecipientType; Option)
        {
            Caption = 'RecipientType';
            OptionCaption = 'CC,BCC';
            OptionMembers = CC,BCC;
        }
    }

    keys
    {
        key(Key1; "Code", RecipientType)
        {
            Clustered = true;
        }
        key(Key2; Email, RecipientType)
        {
        }
        key(Key3; Email)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; RecipientType, Email)
        {
        }
    }
#if not CLEAN21
    trigger OnInsert()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if Email = '' then
            Error(EmailAddressEmptyErr);

        Code := UpperCase(GraphMgtGeneralTools.GetIdWithoutBrackets(CreateGuid()));

        CheckAlreadyAdded();
    end;

    trigger OnModify()
    begin
        if Email <> '' then
            CheckAlreadyAdded()
        else
            if Delete() then; // If Email validate was called rec may have been deleted already
    end;

    trigger OnRename()
    begin
        CheckAlreadyAdded();
    end;

    var
        EmailAddressEmptyErr: Label 'An email address must be specified.';
        ConfigAlreadyExistsErr: Label 'The email address has already been added.';
        CodeFormatErr: Label 'The code must be a GUID.';
        CodeEmptyErr: Label 'The code must be not null.';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetCCAddressesFromO365EmailSetup() Addresses: Text[250]
    begin
        Reset();
        SetCurrentKey(Email, RecipientType);
        SetRange(RecipientType, RecipientType::CC);

        if FindSet() then
            repeat
                Addresses += Email + ';';
            until Next() = 0;
        Addresses := DelChr(Addresses, '>', ';');
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetBCCAddressesFromO365EmailSetup() Addresses: Text[250]
    begin
        Reset();
        SetCurrentKey(Email, RecipientType);
        SetRange(RecipientType, RecipientType::BCC);
        if FindSet() then
            repeat
                Addresses += Email + ';';
            until Next() = 0;
        Addresses := DelChr(Addresses, '>', ';');
    end;

    local procedure CheckAlreadyAdded()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        O365EmailSetup.SetFilter(Code, '<>%1', Code);
        SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, Email);
        O365EmailSetup.SetRange(RecipientType, RecipientType);
        if not O365EmailSetup.IsEmpty() then
            Error(ConfigAlreadyExistsErr);
    end;
#endif
}


