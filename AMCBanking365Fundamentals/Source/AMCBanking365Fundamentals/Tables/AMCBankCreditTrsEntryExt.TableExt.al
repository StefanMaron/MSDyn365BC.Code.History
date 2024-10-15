tableextension 20105 "AMC Bank Credit Trs. Entry Ext" extends "Credit Transfer Entry"
{
    fields
    {
        field(20100; "Data Exch. Entry No."; Integer) //AMC-JN to find line again in xmlport 51232
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
            DataClassification = CustomerContent;
        }
        field(20101; "Pmt. Disc. Possible"; Decimal) //AMC-JN to find Payment Discount Amount in xmlport 51232
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Possible';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

}

