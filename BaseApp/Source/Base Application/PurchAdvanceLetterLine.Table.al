table 31021 "Purch. Advance Letter Line"
{
    Caption = 'Purch. Advance Letter Line';
#if not CLEAN19
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(3; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
#if not CLEAN19
            TableRelation = "Purch. Advance Letter Header";
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
                    TestStatusOpen;
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
                GetLetterHeader;
                if not PurchAdvanceLetterHeadergre."Amounts Including VAT" then begin
                    Validate(Amount);
                    exit;
                end;
                CalcLineAmtIncVAT;
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
                TestStatusOpen;

                if Amount <> xRec.Amount then
                    PurchAdvanceLetterHeadergre.TestField("Amounts Including VAT", false);
                Amount := Round(Amount, Currency."Amount Rounding Precision");

                GetCurrency;
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT":
                        "Amount Including VAT" :=
                          Round(
                            Amount * (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
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
                TestStatusOpen;

                if "Amount Including VAT" <> xRec."Amount Including VAT" then
                    PurchAdvanceLetterHeadergre.TestField("Amounts Including VAT", true);
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
                TestStatusOpen;
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
                TestStatusOpen;
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
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostGr.ValidateVatBusPostingGroup(GenBusPostGr, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostGr."Def. VAT Bus. Posting Group");
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
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostGr.ValidateVatProdPostingGroup(GenProdPostGr, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostGr."Def. VAT Prod. Posting Group");
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
                    VATPostingSetup.TestField("Purch. Advance VAT Account");
                    GLAcc.Get(VATPostingSetup."Purch. Advance VAT Account");
                    Validate("No.", GLAcc."No.");
                end;

                TestField("Letter No.");
                PurchAdvanceLetterHeadergre.Get("Letter No.");
                GetLetterHeader;

                VendPostGr.Get(PurchAdvanceLetterHeadergre."Vendor Posting Group");
                VendPostGr.TestField("Advance Account");
                Validate("Advance G/L Account No.", VendPostGr."Advance Account");
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
                TestStatusOpen;

                TestField("Letter No.");
                PurchAdvanceLetterHeadergre.Get("Letter No.");
                GetLetterHeader;

                "Pay-to Vendor No." := PurchAdvanceLetterHeadergre."Pay-to Vendor No.";
                "VAT Bus. Posting Group" := PurchAdvanceLetterHeadergre."VAT Bus. Posting Group";
                "Gen. Bus. Posting Group" := PurchAdvanceLetterHeadergre."Gen. Bus. Posting Group";
                "Currency Code" := PurchAdvanceLetterHeadergre."Currency Code";
                "Advance Due Date" := PurchAdvanceLetterHeadergre."Advance Due Date";

                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    VATPostingSetup.TestField("Purch. Advance VAT Account");
                    GLAcc.Get(VATPostingSetup."Purch. Advance VAT Account");
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

                VendPostGr.Get(PurchAdvanceLetterHeadergre."Vendor Posting Group");
                VendPostGr.TestField("Advance Account");
                Validate("Advance G/L Account No.", VendPostGr."Advance Account");
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
                GetCurrency;
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT":
                        "VAT Amount To Refund" :=
                            Round("Amount To Refund" * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount To Refund" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount To Refund" := "Amount To Refund";
                    "VAT Calculation Type"::"Sales Tax":
                        ;
                end;

                "VAT Base To Refund" := "Amount To Refund" - "VAT Amount To Refund";
            end;
#endif
        }
#if not CLEAN19
        field(31016; "Vendor Posting Group"; Code[20])
        {
            CalcFormula = Lookup("Purch. Advance Letter Header"."Vendor Posting Group" WHERE("No." = FIELD("Letter No.")));
            Caption = 'Vendor Posting Group';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Vendor Posting Group";
        }
#endif
        field(31017; "Link Code"; Code[30])
        {
            Caption = 'Link Code';
        }
#if not CLEAN19
        field(31018; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation".Amount WHERE(Type = CONST(Purchase),
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
            TableRelation = "Purchase Header"."No.";
        }
#endif
        field(31020; "Semifinished Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Semifinished Linked Amount';
        }
#if not CLEAN19
        field(31021; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Invoiced Amount" WHERE(Type = CONST(Purchase),
                                                                                      "Letter No." = FIELD("Letter No."),
                                                                                      "Letter Line No." = FIELD("Line No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Inv. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
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
#if not CLEAN19
        field(31023; "Document Linked Ded. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Deducted Amount" WHERE(Type = CONST(Purchase),
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
            CalcFormula = Sum("Advance Letter Line Relation"."Amount To Deduct" WHERE(Type = CONST(Purchase),
                                                                                       "Letter No." = FIELD("Letter No."),
                                                                                       "Letter Line No." = FIELD("Line No."),
                                                                                       "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Doc. Linked Amount to Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(31025; "VAT Difference Inv."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Difference Inv.';
        }
        field(31026; "VAT Amount Inv."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount Inv.';
        }
        field(31027; "VAT Correction Inv."; Boolean)
        {
            Caption = 'VAT Correction Inv.';
        }
        field(31028; "VAT Difference Inv. (LCY)"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Difference Inv. (LCY)';
        }
        field(31029; "VAT Base To Refund"; Decimal)
        {
            BlankZero = true;
            Caption = 'VAT Base To Refund';
        }
        field(31030; "VAT Amount To Refund"; Decimal)
        {
            BlankZero = true;
            Caption = 'VAT Amount To Refund';
        }
#if not CLEAN19
        field(31031; "Amount on Payment Order (LCY)"; Decimal)
        {
            CalcFormula = - Sum("Issued Payment Order Line"."Amount (LCY)" WHERE("Letter Type" = CONST(Purchase),
                                                                                 "Letter No." = FIELD("Letter No."),
                                                                                 "Letter Line No." = FIELD("Line No."),
                                                                                 Status = CONST(" ")));
            Caption = 'Amount on Payment Order (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(31032; "VAT Amount Inv. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount Inv. (LCY)';
        }
        field(31033; "Amount To Invoice (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount To Invoice (LCY)';
        }
    }

    keys
    {
        key(Key1; "Letter No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount Including VAT", "Amount To Link", "Amount Linked", "Amount To Invoice", "Amount Invoiced", "Amount To Deduct", "Amount Deducted";
        }
        key(Key2; "Pay-to Vendor No.", Status)
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
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        TestStatusOpen;

        TestField("Amount Linked", 0);
        SetRange("Doc. No. Filter");
        CalcFields("Document Linked Amount");
        TestField("Document Linked Amount", 0);

        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Advance Letter");
        PurchCommentLine.SetRange("No.", "Letter No.");
        PurchCommentLine.SetRange("Document Line No.", "Line No.");
        if not PurchCommentLine.IsEmpty() then
            PurchCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;

        PurchAdvanceLetterHeadergre.Get("Letter No.");
        "Currency Code" := PurchAdvanceLetterHeadergre."Currency Code";
        "Pay-to Vendor No." := PurchAdvanceLetterHeadergre."Pay-to Vendor No.";

        LockTable();
    end;

    trigger OnModify()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        UpdateStatus;

        "VAT Difference Inv." := 0;
        "VAT Difference Inv. (LCY)" := 0;
        "VAT Correction Inv." := false;
        "VAT Amount Inv." := 0;

        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.SetRange("Letter No.", "Letter No.");
        PurchAdvanceLetterLine.SetFilter("Line No.", '<>%1', "Line No.");
        PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv.", 0);
        PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv. (LCY)", 0);
        PurchAdvanceLetterLine.ModifyAll("VAT Correction Inv.", false);
        PurchAdvanceLetterLine.ModifyAll("VAT Amount Inv.", 0);
        PurchAdvanceLetterLine.ModifyAll("VAT Amount Inv. (LCY)", 0);
        PurchAdvanceLetterLine.ModifyAll("Amount To Invoice (LCY)", 0);
    end;

    trigger OnRename()
    begin
        Error(Text001Err, TableCaption);
    end;

    var
        GenBusPostGr: Record "Gen. Business Posting Group";
        GenProdPostGr: Record "Gen. Product Posting Group";
        Currency: Record Currency;
        PurchAdvanceLetterHeadergre: Record "Purch. Advance Letter Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        PurchSetup: Record "Purchases & Payables Setup";
        CurrencyExchRate: Record "Currency Exchange Rate";
        VendPostGr: Record "Vendor Posting Group";
        Text001Err: Label 'You cannot rename a %1.';
        DimMgt: Codeunit DimensionManagement;
        CurrencyCode: Code[20];
        StatusCheckSuspended: Boolean;
        Text002Err: Label ' must be 0 when %1 is %2.', Comment = '%1=fieldcaption VAT calculation type;%2=VAT calculation type';
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
    procedure ValidateShortcutDimCode(GlobDimNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(GlobDimNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentSheet: Page "Purch. Comment Sheet";
    begin
        TestField("Letter No.");
        TestField("Line No.");
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Advance Letter");
        PurchCommentLine.SetRange("No.", "Letter No.");
        PurchCommentLine.SetRange("Document Line No.", "Line No.");
        PurchCommentSheet.SetTableView(PurchCommentLine);
        PurchCommentSheet.RunModal;
    end;

    local procedure GetLetterHeader()
    begin
        if true then begin
            PurchAdvanceLetterHeadergre.Get("Letter No.");
            if PurchAdvanceLetterHeadergre."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                PurchAdvanceLetterHeadergre.TestField("Currency Factor");
                PurchAdvanceLetterHeadergre.TestField("VAT Currency Factor");
                Currency.Get(PurchAdvanceLetterHeadergre."Currency Code");
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
    procedure UpdateVATOnLines(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        if PurchAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchAdvanceLetterHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();

        with PurchAdvanceLetterLine do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            LockTable();
            if FindSet then
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

                        Modify;

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
    procedure CalcVATAmountLines(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var VATAmountLine: Record "VAT Amount Line"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var TotalVATToInvoice: Decimal; var TotalVATInvoiced: Decimal)
    var
        PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line";
        PrevVatAmountLine: Record "VAT Amount Line";
        VATFactor: Decimal;
        VATCorrection: Boolean;
    begin
        if PurchAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchAdvanceLetterHeader."Currency Code");

        VATAmountLine.DeleteAll();
        PurchAdvanceLetterLine.Init();
        TotalVATToInvoice := 0;
        TotalVATInvoiced := 0;
        VATCorrection := false;

        with PurchAdvanceLetterLine2 do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            if FindSet then
                repeat
                    IncTotalLine(PurchAdvanceLetterLine, PurchAdvanceLetterLine2);
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
#if not CLEAN18
                        VATAmountLine."Currency Code" := Currency.Code;
#endif
                        VATAmountLine.Quantity := 1;
                        VATAmountLine.Insert();
                    end;
                    VATAmountLine."VAT Base" := VATAmountLine."VAT Base" + Amount;
                    VATAmountLine."VAT Amount" := VATAmountLine."VAT Amount" + "VAT Amount";
                    VATAmountLine."Calculated VAT Amount" := VATAmountLine."Calculated VAT Amount" + "VAT Amount" - "VAT Difference";
                    VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + "Amount Including VAT";
                    VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + "Amount Including VAT";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference";
#if not CLEAN18
                    VATAmountLine."VAT Difference (LCY)" := VATAmountLine."VAT Difference (LCY)" + "VAT Difference";
#endif
                    VATAmountLine."Includes Prepayment" := false;
                    VATAmountLine.Modify();
                until Next() = 0;
        end;
#if not CLEAN18
        with VATAmountLine do
            if FindSet then
                repeat
                    if (PrevVatAmountLine."VAT Identifier" <> "VAT Identifier") or
                       (PrevVatAmountLine."VAT Calculation Type" <> "VAT Calculation Type") or
                       (PrevVatAmountLine."Tax Group Code" <> "Tax Group Code") or
                       (PrevVatAmountLine."Use Tax" <> "Use Tax")
                    then
                        PrevVatAmountLine.Init();

                    PurchSetup.Get();
                    if PurchSetup."Allow VAT Difference" and (Quantity <> 0) then
                        if PurchAdvanceLetterHeader."Currency Code" = '' then
                            if "VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT" then begin
                                if (not VATCorrection) and ("VAT Difference" = 0) then begin
                                    "VAT Difference (LCY)" := RoundVAT("VAT Amount") - "Calculated VAT Amount";
                                    Modified := true;
                                end;

                                "VAT Base (LCY)" := "VAT Base";
                                "VAT Amount (LCY)" := "Calculated VAT Amount" + "VAT Difference (LCY)";
                                "Calculated VAT Amount (LCY)" := "Calculated VAT Amount";

                                if "VAT %" <> 0 then begin
                                    if true then begin
                                        "VAT Base" := "VAT Base" - "VAT Difference (LCY)";
                                        "VAT Base (LCY)" := "VAT Base";
                                        "Amount Including VAT (LCY)" := "Amount Including VAT";
                                    end else
                                        "Amount Including VAT (LCY)" := "Amount Including VAT";

                                    if "VAT Amount (LCY)" <> 0 then
                                        Validate("VAT Amount", "VAT Amount (LCY)");
                                    "Amount Including VAT" := "Amount Including VAT (LCY)";
                                end;
                            end else begin
                                "VAT Difference (LCY)" := 0;
                                "VAT Amount (LCY)" := "VAT Amount";
                            end;
                    "Modified (LCY)" := true;

                    Modify;
                until Next() = 0;
#endif
    end;

    [Scope('OnPrem')]
    procedure IncTotalLine(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line")
    begin
        with PurchAdvanceLetterLine2 do begin
            PurchAdvanceLetterLine.Amount := PurchAdvanceLetterLine.Amount + Amount;
            PurchAdvanceLetterLine."Amount Including VAT" := PurchAdvanceLetterLine."Amount Including VAT" + "Amount Including VAT";
            PurchAdvanceLetterLine."VAT Amount" := PurchAdvanceLetterLine."VAT Amount" + "VAT Amount";
            PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount To Link" + "Amount To Link";
            PurchAdvanceLetterLine."Amount Linked" := PurchAdvanceLetterLine."Amount Linked" + "Amount Linked";
            PurchAdvanceLetterLine."Amount To Invoice" := PurchAdvanceLetterLine."Amount To Invoice" + "Amount To Invoice";
            PurchAdvanceLetterLine."Amount Invoiced" := PurchAdvanceLetterLine."Amount Invoiced" + "Amount Invoiced";
            PurchAdvanceLetterLine."Amount To Deduct" := PurchAdvanceLetterLine."Amount To Deduct" + "Amount To Deduct";
            PurchAdvanceLetterLine."Amount Deducted" := PurchAdvanceLetterLine."Amount Deducted" + "Amount Deducted";
            PurchAdvanceLetterLine."Amount Linked To Journal Line" :=
              PurchAdvanceLetterLine."Amount Linked To Journal Line" + "Amount Linked To Journal Line";
        end;
    end;

    local procedure GetCurrency()
    begin
        GetLetterHeader;
        CurrencyCode := PurchAdvanceLetterHeadergre."Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision;
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    procedure CalcVATAmountLines2(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var VATAmountLine: Record "VAT Amount Line"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var TotalVATToInvoice: Decimal; var TotalVATInvoiced: Decimal; var PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line")
    var
        VATFactor: Decimal;
    begin
        if PurchAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchAdvanceLetterHeader."Currency Code");
        PurchSetup.Get();
        VATAmountLine.DeleteAll();
        PurchAdvanceLetterLine.Init();
        TotalVATToInvoice := 0;
        TotalVATInvoiced := 0;

        with PurchAdvanceLetterLine2 do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            if FindSet then
                repeat
                    IncTotalLine(PurchAdvanceLetterLine, PurchAdvanceLetterLine2);
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
#if not CLEAN18
                        VATAmountLine."Currency Code" := Currency.Code;
#endif
                        VATAmountLine.Quantity := 1;
                        VATAmountLine.Insert();
                    end;
                    VATAmountLine."Amount Including VAT" := VATAmountLine."Amount Including VAT" + "Amount Including VAT";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + "VAT Difference Inv.";
#if not CLEAN18
                    if "Currency Code" = '' then
                        VATAmountLine."VAT Difference (LCY)" := VATAmountLine."VAT Difference (LCY)" + "VAT Difference Inv."
                    else
                        VATAmountLine."VAT Difference (LCY)" := VATAmountLine."VAT Difference (LCY)" + "VAT Difference Inv. (LCY)";
#endif
                    VATAmountLine."Includes Prepayment" := false;

                    VATAmountLine.Modify();
                until Next() = 0;
        end;

        with VATAmountLine do
            if FindSet then
                repeat
                    "VAT Amount" :=
                        "VAT Difference" +
                        Round("Amount Including VAT" * "VAT %" / (100 + "VAT %"),
                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Base" := "Amount Including VAT" - "VAT Amount";
                    "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
#if not CLEAN18
                    if PurchAdvanceLetterHeader."Currency Code" = '' then begin

                        "Amount Including VAT (LCY)" := "Amount Including VAT";
                        "VAT Amount (LCY)" := "VAT Amount";
                        "VAT Base (LCY)" := "VAT Base";
                        "Calculated VAT Amount (LCY)" := "Calculated VAT Amount";
                    end else begin
                        "Amount Including VAT (LCY)" := Round(
                            CurrencyExchRate.ExchangeAmtFCYToLCY(
                              PurchAdvanceLetterHeader."Document Date", PurchAdvanceLetterHeader."Currency Code",
                              "Amount Including VAT", PurchAdvanceLetterHeader."VAT Currency Factor"), Currency."Amount Rounding Precision");
                        "VAT Amount (LCY)" :=
                          "VAT Difference (LCY)" + Round(
                            CurrencyExchRate.ExchangeAmtFCYToLCY(
                              PurchAdvanceLetterHeader."Document Date", PurchAdvanceLetterHeader."Currency Code",
                              "VAT Amount", PurchAdvanceLetterHeader."VAT Currency Factor"), Currency."Amount Rounding Precision");
                        "VAT Base (LCY)" := "Amount Including VAT (LCY)" - "VAT Amount (LCY)";
                        "Calculated VAT Amount (LCY)" := "VAT Amount (LCY)" - "VAT Difference (LCY)";
                    end;
#endif
                    Modify;
                until Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InitVATLinesToInv(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        with PurchAdvanceLetterLine do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            if FindSet then
                repeat
                    if "Amount To Invoice" <> 0 then begin
                        TempPurchAdvanceLetterLine.Init();
                        TempPurchAdvanceLetterLine.SuspendStatusCheck(true);
                        TempPurchAdvanceLetterLine."Letter No." := "Letter No.";
                        TempPurchAdvanceLetterLine."Line No." := "Line No.";
                        TempPurchAdvanceLetterLine."No." := "No.";
                        TempPurchAdvanceLetterLine."VAT %" := "VAT %";
                        TempPurchAdvanceLetterLine."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                        TempPurchAdvanceLetterLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                        TempPurchAdvanceLetterLine."VAT Calculation Type" := "VAT Calculation Type";
                        TempPurchAdvanceLetterLine."Tax Area Code" := "Tax Area Code";
                        TempPurchAdvanceLetterLine."Tax Liable" := "Tax Liable";
                        TempPurchAdvanceLetterLine."Tax Group Code" := "Tax Group Code";
                        TempPurchAdvanceLetterLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                        TempPurchAdvanceLetterLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                        TempPurchAdvanceLetterLine."Currency Code" := "Currency Code";
                        TempPurchAdvanceLetterLine."VAT Identifier" := "VAT Identifier";
                        TempPurchAdvanceLetterLine."Amount Including VAT" := "Amount To Invoice";
                        TempPurchAdvanceLetterLine.CalcLineAmtIncVAT;
                        TempPurchAdvanceLetterLine."VAT Difference Inv." := "VAT Difference Inv.";
                        TempPurchAdvanceLetterLine."VAT Difference Inv. (LCY)" := "VAT Difference Inv. (LCY)";
                        TempPurchAdvanceLetterLine."VAT Amount" := TempPurchAdvanceLetterLine."VAT Amount" + "VAT Difference Inv.";
                        TempPurchAdvanceLetterLine.Amount :=
                          TempPurchAdvanceLetterLine."Amount Including VAT" - TempPurchAdvanceLetterLine."VAT Amount";
                        TempPurchAdvanceLetterLine.Insert();
                    end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVATOnLineInv(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempBufVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
#if CLEAN18        
        TempVATAmountLineLCYRemainder: Record "VAT Amount Line" temporary;
#endif        
        VATAmount: Decimal;
        VATAmountLCY: Decimal;
        AmountToInvoiceLCY: Decimal;
        VATDifference: Decimal;
        VATDifferenceLCY: Decimal;
    begin
        GLSetup.Get();
        if PurchAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchAdvanceLetterHeader."Currency Code");

        with PurchAdvanceLetterLine do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter("Amount To Invoice", '<>0');
            LockTable();
            if FindSet then
                repeat
                    VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0);
#if CLEAN18
                    if VATAmountLine.Modified then begin
#else
                    if VATAmountLine.Modified or VATAmountLine."Modified (LCY)" then begin
#endif
                        if not TempVATAmountLineRemainder.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0)
                        then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
#if CLEAN18
                            TempVATAmountLineLCYRemainder := VATAmountLine;
                            TempVATAmountLineLCYRemainder.Init();
                            TempVATAmountLineLCYRemainder.Insert();
#endif
                        end;
#if CLEAN18
                        TempVATAmountLineLCYRemainder.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Amount Including VAT" >= 0);
#endif

                        VATAmount :=
                          TempVATAmountLineRemainder."VAT Amount" +
                          VATAmountLine."VAT Amount" *
                          "Amount To Invoice" /
                          VATAmountLine."Amount Including VAT";
                        VATDifference :=
                          TempVATAmountLineRemainder."VAT Difference" +
                          VATAmountLine."VAT Difference" *
                          "Amount To Invoice" /
                          VATAmountLine."Amount Including VAT";
                        VATDifferenceLCY :=
#if CLEAN18
                          TempVATAmountLineLCYRemainder."VAT Difference" +
                          VATAmountLine.GetVATDifferenceLCY(PurchAdvanceLetterHeader."VAT Date", PurchAdvanceLetterHeader."Currency Code", PurchAdvanceLetterHeader."Currency Factor") *
#else
                          TempVATAmountLineRemainder."VAT Difference (LCY)" +
                          VATAmountLine."VAT Difference (LCY)" *
#endif
                          "Amount To Invoice" /
                          VATAmountLine."Amount Including VAT";
                        AmountToInvoiceLCY :=
#if CLEAN18
                          TempVATAmountLineLCYRemainder."Amount Including VAT" +
                          VATAmountLine.GetAmountIncludingVATLCY(PurchAdvanceLetterHeader."VAT Date", PurchAdvanceLetterHeader."Currency Code", PurchAdvanceLetterHeader."Currency Factor") *
#else
                          TempVATAmountLineRemainder."Amount Including VAT (LCY)" +
                          VATAmountLine."Amount Including VAT (LCY)" *
#endif
                          "Amount To Invoice" /
                          VATAmountLine."Amount Including VAT";

                        "VAT Amount Inv." := Round(VATAmount, Currency."Amount Rounding Precision");

                        if PurchAdvanceLetterHeader."Currency Code" = '' then
                            VATAmountLCY := VATAmount
                        else
                            VATAmountLCY :=
#if CLEAN18
                              TempVATAmountLineLCYRemainder."VAT Amount" + VATDifferenceLCY +
#else
                              TempVATAmountLineRemainder."VAT Amount (LCY)" + VATDifferenceLCY +
#endif
                              CurrencyExchRate.ExchangeAmtFCYToLCY(
                                PurchAdvanceLetterHeader."Document Date", PurchAdvanceLetterHeader."Currency Code",
                                "VAT Amount Inv.", PurchAdvanceLetterHeader."VAT Currency Factor");

                        "VAT Difference Inv." := Round(VATDifference, Currency."Amount Rounding Precision");
                        "VAT Difference Inv. (LCY)" := Round(VATDifferenceLCY, GLSetup."Amount Rounding Precision");

                        if "Currency Code" = '' then
                            "VAT Amount Inv. (LCY)" := "VAT Amount Inv."
                        else begin
                            "VAT Amount Inv. (LCY)" := Round(VATAmountLCY, GLSetup."Amount Rounding Precision");
                            "Amount To Invoice (LCY)" := Round(AmountToInvoiceLCY, GLSetup."Amount Rounding Precision");
                        end;

                        "VAT Correction Inv." := true;

                        TempBufVATAmountLine := VATAmountLine;
                        if TempBufVATAmountLine.Insert() then;

                        TempVATAmountLineRemainder."VAT Amount" := VATAmount -
                          Round(VATAmount, Currency."Amount Rounding Precision");
#if CLEAN18
                        TempVATAmountLineLCYRemainder."VAT Amount" := VATAmountLCY -
#else
                        TempVATAmountLineRemainder."VAT Amount (LCY)" := VATAmountLCY -
#endif
                          Round(VATAmountLCY, GLSetup."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference -
                          Round(VATDifference, Currency."Amount Rounding Precision");
#if CLEAN18
                        TempVATAmountLineLCYRemainder."VAT Difference" := VATDifferenceLCY -
#else
                        TempVATAmountLineRemainder."VAT Difference (LCY)" := VATDifferenceLCY -
#endif
                          Round(VATDifferenceLCY, GLSetup."Amount Rounding Precision");
                        TempVATAmountLineRemainder.Modify();
#if CLEAN18
                        TempVATAmountLineLCYRemainder.Modify();
#endif
                    end else begin
                        "VAT Difference Inv." := 0;
                        "VAT Difference Inv. (LCY)" := 0;
                        "VAT Amount Inv." := 0;
                        "VAT Amount Inv. (LCY)" := 0;
                        "Amount To Invoice (LCY)" := 0;
                        "VAT Correction Inv." := false
                    end;

                    Modify;
                until Next() = 0;
        end;
    end;

    local procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        GetLetterHeader;
        PurchAdvanceLetterHeadergre.CalcFields(Status);
        PurchAdvanceLetterHeadergre.TestField(Status, PurchAdvanceLetterHeadergre.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure SuspendStatusCheck(lboSuspend: Boolean)
    begin
        StatusCheckSuspended := lboSuspend;
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

        GetLetterHeader;
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            PurchAdvanceLetterHeadergre."Dimension Set ID", DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ChangeVATProdPostingGroup()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        TestField("Amount Invoiced", 0);
        if "VAT Prod. Posting Group" <> '' then
            VATProductPostingGroup.Get("VAT Prod. Posting Group");
        if PAGE.RunModal(0, VATProductPostingGroup) <> ACTION::LookupOK then
            exit;
        "VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GetLetterHeader;
        "Pay-to Vendor No." := PurchAdvanceLetterHeadergre."Pay-to Vendor No.";
        "VAT Bus. Posting Group" := PurchAdvanceLetterHeadergre."VAT Bus. Posting Group";
        "Gen. Bus. Posting Group" := PurchAdvanceLetterHeadergre."Gen. Bus. Posting Group";
        "Currency Code" := PurchAdvanceLetterHeadergre."Currency Code";

        if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
            VATPostingSetup.TestField("Purch. Advance VAT Account");
            GLAcc.Get(VATPostingSetup."Purch. Advance VAT Account");
            Validate("No.", GLAcc."No.");
            "VAT %" := VATPostingSetup."VAT %";
            "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
            "VAT Identifier" := VATPostingSetup."VAT Identifier";
        end else begin
            "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
            "VAT Identifier" := '';
            "VAT %" := 0;
        end;
        CalcLineAmtIncVAT;
        Modify(true);
    end;

    [Scope('OnPrem')]
    procedure RecalcVATOnLines(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATAmount: Decimal;
    begin
        if PurchAdvanceLetterHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchAdvanceLetterHeader."Currency Code");

        TempVATAmountLine.DeleteAll();

        with PurchAdvanceLetterLine do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter("Amount Including VAT", '<>0');
            if FindSet then
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
                    TempVATAmountLine."Amount Including VAT" := TempVATAmountLine."Amount Including VAT" + "Amount Including VAT";
                    TempVATAmountLine."Includes Prepayment" := false;
                    TempVATAmountLine.Modify();
                until Next() = 0;
        end;

        if TempVATAmountLine.Find('-') then begin
            repeat
                TempVATAmountLine."VAT Amount" :=
                    Round(TempVATAmountLine."Amount Including VAT" * TempVATAmountLine."VAT %" / (100 + TempVATAmountLine."VAT %"),
                        Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                TempVATAmountLine."VAT Base" := TempVATAmountLine."Amount Including VAT" - TempVATAmountLine."VAT Amount";

                TempVATAmountLine.Modify();
            until TempVATAmountLine.Next() = 0;
        end;

        TempVATAmountLineRemainder.DeleteAll();

        with PurchAdvanceLetterLine do begin
            SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            SetFilter(Amount, '<>0');
            LockTable();
            if FindSet then
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

                        "VAT Amount" := Round(VATAmount, Currency."Amount Rounding Precision");
                        Amount := "Amount Including VAT" - "VAT Amount";
                        Modify;
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - "VAT Amount";
                        TempVATAmountLineRemainder.Modify();
                    end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcLineAmtIncVAT()
    begin
        GetCurrency;
        case "VAT Calculation Type" of
            "VAT Calculation Type"::"Normal VAT":
                "VAT Amount" :=
                    Round("Amount Including VAT" * "VAT %" / (100 + "VAT %"),
                        Currency."Amount Rounding Precision",
                        Currency.VATRoundingDirection);
            "VAT Calculation Type"::"Reverse Charge VAT":
                "VAT Amount" := 0;
            "VAT Calculation Type"::"Full VAT":
                "VAT Amount" := Amount;
            "VAT Calculation Type"::"Sales Tax":
                ;
        end;

        Amount := "Amount Including VAT" - "VAT Amount";
        "VAT Difference" := 0;
    end;

    [Scope('OnPrem')]
    procedure GetAmountToLinkLCY(): Decimal
    var
        PurchAdvanceLetterHdr: Record "Purch. Advance Letter Header";
        CurrExchRate: Record "Currency Exchange Rate";
        Date: Date;
    begin
        PurchAdvanceLetterHdr.Get("Letter No.");
        Date := PurchAdvanceLetterHdr."Document Date";
        if Date = 0D then
            Date := WorkDate;
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCY(Date,
              PurchAdvanceLetterHdr."Currency Code",
              "Amount To Link",
              PurchAdvanceLetterHdr."Currency Factor")));
    end;
#endif
}

