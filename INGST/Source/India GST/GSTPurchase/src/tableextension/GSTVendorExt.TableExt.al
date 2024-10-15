tableextension 18092 "GST Vendor Ext" extends Vendor
{
    fields
    {
        field(18080; "GST Registration No."; Code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18081; "GST Vendor Type"; Enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18082; "Associated Enterprises"; Boolean)
        {
            Caption = 'Associated Enterprises';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18083; "Aggregate Turnover"; Enum "Aggregate Turnover")
        {
            Caption = 'Aggregate Turnover';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18084; "ARN No."; Code[20])
        {
            Caption = 'ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18085; "Composition"; Boolean)
        {
            Caption = 'Composition';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18086; Transporter; Boolean)
        {
            Caption = 'Transporter';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}