table 31000 "Sales Advance Letter Header"
{
    Caption = 'Sales Advance Letter Header';
    DataCaptionFields = "No.", "Bill-to Name";
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    DataClassification = CustomerContent;

    fields
    {
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
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
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
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
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
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
            CalcFormula = sum("Sales Advance Letter Line"."Amount Including VAT" where("Letter No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
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
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            Caption = 'Bill-to County';
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
            CalcFormula = min("Sales Advance Letter Line".Status where("Letter No." = field("No."),
                                                                        "Amount Including VAT" = filter(<> 0)));
            Caption = 'Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Pending Payment,Pending Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Payment","Pending Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(133; "Advance Due Date"; Date)
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
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Templ.";
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(11700; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Bank Account";
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
        field(11760; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
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
            CalcFormula = sum("Sales Advance Letter Line"."Amount To Link" where("Letter No." = field("No.")));
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31014; "Amount To Invoice"; Decimal)
        {
            CalcFormula = sum("Sales Advance Letter Line"."Amount To Invoice" where("Letter No." = field("No.")));
            Caption = 'Amount To Invoice';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31015; "Amount To Deduct"; Decimal)
        {
            CalcFormula = sum("Sales Advance Letter Line"."Amount To Deduct" where("Letter No." = field("No.")));
            Caption = 'Amount To Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31016; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation".Amount where(Type = const(Sale),
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
            TableRelation = "Sales Header"."No.";
        }
        field(31018; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Advance Letter Line Relation"."Invoiced Amount" where(Type = const(Sale),
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
            CalcFormula = sum("Advance Letter Line Relation"."Deducted Amount" where(Type = const(Sale),
                                                                                      "Letter No." = field("No."),
                                                                                      "Document No." = field("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31020; "Amount Linked"; Decimal)
        {
            CalcFormula = sum("Sales Advance Letter Line"."Amount Linked" where("Letter No." = field("No.")));
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31021; "Amount Invoiced"; Decimal)
        {
            CalcFormula = sum("Sales Advance Letter Line"."Amount Invoiced" where("Letter No." = field("No.")));
            Caption = 'Amount Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Amount Deducted"; Decimal)
        {
            CalcFormula = sum("Sales Advance Letter Line"."Amount Deducted" where("Letter No." = field("No.")));
            Caption = 'Amount Deducted';
            Editable = false;
            FieldClass = FlowField;
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
        key(Key3; "Bill-to Customer No.", "Currency Code", Closed)
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