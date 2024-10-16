table 7821 "MS-QBO Item"
{
    Caption = 'MS-QBO Item';
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
        field(6; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(7; Sku; Text[100])
        {
            Caption = 'Sku';
        }
        field(8; Description; BLOB)
        {
            Caption = 'Description';
        }
        field(9; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(10; SubItem; Boolean)
        {
            Caption = 'SubItem';
        }
        field(11; ParentRef; BLOB)
        {
            Caption = 'ParentRef';
        }
        field(12; Level; Integer)
        {
            Caption = 'Level';
        }
        field(13; FullyQualifiedName; Text[250])
        {
            Caption = 'FullyQualifiedName';
        }
        field(14; Taxable; Boolean)
        {
            Caption = 'Taxable';
        }
        field(15; SalesTaxIncluded; Boolean)
        {
            Caption = 'SalesTaxIncluded';
        }
        field(16; UnitPrice; Decimal)
        {
            Caption = 'UnitPrice';
        }
        field(17; Type; Text[250])
        {
            Caption = 'Type';
        }
        field(18; IncomeAccountRef; BLOB)
        {
            Caption = 'IncomeAccountRef';
        }
        field(19; ExpenseAccountRef; BLOB)
        {
            Caption = 'ExpenseAccountRef';
        }
        field(20; PurchaseDesc; Text[30])
        {
            Caption = 'PurchaseDesc';
        }
        field(21; PurchaseTaxIncluded; Boolean)
        {
            Caption = 'PurchaseTaxIncluded';
        }
        field(22; PurchaseCost; Decimal)
        {
            Caption = 'PurchaseCost';
        }
        field(23; AssetAccountRef; BLOB)
        {
            Caption = 'AssetAccountRef';
        }
        field(24; TrackQtyOnHand; Boolean)
        {
            Caption = 'TrackQtyOnHand';
        }
        field(25; InvStartDate; Date)
        {
            Caption = 'InvStartDate';
        }
        field(26; QtyOnHand; Decimal)
        {
            Caption = 'QtyOnHand';
        }
        field(27; SalesTaxCodeRef; BLOB)
        {
            Caption = 'SalesTaxCodeRef';
        }
        field(28; PurchaseTaxCodeRef; BLOB)
        {
            Caption = 'PurchaseTaxCodeRef';
        }
        field(29; All; BLOB)
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

