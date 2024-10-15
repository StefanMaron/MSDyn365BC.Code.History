table 31089 "Acc. Schedule Extension"
{
    Caption = 'Acc. Schedule Extension';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Source Table"; Option)
        {
            Caption = 'Source Table';
            OptionCaption = 'VAT Entry,Value Entry,Customer Entry,Vendor Entry';
            OptionMembers = "VAT Entry","Value Entry","Customer Entry","Vendor Entry";
        }
        field(11; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(12; "Source Filter"; Text[100])
        {
            Caption = 'Source Filter';

            trigger OnLookup()
            begin
                case "Source Type" of
                    "Source Type"::Customer:
                        if PAGE.RunModal(0, Cust) = ACTION::LookupOK then
                            "Source Filter" += Cust."No.";
                    "Source Type"::Vendor:
                        if PAGE.RunModal(0, Vend) = ACTION::LookupOK then
                            "Source Filter" += Vend."No.";
                    "Source Type"::"Bank Account":
                        if PAGE.RunModal(0, BankAcc) = ACTION::LookupOK then
                            "Source Filter" += BankAcc."No.";
                    "Source Type"::"Fixed Asset":
                        if PAGE.RunModal(0, FA) = ACTION::LookupOK then
                            "Source Filter" += FA."No.";
                end;
            end;
        }
        field(13; "G/L Account Filter"; Text[100])
        {
            Caption = 'G/L Account Filter';

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, GLAcc) = ACTION::LookupOK then
                    "G/L Account Filter" += GLAcc."No.";
            end;
        }
        field(14; "G/L Amount Type"; Option)
        {
            Caption = 'G/L Amount Type';
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = " ",Debit,Credit;
        }
        field(15; "Amount Sign"; Option)
        {
            Caption = 'Amount Sign';
            OptionCaption = ' ,Positive,Negative';
            OptionMembers = " ",Positive,Negative;
        }
        field(16; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(17; Prepayment; Option)
        {
            Caption = 'Prepayment';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
        }
        field(18; "Reverse Sign"; Boolean)
        {
            Caption = 'Reverse Sign';
        }
        field(20; "VAT Amount Type"; Option)
        {
            Caption = 'VAT Amount Type';
            OptionCaption = ' ,Base,Amount';
            OptionMembers = " ",Base,Amount;
        }
        field(21; "VAT Bus. Post. Group Filter"; Text[100])
        {
            Caption = 'VAT Bus. Post. Group Filter';

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, VATBusPostGroup) = ACTION::LookupOK then
                    "VAT Bus. Post. Group Filter" += VATBusPostGroup.Code;
            end;
        }
        field(22; "VAT Prod. Post. Group Filter"; Text[100])
        {
            Caption = 'VAT Prod. Post. Group Filter';

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, VATProdPostGroup) = ACTION::LookupOK then
                    "VAT Prod. Post. Group Filter" += VATProdPostGroup.Code;
            end;
        }
        field(30; "Location Filter"; Text[100])
        {
            Caption = 'Location Filter';

            trigger OnLookup()
            begin
                if "Source Table" = "Source Table"::"Value Entry" then
                    if PAGE.RunModal(0, Location) = ACTION::LookupOK then
                        "Location Filter" += Location.Code;
            end;
        }
        field(31; "Bin Filter"; Text[100])
        {
            Caption = 'Bin Filter';

            trigger OnLookup()
            begin
                if "Source Table" = "Source Table"::"Value Entry" then begin
                    Bin.SetFilter("Location Code", "Location Filter");
                    if PAGE.RunModal(0, Bin) = ACTION::LookupOK then
                        "Bin Filter" += Bin.Code;
                end;
            end;
        }
        field(56; "Posting Group Filter"; Code[250])
        {
            Caption = 'Posting Group Filter';
            TableRelation = IF ("Source Table" = CONST("Customer Entry")) "Customer Posting Group"
            ELSE
            IF ("Source Table" = CONST("Vendor Entry")) "Vendor Posting Group";
            ValidateTableRelation = false;
        }
        field(57; "Posting Date Filter"; Code[20])
        {
            Caption = 'Posting Date Filter';
        }
        field(58; "Due Date Filter"; Code[20])
        {
            Caption = 'Due Date Filter';
        }
        field(59; "Document Type Filter"; Text[100])
        {
            Caption = 'Document Type Filter';

            trigger OnValidate()
            begin
                case "Source Table" of
                    "Source Table"::"Customer Entry":
                        begin
                            CustLedgEntry.SetFilter("Document Type", "Document Type Filter");
                            "Document Type Filter" := CopyStr(CustLedgEntry.GetFilter("Document Type"),
                              1, MaxStrLen("Document Type Filter"));
                        end;
                    "Source Table"::"Vendor Entry":
                        begin
                            VendLedgEntry.SetFilter("Document Type", "Document Type Filter");
                            "Document Type Filter" := CopyStr(VendLedgEntry.GetFilter("Document Type"),
                              1, MaxStrLen("Document Type Filter"));
                        end;
                end;
            end;
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

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        GLAcc: Record "G/L Account";
        VATBusPostGroup: Record "VAT Business Posting Group";
        VATProdPostGroup: Record "VAT Product Posting Group";
        Location: Record Location;
        Bin: Record Bin;
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        RenameErr: Label 'You cannot rename a %1.';
}

