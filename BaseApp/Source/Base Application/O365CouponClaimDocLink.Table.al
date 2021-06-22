table 2116 "O365 Coupon Claim Doc. Link"
{
    Caption = 'O365 Coupon Claim Doc. Link';
    ReplicateData = false;

    fields
    {
        field(1; "Claim ID"; Text[150])
        {
            Caption = 'Claim ID';
            TableRelation = "O365 Coupon Claim"."Claim ID";
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
            TableRelation = "Sales Header"."Document Type";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"));
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

