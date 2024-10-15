table 18283 "Periodic GSTR-2A Data"
{
    Caption = 'Periodic GSTR-2A Data';

    fields
    {
        field(1; "GSTIN No."; Code[20])
        {
            Caption = 'GSTIN No.';
            TableRelation = "GST Registration Nos.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "State Code"; Code[10])
        {
            Caption = 'State Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = State;
        }
        field(3; Month; Integer)
        {
            Caption = 'Month';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; Year; Integer)
        {
            Caption = 'Year';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = Invoice,"Revised Invoice","Debit Note","Revised Debit Note","Credit Note","Revised Credit Note","ISD Credit","TDS Credit","TCS Credit";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "GSTIN of Supplier"; Code[20])
        {
            Caption = 'GSTIN of Supplier';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Document No."; Code[35])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Goods/Services"; Option)
        {
            Caption = 'Goods/Services';
            OptionCaption = 'Goods,Services';
            OptionMembers = Goods,Services;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "HSN/SAC"; Code[8])
        {
            Caption = 'HSN/SAC';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Taxable Value"; Decimal)
        {
            Caption = 'Taxable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Component 1 Rate"; Decimal)
        {
            Caption = 'Component 1 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Component 1 Amount"; Decimal)
        {
            Caption = 'Component 1 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Component 2 Rate"; Decimal)
        {
            Caption = 'Component 2 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "Component 2 Amount"; Decimal)
        {
            Caption = 'Component 2 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Component 3 Rate"; Decimal)
        {
            Caption = 'Component 3 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Component 3 Amount"; Decimal)
        {
            Caption = 'Component 3 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; POS; Text[50])
        {
            Caption = 'POS';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "Revised GSTIN of Supplier"; Code[15])
        {
            Caption = 'Revised GSTIN of Supplier';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "Revised Document No."; Code[35])
        {
            Caption = 'Revised Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Revised Document Date"; Date)
        {
            Caption = 'Revised Document Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Revised Document Value"; Decimal)
        {
            Caption = 'Revised Document Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Revised Goods/Services"; Option)
        {
            OptionCaption = 'Goods, Services';
            OptionMembers = Goods,Services;
            Caption = 'Revised Goods/Services';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Revised HSN/SAC"; Code[10])
        {
            Caption = 'Revised HSN/SAC';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Revised Taxable Value"; Decimal)
        {
            Caption = 'Revised Taxable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "Type of Note"; Option)
        {
            Caption = 'Type of Note';
            OptionCaption = 'Debit, Credit';
            OptionMembers = Debit,Credit;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "Debit/Credit Note No."; Code[35])
        {
            Caption = 'Debit/Credit Note No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Debit/Credit Note Date"; Date)
        {
            Caption = 'Debit/Credit Note Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Differential Value"; Decimal)
        {
            Caption = 'Differential Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Date of Payment to Deductee"; Date)
        {
            Caption = 'Date of Payment to Deductee';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; "Value on TDS has been Deducted"; Decimal)
        {
            Caption = 'Value on TDS has been Deducted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(34; "Merch. ID alloc. By e-com port"; Code[35])
        {
            Caption = 'Merch. ID alloc. By e-com port';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Gross Value of Supplies"; Decimal)
        {
            Caption = 'Gross Value of Supplies';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(36; "Tax Value on TCS has Deducted"; Decimal)
        {
            Caption = 'Tax Value on TCS has Deducted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; Reconciled; Boolean)
        {
            Caption = 'Reconciled';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(38; "Reconciliation Date"; Date)
        {
            Caption = 'Reconciliation Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; Matched; Option)
        {
            Caption = 'Matched';
            OptionCaption = ' ,Rec Matched,Error Found,No Line';
            OptionMembers = " ","Rec Matched","Error Found","No Line";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(41; "Component 4 Rate"; Decimal)
        {
            Caption = 'Component 4 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(42; "Component 4 Amount"; Decimal)
        {
            Caption = 'Component 4 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "Component 5 Rate"; Decimal)
        {
            Caption = 'Component 5 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; "Component 5 Amount"; Decimal)
        {
            Caption = 'Component 5 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "Component 6 Rate"; Decimal)
        {
            Caption = 'Component 6 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(46; "Component 6 Amount"; Decimal)
        {
            Caption = 'Component 6 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(47; "Component 7 Rate"; Decimal)
        {
            Caption = 'Component 7 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(48; "Component 7 Amount"; Decimal)
        {
            Caption = 'Component 7 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(49; "Component 8 Rate"; Decimal)
        {
            Caption = 'Component 8 Rate';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50; "Component 8 Amount"; Decimal)
        {
            Caption = 'Component 8 Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "GSTIN No.", "State Code", Month, Year, "Document No.", "HSN/SAC")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "User Id" := CopyStr(UserId(), 1, MaxStrLen("User Id"));
    end;
}

