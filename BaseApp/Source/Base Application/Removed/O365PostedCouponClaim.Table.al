table 2117 "O365 Posted Coupon Claim"
{
    Caption = 'O365 Posted Coupon Claim';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Claim ID"; Text[150])
        {
            Caption = 'Claim ID';
        }
        field(2; "Graph Contact ID"; Text[250])
        {
            Caption = 'Graph Contact ID';
        }
        field(3; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'oneTime,multiUse';
            OptionMembers = oneTime,multiUse;
        }
        field(4; Offer; Text[250])
        {
            Caption = 'Offer';
        }
        field(5; Terms; Text[250])
        {
            Caption = 'Terms';
        }
        field(6; "Code"; Text[30])
        {
            Caption = 'Code';
        }
        field(7; Expiration; Date)
        {
            Caption = 'Expiration';
        }
        field(8; "Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Value';
        }
        field(9; "Discount Type"; Option)
        {
            Caption = 'Discount Type';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(10; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
        field(13; "Amount Text"; Text[30])
        {
            Caption = 'Discount';
        }
        field(17; "Offer Blob"; BLOB)
        {
            Caption = 'Offer Blob';
        }
        field(18; "Terms Blob"; BLOB)
        {
            Caption = 'Terms Blob';
        }
        field(19; "Sales Invoice No."; Code[20])
        {
            Caption = 'Sales Invoice No.';
            TableRelation = "Sales Invoice Header"."No.";
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;
        }
    }

    keys
    {
        key(Key1; "Claim ID", "Sales Invoice No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

