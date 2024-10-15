table 21 "Cust. Ledger Entry"
{
    Caption = 'Cust. Ledger Entry';
    DrillDownPageID = "Customer Ledger Entries";
    LookupPageID = "Customer Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,,,,,,,,,,,Bill';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,,,,,,,,,,Bill;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                IncomingDocument.HyperlinkToDocument("Document No.", "Posting Date");
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry".Amount WHERE("Ledger Entry Amount" = CONST(true),
                                                                         "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                         "Posting Date" = FIELD("Date Filter")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry".Amount WHERE("Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                         "Posting Date" = FIELD("Date Filter"),
                                                                         "Excluded from calculation" = CONST(false)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Amount (LCY)" WHERE("Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                 "Entry Type" = FILTER("Initial Entry" | Expenses),
                                                                                 "Posting Date" = FIELD("Date Filter")));
            Caption = 'Original Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Amount (LCY)" WHERE("Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                 "Posting Date" = FIELD("Date Filter"),
                                                                                 "Excluded from calculation" = CONST(false)));
            Caption = 'Remaining Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Amount (LCY)" WHERE("Ledger Entry Amount" = CONST(true),
                                                                                 "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                 "Posting Date" = FIELD("Date Filter")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales (LCY)';
        }
        field(19; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(20; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(21; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(22; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(25; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(33; "On Hold"; Code[3])
        {
            Caption = 'On Hold';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(34; "Applies-to Doc. Type"; Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,,,,,,,,,,,Bill';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,,,,,,,,,,Bill;
        }
        field(35; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            var
                ReminderEntry: Record "Reminder/Fin. Charge Entry";
                PaymentTerms: Record "Payment Terms";
                ReminderIssue: Codeunit "Reminder-Issue";
            begin
                TestField(Open, true);
                CheckBillSituation;
                if PaymentTerms.Get("Payment Terms Code") then
                    PaymentTerms.VerifyMaxNoDaysTillDueDate("Due Date", "Document Date", FieldCaption("Due Date"));

                if "Due Date" <> xRec."Due Date" then begin
                    ReminderEntry.SetCurrentKey("Customer Entry No.", Type);
                    ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
                    ReminderEntry.SetRange("Reminder Level", "Last Issued Reminder Level");
                    if ReminderEntry.FindLast then
                        ReminderIssue.ChangeDueDate(ReminderEntry, "Due Date", xRec."Due Date");
                end;
                if "Document Situation" <> "Document Situation"::" " then
                    DocMisc.UpdateReceivableDueDate(Rec);
            end;
        }
        field(38; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(39; "Original Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            Editable = false;
        }
        field(40; "Pmt. Disc. Given (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Given (LCY)';
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
        }
        field(46; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(54; "Closed by Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Closed by Amount (LCY)';
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Debit Amount" WHERE("Ledger Entry Amount" = CONST(true),
                                                                                 "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                 "Posting Date" = FIELD("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Credit Amount" WHERE("Ledger Entry Amount" = CONST(true),
                                                                                  "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                  "Posting Date" = FIELD("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Debit Amount (LCY)" WHERE("Ledger Entry Amount" = CONST(true),
                                                                                       "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                       "Posting Date" = FIELD("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry"."Credit Amount (LCY)" WHERE("Ledger Entry Amount" = CONST(true),
                                                                                        "Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(64; "Calculate Interest"; Boolean)
        {
            Caption = 'Calculate Interest';
        }
        field(65; "Closing Interest Calculated"; Boolean)
        {
            Caption = 'Closing Interest Calculated';
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(67; "Closed by Currency Code"; Code[10])
        {
            Caption = 'Closed by Currency Code';
            TableRelation = Currency;
        }
        field(68; "Closed by Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
        }
        field(73; "Adjusted Currency Factor"; Decimal)
        {
            Caption = 'Adjusted Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(74; "Original Currency Factor"; Decimal)
        {
            Caption = 'Original Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(75; "Original Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Cust. Ledg. Entry".Amount WHERE("Cust. Ledger Entry No." = FIELD("Entry No."),
                                                                         "Entry Type" = FILTER("Initial Entry" | Expenses),
                                                                         "Posting Date" = FIELD("Date Filter")));
            Caption = 'Original Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(77; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Original Amount");

                if "Remaining Pmt. Disc. Possible" * Amount < 0 then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(Text000, FieldCaption(Amount)));

                if Abs("Remaining Pmt. Disc. Possible") > Abs("Original Amount") then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(Text001, FieldCaption("Original Amount")));
            end;
        }
        field(78; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(79; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Remaining Amount");

                if "Max. Payment Tolerance" * Amount < 0 then
                    FieldError("Max. Payment Tolerance", StrSubstNo(Text000, FieldCaption(Amount)));

                if Abs("Max. Payment Tolerance") > Abs("Remaining Amount") then
                    FieldError("Max. Payment Tolerance", StrSubstNo(Text001, FieldCaption("Remaining Amount")));
            end;
        }
        field(80; "Last Issued Reminder Level"; Integer)
        {
            Caption = 'Last Issued Reminder Level';
        }
        field(81; "Accepted Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Accepted Payment Tolerance';
        }
        field(82; "Accepted Pmt. Disc. Tolerance"; Boolean)
        {
            Caption = 'Accepted Pmt. Disc. Tolerance';
        }
        field(83; "Pmt. Tolerance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Tolerance (LCY)';
        }
        field(84; "Amount to Apply"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Apply';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields("Remaining Amount");

                CheckBillSituation;

                if "Amount to Apply" * "Remaining Amount" < 0 then
                    FieldError("Amount to Apply", StrSubstNo(Text000, FieldCaption("Remaining Amount")));

                if Abs("Amount to Apply") > Abs("Remaining Amount") then
                    FieldError("Amount to Apply", StrSubstNo(Text001, FieldCaption("Remaining Amount")));
            end;
        }
        field(85; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(86; "Applying Entry"; Boolean)
        {
            Caption = 'Applying Entry';
        }
        field(87; Reversed; Boolean)
        {
            BlankZero = true;
            Caption = 'Reversed';
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(90; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(91; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            Editable = false;
            TableRelation = "Payment Terms";
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                CarteraDoc: Record "Cartera Doc.";
            begin
                TestField(Open, true);
                if "Payment Method Code" <> xRec."Payment Method Code" then begin
                    ValidatePaymentMethod;
                    CarteraDoc.UpdatePaymentMethodCode(
                      "Document No.", "Customer No.", "Bill No.", "Payment Method Code")
                end;
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = "Customer Bank Account".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
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

            trigger OnLookup()
            begin
                ShowDimensions;
            end;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Customer No."));
        }
        field(10700; "Invoice Type"; Option)
        {
            Caption = 'Invoice Type';
            DataClassification = CustomerContent;
            OptionCaption = 'F1 Invoice,F2 Simplified Invoice,F3 Invoice issued to replace simplified invoices,F4 Invoice summary entry';
            OptionMembers = "F1 Invoice","F2 Simplified Invoice","F3 Invoice issued to replace simplified invoices","F4 Invoice summary entry";
        }
        field(10701; "Cr. Memo Type"; Option)
        {
            Caption = 'Cr. Memo Type';
            DataClassification = CustomerContent;
            OptionCaption = 'R1 Corrected Invoice,R2 Corrected Invoice (Art. 80.3),R3 Corrected Invoice (Art. 80.4),R4 Corrected Invoice (Other),R5 Corrected Invoice in Simplified Invoices,F1 Invoice,F2 Simplified Invoice';
            OptionMembers = "R1 Corrected Invoice","R2 Corrected Invoice (Art. 80.3)","R3 Corrected Invoice (Art. 80.4)","R4 Corrected Invoice (Other)","R5 Corrected Invoice in Simplified Invoices","F1 Invoice","F2 Simplified Invoice";
        }
        field(10702; "Special Scheme Code"; Option)
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
            OptionCaption = '01 General,02 Export,03 Special System,04 Gold,05 Travel Agencies,06 Groups of Entities,07 Special Cash,08  IPSI / IGIC,09 Travel Agency Services,10 Third Party,11 Business Withholding,12 Business not Withholding,13 Business Withholding and not Withholding,14 Invoice Work Certification,15 Invoice of Consecutive Nature,16 First Half 2017';
            OptionMembers = "01 General","02 Export","03 Special System","04 Gold","05 Travel Agencies","06 Groups of Entities","07 Special Cash","08  IPSI / IGIC","09 Travel Agency Services","10 Third Party","11 Business Withholding","12 Business not Withholding","13 Business Withholding and not Withholding","14 Invoice Work Certification","15 Invoice of Consecutive Nature","16 First Half 2017";
        }
        field(10703; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(10704; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
        }
        field(10722; "ID Type"; Option)
        {
            Caption = 'ID Type';
            OptionCaption = ' ,02-VAT Registration No.,03-Passport,04-ID Document,05-Certificate Of Residence,06-Other Probative Document,07-Not On The Census';
            OptionMembers = " ","02-VAT Registration No.","03-Passport","04-ID Document","05-Certificate Of Residence","06-Other Probative Document","07-Not On The Census";
        }
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
        }
        field(7000001; "Document Situation"; Option)
        {
            Caption = 'Document Situation';
            OptionCaption = ' ,Posted BG/PO,Closed BG/PO,BG/PO,Cartera,Closed Documents';
            OptionMembers = " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents";
        }
        field(7000002; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
        }
        field(7000003; "Document Status"; Option)
        {
            Caption = 'Document Status';
            OptionCaption = ' ,Open,Honored,Rejected,Redrawn';
            OptionMembers = " ",Open,Honored,Rejected,Redrawn;
        }
        field(7000005; "Remaining Amount (LCY) stats."; Decimal)
        {
            Caption = 'Remaining Amount (LCY) stats.';
        }
        field(7000006; "Amount (LCY) stats."; Decimal)
        {
            Caption = 'Amount (LCY) stats.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)";
        }
        key(Key3; "Customer No.", "Currency Code", "Posting Date")
        {
            Enabled = false;
        }
        key(Key4; "Document No.")
        {
        }
        key(Key5; "External Document No.")
        {
        }
        key(Key6; "Customer No.", Open, Positive, "Due Date", "Currency Code")
        {
        }
        key(Key7; Open, "Due Date")
        {
        }
        key(Key8; "Document Type", "Customer No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)";
        }
        key(Key9; "Salesperson Code", "Posting Date")
        {
        }
        key(Key10; "Closed by Entry No.")
        {
        }
        key(Key11; "Transaction No.")
        {
        }
        key(Key12; "Customer No.", Open, Positive, "Calculate Interest", "Due Date")
        {
            Enabled = false;
        }
        key(Key13; "Customer No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)", "Pmt. Disc. Given (LCY)";
        }
        key(Key14; "Customer No.", Open, "Global Dimension 1 Code", "Global Dimension 2 Code", Positive, "Due Date", "Currency Code")
        {
        }
        key(Key15; Open, "Global Dimension 1 Code", "Global Dimension 2 Code", "Due Date")
        {
            Enabled = false;
        }
        key(Key16; "Document Type", "Customer No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "Currency Code")
        {
        }
        key(Key17; "Customer No.", "Applies-to ID", Open, Positive, "Due Date")
        {
        }
        key(Key18; "Customer No.", Open, Positive, "Applies-to ID", "Due Date")
        {
        }
        key(Key19; "Customer No.", "Document Type", "Document Situation", "Document Status")
        {
            SumIndexFields = "Remaining Amount (LCY) stats.", "Amount (LCY) stats.";
        }
        key(Key20; "Document No.", "Bill No.")
        {
        }
        key(Key21; "Document No.", "Document Type", "Customer No.")
        {
        }
        key(Key22; "Applies-to ID", "Document Type", "Document Situation", "Document Status")
        {
        }
        key(Key23; "Document Type", "Customer No.", "Document Date", "Currency Code")
        {
        }
        key(Key24; "Document Type", "Posting Date")
        {
            SumIndexFields = "Sales (LCY)";
        }
        key(Key25; "Document Type", "Customer No.", Open, "Due Date")
        {
        }
        key(Key26; "Customer Posting Group")
        {
        }
        key(Key27; "Document Type", Open, "Posting Date", "Closed at Date")
        {
        }
        key(Key28; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Customer No.", "Posting Date", "Document Type", "Document No.")
        {
        }
        fieldgroup(Brick; "Document No.", Description, "Remaining Amt. (LCY)", "Due Date")
        {
        }
    }

    var
        Text000: Label 'must have the same sign as %1';
        Text001: Label 'must not be larger than %1';
        Text1100000: Label 'Payment Discount (VAT Excl.)';
        Text1100001: Label 'Payment Discount (VAT Adjustment)';
        DocMisc: Codeunit "Document-Misc";
        CannotChangePmtMethodErr: Label 'For Cartera-based bills and invoices, you cannot change the Payment Method Code to this value.';

    procedure ShowDoc(): Boolean
    var
        SalesInvoiceHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                begin
                    if SalesInvoiceHdr.Get("Document No.") then begin
                        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHdr);
                        exit(true);
                    end;
                    if ServiceInvoiceHeader.Get("Document No.") then begin
                        PAGE.Run(PAGE::"Posted Service Invoice", ServiceInvoiceHeader);
                        exit(true);
                    end;
                end;
            "Document Type"::"Credit Memo":
                begin
                    if SalesCrMemoHdr.Get("Document No.") then begin
                        PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHdr);
                        exit(true);
                    end;
                    if ServiceCrMemoHeader.Get("Document No.") then begin
                        PAGE.Run(PAGE::"Posted Service Credit Memo", ServiceCrMemoHeader);
                        exit(true);
                    end;
                end;
            "Document Type"::"Finance Charge Memo":
                if IssuedFinChargeMemoHeader.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Issued Finance Charge Memo", IssuedFinChargeMemoHeader);
                    exit(true);
                end;
            "Document Type"::Reminder:
                if IssuedReminderHeader.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader);
                    exit(true);
                end;
        end;

        OnAfterShowDoc(Rec);
    end;

    procedure ShowPostedDocAttachment()
    var
        SalesInvoiceHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if SalesInvoiceHdr.Get("Document No.") then
                    OpenDocumentAttachmentDetails(SalesInvoiceHdr);
            "Document Type"::"Credit Memo":
                if SalesCrMemoHdr.Get("Document No.") then
                    OpenDocumentAttachmentDetails(SalesCrMemoHdr);
        end;
    end;

    local procedure OpenDocumentAttachmentDetails("Record": Variant)
    var
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Record);
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal;
    end;

    procedure HasPostedDocAttachment(): Boolean
    var
        SalesInvoiceHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if SalesInvoiceHdr.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(SalesInvoiceHdr));
            "Document Type"::"Credit Memo":
                if SalesCrMemoHdr.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(SalesCrMemoHdr));
        end;
    end;

    procedure DrillDownOnEntries(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DrillDownPageID: Integer;
    begin
        CustLedgEntry.Reset;
        DtldCustLedgEntry.CopyFilter("Customer No.", CustLedgEntry."Customer No.");
        DtldCustLedgEntry.CopyFilter("Currency Code", CustLedgEntry."Currency Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 1", CustLedgEntry."Global Dimension 1 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 2", CustLedgEntry."Global Dimension 2 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Due Date", CustLedgEntry."Due Date");
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange(Open, true);
        OnBeforeDrillDownEntries(CustLedgEntry, DtldCustLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, CustLedgEntry);
    end;

    procedure DrillDownOnOverdueEntries(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DrillDownPageID: Integer;
    begin
        CustLedgEntry.Reset;
        DtldCustLedgEntry.CopyFilter("Customer No.", CustLedgEntry."Customer No.");
        DtldCustLedgEntry.CopyFilter("Currency Code", CustLedgEntry."Currency Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 1", CustLedgEntry."Global Dimension 1 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 2", CustLedgEntry."Global Dimension 2 Code");
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetFilter("Date Filter", '..%1', WorkDate);
        CustLedgEntry.SetFilter("Due Date", '<%1', WorkDate);
        CustLedgEntry.SetFilter("Remaining Amount", '<>%1', 0);
        OnBeforeDrillDownOnOverdueEntries(CustLedgEntry, DtldCustLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, CustLedgEntry);
    end;

    procedure GetOriginalCurrencyFactor(): Decimal
    begin
        if "Original Currency Factor" = 0 then
            exit(1);
        exit("Original Currency Factor");
    end;

    procedure GetAdjustedCurrencyFactor(): Decimal
    begin
        if "Adjusted Currency Factor" = 0 then
            exit(1);
        exit("Adjusted Currency Factor");
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;

    [Scope('OnPrem')]
    procedure PrintBill(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            Copy(Rec);
            CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::Bill);
            CarteraReportSelection.SetFilter("Report ID", '<>0');
            CarteraReportSelection.Find('-');
            repeat
                REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, CustLedgEntry);
            until CarteraReportSelection.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckBillSituation()
    var
        Doc: Record "Cartera Doc.";
        Text1100100: Label '%1 cannot be applied, since it is included in a bill group.';
        Text1100101: Label ' Remove it from its bill group and try again.';
    begin
        if Doc.Get(Doc.Type::Receivable, Rec."Entry No.") then
            if Doc."Bill Gr./Pmt. Order No." <> '' then
                Error(
                  Text1100100 +
                  Text1100101,
                  Rec.Description);
    end;

    procedure SetStyle(): Text
    begin
        if Open then begin
            if WorkDate > "Due Date" then
                exit('Unfavorable')
        end else
            if "Closed at Date" > "Due Date" then
                exit('Attention');
        exit('');
    end;

    procedure SetApplyToFilters(CustomerNo: Code[20]; ApplyDocType: Option; ApplyDocNo: Code[20]; ApplyBillNo: Code[20]; ApplyAmount: Decimal)
    begin
        SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        SetRange("Customer No.", CustomerNo);
        SetRange(Open, true);
        SetFilter("Document Situation", '<>%1', "Document Situation"::"Posted BG/PO");
        if ApplyDocNo <> '' then begin
            SetRange("Document Type", ApplyDocType);
            SetRange("Document No.", ApplyDocNo);
            if ApplyBillNo <> '' then
                SetRange("Bill No.", ApplyBillNo);
            if FindFirst then;
            SetRange("Document Type");
            SetRange("Document No.");
            SetRange("Bill No.");
        end else
            if ApplyDocType <> 0 then begin
                SetRange("Document Type", ApplyDocType);
                if FindFirst then;
                SetRange("Document Type");
            end else
                if ApplyAmount <> 0 then begin
                    SetRange(Positive, ApplyAmount < 0);
                    if FindFirst then;
                    SetRange(Positive);
                end;
    end;

    procedure SetAmountToApply(AppliesToDocNo: Code[20]; CustomerNo: Code[20]; var AppliesToBillNo: Code[20])
    begin
        OnBeforeSetAmountToApply(Rec);

        SetCurrentKey("Document No.");
        SetRange("Document No.", AppliesToDocNo);
        SetRange("Customer No.", CustomerNo);
        SetRange(Open, true);
        if FindFirst then begin
            AppliesToBillNo := "Bill No.";
            if "Amount to Apply" = 0 then begin
                CalcFields("Remaining Amount");
                "Amount to Apply" := "Remaining Amount";
            end else
                "Amount to Apply" := 0;
            "Accepted Payment Tolerance" := 0;
            "Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);
        end;
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Customer No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        "Currency Code" := GenJnlLine."Currency Code";
        "Sales (LCY)" := GenJnlLine."Sales/Purch. (LCY)";
        "Profit (LCY)" := GenJnlLine."Profit (LCY)";
        "Inv. Discount (LCY)" := GenJnlLine."Inv. Discount (LCY)";
        "Sell-to Customer No." := GenJnlLine."Sell-to/Buy-from No.";
        "Customer Posting Group" := GenJnlLine."Posting Group";
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Salesperson Code" := GenJnlLine."Salespers./Purch. Code";
        "Source Code" := GenJnlLine."Source Code";
        "On Hold" := GenJnlLine."On Hold";
        "Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        "Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        "Due Date" := GenJnlLine."Due Date";
        "Pmt. Discount Date" := GenJnlLine."Pmt. Discount Date";
        "Applies-to ID" := GenJnlLine."Applies-to ID";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "Direct Debit Mandate ID" := GenJnlLine."Direct Debit Mandate ID";
        "User ID" := UserId;
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        "No. Series" := GenJnlLine."Posting No. Series";
        "IC Partner Code" := GenJnlLine."IC Partner Code";
        Prepayment := GenJnlLine.Prepayment;
        "Recipient Bank Account" := GenJnlLine."Recipient Bank Account";
        "Message to Recipient" := GenJnlLine."Message to Recipient";
        "Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
        "Payment Method Code" := GenJnlLine."Payment Method Code";
        "Exported to Payment File" := GenJnlLine."Exported to Payment File";
        "Payment Terms Code" := GenJnlLine."Payment Terms Code";
        "Bill No." := GenJnlLine."Bill No.";
        "Applies-to Bill No." := GenJnlLine."Applies-to Bill No.";
        "Invoice Type" := GenJnlLine."Sales Invoice Type";
        "Cr. Memo Type" := GenJnlLine."Sales Cr. Memo Type";
        "Special Scheme Code" := GenJnlLine."Sales Special Scheme Code";
        "Correction Type" := GenJnlLine."Correction Type";
        "Corrected Invoice No." := GenJnlLine."Corrected Invoice No.";
        "Succeeded Company Name" := GenJnlLine."Succeeded Company Name";
        "Succeeded VAT Registration No." := GenJnlLine."Succeeded VAT Registration No.";

        OnAfterCopyCustLedgerEntryFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure CopyFromCVLedgEntryBuffer(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        TransferFields(CVLedgerEntryBuffer);
        Amount := CVLedgerEntryBuffer.Amount;
        "Amount (LCY)" := CVLedgerEntryBuffer."Amount (LCY)";
        "Remaining Amount" := CVLedgerEntryBuffer."Remaining Amount";
        "Remaining Amt. (LCY)" := CVLedgerEntryBuffer."Remaining Amt. (LCY)";
        "Original Amount" := CVLedgerEntryBuffer."Original Amount";
        "Original Amt. (LCY)" := CVLedgerEntryBuffer."Original Amt. (LCY)";

        OnAfterCopyCustLedgerEntryFromCVLedgEntryBuffer(Rec, CVLedgerEntryBuffer);
    end;

    procedure RecalculateAmounts(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if ToCurrencyCode = FromCurrencyCode then
            exit;

        "Remaining Amount" :=
          CurrExchRate.ExchangeAmount("Remaining Amount", FromCurrencyCode, ToCurrencyCode, PostingDate);
        "Remaining Pmt. Disc. Possible" :=
          CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", FromCurrencyCode, ToCurrencyCode, PostingDate);
        "Accepted Payment Tolerance" :=
          CurrExchRate.ExchangeAmount("Accepted Payment Tolerance", FromCurrencyCode, ToCurrencyCode, PostingDate);
        "Amount to Apply" :=
          CurrExchRate.ExchangeAmount("Amount to Apply", FromCurrencyCode, ToCurrencyCode, PostingDate);

        OnAfterRecalculateAmounts(Rec, FromCurrencyCode, ToCurrencyCode, PostingDate);
    end;

    local procedure ValidatePaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get("Payment Method Code");
        if (("Document Type" = "Document Type"::Bill) and (not PaymentMethod."Create Bills")) or
           (("Document Type" = "Document Type"::Invoice) and (not PaymentMethod."Invoices to Cartera")) then
            Error(CannotChangePmtMethodErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromCVLedgEntryBuffer(var CustLedgerEntry: Record "Cust. Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateAmounts(var CustLedgerEntry: Record "Cust. Ledger Entry"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDoc(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOnOverdueEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountToApply(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

