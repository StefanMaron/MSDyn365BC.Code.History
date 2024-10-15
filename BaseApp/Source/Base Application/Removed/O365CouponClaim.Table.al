table 2115 "O365 Coupon Claim"
{
    Caption = 'O365 Coupon Claim';
    Permissions = TableData "O365 Posted Coupon Claim" = imd;
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
            OptionCaption = 'Custom,%,Amount';
            OptionMembers = Custom,"%",Amount;
        }
        field(10; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
        field(11; "Is Valid"; Boolean)
        {
            Caption = 'Is Valid';
        }
        field(12; "Status Text"; Text[50])
        {
            Caption = 'Status';
        }
        field(13; "Amount Text"; Text[30])
        {
            Caption = 'Discount';
        }
        field(14; "Is applied"; Boolean)
        {
#pragma warning disable AL0603
            CalcFormula = exist("O365 Coupon Claim Doc. Link" where("Claim ID" = field("Claim ID"),
                                                                     "Document Type" = field("Document Type Filter"),
                                                                     "Document No." = field("Document No. Filter"),
                                                                     "Graph Contact ID" = field("Graph Contact ID")));
#pragma warning restore AL0603
            Caption = 'Is applied';
            FieldClass = FlowField;
        }
        field(15; "Document Type Filter"; Option)
        {
            Caption = 'Document Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
            TableRelation = "Sales Header"."Document Type";
        }
        field(16; "Document No. Filter"; Code[20])
        {
            Caption = 'Document No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Header"."No.";
        }
        field(17; "Offer Blob"; BLOB)
        {
            Caption = 'Offer Blob';
        }
        field(18; "Terms Blob"; BLOB)
        {
            Caption = 'Terms Blob';
        }
        field(8001; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;
        }
    }

    keys
    {
        key(Key1; "Claim ID", "Graph Contact ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Status Text", "Code", "Amount Text", Offer)
        {
        }
    }
}

