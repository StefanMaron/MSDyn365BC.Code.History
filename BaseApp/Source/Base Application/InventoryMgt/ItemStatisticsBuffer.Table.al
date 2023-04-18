table 5821 "Item Statistics Buffer"
{
    Caption = 'Item Statistics Buffer';
    DataCaptionFields = "Code";
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
            TableRelation = Item;
            ValidateTableRelation = false;
        }
        field(3; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code;
        }
        field(4; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Budget Name".Name WHERE("Analysis Area" = FIELD("Analysis Area Filter"));
        }
        field(6; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(7; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ClosingDates = true;
            FieldClass = FlowFilter;
        }
        field(10; "Entry Type Filter"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Item Ledger Entry Type Filter"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Item Ledger Entry Type Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Item Charge No. Filter"; Code[20])
        {
            Caption = 'Item Charge No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Charge";
        }
        field(13; "Source Type Filter"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Source No. Filter"; Code[20])
        {
            Caption = 'Source No. Filter';
            FieldClass = FlowFilter;
            TableRelation = IF ("Source Type Filter" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type Filter" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type Filter" = CONST(Item)) Item;
            ValidateTableRelation = false;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            CalcFormula = Sum("Value Entry"."Invoiced Quantity" WHERE("Item No." = FIELD("Item Filter"),
                                                                       "Posting Date" = FIELD("Date Filter"),
                                                                       "Variant Code" = FIELD("Variant Filter"),
                                                                       "Location Code" = FIELD("Location Filter"),
                                                                       "Entry Type" = FIELD("Entry Type Filter"),
                                                                       "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                       "Variance Type" = FIELD("Variance Type Filter"),
                                                                       "Item Charge No." = FIELD("Item Charge No. Filter"),
                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                       "Source Type" = FIELD("Source Type Filter"),
                                                                       "Source No." = FIELD("Source No. Filter")));
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Actual)" WHERE("Item No." = FIELD("Item Filter"),
                                                                           "Posting Date" = FIELD("Date Filter"),
                                                                           "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                           "Entry Type" = FIELD("Entry Type Filter"),
                                                                           "Variance Type" = FIELD("Variance Type Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Variant Code" = FIELD("Variant Filter"),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Item Charge No." = FIELD("Item Charge No. Filter"),
                                                                           "Source Type" = FIELD("Source Type Filter"),
                                                                           "Source No." = FIELD("Source No. Filter")));
            Caption = 'Sales Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Actual)" WHERE("Item No." = FIELD("Item Filter"),
                                                                          "Posting Date" = FIELD("Date Filter"),
                                                                          "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                          "Entry Type" = FIELD("Entry Type Filter"),
                                                                          "Variance Type" = FIELD("Variance Type Filter"),
                                                                          "Location Code" = FIELD("Location Filter"),
                                                                          "Variant Code" = FIELD("Variant Filter"),
                                                                          "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                          "Item Charge No." = FIELD("Item Charge No. Filter"),
                                                                          "Source Type" = FIELD("Source Type Filter"),
                                                                          "Source No." = FIELD("Source No. Filter")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Non-Invtbl.)" WHERE("Item No." = FIELD("Item Filter"),
                                                                               "Posting Date" = FIELD("Date Filter"),
                                                                               "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                               "Variance Type" = FIELD("Variance Type Filter"),
                                                                               "Entry Type" = FIELD("Entry Type Filter"),
                                                                               "Location Code" = FIELD("Location Filter"),
                                                                               "Variant Code" = FIELD("Variant Filter"),
                                                                               "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Item Charge No." = FIELD("Item Charge No. Filter"),
                                                                               "Source Type" = FIELD("Source Type Filter"),
                                                                               "Source No." = FIELD("Source No. Filter")));
            Caption = 'Cost Amount (Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Variance Type Filter"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Sales (LCY)"; Integer)
        {
            Caption = 'Sales (LCY)';
            DataClassification = SystemMetadata;
        }
        field(21; "COGS (LCY)"; Integer)
        {
            Caption = 'COGS (LCY)';
            DataClassification = SystemMetadata;
        }
        field(22; "Profit (LCY)"; Integer)
        {
            Caption = 'Profit (LCY)';
            DataClassification = SystemMetadata;
        }
        field(23; "Profit %"; Integer)
        {
            Caption = 'Profit %';
            DataClassification = SystemMetadata;
        }
        field(24; "Inventoriable Costs"; Integer)
        {
            Caption = 'Inventoriable Costs';
            DataClassification = SystemMetadata;
        }
        field(25; "Direct Cost (LCY)"; Integer)
        {
            Caption = 'Direct Cost (LCY)';
            DataClassification = SystemMetadata;
        }
        field(26; "Revaluation (LCY)"; Integer)
        {
            Caption = 'Revaluation (LCY)';
            DataClassification = SystemMetadata;
        }
        field(27; "Rounding (LCY)"; Integer)
        {
            Caption = 'Rounding (LCY)';
            DataClassification = SystemMetadata;
        }
        field(28; "Indirect Cost (LCY)"; Integer)
        {
            Caption = 'Indirect Cost (LCY)';
            DataClassification = SystemMetadata;
        }
        field(29; "Variance (LCY)"; Integer)
        {
            Caption = 'Variance (LCY)';
            DataClassification = SystemMetadata;
        }
        field(30; "Inventoriable Costs, Total"; Integer)
        {
            Caption = 'Inventoriable Costs, Total';
            DataClassification = SystemMetadata;
        }
        field(31; "Inventory (LCY)"; Integer)
        {
            Caption = 'Inventory (LCY)';
            DataClassification = SystemMetadata;
        }
        field(34; "Non-Invtbl. Costs (LCY)"; Integer)
        {
            Caption = 'Non-Invtbl. Costs (LCY)';
            DataClassification = SystemMetadata;
        }
        field(40; "Line Option"; Enum "Item Statistics Line Option")
        {
            Caption = 'Line Option';
            DataClassification = SystemMetadata;
        }
        field(41; "Column Option"; Enum "Item Statistics Column Option")
        {
            Caption = 'Column Option';
            DataClassification = SystemMetadata;
        }
#pragma warning disable AS0070
        field(42; "Analysis Area Filter"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area Filter';
            FieldClass = FlowFilter;
        }
#pragma warning restore AS0070
        field(45; Quantity; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("Item Filter"),
                                                                  "Source Type" = FIELD("Source Type Filter"),
                                                                  "Source No." = FIELD("Source No. Filter"),
                                                                  "Posting Date" = FIELD("Date Filter"),
                                                                  "Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Variant Code" = FIELD("Variant Filter"),
                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Expected)" WHERE("Item No." = FIELD("Item Filter"),
                                                                             "Source Type" = FIELD("Source Type Filter"),
                                                                             "Source No." = FIELD("Source No. Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                             "Variance Type" = FIELD("Variance Type Filter"),
                                                                             "Entry Type" = FIELD("Entry Type Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Variant Code" = FIELD("Variant Filter"),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Item Charge No." = FIELD("Item Charge No. Filter")));
            Caption = 'Sales Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Cost Amount (Expected)" WHERE("Item No." = FIELD("Item Filter"),
                                                                            "Source Type" = FIELD("Source Type Filter"),
                                                                            "Source No." = FIELD("Source No. Filter"),
                                                                            "Posting Date" = FIELD("Date Filter"),
                                                                            "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                            "Variance Type" = FIELD("Variance Type Filter"),
                                                                            "Entry Type" = FIELD("Entry Type Filter"),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Variant Code" = FIELD("Variant Filter"),
                                                                            "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                            "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                            "Item Charge No." = FIELD("Item Charge No. Filter")));
            Caption = 'Cost Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Budgeted Quantity"; Decimal)
        {
            CalcFormula = Sum("Item Budget Entry".Quantity WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                  "Budget Name" = FIELD("Budget Filter"),
                                                                  "Item No." = FIELD("Item Filter"),
                                                                  Date = FIELD("Date Filter"),
                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                  "Budget Dimension 1 Code" = FIELD("Dimension 1 Filter"),
                                                                  "Budget Dimension 2 Code" = FIELD("Dimension 2 Filter"),
                                                                  "Budget Dimension 3 Code" = FIELD("Dimension 3 Filter"),
                                                                  "Source Type" = FIELD("Source Type Filter"),
                                                                  "Source No." = FIELD("Source No. Filter"),
                                                                  "Location Code" = FIELD("Location Filter")));
            Caption = 'Budgeted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Budgeted Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Budget Entry"."Sales Amount" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                        "Budget Name" = FIELD("Budget Filter"),
                                                                        "Item No." = FIELD("Item Filter"),
                                                                        Date = FIELD("Date Filter"),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Budget Dimension 1 Code" = FIELD("Dimension 1 Filter"),
                                                                        "Budget Dimension 2 Code" = FIELD("Dimension 2 Filter"),
                                                                        "Budget Dimension 3 Code" = FIELD("Dimension 3 Filter"),
                                                                        "Source Type" = FIELD("Source Type Filter"),
                                                                        "Source No." = FIELD("Source No. Filter"),
                                                                        "Location Code" = FIELD("Location Filter")));
            Caption = 'Budgeted Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Budgeted Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Budget Entry"."Cost Amount" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                       "Budget Name" = FIELD("Budget Filter"),
                                                                       "Item No." = FIELD("Item Filter"),
                                                                       Date = FIELD("Date Filter"),
                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                       "Budget Dimension 1 Code" = FIELD("Dimension 1 Filter"),
                                                                       "Budget Dimension 2 Code" = FIELD("Dimension 2 Filter"),
                                                                       "Budget Dimension 3 Code" = FIELD("Dimension 3 Filter"),
                                                                       "Source Type" = FIELD("Source Type Filter"),
                                                                       "Source No." = FIELD("Source No. Filter"),
                                                                       "Location Code" = FIELD("Location Filter")));
            Caption = 'Budgeted Cost Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Analysis View Filter"; Code[10])
        {
            Caption = 'Analysis View Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Analysis View".Code WHERE("Analysis Area" = FIELD("Analysis Area Filter"));
        }
        field(71; "Dimension 1 Filter"; Code[20])
        {
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(72; "Dimension 2 Filter"; Code[20])
        {
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(73; "Dimension 3 Filter"; Code[20])
        {
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(80; "Analysis - Quantity"; Decimal)
        {
            CalcFormula = Sum("Item Analysis View Entry".Quantity WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                         "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                         "Item No." = FIELD("Item Filter"),
                                                                         "Location Code" = FIELD("Location Filter"),
                                                                         "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                         "Posting Date" = FIELD("Date Filter"),
                                                                         "Source Type" = FIELD("Source Type Filter"),
                                                                         "Source No." = FIELD("Source No. Filter"),
                                                                         "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                         "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(81; "Analysis - Invoiced Quantity"; Decimal)
        {
            CalcFormula = Sum("Item Analysis View Entry"."Invoiced Quantity" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                    "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                    "Item No." = FIELD("Item Filter"),
                                                                                    "Location Code" = FIELD("Location Filter"),
                                                                                    "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                    "Posting Date" = FIELD("Date Filter"),
                                                                                    "Source Type" = FIELD("Source Type Filter"),
                                                                                    "Source No." = FIELD("Source No. Filter"),
                                                                                    "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                    "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(82; "Analysis - Sales Amt. (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Entry"."Sales Amount (Actual)" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                        "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                        "Item No." = FIELD("Item Filter"),
                                                                                        "Location Code" = FIELD("Location Filter"),
                                                                                        "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                        "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                        "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                        "Posting Date" = FIELD("Date Filter"),
                                                                                        "Source Type" = FIELD("Source Type Filter"),
                                                                                        "Source No." = FIELD("Source No. Filter"),
                                                                                        "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                        "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Sales Amt. (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "Analysis - Sales Amt. (Exp)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Entry"."Sales Amount (Expected)" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                          "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                          "Item No." = FIELD("Item Filter"),
                                                                                          "Location Code" = FIELD("Location Filter"),
                                                                                          "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                          "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                          "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                          "Posting Date" = FIELD("Date Filter"),
                                                                                          "Source Type" = FIELD("Source Type Filter"),
                                                                                          "Source No." = FIELD("Source No. Filter"),
                                                                                          "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                          "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Sales Amt. (Exp)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Analysis - Cost Amt. (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Entry"."Cost Amount (Actual)" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                       "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                       "Item No." = FIELD("Item Filter"),
                                                                                       "Location Code" = FIELD("Location Filter"),
                                                                                       "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                       "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                       "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                       "Posting Date" = FIELD("Date Filter"),
                                                                                       "Source Type" = FIELD("Source Type Filter"),
                                                                                       "Source No." = FIELD("Source No. Filter"),
                                                                                       "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                       "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Cost Amt. (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Analysis - Cost Amt. (Exp)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Entry"."Cost Amount (Expected)" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                         "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                         "Item No." = FIELD("Item Filter"),
                                                                                         "Location Code" = FIELD("Location Filter"),
                                                                                         "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                         "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                         "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                         "Posting Date" = FIELD("Date Filter"),
                                                                                         "Source Type" = FIELD("Source Type Filter"),
                                                                                         "Source No." = FIELD("Source No. Filter"),
                                                                                         "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                         "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis - Cost Amt. (Exp)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(86; "Analysis CostAmt.(Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Entry"."Cost Amount (Non-Invtbl.)" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                            "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                            "Item No." = FIELD("Item Filter"),
                                                                                            "Location Code" = FIELD("Location Filter"),
                                                                                            "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                            "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                            "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                            "Posting Date" = FIELD("Date Filter"),
                                                                                            "Source Type" = FIELD("Source Type Filter"),
                                                                                            "Source No." = FIELD("Source No. Filter"),
                                                                                            "Item Ledger Entry Type" = FIELD("Item Ledger Entry Type Filter"),
                                                                                            "Entry Type" = FIELD("Entry Type Filter")));
            Caption = 'Analysis CostAmt.(Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Analysis - Budgeted Quantity"; Decimal)
        {
            CalcFormula = Sum("Item Analysis View Budg. Entry".Quantity WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                               "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                               "Budget Name" = FIELD("Budget Filter"),
                                                                               "Item No." = FIELD("Item Filter"),
                                                                               "Location Code" = FIELD("Location Filter"),
                                                                               "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                               "Posting Date" = FIELD("Date Filter"),
                                                                               "Source Type" = FIELD("Source Type Filter"),
                                                                               "Source No." = FIELD("Source No. Filter")));
            Caption = 'Analysis - Budgeted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(92; "Analysis - Budgeted Sales Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Budg. Entry"."Sales Amount" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                     "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                     "Budget Name" = FIELD("Budget Filter"),
                                                                                     "Item No." = FIELD("Item Filter"),
                                                                                     "Location Code" = FIELD("Location Filter"),
                                                                                     "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                     "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                     "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                     "Posting Date" = FIELD("Date Filter"),
                                                                                     "Source Type" = FIELD("Source Type Filter"),
                                                                                     "Source No." = FIELD("Source No. Filter")));
            Caption = 'Analysis - Budgeted Sales Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(93; "Analysis - Budgeted Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Item Analysis View Budg. Entry"."Cost Amount" WHERE("Analysis Area" = FIELD("Analysis Area Filter"),
                                                                                    "Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                    "Budget Name" = FIELD("Budget Filter"),
                                                                                    "Item No." = FIELD("Item Filter"),
                                                                                    "Location Code" = FIELD("Location Filter"),
                                                                                    "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                    "Posting Date" = FIELD("Date Filter"),
                                                                                    "Source Type" = FIELD("Source Type Filter"),
                                                                                    "Source No." = FIELD("Source No. Filter")));
            Caption = 'Analysis - Budgeted Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

