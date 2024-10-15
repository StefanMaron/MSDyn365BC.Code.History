table 31020 "Purch. Advance Letter Header"
{
    Caption = 'Purch. Advance Letter Header';
    DataCaptionFields = "No.", "Pay-to Name";
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';

    fields
    {
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            TableRelation = Vendor.Name;
            ValidateTableRelation = false;
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            TableRelation = if ("Pay-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Pay-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Pay-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            Editable = false;
            TableRelation = "Vendor Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(46; Comment; Boolean)
        {
            Caption = 'Comment';
            Editable = false;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount Including VAT" where("Letter No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(68; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            TableRelation = if ("Pay-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Pay-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Pay-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(86; "Pay-to County"; Text[30])
        {
            Caption = 'Pay-to County';
            CaptionClass = '5,6,' + "Pay-to Country/Region Code";
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(120; Status; Option)
        {
            CalcFormula = min("Purch. Advance Letter Line".Status where("Letter No." = field("No."),
                                                                         "Amount Including VAT" = filter(<> 0)));
            Caption = 'Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Pending Payment,Pending Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Payment","Pending Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(137; "Advance Due Date"; Date)
        {
            Caption = 'Advance Due Date';
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(11700; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
        field(11701; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
            Editable = false;
        }
        field(11702; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(11703; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
        }
        field(11704; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(11705; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
        }
        field(11706; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
            Editable = false;
        }
        field(11707; IBAN; Code[50])
        {
            Caption = 'IBAN';
            Editable = false;
        }
        field(11708; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            Editable = false;
        }
        field(11709; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(11710; "Amount on Payment Order (LCY)"; Decimal)
        {
            CalcFormula = sum("Issued Payment Order Line"."Amount (LCY)" where("Letter Type" = const(Purchase),
                                                                                "Letter No." = field("No."),
                                                                                Status = const(" ")));
            Caption = 'Amount on Payment Order (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11760; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(11761; "VAT Currency Factor"; Decimal)
        {
            Caption = 'VAT Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(11790; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(11791; "Tax Registration No."; Text[20])
        {
            Caption = 'Tax Registration No.';
        }
        field(31008; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(31009; "Semifinished Linked Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Semifinished Linked Amount';
        }
        field(31010; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
        }
        field(31012; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            Editable = false;
        }
        field(31013; "Amount To Link"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount To Link" where("Letter No." = field("No.")));
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31014; "Amount To Invoice"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount To Invoice" where("Letter No." = field("No.")));
            Caption = 'Amount To Invoice';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31015; "Amount To Deduct"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount To Deduct" where("Letter No." = field("No.")));
            Caption = 'Amount To Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31016; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation".Amount where(Type = const(Purchase),
                                                                           "Letter No." = field("No."),
                                                                           "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31017; "Doc. No. Filter"; Code[20])
        {
            Caption = 'Doc. No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Purchase Header"."No.";
        }
        field(31018; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Invoiced Amount" where(Type = const(Purchase),
                                                                                      "Letter No." = field("No."),
                                                                                      "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Inv. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31019; "Document Linked Ded. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Deducted Amount" where(Type = const(Purchase),
                                                                                      "Letter No." = field("No."),
                                                                                      "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31020; "Amount Linked"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount Linked" where("Letter No." = field("No.")));
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31021; "Amount Invoiced"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount Invoiced" where("Letter No." = field("No.")));
            Caption = 'Amount Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Amount Deducted"; Decimal)
        {
            CalcFormula = sum("Purch. Advance Letter Line"."Amount Deducted" where("Letter No." = field("No.")));
            Caption = 'Amount Deducted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31023; "Vendor Adv. Payment No."; Code[20])
        {
            Caption = 'Vendor Adv. Payment No.';
        }
        field(31024; "Due Date from Line"; Boolean)
        {
            Caption = 'Due Date from Line';
        }
        field(31025; "Post Advance VAT Option"; Option)
        {
            Caption = 'Post Advance VAT Option';
            InitValue = Always;
            OptionCaption = ' ,Never,Optional,Always';
            OptionMembers = " ",Never,Optional,Always;
        }
        field(31060; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries hase been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31061; "Perf. Country Currency Factor"; Decimal)
        {
            Caption = 'Perf. Country Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries hase been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31100; "Original Document VAT Date"; Date)
        {
            Caption = 'Original Document VAT Date';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Template Code")
        {
        }
        key(Key3; "Pay-to Vendor No.", "Currency Code", Closed)
        {
        }
        key(Key4; "Order No.")
        {
        }
    }

    fieldgroups
    {
    }
}