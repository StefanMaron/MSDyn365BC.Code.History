table 31001 "Sales Advance Letter Line"
{
    Caption = 'Sales Advance Letter Line';
#if not CLEAN19
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';

    fields
    {
        field(3; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
#if not CLEAN19
            TableRelation = "Sales Advance Letter Header";
#endif
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            TableRelation = "G/L Account";
#if not CLEAN19

            trigger OnValidate()
            begin
                TestField("Amount Invoiced", 0);
            end;
#endif
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
#if not CLEAN19

            trigger OnValidate()
            begin
                if Description <> xRec.Description then
                    TestStatusOpen();
            end;
#endif
        }
        field(12; "Advance Due Date"; Date)
        {
            Caption = 'Advance Due Date';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            begin
                GetLetterHeader();
                if not SalesAdvanceLetterHeadergre."Amounts Including VAT" then begin
                    Validate(Amount);
                    exit;
                end;

                GetCurrency();
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT":
                        "VAT Amount" :=
                            Round("Amount Including VAT" * "VAT %" / (100 + "VAT %"),
                                Currency."Amount Rounding Precision",
                                Currency.VATRoundingDirection());
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" := Amount;
                    "VAT Calculation Type"::"Sales Tax":
                        FieldError("VAT Calculation Type");
                end;

                Amount := "Amount Including VAT" - "VAT Amount";
                "VAT Difference" := 0;
            end;
#endif
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Amount <> xRec.Amount then
                    SalesAdvanceLetterHeadergre.TestField("Amounts Including VAT", false);
                Amount := Round(Amount, Currency."Amount Rounding Precision");

                GetCurrency();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT":
                        "Amount Including VAT" :=
                          Round(
                            Amount * (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "Amount Including VAT" := Amount;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount, StrSubstNo(Text002Err, FieldCaption("VAT Calculation Type"), "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        FieldError("VAT Calculation Type");
                end;

                "VAT Amount" := "Amount Including VAT" - Amount;
            end;
#endif
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Amount Including VAT" <> xRec."Amount Including VAT" then
                    SalesAdvanceLetterHeadergre.TestField("Amounts Including VAT", true);
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");

                Validate("VAT %");
            end;
#endif
        }
        field(31; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(32; "Amount To Link"; Decimal)
        {
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = Normal;
        }
        field(33; "Amount Linked"; Decimal)
        {
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = Normal;
        }
        field(34; "Amount To Invoice"; Decimal)
        {
            Caption = 'Amount To Invoice';
            Editable = false;
        }
        field(35; "Amount Invoiced"; Decimal)
        {
            Caption = 'Amount Invoiced';
            Editable = false;
        }
        field(36; "Amount To Deduct"; Decimal)
        {
            Caption = 'Amount To Deduct';
            Editable = false;
        }
        field(37; "Amount Deducted"; Decimal)
        {
            Caption = 'Amount Deducted';
            Editable = false;
        }
        field(38; "Amount Linked To Journal Line"; Decimal)
        {
            Caption = 'Amount Linked To Journal Line';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();

                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
#endif
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();

                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
#endif
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;
#if not CLEAN19

            trigger OnValidate()
            begin
                CreateDim(DATABASE::Job, "Job No.",
                  DATABASE::"G/L Account", "Advance G/L Account No.");
            end;
#endif
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
#endif
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then begin
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;
            end;
#endif
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    VATPostingSetup.TestField("Sales Advance VAT Account");
                    GLAcc.Get(VATPostingSetup."Sales Advance VAT Account");
                    Validate("No.", GLAcc."No.");
                end;

                TestField("Letter No.");
                SalesAdvanceLetterHeadergre.Get("Letter No.");

                GetLetterHeader();
                CustPostGr.Get(SalesAdvanceLetterHeadergre."Customer Posting Group");
                CustPostGr.TestField("Advance Account");
                Validate("Advance G/L Account No.", CustPostGr."Advance Account");
            end;
#endif
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen();

                TestField("Letter No.");
                SalesAdvanceLetterHeadergre.Get("Letter No.");

                GetLetterHeader();
                "Bill-to Customer No." := SalesAdvanceLetterHeadergre."Bill-to Customer No.";
                "VAT Bus. Posting Group" := SalesAdvanceLetterHeadergre."VAT Bus. Posting Group";
                "Gen. Bus. Posting Group" := SalesAdvanceLetterHeadergre."Gen. Bus. Posting Group";
                "Currency Code" := SalesAdvanceLetterHeadergre."Currency Code";
                "Advance Due Date" := SalesAdvanceLetterHeadergre."Advance Due Date";

                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    VATPostingSetup.TestField("Sales Advance VAT Account");
                    GLAcc.Get(VATPostingSetup."Sales Advance VAT Account");
                    Validate("No.", GLAcc."No.");
                    "VAT %" := VATPostingSetup."VAT %";
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                        "VAT %" := 0;
                    "VAT Identifier" := VATPostingSetup."VAT Identifier";
                    Validate("VAT %");
                end else begin
                    Validate("VAT %", 0);
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
                    "VAT Identifier" := '';
                end;

                CustPostGr.Get(SalesAdvanceLetterHeadergre."Customer Posting Group");
                CustPostGr.TestField("Advance Account");
                Validate("Advance G/L Account No.", CustPostGr."Advance Account");
            end;
#endif
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(120; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Pending Advance Payment,Pending Advance Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Advance Payment","Pending Advance Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
#if not CLEAN19

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
#endif
        }
        field(31015; "Amount To Refund"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            BlankZero = true;
            Caption = 'Amount To Refund';
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Amount To Invoice" + "Amount To Deduct" < "Amount To Refund" then
                    Error(Text003Err, "Letter No.", "Line No.");
            end;
#endif
        }
        field(31016; "Customer Posting Group"; Code[20])
        {
            CalcFormula = Lookup("Sales Advance Letter Header"."Customer Posting Group" WHERE("No." = FIELD("Letter No.")));
            Caption = 'Customer Posting Group';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Customer Posting Group";
        }
        field(31017; "Link Code"; Code[30])
        {
            Caption = 'Link Code';
        }
        field(31018; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation".Amount WHERE(Type = CONST(Sale),
                                                                           "Letter No." = FIELD("Letter No."),
                                                                           "Letter Line No." = FIELD("Line No."),
                                                                           "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31019; "Doc. No. Filter"; Code[20])
        {
            Caption = 'Doc. No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Header"."No.";
        }
        field(31020; "Semifinished Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Semifinished Linked Amount';
        }
        field(31021; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Invoiced Amount" WHERE(Type = CONST(Sale),
                                                                                      "Letter No." = FIELD("Letter No."),
                                                                                      "Letter Line No." = FIELD("Line No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Inv. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Advance G/L Account No."; Code[20])
        {
            Caption = 'Advance G/L Account No.';
            Editable = false;
            TableRelation = "G/L Account";
#if not CLEAN19

            trigger OnValidate()
            begin
                CreateDim(DATABASE::"G/L Account", "Advance G/L Account No.",
                  DATABASE::Job, "Job No.");
            end;
#endif
        }
        field(31023; "Document Linked Ded. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Deducted Amount" WHERE(Type = CONST(Sale),
                                                                                      "Letter No." = FIELD("Letter No."),
                                                                                      "Letter Line No." = FIELD("Line No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31024; "Doc. Linked Amount to Deduct"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Amount To Deduct" WHERE(Type = CONST(Sale),
                                                                                       "Letter No." = FIELD("Letter No."),
                                                                                       "Letter Line No." = FIELD("Line No."),
                                                                                       "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Doc. Linked Amount to Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Letter No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount Including VAT", "Amount To Link", "Amount Linked", "Amount To Invoice", "Amount Invoiced", "Amount To Deduct", "Amount Deducted";
        }
        key(Key2; "Bill-to Customer No.", Status)
        {
        }
        key(Key3; "Link Code")
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    trigger OnDelete()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        TestStatusOpen();

        TestField("Amount Linked", 0);
        SetRange("Doc. No. Filter");
        CalcFields("Document Linked Amount");
        TestField("Document Linked Amount", 0);
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Advance Letter");
        SalesCommentLine.SetRange("No.", "Letter No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        if not SalesCommentLine.IsEmpty() then
            SalesCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
        SalesAdvanceLetterHeadergre.Get("Letter No.");
        "Currency Code" := SalesAdvanceLetterHeadergre."Currency Code";
        "Bill-to Customer No." := SalesAdvanceLetterHeadergre."Bill-to Customer No.";

        LockTable();
    end;

    trigger OnModify()
    begin
        UpdateStatus();
    end;

    trigger OnRename()
    begin
        Error(Text001Err, TableCaption);
    end;

    var
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        Currency: Record Currency;
        SalesAdvanceLetterHeadergre: Record "Sales Advance Letter Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAcc: Record "G/L Account";
        CustPostGr: Record "Customer Posting Group";
        Text001Err: Label 'You cannot rename a %1.';
        Text002Err: Label ' must be 0 when %1 is %2.', Comment = '%1=fieldcaption VAT calculation type;%2=VAT calculation type';
        DimMgt: Codeunit DimensionManagement;
        StatusCheckSuspended: Boolean;
        CurrencyCode: Code[20];
        Text003Err: Label 'Is not possible to refund requested amount on advance letter %1 line no. %2.', Comment = '%1=letter number;%2=letter line number';
        Text004Txt: Label '%1 %2.', Comment = '%1=letter number;%2=letter line number';

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo(Text004Txt, "Letter No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(GlobalDimNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(GlobalDimNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentSheet: Page "Sales Comment Sheet";
    begin
        TestField("Letter No.");
        TestField("Line No.");
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Advance Letter");
        SalesCommentLine.SetRange("No.", "Letter No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        SalesCommentSheet.SetTableView(SalesCommentLine);
        SalesCommentSheet.RunModal();
    end;

    local procedure GetLetterHeader()
    begin
        TestField("Letter No.");

        if true then begin
            SalesAdvanceLetterHeadergre.Get("Letter No.");
            if SalesAdvanceLetterHeadergre."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                SalesAdvanceLetterHeadergre.TestField("Currency Factor");
                Currency.Get(SalesAdvanceLetterHeadergre."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateStatus()
    begin
        Status := Status::Open;
        if ("Amount To Deduct" = 0) and ("Amount Deducted" <> 0) then
            Status := Status::Closed;
        if "Amount To Deduct" <> 0 then
            Status := Status::"Pending Final Invoice";
        if "Amount To Invoice" <> 0 then
            Status := Status::"Pending Advance Invoice";
        if "Amount To Link" <> 0 then
            Status := Status::"Pending Advance Payment";
        if ("Amount To Link" = 0) and ("Amount Linked" = 0) then
            Status := Status::Open;
    end;

    [Scope('OnPrem')]
    procedure UpdateVATOnLines(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        if SalesAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesAdvanceLetterHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();

        with SalesAdvanceLetterLine do begin
            SetRange("Letter No.", SalesAdvanceLetterHeader."No.");

            LockTable();
            if FindSet() then
                repeat
                    VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0);
                    if VATAmountLine.Modified then begin
                        if not TempVATAmountLineRemainder.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0)
                        then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder."VAT Difference" := VATAmountLine."VAT Difference";
                            TempVATAmountLineRemainder.Insert();
                        end;

                        VATAmount :=
                          TempVATAmountLineRemainder."VAT Amount" +
                          VATAmountLine."VAT Amount" *
                          "Amount Including VAT" /
                          VATAmountLine."Line Amount";
                        NewAmountIncludingVAT :=
                          TempVATAmountLineRemainder."Amount Including VAT" +
                          VATAmountLine."Amount Including VAT" *
                          "Amount Including VAT" /
                          VATAmountLine."Line Amount";

                        NewAmount :=
                          Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                          Round(VATAmount, Currency."Amount Rounding Precision");

                        VATDifference :=
                          TempVATAmountLineRemainder."VAT Difference" +
                          VATAmountLine."VAT Difference" * "Amount To Invoice" /
                          VATAmountLine."Amount Including VAT";
                        "VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");

                        "Amount Including VAT" := Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        Amount := NewAmount;
                        "VAT Amount" := VATAmount;

                        Modify();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - "VAT Difference";
                        TempVATAmountLineRemainder.Modify();
                    end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcVATAmountLines(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var VATAmountLine: Record "VAT Amount Line"; var SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var TotalVATToInvoice: Decimal; var TotalVATInvoiced: Decimal)
    var
        SalesAdvanceLetterLine2: Record "Sales Advance Letter Line";
        VATFactor: Decimal;
    begin
        if SalesAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesAdvanceLetterHeader."Currency Code");

        VATAmountLine.DeleteAll();
        SalesAdvanceLetterLine.Init();
        TotalVATToInvoice := 0;
        TotalVATInvoiced := 0;

        with SalesAdvanceLetterLine2 do begin
            SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            if FindSet() then
                repeat
                    IncTotalLine(SalesAdvanceLetterLine, SalesAdvanceLetterLine2);
                    VATFactor := "VAT Amount" / "Amount Including VAT";
                    TotalVATToInvoice :=
                      TotalVATToInvoice + Round("Amount To Invoice" * VATFactor, Currency."Amount Rounding Precision");
                    TotalVATInvoiced :=
                      TotalVATInvoiced + Round("Amount Invoiced" * VATFactor, Currency."Amount Rounding Precision");

                    if not VATAmountLine.Get(
                         "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0)
                    then begin
                        VATAmountLine.Init();
                        VATAmountLine."VAT Identifier" := "VAT Identifier";
                        VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        VATAmountLine."Tax Group Code" := "Tax Group Code";
                        VATAmountLine."VAT %" := "VAT %";
                        VATAmountLine.Modified := false;
                        VATAmountLine.Positive := "Amount Including VAT" >= 0;
                        VATAmountLine.Insert();
                    end;
                    VATAmountLine."VAT Base" := VATAmountLine."VAT Base" + Amount;
                    VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + "VAT Amount";
                    VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + "VAT Amount" - "VAT Difference";
                    VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + "Amount Including VAT";
                    VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + "Amount Including VAT";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference";
                    VATAmountLine."Includes Prepayment" := false;
                    VATAmountLine.Modify();
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure IncTotalLine(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; SalesAdvanceLetterLine2: Record "Sales Advance Letter Line")
    begin
        with SalesAdvanceLetterLine2 do begin
            SalesAdvanceLetterLine.Amount := SalesAdvanceLetterLine.Amount + Amount;
            SalesAdvanceLetterLine."Amount Including VAT" := SalesAdvanceLetterLine."Amount Including VAT" + "Amount Including VAT";
            SalesAdvanceLetterLine."VAT Amount" := SalesAdvanceLetterLine."VAT Amount" + "VAT Amount";
            SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount To Link" + "Amount To Link";
            SalesAdvanceLetterLine."Amount Linked" := SalesAdvanceLetterLine."Amount Linked" + "Amount Linked";
            SalesAdvanceLetterLine."Amount To Invoice" := SalesAdvanceLetterLine."Amount To Invoice" + "Amount To Invoice";
            SalesAdvanceLetterLine."Amount Invoiced" := SalesAdvanceLetterLine."Amount Invoiced" + "Amount Invoiced";
            SalesAdvanceLetterLine."Amount To Deduct" := SalesAdvanceLetterLine."Amount To Deduct" + "Amount To Deduct";
            SalesAdvanceLetterLine."Amount Deducted" := SalesAdvanceLetterLine."Amount Deducted" + "Amount Deducted";
            SalesAdvanceLetterLine."Amount Linked To Journal Line" :=
              SalesAdvanceLetterLine."Amount Linked To Journal Line" + "Amount Linked To Journal Line";
        end;
    end;

    local procedure GetCurrency()
    begin
        GetLetterHeader();
        CurrencyCode := SalesAdvanceLetterHeadergre."Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        GetLetterHeader();
        SalesAdvanceLetterHeadergre.CalcFields(Status);
        SalesAdvanceLetterHeadergre.TestField(Status, SalesAdvanceLetterHeadergre.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure SuspendStatusCheck(SuspendStatusCheckNew: Boolean)
    begin
        StatusCheckSuspended := SuspendStatusCheckNew;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        GetLetterHeader();
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            SalesAdvanceLetterHeadergre."Dimension Set ID", DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure RecalcVATOnLines(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        if SalesAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesAdvanceLetterHeader."Currency Code");

        TempVATAmountLine.DeleteAll();
        VATDifference := 0;

        with SalesAdvanceLetterLine do begin
            SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            if FindSet() then
                repeat
                    if not TempVATAmountLine.Get(
                         "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0)
                    then begin
                        TempVATAmountLine.Init();
                        TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                        TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                        TempVATAmountLine."VAT %" := "VAT %";
                        TempVATAmountLine.Modified := true;
                        TempVATAmountLine.Positive := "Amount Including VAT" >= 0;
                        TempVATAmountLine.Insert();
                    end;
                    TempVATAmountLine."VAT Base" := TempVATAmountLine."VAT Base" + Amount;
                    TempVATAmountLine."VAT Amount" := TempVATAmountLine."VAT Amount" + "VAT Amount";
                    TempVATAmountLine."Calculated VAT Amount" := TempVATAmountLine."Calculated VAT Amount" + "VAT Amount" - "VAT Difference";
                    TempVATAmountLine."Line Amount" := TempVATAmountLine."Line Amount" + "Amount Including VAT";
                    TempVATAmountLine."Amount Including VAT" := TempVATAmountLine."Amount Including VAT" + "Amount Including VAT";
                    TempVATAmountLine."VAT Difference" := TempVATAmountLine."VAT Difference" + "VAT Difference";
                    TempVATAmountLine."Includes Prepayment" := false;
                    TempVATAmountLine.Modify();
                until Next() = 0;
        end;

        if TempVATAmountLine.Find('-') then begin
            repeat
                TempVATAmountLine."VAT Amount" :=
                    Round(TempVATAmountLine."Amount Including VAT" * TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"),
                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                TempVATAmountLine."VAT Base" := TempVATAmountLine."Amount Including VAT" - TempVATAmountLine."VAT Amount";
                TempVATAmountLine.Modify();
            until TempVATAmountLine.Next() = 0;
        end;

        TempVATAmountLineRemainder.DeleteAll();

        with SalesAdvanceLetterLine do begin
            SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
            SetFilter(Amount, '<>0');
            LockTable();
            if FindSet() then
                repeat
                    TempVATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0);
                    if TempVATAmountLine.Modified then begin
                        if not TempVATAmountLineRemainder.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0)
                        then begin
                            TempVATAmountLineRemainder := TempVATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        VATAmount :=
                          TempVATAmountLineRemainder."VAT Amount" +
                          TempVATAmountLine."VAT Amount" *
                          "Amount Including VAT" /
                          TempVATAmountLine."Amount Including VAT";

                        NewAmountIncludingVAT :=
                          TempVATAmountLineRemainder."Amount Including VAT" +
                          TempVATAmountLine."Amount Including VAT" *
                          "Amount Including VAT" /
                          TempVATAmountLine."Line Amount";

                        NewAmount :=
                          Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                          Round(VATAmount, Currency."Amount Rounding Precision");

                        "Amount Including VAT" := Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        Amount := NewAmount;
                        "VAT Amount" := Round(VATAmount, Currency."Amount Rounding Precision");

                        Modify();
                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - "VAT Difference";
                        TempVATAmountLineRemainder.Modify();
                    end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAmountToLinkLCY(): Decimal
    var
        SalesAdvanceLetterHdr: Record "Sales Advance Letter Header";
        CurrExchRate: Record "Currency Exchange Rate";
        Date: Date;
    begin
        SalesAdvanceLetterHdr.Get("Letter No.");
        Date := SalesAdvanceLetterHdr."Document Date";
        if Date = 0D then
            Date := WorkDate();
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCY(Date,
              SalesAdvanceLetterHdr."Currency Code",
              "Amount To Link",
              SalesAdvanceLetterHdr."Currency Factor")));
    end;
#endif
}

