tableextension 18151 "GST Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(18141; "GST Place Of Supply"; Enum "GST Place Of Supply")
        {
            Caption = 'GST Place of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18142; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "GST Group";
        }
        field(18143; "GST Group Type"; Enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18144; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(18145; "GST Jurisdiction Type"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18146; "Invoice Type"; Enum "Sales Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18147; Exempted; Boolean)
        {
            Caption = 'Exempted';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18148; "GST Rounding Line"; Boolean)
        {
            Caption = 'GST Rounding Line';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18149; "GST On Assessable Value"; Boolean)
        {
            Caption = 'GST On Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18150; "GST Assessable Value (LCY)"; Decimal)
        {
            Caption = 'GST Assessable Value (LCY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18151; "Non-GST Line"; Boolean)
        {
            Caption = 'Non-GST Line';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18152; "Price Inclusive of Tax"; boolean)
        {
            Caption = 'Price Inclusive of Tax';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18153; "GST Credit"; Enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18154; "GST Assessable Value (FCY)"; Decimal)
        {
            Caption = 'GST Assessable Value (FCY)';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18155; "Unit Price Incl. of Tax"; Decimal)
        {
            Caption = 'Unit Price Incl. of Tax';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18156; "Total UPIT Amount"; Decimal)
        {
            Caption = 'Total UPIT Amount';
            DataClassification = EndUserIdentifiableInformation;
        }

    }
}