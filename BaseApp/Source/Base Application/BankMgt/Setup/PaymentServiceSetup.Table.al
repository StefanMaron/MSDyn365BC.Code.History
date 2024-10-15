namespace Microsoft.Bank.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Reflection;
using System.IO;

table 1060 "Payment Service Setup"
{
    Caption = 'Payment Service Setup';
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Payment Reporting Argument" = rimd;

    fields
    {
        field(1; "No."; Text[250])
        {
            Caption = 'No.';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            NotBlank = true;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(5; "Always Include on Documents"; Boolean)
        {
            Caption = 'Always Include on Documents';

            trigger OnValidate()
            var
                SalesHeader: Record "Sales Header";
            begin
                if Confirm(UpdateExistingInvoicesQst) then begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    if SalesHeader.FindSet(true, false) then
                        repeat
                            SalesHeader.SetDefaultPaymentServices();
                            SalesHeader.Modify();
                        until SalesHeader.Next() = 0;
                end;
            end;
        }
        field(6; "Setup Record ID"; RecordID)
        {
            Caption = 'Setup Record ID';
            DataClassification = CustomerContent;
        }
        field(7; "Setup Page ID"; Integer)
        {
            Caption = 'Setup Page ID';
        }
        field(8; "Terms of Service"; Text[250])
        {
            Caption = 'Terms of Service';
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(100; Available; Boolean)
        {
            Caption = 'Available';
        }
        field(101; "Management Codeunit ID"; Integer)
        {
            Caption = 'Management Codeunit ID';
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
    begin
        DeletePaymentServiceSetup(true);
    end;

    var
        NoPaymentMethodsSelectedTxt: Label 'No payment service is made available.';
        SetupPaymentServicesQst: Label 'No payment services have been set up.\\Do you want to set up a payment service?';
        SetupExistingServicesOrCreateNewQst: Label 'One or more payment services are set up, but none are enabled.\\Do you want to:';
        CreateOrUpdateOptionQst: Label 'Set Up a Payment Service,Create a New Payment Service';
        UpdateExistingInvoicesQst: Label 'Do you want to update the ongoing Sales Invoices with this Payment Service information?';
        ReminderToSendAgainMsg: Label 'The payment service was successfully changed.\\The invoice recipient will see the change when you send, or resend, the invoice.';

    procedure OpenSetupCard()
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SetupRecordRef: RecordRef;
        SetupRecordVariant: Variant;
    begin
        if not DataTypeManagement.GetRecordRef("Setup Record ID", SetupRecordRef) then
            exit;

        SetupRecordVariant := SetupRecordRef;
        PAGE.RunModal("Setup Page ID", SetupRecordVariant);
    end;

    procedure CreateReportingArgs(var PaymentReportingArgument: Record "Payment Reporting Argument"; DocumentRecordVariant: Variant)
    var
        DummySalesHeader: Record "Sales Header";
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        DataTypeMgt: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        PaymentServiceFieldRef: FieldRef;
        SetID: Integer;
        LastKey: Integer;
    begin
        PaymentReportingArgument.Reset();
        PaymentReportingArgument.DeleteAll();

        DataTypeMgt.GetRecordRef(DocumentRecordVariant, DocumentRecordRef);
        DataTypeMgt.FindFieldByName(DocumentRecordRef, PaymentServiceFieldRef, DummySalesHeader.FieldName("Payment Service Set ID"));

        SetID := PaymentServiceFieldRef.Value;

        GetEnabledPaymentServices(TempPaymentServiceSetup);
        LoadSet(TempPaymentServiceSetup, SetID);
        TempPaymentServiceSetup.SetRange(Available, true);

        if not TempPaymentServiceSetup.FindFirst() then
            exit;

        repeat
            LastKey := PaymentReportingArgument.Key;
            Clear(PaymentReportingArgument);
            PaymentReportingArgument.Key := LastKey + 1;
            PaymentReportingArgument.Validate("Document Record ID", DocumentRecordRef.RecordId);
            PaymentReportingArgument.Validate("Setup Record ID", TempPaymentServiceSetup."Setup Record ID");
            PaymentReportingArgument.Insert(true);
            CODEUNIT.Run(TempPaymentServiceSetup."Management Codeunit ID", PaymentReportingArgument);
        until TempPaymentServiceSetup.Next() = 0;
    end;

    procedure GetDefaultPaymentServices(var SetID: Integer): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        OnRegisterPaymentServices(TempPaymentServiceSetup);
        TempPaymentServiceSetup.SetRange("Always Include on Documents", true);
        TempPaymentServiceSetup.SetRange(Enabled, true);

        if not TempPaymentServiceSetup.FindFirst() then
            exit(false);

        TransferToRecordSetBuffer(TempPaymentServiceSetup, TempRecordSetBuffer);
        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);
        if SetID = 0 then
            SetID := RecordSetManagement.SaveSet(TempRecordSetBuffer);

        exit(true);
    end;

    procedure SelectPaymentService(var SetID: Integer): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        if not GetEnabledPaymentServices(TempPaymentServiceSetup) then begin
            if not AskUserToSetupNewPaymentService(TempPaymentServiceSetup) then
                exit(false);

            // If user has setup the service then just select that one
            if TempPaymentServiceSetup.Count = 1 then begin
                TempPaymentServiceSetup.FindFirst();
                SetID := SaveSet(TempPaymentServiceSetup);
                exit(true);
            end;
        end;

        if SetID <> 0 then
            LoadSet(TempPaymentServiceSetup, SetID);

        TempPaymentServiceSetup.Reset();
        TempPaymentServiceSetup.SetRange(Enabled, true);

        if not (PAGE.RunModal(PAGE::"Select Payment Service", TempPaymentServiceSetup) = ACTION::LookupOK) then
            exit(false);

        TempPaymentServiceSetup.SetRange(Available, true);
        if TempPaymentServiceSetup.FindFirst() then
            SetID := SaveSet(TempPaymentServiceSetup)
        else
            Clear(SetID);

        exit(true);
    end;

    local procedure GetEnabledPaymentServices(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Boolean
    begin
        TempPaymentServiceSetup.Reset();
        TempPaymentServiceSetup.DeleteAll();
        OnRegisterPaymentServices(TempPaymentServiceSetup);
        TempPaymentServiceSetup.SetRange(Enabled, true);
        exit(TempPaymentServiceSetup.FindSet());
    end;

    local procedure TransferToRecordSetBuffer(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempRecordSetBuffer: Record "Record Set Buffer" temporary)
    var
        CurrentKey: Integer;
    begin
        TempPaymentServiceSetup.FindFirst();

        repeat
            CurrentKey := TempRecordSetBuffer.No;
            Clear(TempRecordSetBuffer);
            TempRecordSetBuffer.No := CurrentKey + 1;
            TempRecordSetBuffer."Value RecordID" := TempPaymentServiceSetup."Setup Record ID";
            TempRecordSetBuffer.Insert();
        until TempPaymentServiceSetup.Next() = 0;
    end;

    procedure SaveSet(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Integer
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        TransferToRecordSetBuffer(TempPaymentServiceSetup, TempRecordSetBuffer);
        exit(RecordSetManagement.SaveSet(TempRecordSetBuffer));
    end;

    procedure LoadSet(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; SetID: Integer)
    var
        TempRecordSetBuffer: Record "Record Set Buffer" temporary;
        RecordSetManagement: Codeunit "Record Set Management";
    begin
        if not TempPaymentServiceSetup.FindFirst() then
            exit;

        RecordSetManagement.GetSet(TempRecordSetBuffer, SetID);

        if not TempRecordSetBuffer.FindFirst() then begin
            TempPaymentServiceSetup.ModifyAll(Available, false);
            exit;
        end;

        repeat
            TempRecordSetBuffer.SetRange("Value RecordID", TempPaymentServiceSetup."Setup Record ID");
            if TempRecordSetBuffer.FindFirst() then begin
                TempPaymentServiceSetup.Available := true;
                TempPaymentServiceSetup.Modify();
            end;
        until TempPaymentServiceSetup.Next() = 0;
    end;

    procedure GetSelectedPaymentsText(SetID: Integer) SelectedPaymentServices: Text
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        SelectedPaymentServices := NoPaymentMethodsSelectedTxt;

        if SetID = 0 then
            exit;

        OnRegisterPaymentServices(TempPaymentServiceSetup);
        LoadSet(TempPaymentServiceSetup, SetID);

        TempPaymentServiceSetup.SetRange(Available, true);
        if not TempPaymentServiceSetup.FindSet() then
            exit;

        Clear(SelectedPaymentServices);
        repeat
            SelectedPaymentServices += StrSubstNo(',%1', TempPaymentServiceSetup.Name);
        until TempPaymentServiceSetup.Next() = 0;

        SelectedPaymentServices := CopyStr(SelectedPaymentServices, 2);
    end;

    procedure CanChangePaymentService(DocumentVariant: Variant) Result: Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        PaymentMethodCodeFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        DataTypeManagement.GetRecordRef(DocumentVariant, DocumentRecordRef);
        IsHandled := false;
        OnCanChangePaymentServiceOnAfterGetRecordRef(DocumentVariant, DocumentRecordRef, Result, IsHandled);
        if IsHandled then
            exit(Result);
        case DocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Copy(DocumentVariant);
                    SalesInvoiceHeader.CalcFields(Closed, "Remaining Amount");
                    if SalesInvoiceHeader.Closed or (SalesInvoiceHeader."Remaining Amount" = 0) then
                        exit(false);
                end
            else
                if DataTypeManagement.FindFieldByName(
                        DocumentRecordRef, PaymentMethodCodeFieldRef, SalesInvoiceHeader.FieldName("Payment Method Code"))
                then
                    if not CanUsePaymentMethod(Format(PaymentMethodCodeFieldRef.Value)) then
                        exit(false);
        end;

        exit(true);
    end;

    local procedure CanUsePaymentMethod(PaymentMethodCode: Code[10]) Result: Boolean
    var
        PaymentMethod: Record "Payment Method";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanUsePaymentMethod(PaymentMethodCode, Result, IsHandled);
        if IsHandled then
            exit;

        if not PaymentMethod.Get(PaymentMethodCode) then
            exit(true);

        exit(PaymentMethod."Bal. Account No." = '');
    end;

    procedure ChangePaymentServicePostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        SetID := SalesInvoiceHeader."Payment Service Set ID";
        if PaymentServiceSetup.SelectPaymentService(SetID) then begin
            SalesInvoiceHeader.Validate("Payment Service Set ID", SetID);
            SalesInvoiceHeader.Modify(true);
            if GuiAllowed and (Format(SalesInvoiceHeader."Payment Service Set ID") <> '') then
                Message(ReminderToSendAgainMsg);
        end;
    end;

    local procedure AskUserToSetupNewPaymentService(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Boolean
    var
        TempNotEnabledPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
        SetupOrCreatePaymentService: Option ,"Setup Payment Services","Create New";
        SelectedOption: Integer;
        DefinedPaymentServiceExist: Boolean;
    begin
        if not GuiAllowed then
            exit(false);

        OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        if not TempPaymentServiceSetupProviders.FindFirst() then
            exit(false);

        // Check if there are payment services that are not enabled
        OnRegisterPaymentServices(TempNotEnabledPaymentServiceSetupProviders);
        DefinedPaymentServiceExist := TempNotEnabledPaymentServiceSetupProviders.FindFirst();

        if DefinedPaymentServiceExist then begin
            SelectedOption := StrMenu(CreateOrUpdateOptionQst, 1, SetupExistingServicesOrCreateNewQst);
            case SelectedOption of
                SetupOrCreatePaymentService::"Setup Payment Services":
                    PAGE.RunModal(PAGE::"Payment Services");
                SetupOrCreatePaymentService::"Create New":
                    NewPaymentService();
                else
                    exit(false);
            end;
            exit(GetEnabledPaymentServices(TempPaymentServiceSetup));
        end;

        // Ask to create a new service
        if Confirm(SetupPaymentServicesQst) then begin
            NewPaymentService();
            exit(GetEnabledPaymentServices(TempPaymentServiceSetup));
        end;

        exit(false);
    end;

    procedure IsPaymentServiceVisible(): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        exit(not TempPaymentServiceSetup.IsEmpty);
    end;

    procedure NewPaymentService(): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
    begin
        OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        case TempPaymentServiceSetupProviders.Count of
            0:
                exit(false);
            1:
                begin
                    TempPaymentServiceSetupProviders.FindFirst();
                    OnCreatePaymentService(TempPaymentServiceSetupProviders);
                    exit(true);
                end;
            else begin
                Commit();
                if PAGE.RunModal(PAGE::"Select Payment Service Type", TempPaymentServiceSetup) = ACTION::LookupOK then begin
                    OnCreatePaymentService(TempPaymentServiceSetup);
                    exit(true);
                end;
                exit(false);
            end;
        end;
    end;

    procedure AssignPrimaryKey(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
        PaymentServiceSetup."No." := Format(PaymentServiceSetup."Setup Record ID");
    end;

    procedure DeletePaymentServiceSetup(RunTrigger: Boolean)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SetupRecordRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef("Setup Record ID", SetupRecordRef);
        SetupRecordRef.Delete(RunTrigger);
    end;

    procedure TermsOfServiceDrillDown()
    begin
        if "Terms of Service" <> '' then
            HyperLink("Terms of Service");
    end;

    [IntegrationEvent(false, false)]
    procedure OnRegisterPaymentServices(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRegisterPaymentServiceProviders(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanUsePaymentMethod(PaymentMethodCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCreatePaymentService(var PaymentServiceSetup: Record "Payment Service Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDoNotIncludeAnyPaymentServicesOnAllDocuments()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanChangePaymentServiceOnAfterGetRecordRef(DocumentVariant: Variant; DocumentRecordRef: RecordRef; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

