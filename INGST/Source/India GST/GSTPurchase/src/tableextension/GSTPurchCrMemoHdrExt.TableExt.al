tableextension 18085 "GST Purch. Cr. Memo Hdr. Ext" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(18080; "Nature of Supply"; enum "GST Nature of Supply")
        {
            Caption = 'Nature of Supply';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18081; "GST Vendor Type"; Enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18082; "Associated Enterprises"; Boolean)
        {
            Caption = 'Associated Enterprises';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18083; "Invoice Type"; enum "GST Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18084; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            MinValue = 0;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18085; "GST Inv. Rounding Type"; enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18086; "Supply Finish Date"; Enum "GST Rate Change")
        {
            Caption = 'Supply Finish Date';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18087; "Payment Date"; enum "GST Rate Change")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Payment Date';

        }
        field(18088; "Rate Change Applicable"; Boolean)
        {
            Caption = 'Rate Change Applicable';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18089; "GST Reason Type"; enum "GST Reason Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Reason Type';

        }
        field(18090; "GST Input Service Distribution"; Boolean)
        {
            Caption = 'GST Input Service Distribution';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18091; "RCM Exempt"; Boolean)
        {
            Caption = 'RCM Exempt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18092; "GST Order Address State"; Code[10])
        {
            Caption = 'GST Order Address State';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18093; "Vendor GST Reg. No."; Code[20])
        {
            Caption = 'Vendor GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18094; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = State;
        }
        field(18095; "Location GST Reg. No."; Code[20])
        {
            Caption = 'Location GST Reg. No.';
            TableRelation = "GST Registration Nos.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18096; "Order Address GST Reg. No."; Code[20])
        {
            Caption = 'Order Address GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(18097; "Bill to-Location(POS)"; Code[10])
        {
            Caption = 'Bill to-Location(POS)';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18098; "Vehicle No."; Code[20])
        {
            Caption = 'Vehicle No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18099; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18100; "Shipping Agent Service Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code;
        }
        field(18101; "Distance (Km)"; Decimal)
        {
            Caption = 'Distance (Km)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18102; "Vehicle Type"; Enum "GST Vehicle Type")
        {
            Caption = 'Vehicle Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18103; "Reference Invoice No."; Code[20])
        {
            Caption = 'Reference Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18104; "Without Bill Of Entry"; Boolean)
        {
            Caption = 'Without Bill Of Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18105; "E-Way Bill No."; Text[50])
        {
            Caption = 'E-Way Bill No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18106; "POS as Vendor State"; Boolean)
        {
            Caption = 'POS as Vendor State';
            DataClassification = EndUserIdentifiableInformation;


        }
        field(18107; "POS Out Of India"; Boolean)
        {
            Caption = 'POS Out Of India';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18108; "Bill of Entry No."; text[20])
        {
            Caption = 'Bill of Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18109; "Bill of Entry Date"; date)
        {
            caption = 'Bill of Entry Date';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(18110; "GST Invoice"; Boolean)
        {
            Caption = 'GST Invoice';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18111; "Bill of Entry Value"; Decimal)
        {
            Caption = 'Bill of Entry Value';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(18112; "Trading"; Boolean)
        {
            Caption = 'Trading';
            DataClassification = EndUserIdentifiableInformation;
        }

    }
}