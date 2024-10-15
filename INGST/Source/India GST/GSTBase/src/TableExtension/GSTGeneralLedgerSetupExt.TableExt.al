tableextension 18003 "GST General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
        field(18000; "GST Distribution Nos."; code[10])
        {
            caption = 'GST Distribution Nos.';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18001; "GST Credit Adj. Jnl Nos."; code[10])
        {
            Caption = 'GST Credit Adj. Jnl Nos';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18002; "GST Settlement Nos."; code[10])
        {
            Caption = 'GST Settlement Nos.';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18003; "GST Recon. Tolerance"; Decimal)
        {
            Caption = 'GST Recon. Tolerance';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18004; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18005; "GST Inv. Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18006; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18007; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18008; "GST Inv. Rounding Account"; Code[20])
        {
            Caption = 'GST Inv. Rounding Account';
            TableRelation = "G/L Account" WHERE(Blocked = CONST(False), "Account Type" = FILTER(Posting));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18009; "State Code - Kerala"; Code[10])
        {
            Caption = 'State Code - Kerala';
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}

