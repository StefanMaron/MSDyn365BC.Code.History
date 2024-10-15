table 5612 "FA Depreciation Book"
{
    Caption = 'FA Depreciation Book';
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "Maintenance Ledger Entry" = r;

    fields
    {
        field(1; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            NotBlank = true;
            TableRelation = "Fixed Asset";
        }
        field(2; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            NotBlank = true;
            TableRelation = "Depreciation Book";
        }
        field(3; "Depreciation Method"; Option)
        {
            Caption = 'Depreciation Method';
            OptionCaption = 'Straight-Line,Declining-Balance 1,Declining-Balance 2,DB1/SL,DB2/SL,User-Defined,Manual,SL-RU,DB/SL-RU,DB/SL-RU Tax Group';
            OptionMembers = "Straight-Line","Declining-Balance 1","Declining-Balance 2","DB1/SL","DB2/SL","User-Defined",Manual,"SL-RU","DB/SL-RU","DB/SL-RU Tax Group";

            trigger OnValidate()
            begin
                ModifyDeprFields;
                case "Depreciation Method" of
                    "Depreciation Method"::"SL-RU":
                        begin
                            CalcDeprPeriod;
                            "Declining-Balance %" := 0;
                            "Depreciation Table Code" := '';
                            "First User-Defined Depr. Date" := 0D;
                        end;
                    "Depreciation Method"::"Straight-Line":
                        begin
                            "Declining-Balance %" := 0;
                            "Depreciation Table Code" := '';
                            "First User-Defined Depr. Date" := 0D;
                            "Use DB% First Fiscal Year" := false;
                        end;
                    "Depreciation Method"::"Declining-Balance 1",
                    "Depreciation Method"::"Declining-Balance 2":
                        begin
                            "Straight-Line %" := 0;
                            "No. of Depreciation Years" := 0;
                            "No. of Depreciation Months" := 0;
                            "Fixed Depr. Amount" := 0;
                            "Depreciation Ending Date" := 0D;
                            "Depreciation Table Code" := '';
                            "First User-Defined Depr. Date" := 0D;
                            "Use DB% First Fiscal Year" := false;
                        end;
                    "Depreciation Method"::"DB/SL-RU",
                    "Depreciation Method"::"DB1/SL",
                    "Depreciation Method"::"DB2/SL":
                        begin
                            "Depreciation Table Code" := '';
                            "First User-Defined Depr. Date" := 0D;
                        end;
                    "Depreciation Method"::"User-Defined":
                        begin
                            "Straight-Line %" := 0;
                            "No. of Depreciation Years" := 0;
                            "No. of Depreciation Months" := 0;
                            "Fixed Depr. Amount" := 0;
                            "Depreciation Ending Date" := 0D;
                            "Declining-Balance %" := 0;
                            "Use DB% First Fiscal Year" := false;
                        end;
                    "Depreciation Method"::Manual:
                        begin
                            "Straight-Line %" := 0;
                            "No. of Depreciation Years" := 0;
                            "No. of Depreciation Months" := 0;
                            "Fixed Depr. Amount" := 0;
                            "Depreciation Ending Date" := 0D;
                            "Declining-Balance %" := 0;
                            "Depreciation Table Code" := '';
                            "First User-Defined Depr. Date" := 0D;
                            "Use DB% First Fiscal Year" := false;
                        end;
                    "Depreciation Method"::"DB/SL-RU Tax Group":
                        begin
                            FA.Get("FA No.");
                            FA.TestField("Depreciation Group");
                            DeprGroup.Get(FA."Depreciation Group");
                            DeprGroup.TestField("Tax Depreciation Rate");
                            DeprGroup.TestField("Depreciation Factor");
                            TaxRegisterSetup.Get;
                            TaxRegisterSetup.TestField("Use Group Depr. Method from");
                        end;
                end;
                TestHalfYearConventionMethod;
            end;
        }
        field(4; "Depreciation Starting Date"; Date)
        {
            Caption = 'Depreciation Starting Date';
            Editable = true;

            trigger OnValidate()
            begin
                ModifyDeprFields;
                CalcDeprPeriod;
            end;
        }
        field(5; "Straight-Line %"; Decimal)
        {
            Caption = 'Straight-Line %';
            DecimalPlaces = 2 : 8;
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
                if ("Straight-Line %" <> 0) and not LinearMethod then
                    DeprMethodError;
                AdjustLinearMethod("No. of Depreciation Years", "Fixed Depr. Amount");
            end;
        }
        field(6; "No. of Depreciation Years"; Decimal)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Years';
            DecimalPlaces = 2 : 8;
            MinValue = 0;

            trigger OnValidate()
            var
                DeprBook2: Record "Depreciation Book";
            begin
                DeprBook2.Get("Depreciation Book Code");
                DeprBook2.TestField("Fiscal Year 365 Days", false);

                if "Depreciation Starting Date" <> 0D then begin
                    ModifyDeprFields;
                    if ("No. of Depreciation Years" <> 0) and not LinearMethod then
                        DeprMethodError;

                    "No. of Depreciation Months" := Round("No. of Depreciation Years" * 12, 0.00000001);
                    AdjustLinearMethod("Straight-Line %", "Fixed Depr. Amount");
                    "Depreciation Ending Date" := CalcEndingDate;

                    if "Depreciation Method" = "Depreciation Method"::"DB/SL-RU" then
                        "Declining-Balance %" := Round(100 / "No. of Depreciation Months", 0.00000001);
                end;
            end;
        }
        field(7; "No. of Depreciation Months"; Decimal)
        {
            BlankZero = true;
            Caption = 'No. of Depreciation Months';
            DecimalPlaces = 2 : 8;
            MinValue = 0;

            trigger OnValidate()
            var
                DeprBook2: Record "Depreciation Book";
            begin
                DeprBook2.Get("Depreciation Book Code");
                DeprBook2.TestField("Fiscal Year 365 Days", false);

                ModifyDeprFields;
                if ("No. of Depreciation Months" <> 0) and not LinearMethod then
                    DeprMethodError;

                "No. of Depreciation Years" := Round("No. of Depreciation Months" / 12, 0.00000001);
                AdjustLinearMethod("Straight-Line %", "Fixed Depr. Amount");
                "Depreciation Ending Date" := CalcEndingDate;

                if "Depreciation Method" = "Depreciation Method"::"DB/SL-RU" then
                    "Declining-Balance %" := Round(100 / "No. of Depreciation Months", 0.00000001);
            end;
        }
        field(8; "Fixed Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Fixed Depr. Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
                if ("Fixed Depr. Amount" <> 0) and not LinearMethod then
                    DeprMethodError;
                AdjustLinearMethod("Straight-Line %", "No. of Depreciation Years");
            end;
        }
        field(9; "Declining-Balance %"; Decimal)
        {
            Caption = 'Declining-Balance %';
            DecimalPlaces = 2 : 8;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Declining-Balance %" >= 100 then
                    FieldError("Declining-Balance %", Text001);
                ModifyDeprFields;
                if ("Declining-Balance %" <> 0) and not DecliningMethod then
                    DeprMethodError;
            end;
        }
        field(10; "Depreciation Table Code"; Code[10])
        {
            Caption = 'Depreciation Table Code';
            TableRelation = "Depreciation Table Header";

            trigger OnValidate()
            begin
                ModifyDeprFields;
                if ("Depreciation Table Code" <> '') and not UserDefinedMethod then
                    DeprMethodError;
            end;
        }
        field(11; "Final Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Final Rounding Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(12; "Ending Book Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ending Book Value';
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(13; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(14; "Depreciation Ending Date"; Date)
        {
            Caption = 'Depreciation Ending Date';

            trigger OnValidate()
            begin
                TestField("Depreciation Starting Date");
                if ("Depreciation Ending Date" <> 0D) and not LinearMethod then
                    DeprMethodError;
                ModifyDeprFields;
                CalcDeprPeriod;
            end;
        }
        field(15; "Acquisition Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Acquisition Cost"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Acquisition Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; Depreciation; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST(Depreciation),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Depreciation';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Book Value"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "Part of Book Value" = CONST(true),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Book Value';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Proceeds on Disposal"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Proceeds on Disposal"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Proceeds on Disposal';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Gain/Loss"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Gain/Loss"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Gain/Loss';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Write-Down"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Write-Down"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Write-Down';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; Appreciation; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST(Appreciation),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Appreciation';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Custom 1"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Custom 1"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Custom 1';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Custom 2"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Custom 2"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Custom 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Depreciable Basis"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "Part of Depreciable Basis" = CONST(true),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Depreciable Basis';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST("Salvage Value"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Salvage Value';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Book Value on Disposal"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(Disposal),
                                                              "FA Posting Type" = CONST("Book Value on Disposal"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Book Value on Disposal';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; Maintenance; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Maintenance Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                                       "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                                       "Maintenance Code" = FIELD("Maintenance Code Filter"),
                                                                       "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                                       "FA Location Code" = FIELD("FA Location Code Filter"),
                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                       "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Maintenance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Maintenance Code Filter"; Code[10])
        {
            Caption = 'Maintenance Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Maintenance;
        }
        field(29; "FA Posting Date Filter"; Date)
        {
            Caption = 'FA Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(30; "Acquisition Date"; Date)
        {
            Caption = 'Acquisition Date';
            Editable = false;
        }
        field(31; "G/L Acquisition Date"; Date)
        {
            Caption = 'G/L Acquisition Date';
            Editable = false;
        }
        field(32; "Disposal Date"; Date)
        {
            Caption = 'Disposal Date';
            Editable = false;
        }
        field(33; "Last Acquisition Cost Date"; Date)
        {
            Caption = 'Last Acquisition Cost Date';
            Editable = false;
        }
        field(34; "Last Depreciation Date"; Date)
        {
            Caption = 'Last Depreciation Date';
            Editable = false;
        }
        field(35; "Last Write-Down Date"; Date)
        {
            Caption = 'Last Write-Down Date';
            Editable = false;
        }
        field(36; "Last Appreciation Date"; Date)
        {
            Caption = 'Last Appreciation Date';
            Editable = false;
        }
        field(37; "Last Custom 1 Date"; Date)
        {
            Caption = 'Last Custom 1 Date';
            Editable = false;
        }
        field(38; "Last Custom 2 Date"; Date)
        {
            Caption = 'Last Custom 2 Date';
            Editable = false;
        }
        field(39; "Last Salvage Value Date"; Date)
        {
            Caption = 'Last Salvage Value Date';
            Editable = false;
        }
        field(40; "FA Exchange Rate"; Decimal)
        {
            Caption = 'FA Exchange Rate';
            DecimalPlaces = 4 : 4;
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(41; "Fixed Depr. Amount below Zero"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Fixed Depr. Amount below Zero';
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
                "Depr. below Zero %" := 0;
                if "Fixed Depr. Amount below Zero" > 0 then begin
                    DeprBook.Get("Depreciation Book Code");
                    DeprBook.TestField("Allow Depr. below Zero", true);
                    TestField("Use FA Ledger Check", true);
                end;
            end;
        }
        field(42; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(43; "First User-Defined Depr. Date"; Date)
        {
            Caption = 'First User-Defined Depr. Date';

            trigger OnValidate()
            begin
                ModifyDeprFields;
                if ("First User-Defined Depr. Date" <> 0D) and not UserDefinedMethod then
                    DeprMethodError;
            end;
        }
        field(44; "Use FA Ledger Check"; Boolean)
        {
            Caption = 'Use FA Ledger Check';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Use FA Ledger Check" then begin
                    DeprBook.Get("Depreciation Book Code");
                    DeprBook.TestField("Use FA Ledger Check", false);
                    TestField("Fixed Depr. Amount below Zero", 0);
                    TestField("Depr. below Zero %", 0);
                end;
                ModifyDeprFields;
            end;
        }
        field(45; "Last Maintenance Date"; Date)
        {
            Caption = 'Last Maintenance Date';
            Editable = false;
        }
        field(46; "Depr. below Zero %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Depr. below Zero %';
            DecimalPlaces = 2 : 8;
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
                "Fixed Depr. Amount below Zero" := 0;
                if "Depr. below Zero %" > 0 then begin
                    DeprBook.Get("Depreciation Book Code");
                    DeprBook.TestField("Allow Depr. below Zero", true);
                    TestField("Use FA Ledger Check", true);
                end;
            end;
        }
        field(47; "Projected Disposal Date"; Date)
        {
            Caption = 'Projected Disposal Date';
        }
        field(48; "Projected Proceeds on Disposal"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Projected Proceeds on Disposal';
            MinValue = 0;
        }
        field(50; "Depr. Starting Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Starting Date (Custom 1)';

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(51; "Depr. Ending Date (Custom 1)"; Date)
        {
            Caption = 'Depr. Ending Date (Custom 1)';

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(52; "Accum. Depr. % (Custom 1)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Accum. Depr. % (Custom 1)';
            DecimalPlaces = 2 : 8;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(53; "Depr. This Year % (Custom 1)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Depr. This Year % (Custom 1)';
            DecimalPlaces = 2 : 8;
            MaxValue = 100;
            MinValue = 0;
        }
        field(54; "Property Class (Custom 1)"; Option)
        {
            Caption = 'Property Class (Custom 1)';
            OptionCaption = ' ,Personal Property,Real Property';
            OptionMembers = " ","Personal Property","Real Property";

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(55; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(56; "Main Asset/Component"; Option)
        {
            Caption = 'Main Asset/Component';
            Editable = false;
            OptionCaption = ' ,Main Asset,Component';
            OptionMembers = " ","Main Asset",Component;
        }
        field(57; "Component of Main Asset"; Code[20])
        {
            Caption = 'Component of Main Asset';
            Editable = false;
            TableRelation = "Fixed Asset";
        }
        field(58; "FA Add.-Currency Factor"; Decimal)
        {
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(59; "Use Half-Year Convention"; Boolean)
        {
            Caption = 'Use Half-Year Convention';

            trigger OnValidate()
            begin
                ModifyDeprFields;
                TestHalfYearConventionMethod;
            end;
        }
        field(60; "Use DB% First Fiscal Year"; Boolean)
        {
            Caption = 'Use DB% First Fiscal Year';

            trigger OnValidate()
            begin
                if "Use DB% First Fiscal Year" then
                    if not (("Depreciation Method" = "Depreciation Method"::"DB1/SL") or
                            ("Depreciation Method" = "Depreciation Method"::"DB2/SL"))
                    then
                        DeprMethodError;
            end;
        }
        field(61; "Temp. Ending Date"; Date)
        {
            Caption = 'Temp. Ending Date';
        }
        field(62; "Temp. Fixed Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Temp. Fixed Depr. Amount';
        }
        field(63; "Ignore Def. Ending Book Value"; Boolean)
        {
            Caption = 'Ignore Def. Ending Book Value';

            trigger OnValidate()
            begin
                ModifyDeprFields;
            end;
        }
        field(70; "Default FA Depreciation Book"; Boolean)
        {
            Caption = 'Default FA Depreciation Book';

            trigger OnValidate()
            var
                DefaultFADeprBook: Record "FA Depreciation Book";
            begin
                if not "Default FA Depreciation Book" then
                    exit;

                DefaultFADeprBook.SetRange("FA No.", "FA No.");
                DefaultFADeprBook.SetFilter("Depreciation Book Code", '<>%1', "Depreciation Book Code");
                DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);
                if not DefaultFADeprBook.IsEmpty then
                    FieldError("Default FA Depreciation Book", OnlyOneDefaultDeprBookErr);
            end;
        }
        field(12400; "Depreciated Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter")));
            Caption = 'Depreciated Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12405; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(12406; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(12416; "FA Employee Filter"; Code[20])
        {
            Caption = 'FA Employee Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(12470; "FA Location Code Filter"; Code[10])
        {
            Caption = 'FA Location Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "FA Location";
        }
        field(12471; Quantity; Decimal)
        {
            CalcFormula = Sum ("FA Ledger Entry".Quantity WHERE("FA No." = FIELD("FA No."),
                                                                "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                                "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                                "FA Location Code" = FIELD("FA Location Code Filter"),
                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                "Employee No." = FIELD("FA Employee Filter"),
                                                                "FA Posting Type" = FILTER("Acquisition Cost")));
            Caption = 'Quantity';
            FieldClass = FlowField;
        }
        field(12472; "Initial Acquisition"; Boolean)
        {
            Caption = 'Initial Acquisition';
            Editable = false;
        }
        field(12473; "Initial Acquisition Filter"; Boolean)
        {
            Caption = 'Initial Acquisition Filter';
            Editable = false;
            FieldClass = FlowFilter;
            InitValue = true;
        }
        field(12474; "Initial Acquisition Cost"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = FILTER("Acquisition Cost" | Transfer),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter"),
                                                              "Initial Acquisition" = CONST(true)));
            Caption = 'Initial Acquisition Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17201; "Depreciation Bonus"; Decimal)
        {
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = CONST(Depreciation),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter"),
                                                              "Depr. Bonus" = CONST(true)));
            Caption = 'Depreciation Bonus';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17202; "Depr. Bonus Base Amount"; Decimal)
        {
            CalcFormula = Sum ("FA Ledger Entry".Amount WHERE("FA No." = FIELD("FA No."),
                                                              "Depreciation Book Code" = FIELD("Depreciation Book Code"),
                                                              "FA Posting Category" = CONST(" "),
                                                              "FA Posting Type" = FILTER("Acquisition Cost" | Appreciation),
                                                              "FA Posting Date" = FIELD("FA Posting Date Filter"),
                                                              "FA Location Code" = FIELD("FA Location Code Filter"),
                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                              "Employee No." = FIELD("FA Employee Filter"),
                                                              "Depr. Bonus" = CONST(true)));
            Caption = 'Depr. Bonus Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17203; "Depr. Bonus %"; Decimal)
        {
            Caption = 'Depr. Bonus %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Depr. Bonus %" <> xRec."Depr. Bonus %" then begin
                    CalcFields("Depreciation Bonus");
                    TestField("Depreciation Bonus", 0);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "FA No.", "Depreciation Book Code")
        {
            Clustered = true;
        }
        key(Key2; "Depreciation Book Code", "FA No.")
        {
        }
        key(Key3; "Depreciation Book Code", "Component of Main Asset", "Main Asset/Component")
        {
        }
        key(Key4; "Main Asset/Component", "Depreciation Book Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FAMoveEntries.MoveFAEntries(Rec);
    end;

    trigger OnInsert()
    var
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        "Acquisition Date" := 0D;
        "G/L Acquisition Date" := 0D;
        "Last Acquisition Cost Date" := 0D;
        "Last Salvage Value Date" := 0D;
        "Last Depreciation Date" := 0D;
        "Last Write-Down Date" := 0D;
        "Last Appreciation Date" := 0D;
        "Last Custom 1 Date" := 0D;
        "Last Custom 2 Date" := 0D;
        "Disposal Date" := 0D;
        "Last Maintenance Date" := 0D;
        LockTable;
        FA.LockTable;
        DeprBook.LockTable;
        FA.Get("FA No.");
        DeprBook.Get("Depreciation Book Code");
        Description := FA.Description;
        "Main Asset/Component" := FA."Main Asset/Component";
        "Component of Main Asset" := FA."Component of Main Asset";
        if ("No. of Depreciation Years" <> 0) or ("No. of Depreciation Months" <> 0) then
            DeprBook.TestField("Fiscal Year 365 Days", false);
        if TaxRegisterSetup.Get then
            if "Depreciation Book Code" = TaxRegisterSetup."Tax Depreciation Book" then
                "Depr. Bonus %" := TaxRegisterSetup."Default Depr. Bonus %";
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        LockTable;
        DeprBook.LockTable;
        DeprBook.Get("Depreciation Book Code");
        if ("No. of Depreciation Years" <> 0) or ("No. of Depreciation Months" <> 0) then
            DeprBook.TestField("Fiscal Year 365 Days", false);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'must not be 100';
        Text002: Label '%1 is later than %2.';
        Text003: Label 'must not be %1';
        Text004: Label 'untitled';
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DeprGroup: Record "Depreciation Group";
        TaxRegisterSetup: Record "Tax Register Setup";
        FAMoveEntries: Codeunit "FA MoveEntries";
        FADateCalc: Codeunit "FA Date Calculation";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        OnlyOneDefaultDeprBookErr: Label 'Only one fixed asset depreciation book can be marked as the default book';

    local procedure AdjustLinearMethod(var Amount1: Decimal; var Amount2: Decimal)
    begin
        Amount1 := 0;
        Amount2 := 0;
        if "No. of Depreciation Years" = 0 then begin
            "No. of Depreciation Months" := 0;
            "Depreciation Ending Date" := 0D;
        end;
    end;

    local procedure ModifyDeprFields()
    begin
        if ("Last Depreciation Date" > 0D) or
           ("Last Write-Down Date" > 0D) or
           ("Last Appreciation Date" > 0D) or
           ("Last Custom 1 Date" > 0D) or
           ("Last Custom 2 Date" > 0D) or
           ("Disposal Date" > 0D)
        then begin
            DeprBook.Get("Depreciation Book Code");
            DeprBook.TestField("Allow Changes in Depr. Fields", true);
        end;
    end;

    procedure CalcDeprPeriod()
    var
        DeprBook2: Record "Depreciation Book";
    begin
        if ("No. of Depreciation Years" <> 0) or ("No. of Depreciation Months" <> 0) then begin
            if "Depreciation Starting Date" = 0D then
                "Depreciation Ending Date" := 0D
            else begin
                if ("Depreciation Method" = "Depreciation Method"::"SL-RU") or
                  ("Depreciation Method" = "Depreciation Method"::"DB/SL-RU") then
                    "Depreciation Starting Date" := CalcDate('<-1M + CM +1D>', "Depreciation Starting Date");
                "Depreciation Ending Date" := CalcEndingDate;
                AdjustLinearMethod("Straight-Line %", "Fixed Depr. Amount");
            end;
        end else begin
            if "Depreciation Starting Date" = 0D then begin
                "Depreciation Ending Date" := 0D;
                "No. of Depreciation Years" := 0;
                "No. of Depreciation Months" := 0;
            end;
            if ("Depreciation Starting Date" = 0D) or ("Depreciation Ending Date" = 0D) then begin
                "No. of Depreciation Years" := 0;
                "No. of Depreciation Months" := 0;
            end else begin
                if "Depreciation Starting Date" > "Depreciation Ending Date" then
                    Error(
                      Text002,
                      FieldCaption("Depreciation Starting Date"), FieldCaption("Depreciation Ending Date"));
                DeprBook2.Get("Depreciation Book Code");
                if DeprBook2."Fiscal Year 365 Days" then begin
                    "No. of Depreciation Months" := 0;
                    "No. of Depreciation Years" := 0;
                end;
                if not DeprBook2."Fiscal Year 365 Days" then begin
                    "No. of Depreciation Months" :=
                      DepreciationCalc.DeprDays("Depreciation Starting Date", "Depreciation Ending Date", false) / 30;
                    "No. of Depreciation Months" := Round("No. of Depreciation Months", 0.00000001);
                    "No. of Depreciation Years" := Round("No. of Depreciation Months" / 12, 0.00000001);
                end;
                "Straight-Line %" := 0;
                "Fixed Depr. Amount" := 0;
            end;
            if not DeprBook2."Fiscal Year 365 Days" then begin
                "No. of Depreciation Months" :=
                  DepreciationCalc.DeprDays("Depreciation Starting Date", "Depreciation Ending Date", false) / 30;
                "No. of Depreciation Months" := Round("No. of Depreciation Months", 0.00000001);
                "No. of Depreciation Years" := Round("No. of Depreciation Months" / 12, 0.00000001);
            end;
            "Straight-Line %" := 0;
            "Fixed Depr. Amount" := 0;
        end;
    end;

    local procedure CalcEndingDate(): Date
    var
        EndingDate: Date;
    begin
        if "No. of Depreciation Years" = 0 then
            exit(0D);
        if "Depreciation Starting Date" = 0D then
            exit(0D);
        EndingDate := FADateCalc.CalculateDate(
            "Depreciation Starting Date", Round("No. of Depreciation Years" * 360, 1), false);
        EndingDate := DepreciationCalc.Yesterday(EndingDate, false);
        if EndingDate < "Depreciation Starting Date" then
            EndingDate := "Depreciation Starting Date";
        exit(EndingDate);
    end;

    procedure GetExchangeRate(): Decimal
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get("Depreciation Book Code");
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            exit(0);
        if "FA Exchange Rate" > 0 then
            exit("FA Exchange Rate");
        exit(DeprBook."Default Exchange Rate");
    end;

    local procedure LinearMethod(): Boolean
    begin
        exit(
          "Depreciation Method" in
          ["Depreciation Method"::"Straight-Line",
           "Depreciation Method"::"DB1/SL",
           "Depreciation Method"::"DB2/SL",
           "Depreciation Method"::"SL-RU",
           "Depreciation Method"::"DB/SL-RU",
           "Depreciation Method"::"DB/SL-RU Tax Group"]);
    end;

    local procedure DecliningMethod(): Boolean
    begin
        exit(
          "Depreciation Method" in
          ["Depreciation Method"::"Declining-Balance 1",
           "Depreciation Method"::"Declining-Balance 2",
           "Depreciation Method"::"DB1/SL",
           "Depreciation Method"::"DB2/SL",
           "Depreciation Method"::"DB/SL-RU",
           "Depreciation Method"::"DB/SL-RU Tax Group"]);
    end;

    local procedure UserDefinedMethod(): Boolean
    begin
        exit("Depreciation Method" = "Depreciation Method"::"User-Defined");
    end;

    local procedure TestHalfYearConventionMethod()
    begin
        if "Depreciation Method" in
           ["Depreciation Method"::"Declining-Balance 2",
            "Depreciation Method"::"DB2/SL",
            "Depreciation Method"::"User-Defined"]
        then
            TestField("Use Half-Year Convention", false);
    end;

    local procedure DeprMethodError()
    begin
        FieldError("Depreciation Method", StrSubstNo(Text003, "Depreciation Method"));
    end;

    procedure Caption(): Text
    var
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
    begin
        if "FA No." = '' then
            exit(Text004);
        FA.Get("FA No.");
        DeprBook.Get("Depreciation Book Code");
        exit(
          StrSubstNo(
            '%1 %2 %3 %4', "FA No.", FA.Description, "Depreciation Book Code", DeprBook.Description));
    end;

    procedure DrillDownOnBookValue()
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        if "Disposal Date" > 0D then
            ShowBookValueAfterDisposal
        else begin
            SetBookValueFiltersOnFALedgerEntry(FALedgEntry);
            PAGE.Run(0, FALedgEntry);
        end;
    end;

    procedure ShowBookValueAfterDisposal()
    var
        TempFALedgEntry: Record "FA Ledger Entry" temporary;
        FALedgEntry: Record "FA Ledger Entry";
    begin
        if "Disposal Date" > 0D then begin
            Clear(TempFALedgEntry);
            TempFALedgEntry.DeleteAll;
            TempFALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            DepreciationCalc.SetFAFilter(FALedgEntry, "FA No.", "Depreciation Book Code", false);
            with FALedgEntry do begin
                if Find('-') then
                    repeat
                        if (("FA Posting Category" = "FA Posting Category"::Disposal) and
                            ("FA Posting Type" <> "FA Posting Type"::"Book Value on Disposal") and
                            ("FA Posting Type" <> "FA Posting Type"::"Salvage Value")) or
                           "Part of Book Value"
                        then begin
                            TempFALedgEntry := FALedgEntry;
                            TempFALedgEntry.Insert;
                        end;
                    until Next = 0;
                TempFALedgEntry.SetRange("FA No.", TempFALedgEntry."FA No.");
                TempFALedgEntry.SetRange("Depreciation Book Code", TempFALedgEntry."Depreciation Book Code");
                PAGE.Run(0, TempFALedgEntry);
            end;
        end else begin
            SetBookValueFiltersOnFALedgerEntry(FALedgEntry);
            PAGE.Run(0, FALedgEntry);
        end;
    end;

    procedure CalcBookValue()
    begin
        if "Disposal Date" > 0D then
            "Book Value" := 0
        else
            CalcFields("Book Value");
    end;

    procedure SetBookValueFiltersOnFALedgerEntry(var FALedgEntry: Record "FA Ledger Entry")
    begin
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", "FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
        FALedgEntry.SetRange("Part of Book Value", true);
    end;

    [Scope('OnPrem')]
    procedure GetStatus(FANo: Code[20]; DeprBookCode: Code[10]): Integer
    var
        Status: Option "On Hand",,,Saled,Disposed;
    begin
        Get(FANo, DeprBookCode);
        if "Disposal Date" = 0D then
            Status := Status::"On Hand"
        else begin
            CalcFields("Proceeds on Disposal");
            if "Proceeds on Disposal" = 0 then
                Status := Status::Disposed
            else
                Status := Status::Saled;
        end;
        exit(Status);
    end;

    [Scope('OnPrem')]
    procedure GetLocationAtDate(var LocationCode: Code[10]; var EmployeeNo: Code[20]; AtDate: Date)
    var
        FALedgEntry: Record "FA Ledger Entry";
        Found: Boolean;
    begin
        LocationCode := '';
        EmployeeNo := '';

        if AtDate = 0D then
            exit;

        FALedgEntry.Reset;
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
        FALedgEntry.SetRange("FA No.", "FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
        FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
        FALedgEntry.SetFilter("FA Posting Date", '..%1', AtDate);
        if FALedgEntry.Find('+') then
            repeat
                if FALedgEntry."Debit Amount" > 0 then begin
                    LocationCode := FALedgEntry."FA Location Code";
                    EmployeeNo := FALedgEntry."Employee No.";
                    Found := true;
                end;
            until (FALedgEntry.Next(-1) = 0) or Found;
    end;

    procedure LineIsReadyForAcquisition(FANo: Code[20]): Boolean
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get;
        exit(FADepreciationBook.Get(FANo, FASetup."Default Depr. Book") and FADepreciationBook.RecIsReadyForAcquisition);
    end;

    procedure RecIsReadyForAcquisition(): Boolean
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get;
        if ("Depreciation Book Code" = FASetup."Default Depr. Book") and
           ("FA Posting Group" <> '') and
           ("Depreciation Starting Date" > 0D)
        then begin
            if "Depreciation Method" in
               ["Depreciation Method"::"Straight-Line", "Depreciation Method"::"DB1/SL", "Depreciation Method"::"DB2/SL"]
            then
                exit("No. of Depreciation Years" > 0);
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateBookValue()
    begin
        if "Disposal Date" > 0D then
            "Book Value" := 0;
    end;
}

