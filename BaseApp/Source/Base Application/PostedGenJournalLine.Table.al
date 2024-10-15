table 181 "Posted Gen. Journal Line"
{
    Caption = 'Posted Gen. Journal Line';
    LookupPageId = "Posted General Journal";
    DrillDownPageId = "Posted General Journal";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            AutoIncrement = true;
        }
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                          Blocked = CONST(false))
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Account Type" = CONST("IC Partner")) "IC Partner";
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(11; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                               Blocked = CONST(false))
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Bal. Account Type" = CONST("IC Partner")) "IC Partner";
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        field(18; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(22; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor;
        }
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Posting Group"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(30; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(38; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(40; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(43; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(45; "VAT Posting"; Option)
        {
            Caption = 'VAT Posting';
            Editable = false;
            OptionCaption = 'Automatic VAT Entry,Manual VAT Entry';
            OptionMembers = "Automatic VAT Entry","Manual VAT Entry";
        }
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Posted Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Recurring Method"; Enum "Gen. Journal Recurring Method")
        {
            BlankZero = true;
            Caption = 'Recurring Method';
        }
        field(54; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(55; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(57; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(60; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(61; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(62; "Allow Application"; Boolean)
        {
            Caption = 'Allow Application';
            InitValue = true;
        }
        field(63; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(64; "Bal. Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Bal. Gen. Posting Type';
        }
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
        field(68; "Bal. VAT %"; Decimal)
        {
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';
        }
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Payment Type';
        }
        field(71; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(72; "Bal. VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';
        }
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(74; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(75; "Check Printed"; Boolean)
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check Printed';
            Editable = false;
        }
        field(76; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(78; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        field(79; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Source Type" = CONST(Employee)) Employee;
        }
        field(80; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(82; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';
        }
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';
        }
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(92; "Bal. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(93; "Bal. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(95; "Additional-Currency Posting"; Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        field(98; "FA Add.-Currency Factor"; Decimal)
        {
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(99; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(100; "Source Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        field(101; "Source Curr. VAT Base Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        field(102; "Source Curr. VAT Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        field(103; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(104; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(105; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(106; "Bal. VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        field(107; "Bal. VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount (LCY)';
            Editable = false;
        }
        field(108; "Reversing Entry"; Boolean)
        {
            Caption = 'Reversing Entry';
            Editable = false;
        }
        field(109; "Allow Zero-Amount Posting"; Boolean)
        {
            Caption = 'Allow Zero-Amount Posting';
            Editable = false;
        }
        field(110; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Ship-to Address".Code WHERE("Customer No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Order Address".Code WHERE("Vendor No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) "Ship-to Address".Code WHERE("Customer No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Order Address".Code WHERE("Vendor No." = FIELD("Bill-to/Pay-to No."));
        }
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
        }
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(114; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";
        }
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
        }
        field(118; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor;
        }
        field(119; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(120; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(121; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(122; "Financial Void"; Boolean)
        {
            Caption = 'Financial Void';
            Editable = false;
        }
        field(123; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            Editable = false;
            InitValue = true;
        }
        field(125; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            Editable = false;
        }
        field(126; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            Editable = false;
        }
        field(127; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
            Editable = false;
        }
        field(160; "Job Queue Status"; Option)
        {
            Caption = 'Job Queue Status';
            Editable = false;
            OptionCaption = ' ,Scheduled for Posting,Error,Posting';
            OptionMembers = " ","Scheduled for Posting",Error,Posting;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            Numeric = true;
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Bal. Account No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Bal. Account No."));
        }
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(1002; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            Caption = 'Job Unit Price (LCY)';
            Editable = false;
        }
        field(1003; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Total Price (LCY)';
            Editable = false;
        }
        field(1004; "Job Quantity"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(1005; "Job Unit Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            Caption = 'Job Unit Cost (LCY)';
            Editable = false;
        }
        field(1006; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Line Discount %';
        }
        field(1007; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Line Disc. Amount (LCY)';
            Editable = false;
        }
        field(1008; "Job Unit Of Measure Code"; Code[10])
        {
            Caption = 'Job Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(1009; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Line Type';
        }
        field(1010; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Price';
        }
        field(1011; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Price';
            Editable = false;
        }
        field(1012; "Job Unit Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Cost';
            Editable = false;
        }
        field(1013; "Job Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Cost';
            Editable = false;
        }
        field(1014; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Discount Amount';
        }
        field(1015; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Amount';
        }
        field(1016; "Job Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Total Cost (LCY)';
            Editable = false;
        }
        field(1017; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Line Amount (LCY)';
            Editable = false;
        }
        field(1018; "Job Currency Factor"; Decimal)
        {
            Caption = 'Job Currency Factor';
        }
        field(1019; "Job Currency Code"; Code[10])
        {
            Caption = 'Job Currency Code';
        }
        field(1020; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Planning Line No.';
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Remaining Qty.';
            DecimalPlaces = 0 : 5;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = IF ("Account Type" = CONST(Customer)) "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Account No."));
        }
        field(1220; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(1221; "Payer Information"; Text[50])
        {
            Caption = 'Payer Information';
        }
        field(1222; "Transaction Information"; Text[100])
        {
            Caption = 'Transaction Information';
        }
        field(1223; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(1224; "Applied Automatically"; Boolean)
        {
            Caption = 'Applied Automatically';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Gen. Journal Line FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5604; "No. of Depreciation Days"; Integer)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';
        }
        field(5614; "FA Reclassification Entry"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Reclassification Entry';
        }
        field(5615; "FA Error Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(5617; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        field(5701; "Check Exported"; Boolean)
        {
            Caption = 'Check Exported';
        }
        field(5702; "Check Transmitted"; Boolean)
        {
            Caption = 'Check Transmitted';
        }
        field(8001; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".SystemId;
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;
        }
        field(8003; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';
            TableRelation = "Sales Invoice Header".SystemId;
        }
        field(8004; "Contact Graph Id"; Text[250])
        {
            Caption = 'Contact Graph Id';
        }
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8006; "Journal Batch Id"; Guid)
        {
            Caption = 'Journal Batch Id';
            TableRelation = "Gen. Journal Batch".SystemId;
        }
        field(8007; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".SystemId;
        }
        field(8010; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            TableRelation = "G/L Register";
        }
        field(8011; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(12400; "Initial Entry No."; Integer)
        {
            Caption = 'Initial Entry No.';
        }
        field(12401; "Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Beneficiary Bank Code';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST("G/L Account")) "Bank Account Details".Code WHERE("G/L Account" = FIELD("Account No."));
        }
        field(12402; "Payment Purpose"; Text[250])
        {
            Caption = 'Payment Purpose';
        }
        field(12403; "Cash Order Including"; Text[250])
        {
            Caption = 'Cash Order Including';
        }
        field(12404; "Cash Order Supplement"; Text[100])
        {
            Caption = 'Cash Order Supplement';
        }
        field(12405; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionCaption = ' ,Mail,Telegraph,Through Moscow,Clearing,Electronic';
            OptionMembers = " ",Mail,Telegraph,"Through Moscow",Clearing,Electronic;
        }
        field(12406; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(12407; "Payment Subsequence"; Text[2])
        {
            Caption = 'Payment Subsequence';
        }
        field(12408; "Payment Code"; Text[20])
        {
            Caption = 'Payment Code';
        }
        field(12409; "Payment Assignment"; Text[15])
        {
            Caption = 'Payment Assignment';
        }
        field(12410; "Payment Type"; Text[5])
        {
            Caption = 'Payment Type';
        }
        field(12411; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount (LCY)';
        }
        field(12412; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount (LCY)';
        }
        field(12413; "Prepmt. Diff."; Boolean)
        {
            Caption = 'Prepmt. Diff.';
            Editable = false;
        }
        field(12417; "VAT Transaction No."; Integer)
        {
            Caption = 'VAT Transaction No.';
        }
        field(12418; "VAT Settlement Part"; Option)
        {
            Caption = 'VAT Settlement Part';
            Editable = false;
            OptionCaption = ' ,,,,,,,Custom';
            OptionMembers = " ",,,,,,,Custom;
        }
        field(12419; "Unrealized VAT Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Unrealized VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No.";
        }
        field(12420; "Paid Amount"; Decimal)
        {
            Caption = 'Paid Amount';
            Editable = false;
        }
        field(12421; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(12422; "Initial VAT Entry No."; Integer)
        {
            Caption = 'Initial VAT Entry No.';
            TableRelation = IF ("Account Type" = CONST(Vendor)) "VAT Entry"."Entry No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                             "Document No." = FIELD("Document No."),
                                                                                             Type = CONST(Purchase),
                                                                                             "Unrealized VAT Entry No." = FILTER(<> 0),
                                                                                             "Bill-to/Pay-to No." = FIELD("Account No."),
                                                                                             "Prepmt. Diff." = CONST(false))
            ELSE
            IF ("Account Type" = CONST(Customer)) "VAT Entry"."Entry No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                                                                                                     "Document No." = FIELD("Document No."),
                                                                                                                                                                     Type = CONST(Sale),
                                                                                                                                                                     "Bill-to/Pay-to No." = FIELD("Account No."),
                                                                                                                                                                     "Unrealized VAT Entry No." = FILTER(<> 0),
                                                                                                                                                                     "Prepmt. Diff." = CONST(false));
        }
        field(12423; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;
        }
        field(12424; "Object No."; Code[20])
        {
            Caption = 'Object No.';
            TableRelation = IF ("Object Type" = CONST(Customer)) Customer
            ELSE
            IF ("Object Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Object Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Object Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Object Type" = CONST("G/L Account")) "G/L Account";
        }
        field(12425; "Prepayment Document No."; Code[20])
        {
            Caption = 'Prepayment Document No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Sales Header"."No." WHERE("Document Type" = FILTER(Order | Invoice),
                                                                                            "Bill-to Customer No." = FIELD("Account No."),
                                                                                            "Agreement No." = FIELD("Agreement No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Purchase Header"."No." WHERE("Document Type" = FILTER(Order | Invoice),
                                                                                                                                                                  "Buy-from Vendor No." = FIELD("Account No."),
                                                                                                                                                                  "Agreement No." = FIELD("Agreement No."));
        }
        field(12426; "Prepayment Status"; Option)
        {
            Caption = 'Prepayment Status';
            OptionCaption = ' ,Set,Reset';
            OptionMembers = " ",Set,Reset;
        }
        field(12427; "Advance VAT Base Amount"; Decimal)
        {
            Caption = 'Advance VAT Base Amount';
        }
        field(12428; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(12429; "Prepmt. Diff. Appln. Entry No."; Integer)
        {
            Caption = 'Prepmt. Diff. Appln. Entry No.';
            Editable = false;
        }
        field(12430; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(12431; "Corrective Doc. Type"; Option)
        {
            Caption = 'Corrective Doc. Type';
            OptionCaption = ' ,Correction,Revision';
            OptionMembers = " ",Correction,Revision;
        }
        field(12434; "Initial Document No."; Code[20])
        {
            Caption = 'Initial Document No.';
            TableRelation = IF ("Account Type" = CONST(Vendor),
                                "Document Type" = FILTER(Payment | Refund)) "Purch. Inv. Header" WHERE("Buy-from Vendor No." = FIELD("Account No."));
        }
        field(12435; "Vendor VAT Invoice No."; Code[30])
        {
            Caption = 'Vendor VAT Invoice No.';
        }
        field(12436; "Vendor VAT Invoice Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Date';
        }
        field(12437; "Vendor VAT Invoice Rcvd Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Rcvd Date';
        }
        field(12445; "VAT Entry Type"; Code[15])
        {
            Caption = 'VAT Entry Type';
        }
        field(12470; "Vendor Receipts No."; Code[20])
        {
            Caption = 'Vendor Receipts No.';
        }
        field(12471; "Vendor Receipts Date"; Date)
        {
            Caption = 'Vendor Receipts Date';
        }
        field(12472; "Applies-to Doc. Date"; Date)
        {
            Caption = 'Applies-to Doc. Date';
        }
        field(12476; "FA Charge No."; Code[20])
        {
            Caption = 'FA Charge No.';
            Editable = false;
            TableRelation = "FA Charge";
        }
        field(12480; KBK; Code[20])
        {
            Caption = 'KBK';
            TableRelation = KBK;
        }
        field(12481; OKATO; Code[11])
        {
            Caption = 'OKATO';
            TableRelation = OKATO;
        }
        field(12482; "Period Code"; Option)
        {
            Caption = 'Period Code';
            OptionCaption = ' ,0,D1-payment for the first decade of month,D2-payment for the second decade of month,D3-payment for the third decade of month,MH-monthly payments,QT-quarter payment,HY-half-year payments,YR-year payments';
            OptionMembers = " ","0",D1,D2,D3,MH,QT,HY,YR;
        }
        field(12483; "Payment Reason Code"; Code[10])
        {
            Caption = 'Payment Reason Code';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Payment Reason"));
        }
        field(12484; "Reason Document No."; Code[10])
        {
            Caption = 'Reason Document No.';
        }
        field(12485; "Reason Document Date"; Date)
        {
            AutoFormatType = 2;
            Caption = 'Reason Document Date';
        }
        field(12486; "Tax Payment Type"; Code[10])
        {
            Caption = 'Tax Payment Type';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Tax Payment Type"));
        }
        field(12487; "Tax Period"; Code[10])
        {
            Caption = 'Tax Period';
        }
        field(12488; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            Editable = false;
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;
        }
        field(12489; "Taxpayer Status"; Option)
        {
            Caption = 'Taxpayer Status';
            OptionCaption = ' ,01-taxpayer (charges payer),02-tax agent,03-collector of taxes and charges,04-tax authority,05-service of officers of justice of Department of Justice of Russian Federation,06-participant of foreign-economic activity,07-tax authority,08-payer of other mandatory payments';
            OptionMembers = " ","01","02","03","04","05","06","07","08";
        }
        field(12490; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Agreement"."No." WHERE("Customer No." = FIELD("Account No."),
                                                                                                  Active = CONST(true))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Agreement"."No." WHERE("Vendor No." = FIELD("Account No."),
                                                                                                                                                                         Active = CONST(true));
        }
        field(12491; "Depr. Period Starting Date"; Date)
        {
            Caption = 'Depr. Period Starting Date';
            TableRelation = "Accounting Period";
        }
        field(12492; "Payer Vendor No."; Code[20])
        {
            Caption = 'Payer Vendor No.';
            TableRelation = Vendor;
        }
        field(12493; "Payer Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Payer Beneficiary Bank Code';
            TableRelation = "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Payer Vendor No."));
        }
        field(12497; "Include In Other VAT Ledger"; Boolean)
        {
            Caption = 'Include In Other VAT Ledger';
        }
        field(12498; "Additional VAT Ledger Sheet"; Boolean)
        {
            Caption = 'Additional VAT Ledger Sheet';
        }
        field(12499; "Corrected Document Date"; Date)
        {
            Caption = 'Corrected Document Date';
        }
        field(14900; "Export Status"; Option)
        {
            Caption = 'Export Status';
            Editable = false;
            OptionCaption = ' ,New,Exported,Bank Statement Found';
            OptionMembers = " ",New,Exported,"Bank Statement Found";
        }
        field(14901; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        field(14902; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(14903; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(14904; "Bank Acc. Details VAT Reg. No."; Text[20])
        {
            Caption = 'Bank Acc. Details VAT Reg. No.';
        }
        field(14905; "Bank Acc. Dtls. Bank Acc. No."; Code[30])
        {
            Caption = 'Bank Acc. Dtls. Bank Acc. No.';
        }
        field(14910; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Acc. Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(14911; "Acc. Schedule Line No."; Integer)
        {
            Caption = 'Acc. Schedule Line No.';
            TableRelation = "Acc. Schedule Line"."Line No." WHERE("Schedule Name" = FIELD("Acc. Schedule Name"));
        }
        field(14912; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(14913; "Column Layout Line No."; Integer)
        {
            Caption = 'Column Layout Line No.';
            TableRelation = "Column Layout"."Line No." WHERE("Column Layout Name" = FIELD("Column Layout Name"));
        }
        field(14926; "Unrealized Amount"; Decimal)
        {
            Caption = 'Unrealized Amount';
        }
        field(14927; "VAT Allocation Type"; Option)
        {
            Caption = 'VAT Allocation Type';
            OptionCaption = 'VAT,Write-Off,Charge';
            OptionMembers = VAT,WriteOff,Charge;
        }
        field(14929; "Reinstatement VAT Entry No."; Integer)
        {
            Caption = 'Reinstatement VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No." WHERE(Amount = FILTER(<> 0),
                                                           "VAT Allocation Type" = CONST(VAT),
                                                           Type = CONST(Purchase),
                                                           Reversed = CONST(false),
                                                           "Unrealized VAT Entry No." = FILTER(<> 0),
                                                           "VAT Reinstatement" = CONST(false));
        }
        field(17201; "Depr. Bonus"; Boolean)
        {
            Caption = 'Depr. Bonus';
        }
        field(17202; "Tax. Diff. Dtld. Entry No."; Integer)
        {
            Caption = 'Tax. Diff. Dtld. Entry No.';
        }
        field(17300; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            TableRelation = "Tax Difference" WHERE("Source Code Mandatory" = CONST(true),
                                                    "Depreciation Bonus" = CONST(false));
        }
        field(17301; "Depr. Group Elimination"; Boolean)
        {
            Caption = 'Depr. Group Elimination';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "G/L Register No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
        }
        fieldgroup(Brick; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
        }
    }

    procedure InsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; GLRegNo: Integer; FirstLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertFromGenJournalLine(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        Init();
        TransferFields(GenJournalLine);
        "Line No." := 0;
        "G/L Register No." := GLRegNo;
        if not FirstLine then
            Indentation := 1;
        Insert();

        OnAfterInsertFromGenJournalLine(GenJournalLine);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

