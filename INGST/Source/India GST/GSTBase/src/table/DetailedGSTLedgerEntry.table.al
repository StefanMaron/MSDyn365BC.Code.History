table 18001 "Detailed GST Ledger Entry"
{
    Caption = 'Detailed GST Ledger Entry';
    LookupPageId = "Detailed GST Ledger Entry";
    DrillDownPageId = "Detailed GST Ledger Entry";
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = EndUserIdentifiableInformation;
            AutoIncrement = true;
        }
        field(2; "Entry Type"; Enum "Detail Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Transaction Type"; Enum "Detail Ledger Transaction Type")
        {
            Caption = 'Transaction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Document Type"; Enum "GST Document Type")
        {
            Caption = 'Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Type; enum Type)
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge";
        }
        field(10; "Product Type"; enum "Product Type")
        {
            Caption = 'Product Type';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(11; "Source Type"; enum "Source Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor;
        }
        field(13; "HSN/SAC Code"; Code[10])
        {
            Caption = 'HSN/SAC Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "HSN/SAC".Code WHERE("GST Group Code" = FIELD("GST Group Code"));
        }
        field(14; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(15; "GST Group Code"; Code[20])
        {
            Caption = 'GST Group Code';
            TableRelation = "GST Group";
            DataClassification = EndUserIdentifiableInformation;

        }
        field(16; "GST Jurisdiction Type"; enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(18; "GST %"; Decimal)
        {
            Caption = 'GST %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(20; "External Document No."; Code[40])
        {
            Caption = 'External Document No.';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(22; "Amount Loaded on Item"; Decimal)
        {
            Caption = 'Amount Loaded on Item';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(25; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "GST Without Payment of Duty"; Boolean)
        {
            Caption = 'GST Without Payment of Duty';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(30; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Reversed by Entry No."; Integer)
        {
            Caption = 'Reversed by Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(33; Reversed; Boolean)
        {
            Caption = 'Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(38; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(42; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "Item Charge Entry"; Boolean)
        {
            Caption = 'Item Charge Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; "Reverse Charge"; Boolean)
        {
            Caption = 'Reverse Charge';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "GST on Advance Payment"; Boolean)
        {
            Caption = 'GST on Advance Payment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(46; "Nature of Supply"; Enum "GST Nature of Supply")
        {
            Caption = 'Nature of Supply';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(48; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(52; "GST Exempted Goods"; Boolean)
        {
            Caption = 'GST Exempted Goods';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(53; "Location State Code"; Code[10])
        {
            Caption = 'Location State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(54; "Buyer/Seller State Code"; Code[10])
        {
            Caption = 'Buyer/Seller State Code';
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(55; "Shipping Address State Code"; Code[10])
        {
            Caption = 'Shipping Address State Code';
            TableRelation = State;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(56; "Location  Reg. No."; Code[20])
        {
            Caption = 'Location  Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57; "Buyer/Seller Reg. No."; Code[20])
        {
            Caption = 'Buyer/Seller Reg. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(58; "GST Group Type"; enum "GST Group Type")
        {
            Caption = 'GST Group Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(59; "GST Credit"; enum "Detail GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(61; "Reversal Entry"; Boolean)
        {
            Caption = 'Reversal Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(62; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(63; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(64; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 1 : 6;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(65; "Application Doc. Type"; Enum "Application Doc Type")
        {
            Caption = 'Application Doc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(66; "Application Doc. No"; Code[20])
        {
            Caption = 'Application Doc. No';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(67; "Original Doc. Type"; enum "Original Doc Type")
        {
            Caption = 'Original Doc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(68; "Original Doc. No."; Code[20])
        {
            Caption = 'Original Doc. No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(69; "Applied From Entry No."; Integer)
        {
            Caption = 'Applied From Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(70; "Reversed Entry No."; Integer)
        {
            Caption = 'Reversed Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Remaining Closed"; Boolean)
        {
            Caption = 'Remaining Closed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(72; "GST Rounding Precision"; Decimal)
        {
            Caption = 'GST Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(73; "GST Rounding Type"; Enum "GST Inv Rounding Type")
        {
            Caption = 'GST Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(74; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(75; "GST Customer Type"; Enum "GST Customer Type")
        {
            Caption = 'GST Customer Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(76; "GST Vendor Type"; Enum "GST Vendor Type")
        {
            Caption = 'GST Vendor Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(77; "CLE/VLE Entry No."; Integer)
        {
            Caption = 'CLE/VLE Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(78; "Bill Of Export No."; Code[20])
        {
            Caption = 'Bill Of Export No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(79; "Bill Of Export Date"; Date)
        {
            Caption = 'Bill Of Export Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(80; "e-Comm. Merchant Id"; Code[30])
        {
            Caption = 'e-Comm. Merchant Id';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(81; "e-Comm. Operator GST Reg. No."; Code[20])
        {
            Caption = 'e-Comm. Operator GST Reg. No.';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(82; "Sales Invoice Type"; Enum "Sales Invoice Type")
        {
            Caption = 'Sales Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(83; "Original Invoice No."; Code[20])
        {
            Caption = 'Original Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(84; "Original Invoice Date"; Date)
        {
            Caption = 'Original Invoice Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(85; "Reconciliation Month"; Integer)
        {
            Caption = 'Reconciliation Month';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(86; "Reconciliation Year"; Integer)
        {
            Caption = 'Reconciliation Year';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(87; Reconciled; Boolean)
        {
            Caption = 'Reconciled';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(88; "Credit Availed"; Boolean)
        {
            Caption = 'Credit Availed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(89; Paid; Boolean)
        {
            Caption = 'Paid';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(90; "Amount to Customer/Vendor"; Decimal)
        {
            Caption = 'Amount to Customer/Vendor';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(91; "Credit Adjustment Type"; Enum "Credit Adjustment Type")
        {
            Caption = 'Credit Adjustment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(92; "Adv. Pmt. Adjustment"; Boolean)
        {
            Caption = 'Adv. Pmt. Adjustment';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(93; "Original Adv. Pmt Doc. No."; Code[20])
        {
            Caption = 'Original Adv. Pmt Doc. No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(94; "Original Adv. Pmt Doc. Date"; Date)
        {
            Caption = 'Original Adv. Pmt Doc. Date';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(96; "Payment Document Date"; Date)
        {
            Caption = 'Payment Document Date';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(97; Cess; Boolean)
        {
            Caption = 'Cess';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(98; UnApplied; Boolean)
        {
            Caption = 'UnApplied';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(99; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry" WHERE("Entry No." = FIELD("Item Ledger Entry No."));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(100; "Credit Reversal"; Enum "Credit Reversal")
        {
            Caption = 'Credit Reversal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(101; "GST Place of Supply"; enum "GST Place Of Supply")
        {
            Caption = 'GST Place of Supply';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(102; "Item Charge Assgn. Line No."; Integer)
        {
            Caption = 'Item Charge Assgn. Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(103; "Payment Type"; Enum "Payment Type")
        {
            Caption = 'Payment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(104; Distributed; Boolean)
        {
            Caption = 'Distributed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(105; "Distributed Reversed"; Boolean)
        {
            Caption = 'Distributed Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(106; "Input Service Distribution"; Boolean)
        {
            Caption = 'Input Service Distribution';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(107; Opening; Boolean)
        {
            Caption = 'Opening';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(108; "Remaining Amount Closed"; Boolean)
        {
            Caption = 'Remaining Amount Closed';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(109; "Remaining Base Amount"; Decimal)
        {
            Caption = 'Remaining Base Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(110; "Remaining GST Amount"; Decimal)
        {
            Caption = 'Remaining GST Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(112; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(113; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(114; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Reason Code";
        }
        field(115; "Dist. Document No."; Code[20])
        {
            Caption = 'Dist. Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(116; "Associated Enterprises"; Boolean)
        {
            Caption = 'Associated Enterprises';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(117; "Delivery Challan Amount"; Decimal)
        {

            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Delivery Challan Amount';
        }
        field(118; "Liable to Pay"; Boolean)
        {
            Caption = 'Liable to Pay';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(119; "Subcon Document No."; Code[20])
        {
            Caption = 'Subcon Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(120; "Last Credit Adjusted Date"; Date)
        {
            Caption = 'Last Credit Adjusted Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(121; "Dist. Input GST Credit"; Boolean)
        {
            Caption = 'Dist. Input GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(122; "Component Calc. Type"; Enum "Component Calc Type")
        {
            Caption = 'Component Calc. Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(123; "Cess Amount Per Unit Factor"; Decimal)
        {
            Caption = 'Cess Amount Per Unit Factor';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(124; "Cess UOM"; Code[10])
        {
            Caption = 'Cess UOM';
            TableRelation = "Unit of Measure";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(125; "Cess Factor Quantity"; Decimal)
        {
            Caption = 'Cess Factor Quantity';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(126; "Dist. Reverse Document No."; Code[20])
        {
            Caption = 'Dist. Reverse Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(127; UOM; Code[10])
        {
            Caption = 'UOM';
            TableRelation = "Unit of Measure";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(128; "Purchase Invoice Type"; Enum "GST Invoice Type")
        {
            Caption = 'Purchase Invoice Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(129; "Bank Charge Entry"; Boolean)
        {
            Caption = 'Bank Charge Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(130; "Foreign Exchange"; Boolean)
        {
            Caption = 'Foreign Exchange';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(131; "Bill of Entry No."; Text[20])
        {
            Caption = 'Bill of Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(132; "Bill of Entry Date"; Date)
        {
            Caption = 'Bill of Entry Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(133; "Eligibility for ITC"; Enum "Eligibility for ITC")
        {
            Caption = 'Eligibility for ITC';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(134; "GST Assessable Value"; Decimal)
        {
            Caption = 'GST Assessable Value';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(135; "GST Reason Type"; Enum "GST Reason Type")
        {
            Caption = 'GST Reason Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(136; "GST Rate %"; Decimal)
        {
            Caption = 'GST Rate %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(137; "Jnl. Bank Charge"; Code[10])
        {
            Caption = 'Bank Charge';
            // TableRelation = "Bank Charge";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(138; "GST Inv. Rounding Precision"; Decimal)
        {
            Caption = 'GST Inv. Rounding Precision';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(139; "GST Inv. Rounding Type"; enum "GST Inv Rounding Type")
        {
            Caption = 'GST Inv. Rounding Type';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(140; "RCM Exempt"; Boolean)
        {
            Caption = 'RCM Exempt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(141; "RCM Exempt Transaction"; Boolean)
        {
            Caption = 'RCM Exempt Transaction';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(142; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(143; "Cr. & Libty. Adjustment Type"; Enum "Cr Libty Adjustment Type")
        {
            Caption = 'Cr. & Libty. Adjustment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(144; "AdjustmentBase Amount"; Decimal)
        {
            Caption = 'AdjustmentBase Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(145; "Adjustment Amount"; Decimal)
        {
            Caption = 'Adjustment Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(146; "Bill to-Location(POS)"; Code[10])
        {
            Caption = 'Bill to-Location(POS)';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(147; "Custom Duty Amount"; Decimal)
        {
            Caption = 'Custom Duty Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(148; "Journal Entry"; Boolean)
        {
            Caption = 'Journal Entry';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(149; "Recurring Journal"; Boolean)
        {
            Caption = 'Recurring Journal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(150; "Allocations Line No."; Integer)
        {
            Caption = 'Allocations Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(156; "GST Journal Type"; Enum "GST Journal Type")
        {
            Caption = 'GST Journal Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(157; "Adjustment Type"; Enum "Adjustment Type")
        {
            Caption = 'Adjustment Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(158; "Remaining Quantity"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Remaining Quantity';
        }
        field(159; "ARN No."; Code[20])
        {
            Caption = 'ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(160; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(161; "FA Journal Entry"; Boolean)
        {
            Caption = 'FA Journal Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(162; "Without Bill Of Entry"; Boolean)
        {
            Caption = 'Without Bill Of Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(163; "Finance Charge Memo"; Boolean)
        {
            Caption = 'Finance Charge Memo';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(164; "Forex Fluctuation"; Boolean)
        {
            Caption = 'Forex Fluctuation';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(165; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(166; "Fluctuation Amt. Credit"; Boolean)
        {
            Caption = 'Fluctuation Amt. Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(167; "CAJ %"; Decimal)
        {
            Caption = 'CAJ %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(168; "CAJ Amount"; Decimal)
        {
            Caption = 'CAJ Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(169; "CAJ % Permanent Reversal"; Decimal)
        {
            Caption = 'CAJ % Permanent Reversal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(170; "CAJ Amount Permanent Reversal"; Decimal)
        {
            Caption = 'CAJ Amount Permanent Reversal';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(171; "Location ARN No."; Code[20])
        {
            Caption = 'Location ARN No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(180; "Rate Change Applicable"; Boolean)
        {
            Caption = 'Rate Change Applicable';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(181; "Remaining CAJ Adj. Base Amt"; Decimal)
        {
            Caption = 'Remaining CAJ Adj. Base Amt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(182; "Remaining CAJ Adj. Amt"; Decimal)
        {
            Caption = 'Remaining CAJ Adj. Amt';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(183; "CAJ Base Amount"; Decimal)
        {
            Caption = 'CAJ Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(184; "POS as Vendor State"; Boolean)
        {
            Caption = 'POS as Vendor State';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(185; "GST Base Amount FCY"; Decimal)
        {
            Caption = 'GST Base Amount FCY';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(186; "GST Amount FCY"; Decimal)
        {
            Caption = 'GST Amount FCY';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(187; "POS Out Of India"; Boolean)
        {
            Caption = 'POS Out Of India';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(188; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = False;
        }
        field(189; "Skip Tax Engine Trigger"; Boolean)
        {
            Caption = 'Skip Tax Engine Trigger';
            DataClassification = EndUserIdentifiableInformation;
            Editable = False;
        }


    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction No.")
        {
        }
        key(Key3; "Transaction Type", "Location  Reg. No.", "Document Type", Reconciled, "GST Vendor Type", Reversed, "Posting Date", Paid, "Credit Adjustment Type")
        {
        }
        key(Key4; "Location  Reg. No.", "Transaction Type", "Entry Type", "GST Vendor Type", "GST Credit", "Reconciliation Month", "Reconciliation Year")
        {
        }
        key(Key5; "Document No.", "Document Line No.", "GST Component Code")
        {
        }
        key(Key6; "Transaction Type", "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key7; "Payment Document No.")
        {
        }
        key(Key8; "Transaction Type", "Document No.", "Entry Type", "HSN/SAC Code", Cess, "Document Line No.")
        {
        }
        key(Key9; "Transaction Type", "Document Type", "Document No.", "Transaction No.")
        {
        }
        key(Key10; "CLE/VLE Entry No.", "GST Group Code")
        {
        }
        key(Key11; "Document No.", "HSN/SAC Code")
        {
            SumIndexFields = "GST Base Amount", "GST Amount";
        }
        key(Key12; "Transaction Type", "Source No.", "Original Doc. Type", "Original Doc. No.", "GST Group Code")
        {
        }
        key(Key13; "Transaction Type", "Source No.", "CLE/VLE Entry No.", "Document Type", "Document No.", "GST Group Code")
        {
        }
        key(Key14; "Transaction Type", "Document Type", "Document No.", "Document Line No.", "GST Component Code")
        {
            SumIndexFields = "GST Amount";
        }
        key(Key15; "Transaction Type", "Source Type", "Source No.", "Document Type", "Document No.", "GST Group Type")
        {
        }
        key(Key16; "Location  Reg. No.", "Transaction Type", Paid, "Entry Type", "Original Doc. Type", "Posting Date", "Reverse Charge", "GST Credit", "Payment Type", "GST Component Code")
        {
        }
        key(Key17; "Document No.", "GST Component Code")
        {
        }
        key(Key18; "Entry Type", "Transaction Type", "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key19; "Transaction Type", "Entry Type", "Document No.", "Document Line No.")
        {
        }
        key(Key20; "Dist. Document No.", Distributed)
        {
        }
        key(Key21; "Location  Reg. No.", Reconciled, "Reconciliation Month", "Reconciliation Year")
        {
        }
        key(Key22; "Location  Reg. No.", "Transaction Type", "Entry Type", "GST Vendor Type", "GST Credit", "Posting Date", "Source No.", "Document Type", "Document No.")
        {
        }
        key(Key23; "Location  Reg. No.", "Transaction Type", "Entry Type", "GST Vendor Type", "GST Credit", "Posting Date", "Source No.", "Document Type", "Document No.", "Document Line No.")
        {
        }
        key(Key24; "Transaction Type", "GST Jurisdiction Type", "Source No.", "Document Type", "Document No.", "Posting Date")
        {
        }
        key(Key25; "Location  Reg. No.", "GST Component Code", Paid, "Posting Date", "Liable to Pay", "Reverse Charge")
        {
        }
        key(Key26; "Location  Reg. No.", "GST Component Code", Paid, "Posting Date", "Credit Availed")
        {
        }
        key(Key27; "Location  Reg. No.", "Posting Date", "Entry Type", "Transaction Type", "Document Type")
        {
        }
        key(Key28; "Location  Reg. No.", "Document Type", "Document No.", "HSN/SAC Code", "GST %")
        {
            SumIndexFields = "GST Amount";
        }
        key(Key29; "Transaction Type", "Entry Type", "Document Type", "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}


