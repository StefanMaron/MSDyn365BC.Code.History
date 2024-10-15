table 12142 "VAT Book Entry"
{
    Caption = 'VAT Book Entry';
    DrillDownPageID = "VAT Book Entries";
    LookupPageID = "VAT Book Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Document Type"; Option)
        {
            CalcFormula = Lookup ("VAT Entry"."Document Type" WHERE("Document No." = FIELD("Document No."),
                                                                    Type = FIELD(Type),
                                                                    "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                    "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                    "VAT %" = FIELD("VAT %"),
                                                                    "Deductible %" = FIELD("Deductible %"),
                                                                    "VAT Identifier" = FIELD("VAT Identifier"),
                                                                    "Transaction No." = FIELD("Transaction No."),
                                                                    "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Document Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,Dishonored';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,Dishonored;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry".Base WHERE("Document No." = FIELD("Document No."),
                                                      Type = FIELD(Type),
                                                      "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                      "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                      "VAT %" = FIELD("VAT %"),
                                                      "Deductible %" = FIELD("Deductible %"),
                                                      "VAT Identifier" = FIELD("VAT Identifier"),
                                                      "Transaction No." = FIELD("Transaction No."),
                                                      "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry".Amount WHERE("Document No." = FIELD("Document No."),
                                                        Type = FIELD(Type),
                                                        "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                        "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                        "VAT %" = FIELD("VAT %"),
                                                        "Deductible %" = FIELD("Deductible %"),
                                                        "VAT Identifier" = FIELD("VAT Identifier"),
                                                        "Transaction No." = FIELD("Transaction No."),
                                                        "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "VAT Calculation Type"; Option)
        {
            CalcFormula = Lookup ("VAT Entry"."VAT Calculation Type" WHERE("Document No." = FIELD("Document No."),
                                                                           Type = FIELD(Type),
                                                                           "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                           "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                           "VAT %" = FIELD("VAT %"),
                                                                           "Deductible %" = FIELD("Deductible %"),
                                                                           "VAT Identifier" = FIELD("VAT Identifier"),
                                                                           "Transaction No." = FIELD("Transaction No."),
                                                                           "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'VAT Calculation Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(12; "Sell-to/Buy-from No."; Code[20])
        {
            CalcFormula = Lookup ("VAT Entry"."Bill-to/Pay-to No." WHERE("Document No." = FIELD("Document No."),
                                                                         Type = FIELD(Type),
                                                                         "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                         "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                         "VAT %" = FIELD("VAT %"),
                                                                         "Deductible %" = FIELD("Deductible %"),
                                                                         "VAT Identifier" = FIELD("VAT Identifier"),
                                                                         "Transaction No." = FIELD("Transaction No."),
                                                                         "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Sell-to/Buy-from No.';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = IF (Type = CONST(Purchase)) Vendor
            ELSE
            IF (Type = CONST(Sale)) Customer;
        }
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(26; "External Document No."; Code[35])
        {
            CalcFormula = Lookup ("VAT Entry"."External Document No." WHERE("Document No." = FIELD("Document No."),
                                                                            Type = FIELD(Type),
                                                                            "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                            "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                            "VAT %" = FIELD("VAT %"),
                                                                            "Deductible %" = FIELD("Deductible %"),
                                                                            "VAT Identifier" = FIELD("VAT Identifier"),
                                                                            "Transaction No." = FIELD("Transaction No."),
                                                                            "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'External Document No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "No. Series"; Code[20])
        {
            CalcFormula = Lookup ("VAT Entry"."No. Series" WHERE("Document No." = FIELD("Document No."),
                                                                 Type = FIELD(Type),
                                                                 "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                 "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                 "VAT %" = FIELD("VAT %"),
                                                                 "Deductible %" = FIELD("Deductible %"),
                                                                 "VAT Identifier" = FIELD("VAT Identifier"),
                                                                 "Transaction No." = FIELD("Transaction No."),
                                                                 "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'No. Series';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "No. Series";
        }
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        field(50; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
            TableRelation = "VAT Identifier";
        }
        field(51; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(52; "Nondeductible Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry"."Nondeductible Amount" WHERE("Document No." = FIELD("Document No."),
                                                                        Type = FIELD(Type),
                                                                        "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                        "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                        "VAT %" = FIELD("VAT %"),
                                                                        "Deductible %" = FIELD("Deductible %"),
                                                                        "VAT Identifier" = FIELD("VAT Identifier"),
                                                                        "Transaction No." = FIELD("Transaction No."),
                                                                        "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Nondeductible Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Document Date"; Date)
        {
            CalcFormula = Lookup ("VAT Entry"."Document Date" WHERE("Document No." = FIELD("Document No."),
                                                                    Type = FIELD(Type),
                                                                    "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                    "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                    "VAT %" = FIELD("VAT %"),
                                                                    "Deductible %" = FIELD("Deductible %"),
                                                                    "VAT Identifier" = FIELD("VAT Identifier"),
                                                                    "Transaction No." = FIELD("Transaction No."),
                                                                    "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Document Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
            Editable = false;
        }
        field(56; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
            MinValue = 0;
        }
        field(57; "VAT Difference"; Decimal)
        {
            CalcFormula = Sum ("VAT Entry"."VAT Difference" WHERE("Document No." = FIELD("Document No."),
                                                                  Type = FIELD(Type),
                                                                  "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                  "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                  "Deductible %" = FIELD("Deductible %"),
                                                                  "VAT Identifier" = FIELD("VAT Identifier"),
                                                                  "Transaction No." = FIELD("Transaction No."),
                                                                  "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'VAT Difference';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Nondeductible Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry"."Nondeductible Base" WHERE("Document No." = FIELD("Document No."),
                                                                      Type = FIELD(Type),
                                                                      "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                      "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                      "VAT %" = FIELD("VAT %"),
                                                                      "Deductible %" = FIELD("Deductible %"),
                                                                      "VAT Identifier" = FIELD("VAT Identifier"),
                                                                      "Transaction No." = FIELD("Transaction No."),
                                                                      "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Nondeductible Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry"."Unrealized Base" WHERE("Document No." = FIELD("Document No."),
                                                                   Type = FIELD(Type),
                                                                   "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                   "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                   "VAT %" = FIELD("VAT %"),
                                                                   "Deductible %" = FIELD("Deductible %"),
                                                                   "VAT Identifier" = FIELD("VAT Identifier"),
                                                                   "Transaction No." = FIELD("Transaction No."),
                                                                   "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Unrealized Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("VAT Entry"."Unrealized Amount" WHERE("Document No." = FIELD("Document No."),
                                                                     Type = FIELD(Type),
                                                                     "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                     "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                     "VAT %" = FIELD("VAT %"),
                                                                     "Deductible %" = FIELD("Deductible %"),
                                                                     "VAT Identifier" = FIELD("VAT Identifier"),
                                                                     "Transaction No." = FIELD("Transaction No."),
                                                                     "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Unrealized Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Printing Date"; Date)
        {
            Caption = 'Printing Date';
            Editable = false;
        }
        field(64; "Official Date"; Date)
        {
            Caption = 'Official Date';
            Editable = false;
        }
        field(65; "Reverse VAT Entry"; Boolean)
        {
            Caption = 'Reverse VAT Entry';
            Editable = false;
        }
        field(66; "Unrealized VAT"; Boolean)
        {
            Caption = 'Unrealized VAT';
            Editable = false;
        }
        field(67; "Unrealized VAT Entry No."; Integer)
        {
            Caption = 'Unrealized VAT Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            CalcFormula = Sum ("VAT Entry"."Additional-Currency Amount" WHERE("Document No." = FIELD("Document No."),
                                                                              Type = FIELD(Type),
                                                                              "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                              "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                              "VAT %" = FIELD("VAT %"),
                                                                              "Deductible %" = FIELD("Deductible %"),
                                                                              "VAT Identifier" = FIELD("VAT Identifier"),
                                                                              "Transaction No." = FIELD("Transaction No."),
                                                                              "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Additional-Currency Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Additional-Currency Base"; Decimal)
        {
            CalcFormula = Sum ("VAT Entry"."Additional-Currency Base" WHERE("Document No." = FIELD("Document No."),
                                                                            Type = FIELD(Type),
                                                                            "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                            "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                            "VAT %" = FIELD("VAT %"),
                                                                            "Deductible %" = FIELD("Deductible %"),
                                                                            "VAT Identifier" = FIELD("VAT Identifier"),
                                                                            "Transaction No." = FIELD("Transaction No."),
                                                                            "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Additional-Currency Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Add. Curr. Nondeductible Amt."; Decimal)
        {
            CalcFormula = Sum ("VAT Entry"."Add. Curr. Nondeductible Amt." WHERE("Document No." = FIELD("Document No."),
                                                                                 Type = FIELD(Type),
                                                                                 "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                                 "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                                 "VAT %" = FIELD("VAT %"),
                                                                                 "Deductible %" = FIELD("Deductible %"),
                                                                                 "VAT Identifier" = FIELD("VAT Identifier"),
                                                                                 "Transaction No." = FIELD("Transaction No."),
                                                                                 "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Add. Curr. Nondeductible Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Add. Curr. Nondeductible Base"; Decimal)
        {
            CalcFormula = Sum ("VAT Entry"."Add. Curr. Nondeductible Base" WHERE("Document No." = FIELD("Document No."),
                                                                                 Type = FIELD(Type),
                                                                                 "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"),
                                                                                 "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group"),
                                                                                 "VAT %" = FIELD("VAT %"),
                                                                                 "Deductible %" = FIELD("Deductible %"),
                                                                                 "VAT Identifier" = FIELD("VAT Identifier"),
                                                                                 "Transaction No." = FIELD("Transaction No."),
                                                                                 "Unrealized VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Add. Curr. Nondeductible Base';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT %", "Deductible %", "VAT Identifier", "Transaction No.", "Unrealized VAT Entry No.")
        {
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}

