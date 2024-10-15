table 11704 "Bank Statement Header"
{
    Caption = 'Bank Statement Header';
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
    DrillDownPageID = "Bank Statement List";
    LookupPageID = "Bank Statement List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if ("No." <> xRec."No.") and ("Bank Account No." <> '') then begin
                    BankAccount.Get("Bank Account No.");
                    NoSeriesMgt.TestManual(BankAccount."Bank Statement Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Bank Account"));

            trigger OnValidate()
            var
                BankAccount: Record "Bank Account";
            begin
                if not BankAccount.Get("Bank Account No.") then
                    BankAccount.Init;
                "Account No." := BankAccount."Bank Account No.";
                BankAccount.TestField(Blocked, false);
                IBAN := BankAccount.IBAN;
                "SWIFT Code" := BankAccount."SWIFT Code";
                Validate("Currency Code", BankAccount."Currency Code");

                CalcFields("Bank Account Name");
            end;
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup ("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor;
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmUpdateCurrencyFactor;
                end;
            end;
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then begin
                        UpdateCurrencyFactor;
                        UpdateBankStmtLine(FieldCaption("Currency Code"), false);
                    end else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;

                Validate("Bank Statement Currency Code", "Currency Code");
            end;
        }
        field(8; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;

            trigger OnValidate()
            begin
                if "Currency Code" = "Bank Statement Currency Code" then
                    "Bank Statement Currency Factor" := "Currency Factor";
                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdateBankStmtLine(FieldCaption("Currency Factor"), false);
            end;
        }
        field(9; Amount; Decimal)
        {
            CalcFormula = Sum ("Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = - Sum ("Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No."),
                                                                   Positive = CONST(false)));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = - Sum ("Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No."),
                                                                           Positive = CONST(false)));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = Sum ("Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No."),
                                                                  Positive = CONST(true)));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No."),
                                                                          Positive = CONST(true)));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = Count ("Bank Statement Line" WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(17; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(20; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if CurrFieldNo <> FieldNo("Bank Statement Currency Code") then
                    UpdateOrderCurrencyFactor
                else
                    if "Bank Statement Currency Code" <> xRec."Bank Statement Currency Code" then begin
                        UpdateOrderCurrencyFactor;
                        UpdateBankStmtLine(FieldCaption("Bank Statement Currency Code"), CurrFieldNo <> 0);
                    end else
                        if "Bank Statement Currency Code" <> '' then begin
                            UpdateOrderCurrencyFactor;
                            if "Bank Statement Currency Factor" <> xRec."Bank Statement Currency Factor" then
                                ConfUpdateOrderCurrencyFactor;
                        end;
            end;
        }
        field(21; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;

            trigger OnValidate()
            begin
                if "Currency Code" = "Bank Statement Currency Code" then
                    "Currency Factor" := "Bank Statement Currency Factor";
                if "Bank Statement Currency Factor" <> xRec."Bank Statement Currency Factor" then
                    UpdateBankStmtLine(FieldCaption("Bank Statement Currency Factor"), CurrFieldNo <> 0);
            end;
        }
        field(30; "Last Issuing No."; Code[20])
        {
            Caption = 'Last Issuing No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
                BankStmtHeader: Record "Bank Statement Header";
                IssuedBankStmtHeader: Record "Issued Bank Statement Header";
            begin
                BankStmtHeader.SetFilter("Bank Account No.", "Bank Account No.");
                BankStmtHeader.SetFilter("No.", '<>%1', "No.");
                BankStmtHeader.SetRange("External Document No.", "External Document No.");
                BankAccount.Get("Bank Account No.");
                if BankAccount."Check Ext. No. by Current Year" then begin
                    TestField("Document Date");
                    BankStmtHeader.SetRange("Document Date", CalcDate('<CY>-<1Y>+<1D>', "Document Date"), CalcDate('<CY>', "Document Date"));
                end;
                if BankStmtHeader.FindFirst then begin
                    Message(ExternalDocMsg, BankStmtHeader.FieldCaption("External Document No."), BankStmtHeader.TableCaption,
                      BankStmtHeader.FieldCaption("No."), BankStmtHeader."No.");
                    exit;
                end;

                IssuedBankStmtHeader.SetFilter("Bank Account No.", "Bank Account No.");
                IssuedBankStmtHeader.SetRange("External Document No.", "External Document No.");
                if BankAccount."Check Ext. No. by Current Year" then begin
                    TestField("Document Date");
                    IssuedBankStmtHeader.SetRange("Document Date", CalcDate('<CY>-<1Y>+<1D>', "Document Date"), CalcDate('<CY>', "Document Date"));
                end;
                if IssuedBankStmtHeader.FindFirst then begin
                    Message(ExternalDocMsg, IssuedBankStmtHeader.FieldCaption("External Document No."), IssuedBankStmtHeader.TableCaption,
                      IssuedBankStmtHeader.FieldCaption("No."), IssuedBankStmtHeader."No.");
                    exit;
                end;
            end;
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Check Amount"; Decimal)
        {
            Caption = 'Check Amount';
            Editable = false;
        }
        field(65; "Check Amount (LCY)"; Decimal)
        {
            Caption = 'Check Amount (LCY)';
            Editable = false;
        }
        field(70; "Check Debit"; Decimal)
        {
            Caption = 'Check Debit';
            Editable = false;
        }
        field(75; "Check Debit (LCY)"; Decimal)
        {
            Caption = 'Check Debit (LCY)';
            Editable = false;
        }
        field(80; "Check Credit"; Decimal)
        {
            Caption = 'Check Credit';
            Editable = false;
        }
        field(85; "Check Credit (LCY)"; Decimal)
        {
            Caption = 'Check Credit (LCY)';
            Editable = false;
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        BankStmtLine: Record "Bank Statement Line";
    begin
        BankStmtLine.SetRange("Bank Statement No.", "No.");
        BankStmtLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            BankAccount.Get("Bank Account No.");
            BankAccount.TestField("Bank Statement Nos.");
            NoSeriesMgt.InitSeries(BankAccount."Bank Statement Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Last Date Modified" := Today;
        "User ID" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := UserId;
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        BankAccount: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        ExternalDocMsg: Label 'The %1 field in the %2 table allready exist, field %3 = %4.', Comment = '%1=FIELDCAPTION,%2=TABLECAPTION,%3=FIELDCAPTION,%4=Field Value';
        UpdateCurrExchQst: Label 'Do you want to update Exchange Rate?';
        UpdateLinesQst: Label 'You have modified %1.\Do you want update lines?', Comment = '%1=FIELDCAPTION';

    [Scope('OnPrem')]
    procedure AssistEdit(OldBankStmtHeader: Record "Bank Statement Header"): Boolean
    var
        BankStmtHeader: Record "Bank Statement Header";
    begin
        with BankStmtHeader do begin
            BankStmtHeader := Rec;
            BankAccount.Get("Bank Account No.");
            BankAccount.TestField("Bank Statement Nos.");
            if NoSeriesMgt.SelectSeries(BankAccount."Bank Statement Nos.", OldBankStmtHeader."No. Series", "No. Series") then begin
                BankAccount.Get("Bank Account No.");
                BankAccount.TestField("Bank Account No.");
                NoSeriesMgt.SetSeries("No.");
                Rec := BankStmtHeader;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then
            "Currency Factor" := CurrExchRate.ExchangeRate("Document Date", "Currency Code")
        else
            "Currency Factor" := 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        if HideValidationDialog then
            Confirmed := true
        else
            Confirmed := Confirm(UpdateCurrExchQst, false);
        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('OnPrem')]
    procedure UpdateBankStmtLine(ChangedFieldName: Text[30]; AskQuestion: Boolean)
    var
        BankStmtLine: Record "Bank Statement Line";
        Question: Text[250];
    begin
        if not BankStmtLinesExist then
            exit;

        if AskQuestion then begin
            Question := StrSubstNo(UpdateLinesQst, ChangedFieldName);
            if GuiAllowed and not Confirm(Question, true) then
                exit;
        end;

        BankStmtLine.LockTable;
        "Last Date Modified" := Today;
        "User ID" := UserId;
        Modify;

        BankStmtLine.Reset;
        BankStmtLine.SetRange("Bank Statement No.", "No.");
        if BankStmtLine.FindSet then
            repeat
                case ChangedFieldName of
                    FieldCaption("Currency Code"):
                        begin
                            BankStmtLine.Validate("Currency Code", "Currency Code");
                            BankStmtLine.Validate("Amount (Bank Stat. Currency)");
                        end;
                    FieldCaption("Currency Factor"):
                        begin
                            if "Currency Code" = "Bank Statement Currency Code" then
                                BankStmtLine."Bank Statement Currency Factor" := "Bank Statement Currency Factor";
                            BankStmtLine.Validate("Amount (Bank Stat. Currency)");
                        end;
                    FieldCaption("Bank Statement Currency Code"):
                        begin
                            BankStmtLine."Bank Statement Currency Factor" := "Bank Statement Currency Factor";
                            BankStmtLine."Bank Statement Currency Code" := "Bank Statement Currency Code";
                            BankStmtLine.Validate("Amount (Bank Stat. Currency)");
                        end;
                    FieldCaption("Bank Statement Currency Factor"):
                        begin
                            BankStmtLine."Bank Statement Currency Factor" := "Bank Statement Currency Factor";
                            BankStmtLine.Validate("Amount (Bank Stat. Currency)");
                        end;
                end;
                BankStmtLine.Modify(true);
            until BankStmtLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure BankStmtLinesExist(): Boolean
    var
        BankStmtLine: Record "Bank Statement Line";
    begin
        BankStmtLine.Reset;
        BankStmtLine.SetRange("Bank Statement No.", "No.");
        exit(not BankStmtLine.IsEmpty);
    end;

    local procedure UpdateOrderCurrencyFactor()
    begin
        if "Bank Statement Currency Code" <> '' then
            "Bank Statement Currency Factor" := CurrExchRate.ExchangeRate("Document Date", "Bank Statement Currency Code")
        else
            "Bank Statement Currency Factor" := 0;

        if "Currency Code" = "Bank Statement Currency Code" then
            "Currency Factor" := "Bank Statement Currency Factor";
    end;

    local procedure ConfUpdateOrderCurrencyFactor()
    begin
        if HideValidationDialog then
            Confirmed := true
        else
            Confirmed := Confirm(UpdateCurrExchQst, false);
        if Confirmed then
            Validate("Bank Statement Currency Factor")
        else
            "Bank Statement Currency Factor" := xRec."Bank Statement Currency Factor";
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(HideValidationDialogNew: Boolean)
    begin
        HideValidationDialog := HideValidationDialogNew;
    end;

    [Scope('OnPrem')]
    procedure ImportBankStatement()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bank Account No.");
        if BankAcc.GetBankStatementImportCodeunitID > 0 then
            CODEUNIT.Run(BankAcc.GetBankStatementImportCodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Imp. Launcher Bank Statement", Rec);
    end;

    [Scope('OnPrem')]
    procedure TestPrintRecords(ShowRequestForm: Boolean)
    var
        BankStmtHdr: Record "Bank Statement Header";
    begin
        BankStmtHdr.Copy(Rec);
        REPORT.RunModal(REPORT::"Bank Statement - Test", ShowRequestForm, false, BankStmtHdr);
    end;
}

