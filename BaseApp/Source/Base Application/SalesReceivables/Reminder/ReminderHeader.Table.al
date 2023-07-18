table 295 "Reminder Header"
{
    Caption = 'Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Reminder List";
    LookupPageID = "Reminder List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
                "Posting Description" := StrSubstNo(Text000, "No.");
            end;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
                if CurrFieldNo = FieldNo("Customer No.") then
                    if Undo() then begin
                        "Customer No." := xRec."Customer No.";
                        CreateDimFromDefaultDim();
                        exit;
                    end;
                if "Customer No." = '' then begin
                    CreateDimFromDefaultDim();
                    exit;
                end;
                Cust.Get("Customer No.");
                if Cust."Privacy Blocked" then
                    Cust.CustPrivacyBlockedErrorMessage(Cust, false);
                CheckCustomerBlockedAll(Cust);

                if Cont.Get(Cust."Primary Contact No.") then
                    Cont.CheckIfPrivacyBlockedGeneric();

                Name := Cust.Name;
                "Name 2" := Cust."Name 2";
                Address := Cust.Address;
                "Address 2" := Cust."Address 2";
                "Post Code" := Cust."Post Code";
                City := Cust.City;
                County := Cust.County;
                Contact := Cust.Contact;
                "Country/Region Code" := Cust."Country/Region Code";
                "Language Code" := Cust."Language Code";
                "Currency Code" := Cust."Currency Code";
                "Shortcut Dimension 1 Code" := Cust."Global Dimension 1 Code";
                "Shortcut Dimension 2 Code" := Cust."Global Dimension 2 Code";
                "VAT Registration No." := Cust."VAT Registration No.";
                Cust.TestField("Customer Posting Group");
                "Customer Posting Group" := Cust."Customer Posting Group";
                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
                "Reminder Terms Code" := Cust."Reminder Terms Code";
                "Fin. Charge Terms Code" := Cust."Fin. Charge Terms Code";
                OnValidateCustomerNoOnAfterAssignCustomerValues(Rec, Cust);
                Validate("Reminder Terms Code");

                CreateDimFromDefaultDim();
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Currency Code") then
                    if Undo() then begin
                        "Currency Code" := xRec."Currency Code";
                        exit;
                    end;
                SetCompanyBankAccount();
            end;
        }
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(18; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");
            end;
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

                if CurrFieldNo = FieldNo("Document Date") then
                    if Undo() then begin
                        "Document Date" := xRec."Document Date";
                        exit;
                    end;
                Validate("Reminder Level");
            end;
        }
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Reminder Terms";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Reminder Terms Code") then
                    if Undo() then begin
                        "Reminder Terms Code" := xRec."Reminder Terms Code";
                        exit;
                    end;
                if "Reminder Terms Code" <> '' then begin
                    ReminderTerms.Get("Reminder Terms Code");
                    "Post Interest" := ReminderTerms."Post Interest";
                    "Post Additional Fee" := ReminderTerms."Post Additional Fee";
                    "Post Add. Fee per Line" := ReminderTerms."Post Add. Fee per Line";
                    Validate("Reminder Level");
                    Validate("Post Interest");
                end;
            end;
        }
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Fin. Charge Terms Code") then
                    if Undo() then begin
                        "Fin. Charge Terms Code" := xRec."Fin. Charge Terms Code";
                        exit;
                    end;
            end;
        }
        field(26; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
        }
        field(27; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
        }
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            TableRelation = "Reminder Level"."No." WHERE("Reminder Terms Code" = FIELD("Reminder Terms Code"));

            trigger OnValidate()
            begin
                if ("Reminder Level" <> 0) and ("Reminder Terms Code" <> '') then begin
                    ReminderTerms.Get("Reminder Terms Code");
                    ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
                    ReminderLevel.SetRange("No.", 1, "Reminder Level");
                    if ReminderLevel.FindLast() and ("Document Date" <> 0D) then
                        "Due Date" := CalcDate(ReminderLevel."Due Date Calculation", "Document Date");

                    OnAfterValidateReminderLevel(Rec, ReminderLevel);
                end;
            end;
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = Exist("Reminder Comment Line" WHERE(Type = CONST(Reminder),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Reminder Line"."Remaining Amount" WHERE("Reminder No." = FIELD("No."),
                                                                        "Line Type" = CONST("Reminder Line"),
                                                                        "Detailed Interest Rates Entry" = CONST(false)));
            Caption = 'Remaining Amount';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Reminder Line".Amount WHERE("Reminder No." = FIELD("No."),
                                                            Type = CONST("Customer Ledger Entry"),
                                                            "Detailed Interest Rates Entry" = CONST(false),
                                                            "Line Type" = FILTER(<> "Not Due")));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Reminder Line".Amount WHERE("Reminder No." = FIELD("No."),
                                                            Type = CONST("G/L Account"),
                                                            "Line Type" = FILTER(<> "Not Due")));
            Caption = 'Additional Fee';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Reminder Line"."VAT Amount" WHERE("Reminder No." = FIELD("No."),
                                                                  "Detailed Interest Rates Entry" = CONST(false),
                                                                  "Line Type" = FILTER(<> "Not Due")));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(38; "Issuing No. Series"; Code[20])
        {
            Caption = 'Issuing No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with ReminderHeader do begin
                    ReminderHeader := Rec;
                    TestNoSeries();
                    if NoSeriesMgt.LookupSeries(GetIssuingNoSeriesCode(), "Issuing No. Series") then
                        Validate("Issuing No. Series");
                    Rec := ReminderHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Issuing No. Series" <> '' then begin
                    TestNoSeries();
                    NoSeriesMgt.TestSeries(GetIssuingNoSeriesCode(), "Issuing No. Series");
                end;
                TestField("Issuing No.", '');
            end;
        }
        field(39; "Issuing No."; Code[20])
        {
            Caption = 'Issuing No.';
        }
        field(41; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(42; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(44; "Use Header Level"; Boolean)
        {
            Caption = 'Use Header Level';
        }
        field(45; "Add. Fee per Line"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            CalcFormula = Sum("Reminder Line".Amount WHERE("Reminder No." = FIELD("No."),
                                                            Type = CONST("Line Fee"),
                                                            "Line Type" = FILTER(<> "Not Due")));
            Caption = 'Add. Fee per Line';
            FieldClass = FlowField;
        }
        field(46; "Post Add. Fee per Line"; Boolean)
        {
            Caption = 'Post Add. Fee per Line';
        }
        field(47; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;

            trigger OnValidate()
            begin
                if "VAT Reporting Date" = 0D then
                    InitVATDate();
            end;
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = FIELD("Currency Code"));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Currency Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Customer No.", Name, "Due Date")
        {
        }
    }

    trigger OnDelete()
    begin
        ReminderIssue.DeleteHeader(Rec, IssuedReminderHeader);

        ReminderLine.SetRange("Reminder No.", "No.");
        ReminderLine.DeleteAll();

        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::Reminder);
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.DeleteAll();

        PrintIssuedReminders();
    end;

    trigger OnInsert()
    begin
        SalesSetup.Get();
        SetReminderNo();
        "Posting Description" := StrSubstNo(Text000, "No.");
        if ("No. Series" <> '') and
           (SalesSetup."Reminder Nos." = GetIssuingNoSeriesCode())
        then
            "Issuing No. Series" := "No. Series"
        else
            NoSeriesMgt.SetDefaultSeries("Issuing No. Series", GetIssuingNoSeriesCode());

        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        "Document Date" := WorkDate();
        "Due Date" := WorkDate();

        InitVATDate();

        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                Validate("Customer No.", GetRangeMin("Customer No."));
    end;

    var
        Text000: Label 'Reminder %1';
        Text001: Label 'Do you want to print reminder %1?';
        Text002: Label 'This change will cause the existing lines to be deleted for this reminder.\\';
        Text003: Label 'Do you want to continue?';
        Text004: Label 'There is not enough space to insert the text.';
        Text005: Label 'Deleting this document will cause a gap in the number series for reminders. ';
        Text006: Label 'An empty reminder %1 will be created to fill this gap in the number series.\\';
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        CustPostingGr: Record "Customer Posting Group";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        FinChrgTerms: Record "Finance Charge Terms";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderCommentLine: Record "Reminder Comment Line";
        Cust: Record Customer;
        PostCode: Record "Post Code";
        IssuedReminderHeader: Record "Issued Reminder Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GLSetup: Record "General Ledger Setup";
        AutoFormat: Codeunit "Auto Format";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReminderIssue: Codeunit "Reminder-Issue";
        DimMgt: Codeunit DimensionManagement;
        NextLineNo: Integer;
        LineSpacing: Integer;
        ReminderTotal: Decimal;
        SelectNoSeriesAllowed: Boolean;

    procedure AssistEdit(OldReminderHeader: Record "Reminder Header"): Boolean
    begin
        with ReminderHeader do begin
            ReminderHeader := Rec;
            TestNoSeries();
            if NoSeriesMgt.SelectSeries(SalesSetup."Reminder Nos.", OldReminderHeader."No. Series", "No. Series") then begin
                TestNoSeries();
                NoSeriesMgt.SetSeries("No.");
                Rec := ReminderHeader;
                exit(true);
            end;
        end;
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then begin
            SalesSetup.TestField("Reminder Nos.");
            SalesSetup.TestField("Issued Reminder Nos.");
        end;

        OnAfterTestNoSeries(Rec);
    end;

    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        NoSeriesCode := SalesSetup."Reminder Nos.";

        OnAfterGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode);
        exit(NoSeriesMgt.GetNoSeriesWithCheck(NoSeriesCode, SelectNoSeriesAllowed, "No. Series"));
    end;

    local procedure InitVATDate()
    begin
        "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
    end;

    local procedure GetIssuingNoSeriesCode() IssuingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeGetIssuingNoSeriesCode(Rec, SalesSetup, IssuingNos, IsHandled);
        if IsHandled then
            exit;

        IssuingNos := SalesSetup."Issued Reminder Nos.";

        OnAfterGetIssuingNoSeriesCode(Rec, IssuingNos);
    end;

    local procedure SetCompanyBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        Validate("Company Bank Account Code", BankAccount.GetDefaultBankAccountNoForCurrency("Currency Code"));
        OnAfterSetCompanyBankAccount(Rec, xRec);
    end;

    procedure Undo(): Boolean
    begin
        ReminderLine.SetRange("Reminder No.", "No.");
        if ReminderLine.Find('-') then begin
            Commit();
            if not
               Confirm(
                 Text002 +
                 Text003,
                 false)
            then
                exit(true);
            ReminderLine.DeleteAll();
            Modify();
        end;
    end;

    procedure InsertLines()
    var
        ReminderLine2: Record "Reminder Line";
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        TranslationHelper: Codeunit "Translation Helper";
        AdditionalFee: Decimal;
    begin
        CurrencyForReminderLevel.Init();
        ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
        ReminderLevel.SetRange("No.", 1, "Reminder Level");
        OnInsertLinesOnAfterReminderLevelSetFilters(Rec, ReminderLevel);
        if ReminderLevel.FindLast() then begin
            CalcFields("Remaining Amount");
            AdditionalFee := ReminderLevel.GetAdditionalFee("Remaining Amount", "Currency Code", false, "Posting Date");
            OnInsertLinesOnAfterCalcAdditionalFee(Rec, ReminderLevel, AdditionalFee);

            if AdditionalFee > 0 then begin
                ReminderLine.Reset();
                ReminderLine.SetRange("Reminder No.", "No.");
                ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
                ReminderLine."Reminder No." := "No.";
                if ReminderLine.Find('+') then
                    NextLineNo := ReminderLine."Line No."
                else
                    NextLineNo := 0;
                ReminderLine.SetRange("Line Type");
                ReminderLine2 := ReminderLine;
                ReminderLine2.CopyFilters(ReminderLine);
                ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");
                if ReminderLine2.Next() <> 0 then
                    LineSpacing := (ReminderLine2."Line No." - ReminderLine."Line No.") div 3
                else
                    LineSpacing := 10000;
                InsertBlankLine(ReminderLine."Line Type"::"Additional Fee");

                NextLineNo := NextLineNo + LineSpacing;
                ReminderLine.Init();
                ReminderLine."Line No." := NextLineNo;
                ReminderLine.Type := ReminderLine.Type::"G/L Account";
                TestField("Customer Posting Group");
                CustPostingGr.Get("Customer Posting Group");
                ReminderLine.Validate("No.", CustPostingGr.GetAdditionalFeeAccount());
                ReminderLine.Description :=
                  CopyStr(
                    TranslationHelper.GetTranslatedFieldCaption(
                      "Language Code", DATABASE::"Currency for Reminder Level",
                      CurrencyForReminderLevel.FieldNo("Additional Fee")), 1, 100);
                ReminderLine.Validate(Amount, AdditionalFee);
                ReminderLine."Line Type" := ReminderLine."Line Type"::"Additional Fee";
#if not CLEAN20                
                OnBeforeInsertReminderTextLine(ReminderLine, ReminderText, ReminderHeader);
                OnBeforeInsertReminderLine(ReminderLine);
#endif
                OnInsertLinesOnBeforeReminderLineInsert(Rec, ReminderLine);
                ReminderLine.Insert();
                if TransferExtendedText.ReminderCheckIfAnyExtText(ReminderLine, false) then
                    TransferExtendedText.InsertReminderExtText(ReminderLine);
            end;
        end;
        ReminderLine."Line No." := ReminderLine."Line No." + 10000;
        ReminderRounding(Rec);
        InsertBeginTexts(Rec);
        InsertEndTexts(Rec);
        Modify();

        OnAfterInsertLines(Rec);
    end;

    procedure UpdateLines(ReminderHeader: Record "Reminder Header"; UpdateAdditionalFee: Boolean)
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetRange(
          "Line Type",
          ReminderLine."Line Type"::"Beginning Text",
          ReminderLine."Line Type"::"Ending Text");
        ReminderLine.SetRange(Type, ReminderLine.Type::" ");
        ReminderLine.SetRange("Attached to Line No.", 0);
        ReminderLine.DeleteAll(true);

        if UpdateAdditionalFee then begin
            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Additional Fee");
            ReminderLine.DeleteAll();
            InsertLines();
        end else begin
            InsertBeginTexts(ReminderHeader);
            InsertEndTexts(ReminderHeader);
        end;

        OnAfterUpdateLines(Rec, UpdateAdditionalFee);
    end;

    local procedure InsertBeginTexts(var ReminderHeader: Record "Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertBeginTexts(ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderLevel.SetRange("No.", 1, ReminderHeader."Reminder Level");
        OnInsertBeginTextsOnAfterReminderLevelSetFilters(ReminderLevel, ReminderHeader);
        if ReminderLevel.FindLast() then begin
            ReminderText.Reset();
            ReminderText.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
            ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
            ReminderText.SetRange(Position, ReminderText.Position::Beginning);
            OnInsertBeginTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine."Reminder No." := ReminderHeader."No.";
            if ReminderLine.Find('-') then begin
                LineSpacing := ReminderLine."Line No." div (ReminderText.Count + 2);
                if LineSpacing = 0 then
                    Error(Text004);
            end else
                LineSpacing := 10000;
            NextLineNo := 0;
            InsertTextLines(ReminderHeader);
        end;
    end;

    local procedure InsertEndTexts(var ReminderHeader: Record "Reminder Header")
    var
        ReminderLine2: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertEndTexts(ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderLevel.SetRange("No.", 1, ReminderHeader."Reminder Level");
        OnInsertEndTextsOnAfterReminderLevelSetFilters(ReminderLevel, ReminderHeader);
        if ReminderLevel.FindLast() then begin
            ReminderText.SetRange(
              "Reminder Terms Code", ReminderHeader."Reminder Terms Code");
            ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
            ReminderText.SetRange(Position, ReminderText.Position::Ending);
            OnInsertEndTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine.SetFilter(
              "Line Type", '%1|%2|%3',
              ReminderLine."Line Type"::"Reminder Line",
              ReminderLine."Line Type"::"Additional Fee",
              ReminderLine."Line Type"::Rounding);
            OnInsertEndTextsOnAfterReminderLineSetFilters(ReminderLine, ReminderHeader);
            if ReminderLine.FindLast() then
                NextLineNo := ReminderLine."Line No."
            else
                NextLineNo := 0;
            ReminderLine.SetRange("Line Type");
            ReminderLine2 := ReminderLine;
            ReminderLine2.CopyFilters(ReminderLine);
            ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");
            if ReminderLine2.Next() <> 0 then begin
                LineSpacing :=
                  (ReminderLine2."Line No." - ReminderLine."Line No.") div
                  (ReminderText.Count + 2);
                if LineSpacing = 0 then
                    Error(Text004);
            end else
                LineSpacing := 10000;
            InsertTextLines(ReminderHeader);
        end;
    end;

    local procedure InsertTextLines(var ReminderHeader: Record "Reminder Header")
    begin
        InsertTextLines(ReminderHeader, ReminderText, NextLineNo, LineSpacing);
    end;

    procedure InsertTextLines(var ReminderHeader: Record "Reminder Header"; var ReminderText: Record "Reminder Text"; var NextLineNo: Integer; LineSpacing: Integer)
    var
        CompanyInfo: Record "Company Information";
        AutoFormatType: Enum "Auto Format";
    begin
        if ReminderText.Find('-') then begin
            if ReminderText.Position = ReminderText.Position::Ending then
                InsertBlankLine(ReminderLine."Line Type"::"Ending Text");
            if ReminderHeader."Fin. Charge Terms Code" <> '' then
                FinChrgTerms.Get(ReminderHeader."Fin. Charge Terms Code");
            if not ReminderLevel."Calculate Interest" then
                FinChrgTerms."Interest Rate" := 0;
            ReminderHeader.CalcFields(
              "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
            ReminderTotal :=
              ReminderHeader."Remaining Amount" + ReminderHeader."Interest Amount" +
              ReminderHeader."Additional Fee" + ReminderHeader."VAT Amount" +
              ReminderHeader."Add. Fee per Line";
            CompanyInfo.Get();

            repeat
                NextLineNo := NextLineNo + LineSpacing;
                ReminderLine.Init();
                ReminderLine."Line No." := NextLineNo;
                ReminderLine.Type := ReminderLine.Type::" ";
                ReminderLine.Description :=
                  CopyStr(
                    StrSubstNo(
                      ReminderText.Text,
                      ReminderHeader."Document Date",
                      ReminderHeader."Due Date",
                      FinChrgTerms."Interest Rate",
                      Format(ReminderHeader."Remaining Amount", 0,
                        AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, ReminderHeader."Currency Code")),
                      ReminderHeader."Interest Amount",
                      ReminderHeader."Additional Fee",
                      Format(ReminderTotal, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, ReminderHeader."Currency Code")),
                      ReminderHeader."Reminder Level",
                      ReminderHeader."Currency Code",
                      ReminderHeader."Posting Date",
                      CompanyInfo.Name,
                      ReminderHeader."Add. Fee per Line"),
                    1,
                    MaxStrLen(ReminderLine.Description));
                if ReminderText.Position = ReminderText.Position::Beginning then
                    ReminderLine."Line Type" := ReminderLine."Line Type"::"Beginning Text"
                else
                    ReminderLine."Line Type" := ReminderLine."Line Type"::"Ending Text";
#if not CLEAN20
                OnBeforeInsertReminderTextLine(ReminderLine, ReminderText, ReminderHeader);
                OnBeforeInsertReminderLine(ReminderLine);
#endif
                OnInsertTextLinesOnBeforeReminderLineInsert(ReminderLine, ReminderText, ReminderHeader);
                ReminderLine.Insert();
            until ReminderText.Next() = 0;
            if ReminderText.Position = ReminderText.Position::Beginning then
                InsertBlankLine(ReminderLine."Line Type"::"Beginning Text");
        end;
    end;

    local procedure InsertBlankLine(LineType: Enum "Reminder Line Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertBlankLine(Rec, LineType, NextLineNo, LineSpacing, IsHandled);
        if IsHandled then
            exit;

        NextLineNo := NextLineNo + LineSpacing;
        ReminderLine.Init();
        ReminderLine."Line No." := NextLineNo;
        ReminderLine."Line Type" := LineType;
#if not CLEAN20
        OnBeforeInsertReminderLine(ReminderLine);
#endif
        OnInsertBlankLineOnBeforeReminderLineInsert(ReminderLine);
        ReminderLine.Insert();
    end;

    procedure PrintRecords()
    var
        ReminderHeader: Record "Reminder Header";
        ReportSelection: Record "Report Selections";
    begin
        with ReminderHeader do begin
            Copy(Rec);
            FindFirst();
            SetRecFilter();
            ReportSelection.PrintForCust(ReportSelection.Usage::"Rem.Test", ReminderHeader, FieldNo("Customer No."));
        end;
    end;

    procedure ConfirmDeletion() Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmDeletion(Rec, IssuedReminderHeader, Confirmed, IsHandled);
        if IsHandled then
            exit(Confirmed);

        ReminderIssue.TestDeleteHeader(Rec, IssuedReminderHeader);
        if IssuedReminderHeader."No." <> '' then
            if not Confirm(
                 Text005 +
                 Text006 +
                 Text003, true,
                 IssuedReminderHeader."No.")
            then
                exit;
        exit(true);
    end;

#if not CLEAN20
    [Obsolete('Replaced by CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])', '20.0')]
    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, TableID, No, Type1, No1, SourceCodeSetup, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Reminder, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, TableID, No);
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN20
        RunEventOnBeforeCreateDim(DefaultDimSource, IsHandled);
#endif
        OnBeforeCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource, IsHandled);
        if not IsHandled then begin
            SourceCodeSetup.Get();
#if not CLEAN20
            RunEventOnAfterCreateDimTableIDs(DefaultDimSource);
#endif

            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Reminder, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;
#if not CLEAN20
        RunEventOnAfterCreateDim(DefaultDimSource);
#endif
        OnAfterCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetInvoiceRoundingAmount(): Decimal
    var
        TotalAmountInclVAT: Decimal;
    begin
        GetCurrency();
        if Currency."Invoice Rounding Precision" = 0 then
            exit(0);

        CalcFields(
            "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
        TotalAmountInclVAT :=
            "Remaining Amount" + "Interest Amount" + "Additional Fee" +
            "Add. Fee per Line" + "VAT Amount";

        exit(
            -Round(
                TotalAmountInclVAT -
                Round(
                    TotalAmountInclVAT,
                    Currency."Invoice Rounding Precision",
                    Currency.InvoiceRoundingDirection()),
                Currency."Amount Rounding Precision"));
    end;

    local procedure ReminderRounding(var ReminderHeader: Record "Reminder Header")
    var
        ReminderRoundingAmount: Decimal;
        Handled: Boolean;
    begin
        OnBeforeReminderRounding(ReminderHeader, Handled);
        if Handled then
            exit;

        ReminderRoundingAmount := ReminderHeader.GetInvoiceRoundingAmount();

        if ReminderRoundingAmount <> 0 then begin
            CustPostingGr.Get(ReminderHeader."Customer Posting Group");
            with ReminderLine do begin
                Init();
                Validate("Line No.", GetNextLineNo(ReminderHeader."No."));
                Validate("Reminder No.", ReminderHeader."No.");
                Validate(Type, Type::"G/L Account");
                "System-Created Entry" := true;
                Validate("No.", CustPostingGr.GetInvRoundingAccount());
                Validate(
                  Amount,
                  Round(
                    ReminderRoundingAmount / (1 + ("VAT %" / 100)),
                    Currency."Amount Rounding Precision"));
                "VAT Amount" := ReminderRoundingAmount - Amount;
                "Line Type" := "Line Type"::Rounding;
                Insert();
            end;
        end;
    end;

    local procedure GetCurrency()
    begin
        if "Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get("Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure UpdateReminderRounding(ReminderHeader: Record "Reminder Header")
    var
        OldLineNo: Integer;
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::Rounding);
        if ReminderLine.FindFirst() then
            ReminderLine.Delete(true);

        ReminderLine.SetRange("Line Type");
        ReminderLine.SetFilter(Type, '<>%1', ReminderLine.Type::" ");
        if ReminderLine.FindLast() then begin
            OldLineNo := ReminderLine."Line No.";
            ReminderLine.SetRange(Type);
            if ReminderLine.Next() <> 0 then
                ReminderLine."Line No." := OldLineNo + ((ReminderLine."Line No." - OldLineNo) div 2)
            else
                ReminderLine."Line No." := OldLineNo + 10000;
        end else
            ReminderLine."Line No." := 10000;

        ReminderRounding(ReminderHeader);
    end;

    procedure ShowDocDim()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDocDim(Rec);
    end;

    procedure CalculateLineFeeVATAmount(): Decimal
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetCurrentKey("Reminder No.", Type, "Line Type");
        ReminderLine.SetRange("Reminder No.", "No.");
        ReminderLine.SetRange(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.CalcSums("VAT Amount");
        exit(ReminderLine."VAT Amount");
    end;

    local procedure GetNextLineNo(ReminderNo: Code[20]): Integer
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        if ReminderLine.FindLast() then
            exit(ReminderLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;

    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    procedure SetCustomerFromFilter()
    begin
        if GetFilterCustNo() <> '' then
            Validate("Customer No.", GetFilterCustNo());
    end;

    [Scope('OnPrem')]
    procedure SetReminderNo()
    begin
        if "No." = '' then begin
            TestNoSeries();
            NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
    end;

    local procedure CheckCustomerBlockedAll(Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustomerBlockedAll(Rec, Cust, IsHandled);
        if IsHandled then
            exit;

        if Cust.Blocked = Cust.Blocked::All then
            Cust.CustBlockedErrorMessage(Cust, false);
    end;

    local procedure PrintIssuedReminders()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintIssuedReminders(Rec, IsHandled);
        if IsHandled then
            exit;

        if IssuedReminderHeader."No." <> '' then begin
            Commit();
            if Confirm(Text001, true, IssuedReminderHeader."No.") then begin
                IssuedReminderHeader.SetRecFilter();
                IssuedReminderHeader.PrintRecords(true, false, false)
            end;
        end;
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Customer No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

#if not CLEAN20
    local procedure RunEventOnBeforeCreateDim(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        Type1: Integer;
        No1: Code[20];
    begin
        if not DimArrayConversionHelper.IsSubscriberExist(Database::"Reminder Header") then
            exit;

        DimArrayConversionHelper.CreateDimTableIDs(Database::"Reminder Header", DefaultDimSource, TableID, No);
        Type1 := TableID[1];
        No1 := No[1];
        OnBeforeCreateDim(Rec, CurrFieldNo, TableID, No, Type1, No1, SourceCodeSetup, IsHandled);
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Reminder Header", DefaultDimSource, TableID, No);
    end;

    local procedure RunEventOnAfterCreateDimTableIDs(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if not DimArrayConversionHelper.IsSubscriberExist(Database::"Reminder Header") then
            exit;

        DimArrayConversionHelper.CreateDimTableIDs(Database::"Reminder Header", DefaultDimSource, TableID, No);
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Reminder Header", DefaultDimSource, TableID, No);
    end;

    local procedure RunEventOnAfterCreateDim(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if not DimArrayConversionHelper.IsSubscriberExist(Database::"Reminder Header") then
            exit;

        DimArrayConversionHelper.CreateDimTableIDs(Database::"Reminder Header", DefaultDimSource, TableID, No);
        OnAfterCreateDim(Rec, CurrFieldNo, TableID, No);
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Reminder Header", DefaultDimSource, TableID, No);
    end;

    [Obsolete('Replaced by OnAfterInitDefaultDimensionSources()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ReminderHeader: Record "Reminder Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ReminderHeader: Record "Reminder Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnAfterCreateDimProcedure()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ReminderHeader: Record "Reminder Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimProcedure(var ReminderHeader: Record "Reminder Header"; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(ReminderHeader: Record "Reminder Header"; IssuedReminderHeader: Record "Issued Reminder Header"; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var ReminderHeader: Record "Reminder Header"; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetIssuingNoSeriesCode(var ReminderHeader: Record "Reminder Header"; var IssuingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompanyBankAccount(var ReminderHeader: Record "Reminder Header"; xReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ReminderHeader: Record "Reminder Header"; var xReminderHeader: Record "Reminder Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLines(var ReminderHeader: Record "Reminder Header"; UpdateAdditionalFee: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocDim(var ReminderHeader: Record "Reminder Header")
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnBeforeCreateDimProcedure()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ReminderHeader: Record "Reminder Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20]; Type1: Integer; No1: Code[20]; SourceCodeSetup: Record "Source Code Setup"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIssuingNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var IssuingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced with OnInsertLinesOnBeforeReminderLineInsert', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReminderLine(var ReminderLine: Record "Reminder Line")
    begin
    end;

    [Obsolete('Replaced with OnInsertTextLinesOnBeforeReminderLineInsert', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReminderTextLine(var ReminderLine: Record "Reminder Line"; var ReminderText: Record "Reminder Text"; var ReminderHeader: Record "Reminder Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnBeforeReminderLineInsert(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBlankLineOnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTextLinesOnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line"; var ReminderText: Record "Reminder Text"; var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEndTextsOnAfterReminderLineSetFilters(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEndTextsOnAfterReminderLevelSetFilters(var ReminderLevel: Record "Reminder Level"; ReminderHeader: Record "Reminder Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBeginTextsOnAfterReminderLevelSetFilters(var ReminderLevel: Record "Reminder Level"; var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnAfterReminderLevelSetFilters(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderRounding(var ReminderHeader: Record "Reminder Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBeginTexts(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBlankLine(var ReminderHeader: Record "Reminder Header"; LineType: Enum "Reminder Line Type"; NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEndTexts(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateReminderLevel(var ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ReminderHeader: Record "Reminder Header"; var xReminderHeader: Record "Reminder Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerBlockedAll(var ReminderHeader: Record "Reminder Header"; Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintIssuedReminders(var Rec: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBeginTextsOnAfterReminderTextSetFilters(var ReminderText: Record "Reminder Text"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEndTextsOnAfterReminderTextSetFilters(var ReminderText: Record "Reminder Text"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnAfterCalcAdditionalFee(var ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; var AdditionalFee: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnAfterAssignCustomerValues(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var ReminderHeader: Record "Reminder Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var ReminderHeader: Record "Reminder Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

