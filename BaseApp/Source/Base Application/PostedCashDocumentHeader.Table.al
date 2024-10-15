table 11735 "Posted Cash Document Header"
{
    Caption = 'Posted Cash Document Header';
    DataCaptionFields = "Cash Desk No.", "Cash Document Type", "No.", "Pay-to/Receive-from Name";
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Pay-to/Receive-from Name"; Text[100])
        {
            Caption = 'Pay-to/Receive-from Name';
        }
        field(4; "Pay-to/Receive-from Name 2"; Text[50])
        {
            Caption = 'Pay-to/Receive-from Name 2';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7; Amount; Decimal)
        {
            CalcFormula = sum("Posted Cash Document Line".Amount where("Cash Desk No." = field("Cash Desk No."),
                                                                        "Cash Document No." = field("No.")));
            Caption = 'Amount';
            FieldClass = FlowField;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Posted Cash Document Line"."Amount (LCY)" where("Cash Desk No." = field("Cash Desk No."),
                                                                                "Cash Document No." = field("No.")));
            Caption = 'Amount (LCY)';
            FieldClass = FlowField;
        }
        field(13; "Cash Desk Report No."; Code[20])
        {
            Caption = 'Cash Desk Report No.';
        }
        field(15; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(17; "Created ID"; Code[50])
        {
            Caption = 'Created ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(18; "Released ID"; Code[50])
        {
            Caption = 'Released ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(19; "Posted ID"; Code[50])
        {
            Caption = 'Posted ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(20; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(35; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(38; "Created Date"; Date)
        {
            Caption = 'Created Date';
        }
        field(40; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(45; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
        }
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cash Document Line"."VAT Base Amount" where("Cash Desk No." = field("Cash Desk No."),
                                                                                   "Cash Document No." = field("No.")));
            Caption = 'VAT Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cash Document Line"."Amount Including VAT" where("Cash Desk No." = field("Cash Desk No."),
                                                                                        "Cash Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Posted Cash Document Line"."VAT Base Amount (LCY)" where("Cash Desk No." = field("Cash Desk No."),
                                                                                         "Cash Document No." = field("No.")));
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            CalcFormula = sum("Posted Cash Document Line"."Amount Including VAT (LCY)" where("Cash Desk No." = field("Cash Desk No."),
                                                                                              "Cash Document No." = field("No.")));
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(62; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(65; "Payment Purpose"; Text[100])
        {
            Caption = 'Payment Purpose';
        }
        field(70; "Received By"; Text[80])
        {
            Caption = 'Received By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Identification Card No."; Code[10])
        {
            Caption = 'Identification Card No.';
        }
        field(72; "Paid By"; Text[100])
        {
            Caption = 'Paid By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(73; "Received From"; Text[100])
        {
            Caption = 'Received From';
        }
        field(74; "Paid To"; Text[100])
        {
            Caption = 'Paid To';
        }
        field(80; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(81; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(90; "Partner Type"; Option)
        {
            Caption = 'Partner Type';
            OptionCaption = ' ,Customer,Vendor,Contact,Salesperson/Purchaser,Employee';
            OptionMembers = " ",Customer,Vendor,Contact,"Salesperson/Purchaser",Employee;
        }
        field(91; "Partner No."; Code[20])
        {
            Caption = 'Partner No.';
            TableRelation = if ("Partner Type" = const(Customer)) Customer
            else
            if ("Partner Type" = const(Vendor)) Vendor
            else
            if ("Partner Type" = const(Contact)) Contact
            else
            if ("Partner Type" = const("Salesperson/Purchaser")) "Salesperson/Purchaser"
            else
            if ("Partner Type" = const(Employee)) Employee;
        }
        field(98; "Canceled Document"; Boolean)
        {
            Caption = 'Canceled Document';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(31123; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Desk No.", "Cash Document Type", "No.")
        {
        }
        key(Key3; "Cash Desk No.", "Posting Date")
        {
        }
        key(Key4; "External Document No.")
        {
        }
        key(Key5; "No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}