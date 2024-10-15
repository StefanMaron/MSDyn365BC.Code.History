table 11404 "Audit File Buffer"
{
    Caption = 'Audit File Buffer';

    fields
    {
        field(1; Rectype; Option)
        {
            Caption = 'Rectype';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Transaction';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account",Transaction;
        }
        field(5; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(10; JournalID; Text[20])
        {
            Caption = 'JournalID';
            DataClassification = SystemMetadata;
        }
        field(15; JournalDescription; Text[100])
        {
            Caption = 'JournalDescription';
            DataClassification = SystemMetadata;
        }
        field(20; TransactionID; Text[20])
        {
            Caption = 'TransactionID';
            DataClassification = SystemMetadata;
        }
        field(25; TransactionDescription; Text[100])
        {
            Caption = 'TransactionDescription';
            DataClassification = SystemMetadata;
        }
        field(30; Period; Text[5])
        {
            Caption = 'Period';
            DataClassification = SystemMetadata;
        }
        field(35; TransactionDate; Date)
        {
            Caption = 'TransactionDate';
            DataClassification = SystemMetadata;
        }
        field(40; RecordID; Text[20])
        {
            Caption = 'RecordID';
            DataClassification = SystemMetadata;
        }
        field(45; AccountID; Text[15])
        {
            Caption = 'AccountID';
            DataClassification = SystemMetadata;
        }
        field(50; CustSupID; Text[15])
        {
            Caption = 'CustSupID';
            DataClassification = SystemMetadata;
        }
        field(55; DocumentID; Text[15])
        {
            Caption = 'DocumentID';
            DataClassification = SystemMetadata;
        }
        field(60; EffectiveDate; Date)
        {
            Caption = 'EffectiveDate';
            DataClassification = SystemMetadata;
        }
        field(65; LineDescription; Text[100])
        {
            Caption = 'LineDescription';
            DataClassification = SystemMetadata;
        }
        field(70; DebitAmount; Decimal)
        {
            Caption = 'DebitAmount';
            DataClassification = SystemMetadata;
        }
        field(75; CreditAmount; Decimal)
        {
            Caption = 'CreditAmount';
            DataClassification = SystemMetadata;
        }
        field(76; CostDescription; Text[100])
        {
            Caption = 'CostDescription';
            DataClassification = SystemMetadata;
        }
        field(77; ProductDescription; Text[100])
        {
            Caption = 'ProductDescription';
            DataClassification = SystemMetadata;
        }
        field(80; VATCode; Code[20])
        {
            Caption = 'VATCode';
            DataClassification = SystemMetadata;
        }
        field(81; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(82; VATAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VATAmount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Rectype, "Code", JournalID, TransactionID, RecordID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

