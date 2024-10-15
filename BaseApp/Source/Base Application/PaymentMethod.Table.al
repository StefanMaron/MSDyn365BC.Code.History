table 289 "Payment Method"
{
    Caption = 'Payment Method';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Payment Methods";
    LookupPageID = "Payment Methods";

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
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

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
                if DataExchLineDef.FindSet then begin
                    repeat
                        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");
                        if DataExchDef.Type = DataExchDef.Type::"Payment Export" then begin
                            TempDataExchLineDef.Init();
                            TempDataExchLineDef.Code := DataExchLineDef.Code;
                            TempDataExchLineDef.Name := DataExchLineDef.Name;
                            if TempDataExchLineDef.Insert() then;
                        end;
                    until DataExchLineDef.Next = 0;
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
            ObsoleteState = Pending;
            ObsoleteReason = 'Microsoft Invoicing is not supported on Business Central';
            ObsoleteTag = '15.0';

            trigger OnValidate()
            var
                EnvInfoProxy: Codeunit "Env. Info Proxy";
            begin
                if EnvInfoProxy.IsInvoicing then
                    if not "Use for Invoicing" then
                        Error(UseForInvoicingErr);
            end;
        }
        field(11; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(10700; "SII Payment Method Code"; Option)
        {
            Caption = 'SII Payment Method Code';
            OptionCaption = ' ,01,02,03,04,05';
            OptionMembers = " ","01","02","03","04","05";
        }
        field(7000000; "Create Bills"; Boolean)
        {
            Caption = 'Create Bills';

            trigger OnValidate()
            begin
                if "Invoices to Cartera" and "Create Bills" then
                    Error(Text1100000, FieldCaption("Invoices to Cartera"));
            end;
        }
        field(7000001; "Collection Agent"; Option)
        {
            Caption = 'Collection Agent';
            OptionCaption = 'Direct,Bank';
            OptionMembers = Direct,Bank;
        }
        field(7000002; "Submit for Acceptance"; Boolean)
        {
            Caption = 'Submit for Acceptance';
        }
        field(7000003; "Bill Type"; Option)
        {
            Caption = 'Bill Type';
            OptionCaption = ' ,Bill of Exchange,Receipt,IOU,Check,Transfer';
            OptionMembers = " ","Bill of Exchange",Receipt,IOU,Check,Transfer;
        }
        field(7000004; "Invoices to Cartera"; Boolean)
        {
            Caption = 'Invoices to Cartera';

            trigger OnValidate()
            begin
                if "Create Bills" and "Invoices to Cartera" then
                    Error(Text1100000, FieldCaption("Create Bills"));
            end;
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
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if EnvInfoProxy.IsInvoicing then
            if not "Use for Invoicing" then
                Validate("Use for Invoicing", true);

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

    var
        Text1100000: Label '%1 must be set equal to False';
        UseForInvoicingErr: Label 'The Use for Invoicing property must be set to true in the Invoicing App.';

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
            GLAcc.CheckGLAcc;
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
        if PaymentMethodTranslation.Get(Code, Language.GetUserLanguageCode) then
            exit(PaymentMethodTranslation.Description);

        exit(Description);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var PaymentMethod: Record "Payment Method"; CurrFieldNo: Integer; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

