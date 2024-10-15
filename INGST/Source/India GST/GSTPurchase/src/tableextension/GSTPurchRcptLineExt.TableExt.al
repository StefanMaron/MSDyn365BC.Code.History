tableextension 18091 "GST Purch. Rcpt. Line Ext" extends "Purch. Rcpt. Line"
{
    fields
    {
        field(18080; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            TableRelation = "GST Group";
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18081; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18082; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18083; "GST Jurisdiction Type"; enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18084; "Custom Duty Amount"; Decimal)
        {
            Caption = 'Custom Duty Amount';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(18085; "GST Reverse Charge"; Boolean)
        {
            Caption = 'GST Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18086; "GST Assessable Value"; Decimal)
        {
            Caption = 'GST Assessable Value';
            MinValue = 0;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18087; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18088; "Buy-From GST Registration No"; Code[20])
        {
            Caption = 'Buy-From GST Registration No';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18089; "GST Rounding Line"; Boolean)
        {
            Caption = 'GST Rounding Line';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18090; "Bill to-Location(POS)"; Code[20])
        {
            Caption = 'Bill to-Location(POS)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18091; "Non-GST Line"; Boolean)
        {
            Caption = 'Non-GST Line';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18092; "Supplementary"; Boolean)
        {
            Caption = 'Supplementary';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18093; "Source Document Type"; Enum "GST Source Document Type")
        {
            Caption = 'Source Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18094; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation =
            if ("Source Document Type" = filter("Posted Invoice")) "Purch. Inv. Header"."No." else
            if ("Source Document Type" = filter("Posted Credit Memo")) "Purch. Cr. Memo Hdr."."No.";
        }
        field(18095; "GST Credit"; Enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18096; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}