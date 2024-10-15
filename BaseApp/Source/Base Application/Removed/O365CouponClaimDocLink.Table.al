table 2116 "O365 Coupon Claim Doc. Link"
{
    Caption = 'O365 Coupon Claim Doc. Link';
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
            TableRelation = "O365 Coupon Claim"."Claim ID";
        }
        field(2; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            TableRelation = "Sales Header"."Document Type";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header"."No." where("Document Type" = field("Document Type"));
        }
        field(4; "Graph Contact ID"; Text[250])
        {
            Caption = 'Graph Contact ID';
        }
    }

    keys
    {
        key(Key1; "Claim ID", "Graph Contact ID", "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

