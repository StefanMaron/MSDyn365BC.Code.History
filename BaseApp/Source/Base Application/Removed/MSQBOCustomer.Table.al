table 7820 "MS-QBO Customer"
{
    Caption = 'MS-QBO Customer';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
        }
        field(2; SyncToken; Text[250])
        {
            Caption = 'SyncToken';
        }
        field(3; MetaData; BLOB)
        {
            Caption = 'MetaData';
        }
        field(4; "MetaData CreateTime"; DateTime)
        {
            Caption = 'MetaData CreateTime';
        }
        field(5; "MetaData LastUpdatedTime"; DateTime)
        {
            Caption = 'MetaData LastUpdatedTime';
        }
        field(6; Title; Text[15])
        {
            Caption = 'Title';
        }
        field(7; GivenName; Text[25])
        {
            Caption = 'GivenName';
        }
        field(8; MiddleName; Text[25])
        {
            Caption = 'MiddleName';
        }
        field(9; FamilyName; Text[25])
        {
            Caption = 'FamilyName';
        }
        field(10; Suffix; Text[10])
        {
            Caption = 'Suffix';
        }
        field(11; DisplayName; Text[100])
        {
            Caption = 'DisplayName';
        }
        field(12; FullyQualifiedName; Text[250])
        {
            Caption = 'FullyQualifiedName';
        }
        field(13; CompanyName; Text[50])
        {
            Caption = 'CompanyName';
        }
        field(14; PrintOnCheckName; Text[110])
        {
            Caption = 'PrintOnCheckName';
        }
        field(15; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(16; PrimaryPhone; BLOB)
        {
            Caption = 'PrimaryPhone';
            SubType = Json;
        }
        field(17; AlternatePhone; BLOB)
        {
            Caption = 'AlternatePhone';
        }
        field(18; Mobile; BLOB)
        {
            Caption = 'Mobile';
        }
        field(19; Fax; BLOB)
        {
            Caption = 'Fax';
        }
        field(20; PrimaryEmailAddr; BLOB)
        {
            Caption = 'PrimaryEmailAddr';
            SubType = Json;
        }
        field(21; WebAddr; BLOB)
        {
            Caption = 'WebAddr';
        }
        field(22; DefaultTaxCodeRef; BLOB)
        {
            Caption = 'DefaultTaxCodeRef';
        }
        field(23; Taxable; Boolean)
        {
            Caption = 'Taxable';
        }
        field(24; BillAddr; BLOB)
        {
            Caption = 'BillAddr';
            SubType = Json;
        }
        field(25; ShipAddr; BLOB)
        {
            Caption = 'ShipAddr';
        }
        field(26; Notes; BLOB)
        {
            Caption = 'Notes';
        }
        field(27; Job; Boolean)
        {
            Caption = 'Job';
        }
        field(28; BillWithParent; Boolean)
        {
            Caption = 'BillWithParent';
        }
        field(29; ParentRef; BLOB)
        {
            Caption = 'ParentRef';
        }
        field(30; Level; Integer)
        {
            Caption = 'Level';
        }
        field(31; SalesTermRef; BLOB)
        {
            Caption = 'SalesTermRef';
        }
        field(32; PaymentMethodRef; BLOB)
        {
            Caption = 'PaymentMethodRef';
        }
        field(33; Balance; Decimal)
        {
            Caption = 'Balance';
        }
        field(34; OpenBalanceDate; Date)
        {
            Caption = 'OpenBalanceDate';
        }
        field(35; BalanceWithJobs; Decimal)
        {
            Caption = 'BalanceWithJobs';
        }
        field(36; CurrencyRef; BLOB)
        {
            Caption = 'CurrencyRef';
        }
        field(37; PreferredDeliveryMethod; Text[250])
        {
            Caption = 'PreferredDeliveryMethod';
        }
        field(38; ResaleNum; Text[16])
        {
            Caption = 'ResaleNum';
        }
        field(39; All; BLOB)
        {
            Caption = 'All';
            SubType = Json;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "MetaData LastUpdatedTime")
        {
        }
    }

    fieldgroups
    {
    }
}

