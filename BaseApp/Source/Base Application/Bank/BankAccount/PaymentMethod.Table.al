namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.PaymentTerms;
using System.Globalization;
using System.IO;

table 289 "Payment Method"
{
    Caption = 'Payment Method';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Payment Methods";
    LookupPageID = "Payment Methods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(4; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account No." <> '' then
                    TestField("Direct Debit", false);
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" then
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        field(6; "Direct Debit"; Boolean)
        {
            Caption = 'Direct Debit';

            trigger OnValidate()
            begin
                if not "Direct Debit" then
                    "Direct Debit Pmt. Terms Code" := '';
                if "Direct Debit" then
                    TestField("Bal. Account No.", '');
            end;
        }
        field(7; "Direct Debit Pmt. Terms Code"; Code[10])
        {
            Caption = 'Direct Debit Pmt. Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                if "Direct Debit Pmt. Terms Code" <> '' then
                    TestField("Direct Debit", true);
            end;
        }
        field(8; "Pmt. Export Line Definition"; Code[20])
        {
            Caption = 'Pmt. Export Line Definition';

            trigger OnLookup()
            var
                DataExchLineDef: Record "Data Exch. Line Def";
                TempDataExchLineDef: Record "Data Exch. Line Def" temporary;
                DataExchDef: Record "Data Exch. Def";
            begin
                DataExchLineDef.SetFilter(Code, '<>%1', '');
                if DataExchLineDef.FindSet() then begin
                    repeat
                        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");
                        if DataExchDef.Type = DataExchDef.Type::"Payment Export" then begin
                            TempDataExchLineDef.Init();
                            TempDataExchLineDef.Code := DataExchLineDef.Code;
                            TempDataExchLineDef.Name := DataExchLineDef.Name;
                            if TempDataExchLineDef.Insert() then;
                        end;
                    until DataExchLineDef.Next() = 0;
                    if PAGE.RunModal(PAGE::"Pmt. Export Line Definitions", TempDataExchLineDef) = ACTION::LookupOK then
                        "Pmt. Export Line Definition" := TempDataExchLineDef.Code;
                end;
            end;
        }
        field(9; "Bank Data Conversion Pmt. Type"; Text[50])
        {
            Caption = 'Bank Data Conversion Pmt. Type';
            ObsoleteState = Removed;
            ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
            ObsoleteTag = '15.0';
        }
        field(10; "Use for Invoicing"; Boolean)
        {
            Caption = 'Use for Invoicing';
            ObsoleteReason = 'Microsoft Invoicing is not supported on Business Central';
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
        }
        field(11; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
    begin
        PaymentMethodTranslation.SetRange("Payment Method Code", Code);
        PaymentMethodTranslation.DeleteAll();
    end;

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAcc(Rec, CurrFieldNo, AccNo, IsHandled);
        if IsHandled then
            exit;

        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Direct Posting", true);
        end;
    end;

    procedure TranslateDescription(Language: Code[10])
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
    begin
        if PaymentMethodTranslation.Get(Code, Language) then
            Validate(Description, CopyStr(PaymentMethodTranslation.Description, 1, MaxStrLen(Description)));
    end;

    procedure GetDescriptionInCurrentLanguage(): Text[100]
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
        Language: Codeunit Language;
    begin
        if PaymentMethodTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(PaymentMethodTranslation.Description);

        exit(Description);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var PaymentMethod: Record "Payment Method"; CurrFieldNo: Integer; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

