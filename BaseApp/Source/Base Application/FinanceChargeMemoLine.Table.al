table 303 "Finance Charge Memo Line"
{
    Caption = 'Finance Charge Memo Line';

    fields
    {
        field(1; "Finance Charge Memo No."; Code[20])
        {
            Caption = 'Finance Charge Memo No.';
            TableRelation = "Finance Charge Memo Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Finance Charge Memo Line"."Line No." WHERE("Finance Charge Memo No." = FIELD("Finance Charge Memo No."));
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Customer Ledger Entry';
            OptionMembers = " ","G/L Account","Customer Ledger Entry";

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    FinChrgMemoLine := Rec;
                    Init;
                    Type := FinChrgMemoLine.Type;
                    GetFinChrgMemoHeader;
                    DeleteDtldFinChargeMemoLn; // NAVCZ
                end;
            end;
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                SetCustLedgEntryView;
                if CustLedgEntry.Get("Entry No.") then;
                LookupCustLedgEntry;
            end;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                TestField("Attached to Line No.", 0);
                GetFinChrgMemoHeader;
                CustLedgEntry.Get("Entry No.");
                case FinChrgTerms."Interest Calculation" of
                    FinChrgTerms."Interest Calculation"::"Open Entries":
                        CustLedgEntry.TestField(Open, true);
                    FinChrgTerms."Interest Calculation"::"Closed Entries":
                        CustLedgEntry.TestField(Open, false);
                end;
                CustLedgEntry.TestField("Customer No.", FinChrgMemoHeader."Customer No.");
                CustLedgEntry.TestField("On Hold", '');
                if CustLedgEntry."Currency Code" <> FinChrgMemoHeader."Currency Code" then
                    Error(
                      Text000,
                      FinChrgMemoHeader.FieldCaption("Currency Code"),
                      FinChrgMemoHeader.TableCaption, CustLedgEntry.TableCaption);
                "Posting Date" := CustLedgEntry."Posting Date";
                "Document Date" := CustLedgEntry."Document Date";
                "Due Date" := CustLedgEntry."Due Date";
                "Document Type" := CustLedgEntry."Document Type";
                "Document No." := CustLedgEntry."Document No.";
                Description := CustLedgEntry.Description;
                CustLedgEntry.SetFilter("Date Filter", '..%1', FinChrgMemoHeader."Document Date");
                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                "Original Amount" := CustLedgEntry.Amount;
                "Remaining Amount" := CustLedgEntry."Remaining Amount";
                CalcFinChrg;
            end;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                Validate("Document No.");
            end;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                LookupDocNo;
            end;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                "Entry No." := 0;
                DeleteDtldFinChargeMemoLn; // NAVCZ
                if "Document No." <> '' then begin
                    SetCustLedgEntryView;
                    if "Document Type" <> "Document Type"::" " then
                        CustLedgEntry.SetRange("Document Type", "Document Type");
                    CustLedgEntry.SetRange("Document No.", "Document No.");
                    if CustLedgEntry.FindFirst then
                        Validate("Entry No.", CustLedgEntry."Entry No.")
                    else
                        Error(Text004, Format(Type), FieldCaption("Document No."), "Document No.");
                end;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
            Editable = false;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account";

            trigger OnValidate()
            begin
                if "No." <> '' then
                    case Type of
                        Type::" ":
                            begin
                                StdTxt.Get("No.");
                                Description := StdTxt.Description;
                            end;
                        Type::"Customer Ledger Entry":
                            begin
                                FinChrgMemoLine.Type := FinChrgMemoLine.Type::" ";
                                FinChrgMemoLine2.Type := FinChrgMemoLine2.Type::"G/L Account";
                                Error(
                                  Text001,
                                  FieldCaption(Type), FinChrgMemoLine.Type, FinChrgMemoLine2.Type);
                            end;
                        Type::"G/L Account":
                            begin
                                GLAcc.Get("No.");
                                GLAcc.CheckGLAcc;
                                if not "System-Created Entry" then
                                    GLAcc.TestField("Direct Posting", true);
                                GLAcc.TestField("Gen. Prod. Posting Group");
                                Description := GLAcc.Name;
                                GetFinChrgMemoHeader;
                                "Tax Group Code" := GLAcc."Tax Group Code";
                                Validate("Gen. Prod. Posting Group", GLAcc."Gen. Prod. Posting Group");
                                Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");
                            end;
                    end;
            end;
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if Type = Type::" " then begin
                    FinChrgMemoLine.Type := Type::"G/L Account";
                    FinChrgMemoLine2.Type := Type::"Customer Ledger Entry";
                    Error(
                      Text001,
                      FieldCaption(Type), FinChrgMemoLine.Type, FinChrgMemoLine2.Type);
                end;
                if Type = Type::"Customer Ledger Entry" then
                    TestField("Attached to Line No.", 0);
                GetFinChrgMemoHeader;
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT",
                  "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" :=
                          Round(Amount * "VAT %" / 100, Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                FinChrgMemoHeader."Tax Area Code", "Tax Group Code", FinChrgMemoHeader."Tax Liable",
                                FinChrgMemoHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
            end;
        }
        field(17; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                TestField("Entry No.");
                CalcFinChrg;
            end;
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(19; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "VAT Calculation Type"; enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                GetFinChrgMemoHeader;
                VATPostingSetup.Get(FinChrgMemoHeader."VAT Bus. Posting Group", "VAT Prod. Posting Group");
                OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(VATPostingSetup, Rec);
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT %" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            TestField(Type, Type::"G/L Account");
                            TestField("No.", VATPostingSetup.GetSalesAccount(false));
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                FinChrgMemoHeader."Tax Area Code", "Tax Group Code", FinChrgMemoHeader."Tax Liable",
                                FinChrgMemoHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                Validate(Amount);
            end;
        }
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(25; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Finance Charge Memo Line,Beginning Text,Ending Text,Rounding';
            OptionMembers = "Finance Charge Memo Line","Beginning Text","Ending Text",Rounding;
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(11761; Days; Integer)
        {
            Caption = 'Days';
        }
        field(11762; "Multiple Interest Rate"; Decimal)
        {
            Caption = 'Multiple Interest Rate';
        }
        field(11763; "Interests Amount"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Detailed Fin. Charge Memo Line"."Interest Amount" WHERE("Finance Charge Memo No." = FIELD("Finance Charge Memo No."),
                                                                                        "Fin. Charge. Memo Line No." = FIELD("Line No.")));
            Caption = 'Interests Amount';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Finance Charge Memo No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Finance Charge Memo No.", Type, "Detailed Interest Rates Entry")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Finance Charge Memo No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
        FinChrgMemoLine.DeleteAll();
        // NAVCZ
        DtldFinChargeMemoLine.Reset();
        DtldFinChargeMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        DtldFinChargeMemoLine.SetRange("Fin. Charge. Memo Line No.", "Line No.");
        DtldFinChargeMemoLine.DeleteAll();
        // NAVCZ
    end;

    trigger OnInsert()
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinChrgMemoHeader.Get("Finance Charge Memo No.");
        if Type = Type::"Customer Ledger Entry" then
            TestField("Attached to Line No.", 0);
        "Attached to Line No." := 0;
    end;

    trigger OnModify()
    begin
        TestField("System-Created Entry", false);
    end;

    var
        Text000: Label 'The %1 on the %2 and the %3 must be the same.';
        Text001: Label '%1 must be %2 or %3.';
        Text002: Label 'Document';
        CustLedgEntry2: Record "Cust. Ledger Entry";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        FinChrgMemoLine2: Record "Finance Charge Memo Line";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        StdTxt: Record "Standard Text";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        AutoFormat: Codeunit "Auto Format";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        InterestCalcDate: Date;
        DocTypeText: Text[30];
        Text004: Label 'There is no open %1 with %2 %3.';
        ClosedatDate: Date;
        SalesSetup: Record "Sales & Receivables Setup";
        DtldFinChargeMemoLine: Record "Detailed Fin. Charge Memo Line";
        GLSetup: Record "General Ledger Setup";
        DtldLineNo: Integer;

    local procedure CalcFinChrg()
    var
        DtldCLE: Record "Detailed Cust. Ledg. Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        InterestStartDate: Date;
        BaseAmount: Decimal;
        LineFee: Decimal;
        MultipleInterestCalcLine: Record "Multiple Interest Calc. Line" temporary;
        OriginalInterestRate: Record "Multiple Interest Rate";
    begin
        OnBeforeCalcFinCharge(Rec, FinChrgMemoHeader);

        GetFinChrgMemoHeader;
        // NAVCZ
        GLSetup.Get();
        SalesSetup.Get();
        // NAVCZ
        Amount := 0;
        "VAT Amount" := 0;
        "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
        "Gen. Prod. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        "Interest Rate" := 0;
        CustLedgEntry.Get("Entry No.");
        if CustLedgEntry."On Hold" <> '' then
            exit;

        "Interest Rate" := FinChrgTerms."Interest Rate";
        case FinChrgTerms."Interest Calculation Method" of
            FinChrgTerms."Interest Calculation Method"::"Average Daily Balance":
                begin
                    FinChrgTerms.TestField("Interest Period (Days)");
                    ReminderEntry.SetCurrentKey("Customer Entry No.");
                    ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::"Finance Charge Memo");
                    ReminderEntry.SetRange(Canceled, false);
                    InterestCalcDate := CustLedgEntry."Due Date";
                    if ReminderEntry.FindLast then
                        InterestCalcDate := ReminderEntry."Document Date";
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
                    ReminderEntry.SetRange("Interest Posted", true);
                    if ReminderEntry.FindLast then
                        if ReminderEntry."Document Date" > InterestCalcDate then
                            InterestCalcDate := ReminderEntry."Document Date";
                    // NAVCZ
                    if FinChrgMemoHeader."Document Date" < InterestCalcDate then
                        InterestCalcDate := FinChrgMemoHeader."Document Date";
                    // NAVCZ
                    if CalcDate(FinChrgTerms."Grace Period", "Due Date") < FinChrgMemoHeader."Document Date" then begin
                        DtldCLE.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                        DtldCLE.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
                        DtldCLE.SetFilter("Entry Type", '%1|%2',
                          DtldCLE."Entry Type"::"Initial Entry",
                          DtldCLE."Entry Type"::Application);
                        DtldCLE.SetRange("Posting Date", 0D, FinChrgMemoHeader."Document Date");
                        if DtldCLE.Find('-') then begin
                            FinChrgTerms.FindMultipleInterestRate(CustLedgEntry."Due Date", OriginalInterestRate); // NAVCZ
                            repeat
                                if DtldCLE."Entry Type" = DtldCLE."Entry Type"::"Initial Entry" then
                                    InterestStartDate := CustLedgEntry."Due Date"
                                else
                                    InterestStartDate := DtldCLE."Posting Date";

                                if DtldCLE."Entry Type" = DtldCLE."Entry Type"::"Initial Entry" then
                                    if not FinChrgTerms."Add. Line Fee in Interest" then
                                        if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Reminder then
                                            if IssuedReminderHeader.Get(CustLedgEntry."Document No.") then begin
                                                IssuedReminderHeader.CalcFields("Add. Fee per Line");
                                                LineFee := IssuedReminderHeader."Add. Fee per Line" + IssuedReminderHeader.CalculateLineFeeVATAmount;
                                                DtldCLE.Amount -= LineFee;
                                                if DtldCLE.Amount < 0 then
                                                    DtldCLE.Amount := 0;
                                            end;

                                // NAVCZ
                                if FinChrgMemoHeader."Document Date" < InterestStartDate then
                                    InterestStartDate := FinChrgMemoHeader."Document Date";
                                // NAVCZ
                                if InterestCalcDate > InterestStartDate then
                                    InterestStartDate := InterestCalcDate;
                                // NAVCZ
                                DtldLineNo := 0;
                                MultipleInterestCalcLine.DeleteAll();
                                if InterestStartDate < FinChrgMemoHeader."Document Date" then
                                    FinChrgTerms.SetRatesForCalc(InterestStartDate, FinChrgMemoHeader."Document Date", MultipleInterestCalcLine);
                                if MultipleInterestCalcLine.Find('-') then begin
                                    repeat
                                        DtldLineNo := DtldLineNo + 1;
                                        DtldFinChargeMemoLine.Init();
                                        DtldFinChargeMemoLine."Finance Charge Memo No." := FinChrgMemoHeader."No.";
                                        DtldFinChargeMemoLine."Fin. Charge. Memo Line No." := "Line No.";
                                        DtldFinChargeMemoLine."Detailed Customer Entry No." := DtldCLE."Entry No.";
                                        DtldFinChargeMemoLine."Line No." := DtldLineNo;
                                        DtldFinChargeMemoLine.Days := MultipleInterestCalcLine.Days;
                                        if OriginalInterestRate."Use Due Date Interest Rate" then
                                            DtldFinChargeMemoLine."Interest Rate" := OriginalInterestRate."Interest Rate"
                                        else
                                            DtldFinChargeMemoLine."Interest Rate" := MultipleInterestCalcLine."Interest Rate";

                                        if MultipleInterestCalcLine."Rate Factor" <> 0 then
                                            DtldFinChargeMemoLine."Interest Amount" :=
                                              Round(
                                                DtldCLE.Amount * DtldFinChargeMemoLine."Interest Rate" *
                                                MultipleInterestCalcLine.Days / MultipleInterestCalcLine."Rate Factor",
                                                Currency."Amount Rounding Precision")
                                        else
                                            DtldFinChargeMemoLine."Interest Amount" := 0;
                                        DtldFinChargeMemoLine."Interest Base Amount" := DtldCLE.Amount;
                                        if DtldFinChargeMemoLine."Interest Amount" <> 0 then
                                            DtldFinChargeMemoLine.Insert();
                                    until MultipleInterestCalcLine.Next() = 0;
                                end;
                                Amount += DtldCLE.Amount * (FinChrgMemoHeader."Document Date" - InterestStartDate); // NAVCZ
                            until DtldCLE.Next() = 0;
                        end;
                    end;

                    BaseAmount := Amount / FinChrgTerms."Interest Period (Days)";
                    // NAVCZ
                    DtldFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader."No.");
                    DtldFinChargeMemoLine.SetRange("Fin. Charge. Memo Line No.", "Line No.");
                    DtldFinChargeMemoLine.CalcSums("Interest Amount");
                    Amount := DtldFinChargeMemoLine."Interest Amount";
                    // NAVCZ

                end;
            FinChrgTerms."Interest Calculation Method"::"Balance Due":
                if CalcDate(FinChrgTerms."Grace Period", "Due Date") < FinChrgMemoHeader."Document Date" then begin
                    Amount := "Remaining Amount" * "Interest Rate" / 100;
                    BaseAmount := "Remaining Amount";
                end;
        end;

        if FinChrgTerms."Line Description" <> '' then begin
            DocTypeText := DelChr(Format("Document Type"), '<');
            if DocTypeText = '' then
                DocTypeText := Text002;
            Description :=
              CopyStr(
                StrSubstNo(
                  FinChrgTerms."Line Description",
                  CustLedgEntry.Description,
                  DocTypeText,
                  "Document No.",
                  "Interest Rate",
                  Format("Original Amount", 0, AutoFormat.ResolveAutoFormat(1, FinChrgMemoHeader."Currency Code")),
                  Format(BaseAmount, 0, AutoFormat.ResolveAutoFormat(1, FinChrgMemoHeader."Currency Code")),
                  "Due Date",
                  FinChrgMemoHeader."Currency Code"),
                1,
                MaxStrLen(Description));
        end;

        if Amount <> 0 then begin
            CustPostingGr.Get(FinChrgMemoHeader."Customer Posting Group");
            GLAcc.Get(CustPostingGr.GetInterestAccount);
            GLAcc.TestField("Gen. Prod. Posting Group");
            Validate("Gen. Prod. Posting Group", GLAcc."Gen. Prod. Posting Group");
            Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");
        end;

        OnAfterCalcFinCharge(Rec, FinChrgMemoHeader);
    end;

    procedure CheckAttachedLines(): Boolean
    var
        FinChrgMemoLine: Record "Finance Charge Memo Line";
    begin
        if "Line No." <> 0 then begin
            FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
            FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
            exit(not FinChrgMemoLine.IsEmpty);
        end;
        exit(false);
    end;

    procedure UpdateAttachedLines()
    var
        FinChrgMemoLine: Record "Finance Charge Memo Line";
    begin
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
        FinChrgMemoLine.DeleteAll();
    end;

    local procedure SetCustLedgEntryView()
    begin
        GetFinChrgMemoHeader;
        case FinChrgTerms."Interest Calculation" of
            FinChrgTerms."Interest Calculation"::"Open Entries":
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", FinChrgMemoHeader."Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                end;
            FinChrgTerms."Interest Calculation"::"Closed Entries",
            FinChrgTerms."Interest Calculation"::"All Entries":
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.");
                    CustLedgEntry.SetRange("Customer No.", FinChrgMemoHeader."Customer No.");
                end;
        end;

        OnAfterSetCustLedgEntryView(CustLedgEntry, FinChrgTerms, FinChrgMemoHeader);
    end;

    local procedure LookupCustLedgEntry()
    begin
        GetFinChrgMemoHeader;
        case FinChrgTerms."Interest Calculation" of
            FinChrgTerms."Interest Calculation"::"Open Entries":
                if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then
                    Validate("Entry No.", CustLedgEntry."Entry No.");
            FinChrgTerms."Interest Calculation"::"Closed Entries",
          FinChrgTerms."Interest Calculation"::"All Entries":
                if PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgEntry) = ACTION::LookupOK then
                    Validate("Entry No.", CustLedgEntry."Entry No.");
        end;
    end;

    local procedure GetFinChrgMemoHeader()
    begin
        if "Finance Charge Memo No." <> FinChrgMemoHeader."No." then begin
            FinChrgMemoHeader.Get("Finance Charge Memo No.");
            ProcessFinChrgMemoHeader;
        end;
    end;

    procedure SetFinChrgMemoHeader(var NewFinChrgMemoHeader: Record "Finance Charge Memo Header")
    begin
        FinChrgMemoHeader := NewFinChrgMemoHeader;
        ProcessFinChrgMemoHeader;
    end;

    local procedure ProcessFinChrgMemoHeader()
    begin
        FinChrgMemoHeader.TestField("Customer No.");
        FinChrgMemoHeader.TestField("Document Date");
        FinChrgMemoHeader.TestField("Customer Posting Group");
        FinChrgMemoHeader.TestField("Fin. Charge Terms Code");
        FinChrgTerms.Get(FinChrgMemoHeader."Fin. Charge Terms Code");
        if FinChrgMemoHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(FinChrgMemoHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
    begin
        if "Finance Charge Memo No." = FinChrgMemoHeader."No." then
            exit(FinChrgMemoHeader."Currency Code");

        if FinChrgMemoHeader.Get("Finance Charge Memo No.") then
            exit(FinChrgMemoHeader."Currency Code");

        exit('');
    end;

    procedure CalcClosedatDate() ClosedatDate: Date
    begin
        if CustLedgEntry2.Get(CustLedgEntry."Closed by Entry No.") then
            if CustLedgEntry2."Document Date" > CustLedgEntry."Closed at Date" then
                ClosedatDate := CustLedgEntry2."Document Date"
            else
                ClosedatDate := CustLedgEntry."Closed at Date";
        CustLedgEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgEntry2.SetRange("Closed by Entry No.", CustLedgEntry."Entry No.");
        if CustLedgEntry2.Find('-') then
            repeat
                if CustLedgEntry2."Document Date" > CustLedgEntry."Closed at Date" then
                    ClosedatDate := CustLedgEntry2."Document Date"
                else
                    ClosedatDate := CustLedgEntry."Closed at Date";
            until CustLedgEntry2.Next() = 0;
    end;

    procedure LookupDocNo()
    begin
        if Type <> Type::"Customer Ledger Entry" then
            exit;
        SetCustLedgEntryView;
        if "Document Type" <> "Document Type"::" " then
            CustLedgEntry.SetRange("Document Type", "Document Type");
        if "Document No." <> '' then
            CustLedgEntry.SetRange("Document No.", "Document No.");
        if CustLedgEntry.FindFirst then;
        CustLedgEntry.SetRange("Document Type");
        CustLedgEntry.SetRange("Document No.");
        LookupCustLedgEntry;
    end;

    [Scope('OnPrem')]
    procedure DeleteDtldFinChargeMemoLn()
    begin
        // NAVCZ
        DtldFinChargeMemoLine.Reset();
        DtldFinChargeMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        DtldFinChargeMemoLine.SetRange("Fin. Charge. Memo Line No.", "Line No.");
        DtldFinChargeMemoLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCalcFinCharge(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeCalcFinCharge(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryView(var CustLedgEntry: Record "Cust. Ledger Entry"; FinChrgTerms: Record "Finance Charge Terms"; FinChrgMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;
}

