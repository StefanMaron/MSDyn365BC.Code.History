// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.History;
using System.IO;
using System.Utilities;

codeunit 27000 "Export Accounts"
{

    trigger OnRun()
    begin
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        TestFileName: Text;
        GLAccountTypeErr: Label 'Debit/Credit ''%1'' is not supported in %2.';
        InvalidMonthErr: Label 'The Month must be in the range 1-12.';
        InvalidYearErr: Label 'The Year must be in the range 2000-2999.';
        MissingUpdateDateErr: Label 'You need to specify an update date before export.';
        MissingOrderNumberErr: Label 'You need to specify an Order Number before export.';
        NoSATAccountDefinedErr: Label 'You need to specify SAT Account Code on G/L Accounts before export.';
        NamespaceTxt: Label 'http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/', Locked = true;
        NamespaceW3Txt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        CatalogoNamespaceTxt: Label 'CatalogoCuentas', Locked = true;
        BalanzaNamespaceTxt: Label 'BalanzaComprobacion', Locked = true;
        PolizasNamespaceTxt: Label 'PolizasPeriodo', Locked = true;
        AuxiliaryAccountNamespaceTxt: Label 'AuxiliarCtas', Locked = true;
        CatalogoNodeTxt: Label 'Catalogo', Locked = true;
        BalanzaNodeTxt: Label 'Balanza', Locked = true;
        PolizasNodeTxt: Label 'Polizas', Locked = true;
        AuxiliaryAccountNodeTxt: Label 'AuxiliarCtas', Locked = true;

    procedure ExportChartOfAccounts(Year: Integer; Month: Integer)
    var
        GLAccount: Record "G/L Account";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempErrorMessage.ClearLog();
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        CreateXMLHeader(TempXMLBuffer, CatalogoNodeTxt, CatalogoNamespaceTxt, Year, Month, '1.3');
        if GLAccount.FindSet() then
            repeat
                TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

                GLAccount.CalcFields("Debit Amount", "Credit Amount");
                TempXMLBuffer.AddGroupElement('Ctas');
                TempXMLBuffer.AddAttribute('CodAgrup', GLAccount."SAT Account Code");
                TempXMLBuffer.AddAttribute('NumCta', GLAccount."No.");
                TempXMLBuffer.AddAttribute('Desc', GLAccount.Name);
                TempXMLBuffer.AddAttribute('Nivel', Format(GLAccount.Indentation + 1));
                case GLAccount."Debit/Credit" of
                    GLAccount."Debit/Credit"::Debit:
                        TempXMLBuffer.AddAttribute('Natur', 'D');
                    GLAccount."Debit/Credit"::Credit:
                        TempXMLBuffer.AddAttribute('Natur', 'A');
                    else
                        TempErrorMessage.LogMessage(
                          GLAccount, GLAccount.FieldNo("Debit/Credit"), TempErrorMessage."Message Type"::Error,
                          StrSubstNo(GLAccountTypeErr, GLAccount."Debit/Credit", GLAccount.RecordId));
                end;
                TempXMLBuffer.GetParent();
            until GLAccount.Next() = 0
        else
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, NoSATAccountDefinedErr);

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(TempXMLBuffer, Year, Month, 'CT');
        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportBalanceSheet(Year: Integer; Month: Integer; DeliveryType: Option Normal,Complementary; UpdateDate: Date; ClosingBalanceSheet: Boolean)
    var
        GLAccount: Record "G/L Account";
        GLAccountBalanceIni: Record "G/L Account";
        GLAccountBalanceFin: Record "G/L Account";
        TempXMLBuffer: Record "XML Buffer" temporary;
        StartDate: Date;
        EndDate: Date;
        FileType: Text;
    begin
        TempErrorMessage.ClearLog();

        if not ClosingBalanceSheet then begin
            StartDate := DMY2Date(1, Month, Year);
            EndDate := CalcDate('<CM>', StartDate);
        end else begin
            StartDate := DMY2Date(1, 1, Year);
            EndDate := ClosingDate(CalcDate('<CY>', DMY2Date(1, 1, Year)));
            Month := 13;
        end;

        CreateXMLHeader(TempXMLBuffer, BalanzaNodeTxt, BalanzaNamespaceTxt, Year, Month, '1.3');

        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        if DeliveryType = DeliveryType::Normal then
            TempXMLBuffer.AddAttribute('TipoEnvio', 'N')
        else begin
            TempXMLBuffer.AddAttribute('TipoEnvio', 'C');
            if UpdateDate = 0D then
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingUpdateDateErr);
            TempXMLBuffer.AddAttribute('FechaModBal', Format(UpdateDate, 0, 9));
        end;

        if GLAccount.FindSet() then
            repeat
                GLAccount.CalcFields("Debit Amount", "Credit Amount");

                GLAccountBalanceIni.Get(GLAccount."No.");
                GLAccountBalanceIni.SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
                GLAccountBalanceIni.CalcFields("Balance at Date");

                GLAccountBalanceFin.Get(GLAccount."No.");
                GLAccountBalanceFin.SetFilter("Date Filter", '..%1', EndDate);
                GLAccountBalanceFin.CalcFields("Balance at Date");

                TempXMLBuffer.AddGroupElement('Ctas');
                TempXMLBuffer.AddAttribute('NumCta', GLAccount."No.");
                TempXMLBuffer.AddAttribute('SaldoIni', FormatDecimal(GLAccountBalanceIni."Balance at Date"));
                TempXMLBuffer.AddAttribute('Debe', FormatDecimal(GLAccount."Debit Amount"));
                TempXMLBuffer.AddAttribute('Haber', FormatDecimal(GLAccount."Credit Amount"));
                TempXMLBuffer.AddAttribute('SaldoFin', FormatDecimal(GLAccountBalanceFin."Balance at Date"));
                TempXMLBuffer.GetParent();
            until GLAccount.Next() = 0;

        if DeliveryType = DeliveryType::Normal then
            FileType := 'BN'
        else
            FileType := 'BC';

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(TempXMLBuffer, Year, Month, FileType);

        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportTransactions(Year: Integer; Month: Integer; RequestType: Option AF,FC,DE,CO; OrderNumber: Text[13]; ProcessNumber: Text[14])
    var
        GLEntry: Record "G/L Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        StartDate: Date;
        EndDate: Date;
        TransactionNoCurrent: Integer;
    begin
        TempErrorMessage.ClearLog();
        StartDate := DMY2Date(1, Month, Year);
        EndDate := CalcDate('<CM>', StartDate);

        CreateXMLHeader(TempXMLBuffer, PolizasNodeTxt, PolizasNamespaceTxt, Year, Month, '1.3');
        TempXMLBuffer.AddAttribute('TipoSolicitud', Format(RequestType));
        if RequestType in [RequestType::AF, RequestType::FC] then begin
            if OrderNumber <> '' then
                TempXMLBuffer.AddAttribute('NumOrden', OrderNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);
        end else
            if ProcessNumber <> '' then
                TempXMLBuffer.AddAttribute('NumTramite', ProcessNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Posting Date", StartDate, EndDate);

        if GLEntry.FindSet() then begin
            repeat
                if TransactionNoCurrent <> GLEntry."Transaction No." then begin
                    if TransactionNoCurrent <> 0 then
                        TempXMLBuffer.GetParent();
                    TransactionNoCurrent := GLEntry."Transaction No.";
                    CreatePolizaNode(TempXMLBuffer, GLEntry);
                end;
                CreateTransaccionNode(TempXMLBuffer, GLEntry);
            until GLEntry.Next() = 0;
            TempXMLBuffer.GetParent();
        end;

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(TempXMLBuffer, Year, Month, 'PL');

        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportAuxiliaryAccounts(Year: Integer; Month: Integer; RequestType: Option AF,FC,DE,CO; OrderNumber: Text[13]; ProcessNumber: Text[14])
    var
        GLAccount: Record "G/L Account";
        GLAccountBalanceIni: Record "G/L Account";
        GLAccountBalanceFin: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        StartDate: Date;
        EndDate: Date;
    begin
        TempErrorMessage.ClearLog();
        StartDate := DMY2Date(1, Month, Year);
        EndDate := CalcDate('<CM>', StartDate);

        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        CreateXMLHeader(TempXMLBuffer, AuxiliaryAccountNodeTxt, AuxiliaryAccountNamespaceTxt, Year, Month, '1.3');
        TempXMLBuffer.AddAttribute('TipoSolicitud', Format(RequestType));
        if RequestType in [RequestType::AF, RequestType::FC] then begin
            if OrderNumber <> '' then
                TempXMLBuffer.AddAttribute('NumOrden', OrderNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);
        end else
            if ProcessNumber <> '' then
                TempXMLBuffer.AddAttribute('NumTramite', ProcessNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);

        if GLAccount.FindSet() then
            repeat
                GLEntry.SetRange("G/L Account No.", GLAccount."No.");
                GLEntry.SetRange("Posting Date", StartDate, EndDate);
                if GLEntry.FindSet() then begin
                    GLAccountBalanceIni.Get(GLAccount."No.");
                    GLAccountBalanceIni.SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
                    GLAccountBalanceIni.CalcFields("Balance at Date");

                    GLAccountBalanceFin.Get(GLAccount."No.");
                    GLAccountBalanceFin.SetFilter("Date Filter", '..%1', EndDate);
                    GLAccountBalanceFin.CalcFields("Balance at Date");

                    TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

                    TempXMLBuffer.AddGroupElement('Cuenta');
                    TempXMLBuffer.AddAttribute('NumCta', GLAccount."No.");
                    TempXMLBuffer.AddAttribute('DesCta', GLAccount.Name);
                    TempXMLBuffer.AddAttribute('SaldoIni', FormatDecimal(GLAccountBalanceIni."Balance at Date"));
                    TempXMLBuffer.AddAttribute('SaldoFin', FormatDecimal(GLAccountBalanceFin."Balance at Date"));

                    repeat
                        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo(Description), TempErrorMessage."Message Type"::Warning);
                        TempXMLBuffer.AddGroupElement('DetalleAux');
                        TempXMLBuffer.AddAttribute('Fecha', Format(GLEntry."Posting Date", 0, 9));
                        TempXMLBuffer.AddAttribute('NumUnIdenPol', Format(GLEntry."Transaction No."));
                        TempXMLBuffer.AddAttribute('Concepto', GLEntry.Description);
                        TempXMLBuffer.AddAttribute('Debe', FormatDecimal(GLEntry."Debit Amount"));
                        TempXMLBuffer.AddAttribute('Haber', FormatDecimal(GLEntry."Credit Amount"));
                        TempXMLBuffer.GetParent();
                    until GLEntry.Next() = 0;
                    TempXMLBuffer.GetParent();
                end;
            until GLAccount.Next() = 0;

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(TempXMLBuffer, Year, Month, 'XC');

        TempErrorMessage.ShowErrorMessages(false);
    end;

    local procedure CreateXMLHeader(var TempXMLBuffer: Record "XML Buffer" temporary; RootNodeName: Text; NodeNameSpace: Text; Year: Integer; Month: Integer; Version: Text)
    var
        CompanyInformation: Record "Company Information";
        FullNameSpace: Text;
    begin
        CompanyInformation.Get();

        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
        if (Month < 1) or (Month > 13) then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, InvalidMonthErr);
        if (Year < 2000) or (Month > 2999) then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, InvalidYearErr);

        FullNameSpace := NamespaceTxt + NodeNameSpace;
        TempXMLBuffer.CreateRootElement(RootNodeName);
        TempXMLBuffer.AddNamespace('', FullNameSpace);

        TempXMLBuffer.AddAttribute('Version', Version);
        TempXMLBuffer.AddAttribute('RFC', CompanyInformation."RFC Number");
        TempXMLBuffer.AddAttribute('Mes', Format(Month, 2, '<Integer,2><Filler Character,0>'));
        TempXMLBuffer.AddAttribute('Anio', Format(Year));
        TempXMLBuffer.AddAttribute('xsi:schemaLocation',
          FullNameSpace + ' ' + FullNameSpace + '/' + NodeNameSpace + '_1_3.xsd');
        TempXMLBuffer.AddAttribute('xmlns:xsi', NamespaceW3Txt);
    end;

    local procedure CreatePolizaNode(var TempXMLBuffer: Record "XML Buffer" temporary; GLEntry: Record "G/L Entry")
    begin
        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo("Source Code"), TempErrorMessage."Message Type"::Warning);

        TempXMLBuffer.AddGroupElement('Poliza');
        TempXMLBuffer.AddAttribute('NumUnIdenPol', Format(GLEntry."Transaction No."));
        TempXMLBuffer.AddAttribute('Fecha', Format(GLEntry."Posting Date", 0, 9));
        TempXMLBuffer.AddAttribute('Concepto', GLEntry."Source Code");
    end;

    local procedure CreateTransaccionNode(var TempXMLBuffer: Record "XML Buffer"; GLEntry: Record "G/L Entry")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralLedgerSetup.Get();
        GLAccount.Get(GLEntry."G/L Account No.");

        TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo(Description), TempErrorMessage."Message Type"::Warning);

        TempXMLBuffer.AddGroupElement('Transaccion');
        TempXMLBuffer.AddAttribute('NumCta', GLAccount."No.");
        TempXMLBuffer.AddAttribute('DesCta', GLAccount.Name);
        TempXMLBuffer.AddAttribute('Concepto', GLEntry.Description);
        TempXMLBuffer.AddAttribute('Debe', FormatDecimal(GLEntry."Debit Amount"));
        TempXMLBuffer.AddAttribute('Haber', FormatDecimal(GLEntry."Credit Amount"));

        CreateCustomerReceipts(TempXMLBuffer, GLEntry, false);
        CreateVendorReceipts(TempXMLBuffer, GLEntry, false);

        CreateTransfers(TempXMLBuffer, GLEntry);
        TempXMLBuffer.GetParent();
    end;

    local procedure CreateVendorReceipts(var TempXMLBuffer: Record "XML Buffer"; GLEntry: Record "G/L Entry"; IsAuxiliary: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");

        if VendorLedgerEntry.FindSet() then
            repeat
                VendorPostingGroup.Get(VendorLedgerEntry."Vendor Posting Group");
                if VendorPostingGroup."Payables Account" = GLEntry."G/L Account No." then
                    if VendorLedgerEntry."Document Type" in [VendorLedgerEntry."Document Type"::Payment,
                                                             VendorLedgerEntry."Document Type"::Refund]
                    then begin
                        FindAppliedVendorReceipts(AppliedVendorLedgerEntry, VendorLedgerEntry."Entry No.");
                        if AppliedVendorLedgerEntry.FindSet() then
                            repeat
                                CreateReceipt(TempXMLBuffer, AppliedVendorLedgerEntry, IsAuxiliary);
                            until AppliedVendorLedgerEntry.Next() = 0;
                    end else
                        CreateReceipt(TempXMLBuffer, VendorLedgerEntry, IsAuxiliary);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CreateCustomerReceipts(var TempXMLBuffer: Record "XML Buffer"; GLEntry: Record "G/L Entry"; IsAuxiliary: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");

        if CustLedgerEntry.FindSet() then
            repeat
                CustomerPostingGroup.Get(CustLedgerEntry."Customer Posting Group");
                if CustomerPostingGroup."Receivables Account" = GLEntry."G/L Account No." then
                    if CustLedgerEntry."Document Type" in [CustLedgerEntry."Document Type"::Payment,
                                                           CustLedgerEntry."Document Type"::Refund]
                    then begin
                        FindAppliedCustomerReceipts(AppliedCustLedgerEntry, CustLedgerEntry."Entry No.");
                        if AppliedCustLedgerEntry.FindSet() then
                            repeat
                                CreateReceipt(TempXMLBuffer, AppliedCustLedgerEntry, IsAuxiliary);
                            until AppliedCustLedgerEntry.Next() = 0;
                    end else
                        CreateReceipt(TempXMLBuffer, CustLedgerEntry, IsAuxiliary);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure FindAppliedVendorReceipts(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; EntryNo: Integer)
    var
        DetailedVendorLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        AppliedVendorLedgerEntry.Reset();

        VendorLedgerEntry.Get(EntryNo);

        DetailedVendorLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DetailedVendorLedgEntry1.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry1.SetRange(Unapplied, false);
        if DetailedVendorLedgEntry1.Find('-') then
            repeat
                if DetailedVendorLedgEntry1."Vendor Ledger Entry No." =
                   DetailedVendorLedgEntry1."Applied Vend. Ledger Entry No."
                then begin
                    DetailedVendorLedgEntry2.Init();
                    DetailedVendorLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DetailedVendorLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DetailedVendorLedgEntry1."Applied Vend. Ledger Entry No.");
                    DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::Application);
                    DetailedVendorLedgEntry2.SetRange(Unapplied, false);
                    if DetailedVendorLedgEntry2.Find('-') then
                        repeat
                            if DetailedVendorLedgEntry2."Vendor Ledger Entry No." <> DetailedVendorLedgEntry2."Applied Vend. Ledger Entry No."
                            then begin
                                AppliedVendorLedgerEntry.SetCurrentKey("Entry No.");
                                AppliedVendorLedgerEntry.SetRange("Entry No.", DetailedVendorLedgEntry2."Vendor Ledger Entry No.");
                                if AppliedVendorLedgerEntry.Find('-') then
                                    AppliedVendorLedgerEntry.Mark(true);
                            end;
                        until DetailedVendorLedgEntry2.Next() = 0;
                end else begin
                    AppliedVendorLedgerEntry.SetCurrentKey("Entry No.");
                    AppliedVendorLedgerEntry.SetRange("Entry No.", DetailedVendorLedgEntry1."Applied Vend. Ledger Entry No.");
                    if AppliedVendorLedgerEntry.Find('-') then
                        AppliedVendorLedgerEntry.Mark(true);
                end;
            until DetailedVendorLedgEntry1.Next() = 0;

        AppliedVendorLedgerEntry.SetCurrentKey("Entry No.");
        AppliedVendorLedgerEntry.SetRange("Entry No.");

        if VendorLedgerEntry."Closed by Entry No." <> 0 then begin
            AppliedVendorLedgerEntry."Entry No." := VendorLedgerEntry."Closed by Entry No.";
            AppliedVendorLedgerEntry.Mark(true);
        end;

        AppliedVendorLedgerEntry.SetCurrentKey("Closed by Entry No.");
        AppliedVendorLedgerEntry.SetRange("Closed by Entry No.", VendorLedgerEntry."Entry No.");
        if AppliedVendorLedgerEntry.Find('-') then
            repeat
                AppliedVendorLedgerEntry.Mark(true);
            until AppliedVendorLedgerEntry.Next() = 0;

        AppliedVendorLedgerEntry.SetCurrentKey("Entry No.");
        AppliedVendorLedgerEntry.SetRange("Closed by Entry No.");
        AppliedVendorLedgerEntry.MarkedOnly(true);
    end;

    local procedure FindAppliedCustomerReceipts(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; EntryNo: Integer)
    var
        DetailedCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        AppliedCustLedgerEntry.Reset();

        CustLedgerEntry.Get(EntryNo);

        DetailedCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DetailedCustLedgEntry1.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry1.SetRange(Unapplied, false);
        if DetailedCustLedgEntry1.Find('-') then
            repeat
                if DetailedCustLedgEntry1."Cust. Ledger Entry No." = DetailedCustLedgEntry1."Applied Cust. Ledger Entry No." then begin
                    DetailedCustLedgEntry2.Init();
                    DetailedCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DetailedCustLedgEntry2.SetRange(
                      "Applied Cust. Ledger Entry No.", DetailedCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    DetailedCustLedgEntry2.SetRange("Entry Type", DetailedCustLedgEntry2."Entry Type"::Application);
                    DetailedCustLedgEntry2.SetRange(Unapplied, false);
                    if DetailedCustLedgEntry2.Find('-') then
                        repeat
                            if DetailedCustLedgEntry2."Cust. Ledger Entry No." <> DetailedCustLedgEntry2."Applied Cust. Ledger Entry No."
                            then begin
                                AppliedCustLedgerEntry.SetCurrentKey("Entry No.");
                                AppliedCustLedgerEntry.SetRange("Entry No.", DetailedCustLedgEntry2."Cust. Ledger Entry No.");
                                if AppliedCustLedgerEntry.Find('-') then
                                    AppliedCustLedgerEntry.Mark(true);
                            end;
                        until DetailedCustLedgEntry2.Next() = 0;
                end else begin
                    AppliedCustLedgerEntry.SetCurrentKey("Entry No.");
                    AppliedCustLedgerEntry.SetRange("Entry No.", DetailedCustLedgEntry1."Applied Cust. Ledger Entry No.");
                    if AppliedCustLedgerEntry.Find('-') then
                        AppliedCustLedgerEntry.Mark(true);
                end;
            until DetailedCustLedgEntry1.Next() = 0;

        AppliedCustLedgerEntry.SetCurrentKey("Entry No.");
        AppliedCustLedgerEntry.SetRange("Entry No.");

        if CustLedgerEntry."Closed by Entry No." <> 0 then begin
            AppliedCustLedgerEntry."Entry No." := CustLedgerEntry."Closed by Entry No.";
            AppliedCustLedgerEntry.Mark(true);
        end;

        AppliedCustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        AppliedCustLedgerEntry.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
        if AppliedCustLedgerEntry.Find('-') then
            repeat
                AppliedCustLedgerEntry.Mark(true);
            until AppliedCustLedgerEntry.Next() = 0;

        AppliedCustLedgerEntry.SetCurrentKey("Entry No.");
        AppliedCustLedgerEntry.SetRange("Closed by Entry No.");
        AppliedCustLedgerEntry.MarkedOnly(true);
    end;

    local procedure CreateReceipt(var TempXMLBuffer: Record "XML Buffer"; LedgerEntry: Variant; IsAuxiliary: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        CompanyInformation: Record "Company Information";
        PaymentMethod: Record "Payment Method";
        LedgerEntryRecordRef: RecordRef;
        AmountFieldRef: FieldRef;
        CountryRegion: Code[10];
        DocumentNo: Code[20];
        RFCNo: Code[13];
        CurrencyCode: Code[10];
        PaymentMethodCode: Code[10];
        UUIDCFDI: Text;
        VATRegistrationNo: Text[20];
        CustVendName: Text;
        Amount: Decimal;
        AdjustedCurrencyFactor: Decimal;
    begin
        SourceCodeSetup.Get();
        CompanyInformation.Get();

        LedgerEntryRecordRef.GetTable(LedgerEntry);
        FindCustVendDetails(LedgerEntryRecordRef, CountryRegion, RFCNo, VATRegistrationNo, CustVendName);
        AmountFieldRef := LedgerEntryRecordRef.Field(13);
        AmountFieldRef.CalcField();
        Amount := AmountFieldRef.Value();
        CurrencyCode := LedgerEntryRecordRef.Field(11).Value();
        AdjustedCurrencyFactor := LedgerEntryRecordRef.Field(73).Value();
        PaymentMethodCode := LedgerEntryRecordRef.Field(172).Value();

        DocumentNo := LedgerEntryRecordRef.Field(6).Value();
        if (CountryRegion = CompanyInformation."Country/Region Code") or (CountryRegion = '') then begin
            UUIDCFDI := FindUUIDCFDI(LedgerEntryRecordRef);

            if UUIDCFDI <> '' then begin
                if IsAuxiliary then
                    TempXMLBuffer.AddGroupElement('ComprNal')
                else
                    TempXMLBuffer.AddGroupElement('CompNal');
                TempXMLBuffer.AddAttribute('UUID_CFDI', UUIDCFDI);
            end else begin
                if IsAuxiliary then
                    TempXMLBuffer.AddGroupElement('ComprNalOtr')
                else
                    TempXMLBuffer.AddGroupElement('CompNalOtr');
                TempErrorMessage.LogIfInvalidCharacters(LedgerEntryRecordRef, 6, TempErrorMessage."Message Type"::Warning, '0123456789');
                DocumentNo := DelChr(DocumentNo, '=', DelChr(DocumentNo, '=', '0123456789'));
                TempXMLBuffer.AddAttribute('CFD_CBB_NumFol', DocumentNo);
            end;
            TempXMLBuffer.AddAttribute('RFC', RFCNo);
        end else begin
            if IsAuxiliary then
                TempXMLBuffer.AddGroupElement('ComprExt')
            else
                TempXMLBuffer.AddGroupElement('CompExt');
            TempXMLBuffer.AddAttribute('NumFactExt', DocumentNo);
            TempXMLBuffer.AddAttribute('TaxID', VATRegistrationNo);
        end;

        if IsAuxiliary and PaymentMethod.Get(PaymentMethodCode) then begin
            TempErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("SAT Payment Method Code"), TempErrorMessage."Message Type"::Error);
            TempXMLBuffer.AddAttribute('MetPagoAux', PaymentMethod."SAT Payment Method Code");
        end;

        if LedgerEntryRecordRef.Number = DATABASE::"Vendor Ledger Entry" then
            Amount := -Amount;
        TempXMLBuffer.AddAttribute('MontoTotal', FormatDecimal(Amount));
        if CurrencyCode <> '' then begin
            TempXMLBuffer.AddAttribute('Moneda', CurrencyCode);
            TempXMLBuffer.AddAttribute('TipCamb', FormatDecimal(1 / AdjustedCurrencyFactor));
        end;
        TempXMLBuffer.GetParent();
    end;

    local procedure CreateTransfers(var TempXMLBuffer: Record "XML Buffer" temporary; GLEntry: Record "G/L Entry")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        PaymentHandled: Boolean;
    begin
        BankAccountLedgerEntry.SetCurrentKey("Transaction No.");
        CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");

        BankAccountLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        BankAccountLedgerEntry.SetFilter("Credit Amount", '>0');
        if BankAccountLedgerEntry.FindSet() then
            repeat
                BankAccountPostingGroup.Get(BankAccountLedgerEntry."Bank Acc. Posting Group");
                if BankAccountPostingGroup."G/L Account No." = GLEntry."G/L Account No." then begin
                    CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
                    if CheckLedgerEntry.FindSet() then
                        repeat
                            PaymentHandled := CreateChequeNode(TempXMLBuffer, CheckLedgerEntry) or PaymentHandled;
                        until CheckLedgerEntry.Next() = 0
                    else
                        PaymentHandled := CreateTransferenciaNode(TempXMLBuffer, BankAccountLedgerEntry) or PaymentHandled
                end else
                    PaymentHandled := true;
            until BankAccountLedgerEntry.Next() = 0;

        if (not PaymentHandled) and
            (GLEntry."Credit Amount" > 0) and
            (GLEntry."Document Type" = GLEntry."Document Type"::Payment)
        then begin
            CreateOtrMetodoPagoNode(TempXMLBuffer, DATABASE::"Cust. Ledger Entry", GLEntry."Transaction No.");
            CreateOtrMetodoPagoNode(TempXMLBuffer, DATABASE::"Vendor Ledger Entry", GLEntry."Transaction No.");
        end
    end;

    local procedure CreateChequeNode(var TempXMLBuffer: Record "XML Buffer" temporary; CheckLedgerEntry: Record "Check Ledger Entry"): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Vendor: Record Vendor;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        RecipientBankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        Benef: Text[300];
        RFC: Text[30];
        ExchangeRate: Decimal;
    begin
        BankAccountLedgerEntry.Get(CheckLedgerEntry."Bank Account Ledger Entry No.");
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        TempErrorMessage.LogIfEmpty(CheckLedgerEntry, CheckLedgerEntry.FieldNo("Check No."), TempErrorMessage."Message Type"::Warning);
        TempErrorMessage.LogIfEmpty(CheckLedgerEntry, CheckLedgerEntry.FieldNo("Check Date"), TempErrorMessage."Message Type"::Warning);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

        case CheckLedgerEntry."Bal. Account Type" of
            CheckLedgerEntry."Bal. Account Type"::Vendor:
                begin
                    Vendor.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
                    Benef := Vendor.Name;
                    RFC := Vendor."RFC No.";
                end;
            CheckLedgerEntry."Bal. Account Type"::Customer:
                begin
                    Customer.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
                    Benef := Customer.Name;
                    RFC := Customer."RFC No.";
                end;
            CheckLedgerEntry."Bal. Account Type"::"Bank Account":
                begin
                    CompanyInformation.Get();
                    RecipientBankAccount.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      CompanyInformation, CompanyInformation.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
                    Benef := RecipientBankAccount.Name;
                    RFC := CompanyInformation."RFC Number";
                end;
        end;

        TempXMLBuffer.AddGroupElement('Cheque');
        TempXMLBuffer.AddAttribute('Num', CheckLedgerEntry."Check No.");
        TempXMLBuffer.AddAttribute('BanEmisNal', BankAccount."Bank Code");
        TempXMLBuffer.AddAttribute('BanEmisExt', BankAccount.Name);
        TempXMLBuffer.AddAttribute('CtaOri', BankAccount."Bank Account No.");
        TempXMLBuffer.AddAttribute('Fecha', Format(CheckLedgerEntry."Check Date", 0, 9));
        TempXMLBuffer.AddAttribute('Benef', Benef);
        TempXMLBuffer.AddAttribute('RFC', RFC);
        TempXMLBuffer.AddAttribute('Monto', FormatDecimal(CheckLedgerEntry.Amount));

        if BankAccountLedgerEntry."Currency Code" <> '' then begin
            ExchangeRate := CurrencyExchangeRate.ExchangeRate(CheckLedgerEntry."Posting Date", BankAccountLedgerEntry."Currency Code");
            TempXMLBuffer.AddAttribute('Moneda', BankAccountLedgerEntry."Currency Code");
            TempXMLBuffer.AddAttribute('TipCamb', FormatDecimal(1 / ExchangeRate));
        end;
        TempXMLBuffer.GetParent();

        exit(true);
    end;

    local procedure CreateTransferenciaNode(var TempXMLBuffer: Record "XML Buffer" temporary; BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        RecipientBankAccount: Record "Bank Account";
        CtaDest: Text[50];
        BancoDestNal: Code[3];
        BancoDestExt: Text;
        Benef: Text[300];
        RFC: Text[30];
        ExchangeRate: Decimal;
    begin
        case BankAccountLedgerEntry."Bal. Account Type" of
            BankAccountLedgerEntry."Bal. Account Type"::Customer:
                begin
                    CustLedgerEntry.SetCurrentKey("Transaction No.");
                    CustLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    CustLedgerEntry.SetFilter("Recipient Bank Account", '<>%1', '');
                    if not CustLedgerEntry.FindFirst() then
                        exit(false);
                    Customer.Get(CustLedgerEntry."Customer No.");
                    CustomerBankAccount.Get(Customer."No.", CustLedgerEntry."Recipient Bank Account");

                    TempErrorMessage.LogIfEmpty(
                      CustomerBankAccount, CustomerBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      CustomerBankAccount, CustomerBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(CustomerBankAccount, CustomerBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

                    CtaDest := CustomerBankAccount."Bank Account No.";
                    BancoDestNal := CustomerBankAccount."Bank Code";
                    BancoDestExt := CustomerBankAccount.Name;
                    Benef := Customer.Name;
                    RFC := Customer."RFC No.";
                end;
            BankAccountLedgerEntry."Bal. Account Type"::Vendor:
                begin
                    VendorLedgerEntry.SetCurrentKey("Transaction No.");
                    VendorLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    VendorLedgerEntry.SetFilter("Recipient Bank Account", '<>%1', '');
                    if not VendorLedgerEntry.FindFirst() then
                        exit(false);
                    Vendor.Get(VendorLedgerEntry."Vendor No.");
                    VendorBankAccount.Get(Vendor."No.", VendorLedgerEntry."Recipient Bank Account");

                    TempErrorMessage.LogIfEmpty(
                      VendorBankAccount, VendorBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      VendorBankAccount, VendorBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(VendorBankAccount, VendorBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

                    CtaDest := VendorBankAccount."Bank Account No.";
                    BancoDestNal := VendorBankAccount."Bank Code";
                    BancoDestExt := VendorBankAccount.Name;
                    Benef := Vendor.Name;
                    RFC := Vendor."RFC No.";
                end;
            BankAccountLedgerEntry."Bal. Account Type"::"Bank Account":
                begin
                    if not RecipientBankAccount.Get(BankAccountLedgerEntry."Bal. Account No.") then
                        exit(false);
                    CompanyInformation.Get();

                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      CompanyInformation, CompanyInformation.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);

                    CtaDest := RecipientBankAccount."Bank Account No.";
                    BancoDestNal := RecipientBankAccount."Bank Code";
                    BancoDestExt := RecipientBankAccount.Name;
                    Benef := CompanyInformation.Name;
                    RFC := CompanyInformation."RFC Number";
                end;
            else
                exit(false);
        end;

        BankAccount.Get(BankAccountLedgerEntry."Bank Account No.");

        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

        TempXMLBuffer.AddGroupElement('Transferencia');
        TempXMLBuffer.AddAttribute('CtaOri', BankAccount."Bank Account No.");
        TempXMLBuffer.AddAttribute('BancoOriNal', BankAccount."Bank Code");
        TempXMLBuffer.AddAttribute('BancoOriExt', BankAccount.Name);
        TempXMLBuffer.AddAttribute('CtaDest', CtaDest);
        TempXMLBuffer.AddAttribute('BancoDestNal', BancoDestNal);
        TempXMLBuffer.AddAttribute('BancoDestExt', BancoDestExt);
        TempXMLBuffer.AddAttribute('Fecha', Format(BankAccountLedgerEntry."Posting Date", 0, 9));
        TempXMLBuffer.AddAttribute('Benef', Benef);
        TempXMLBuffer.AddAttribute('RFC', RFC);
        TempXMLBuffer.AddAttribute('Monto', FormatDecimal(BankAccountLedgerEntry."Credit Amount"));

        if BankAccountLedgerEntry."Currency Code" <> '' then begin
            ExchangeRate :=
              CurrencyExchangeRate.ExchangeRate(BankAccountLedgerEntry."Posting Date", BankAccountLedgerEntry."Currency Code");
            TempXMLBuffer.AddAttribute('Moneda', BankAccountLedgerEntry."Currency Code");
            TempXMLBuffer.AddAttribute('TipCamb', FormatDecimal(1 / ExchangeRate));
        end;
        TempXMLBuffer.GetParent();

        exit(true);
    end;

    local procedure CreateOtrMetodoPagoNode(var TempXMLBuffer: Record "XML Buffer"; LedgerEntryTableNo: Integer; TransactionNo: Integer)
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodFieldRef: FieldRef;
        LedgerEntryRecordRef: RecordRef;
        TransactionNoFieldRef: FieldRef;
        AmountFieldRef: FieldRef;
        CountryRegion: Code[10];
        RFCNo: Code[13];
        CurrencyCode: Code[10];
        VATRegistrationNo: Text[20];
        Amount: Decimal;
        AdjustedCurrencyFactor: Decimal;
        Name: Text;
        PostingDate: Date;
    begin
        LedgerEntryRecordRef.Open(LedgerEntryTableNo);
        TransactionNoFieldRef := LedgerEntryRecordRef.Field(53);
        TransactionNoFieldRef.SetRange(TransactionNo);
        PaymentMethodFieldRef := LedgerEntryRecordRef.Field(172);
        PaymentMethodFieldRef.SetFilter('<> %1', '');
        if LedgerEntryRecordRef.FindSet() then
            repeat
                PaymentMethod.Get(PaymentMethodFieldRef.Value);

                TempErrorMessage.LogIfEmpty(
                  PaymentMethod, PaymentMethod.FieldNo("SAT Payment Method Code"), TempErrorMessage."Message Type"::Error);

                FindCustVendDetails(LedgerEntryRecordRef, CountryRegion, RFCNo, VATRegistrationNo, Name);
                AmountFieldRef := LedgerEntryRecordRef.Field(13);
                AmountFieldRef.CalcField();
                Amount := AmountFieldRef.Value();
                CurrencyCode := LedgerEntryRecordRef.Field(11).Value();
                AdjustedCurrencyFactor := LedgerEntryRecordRef.Field(73).Value();
                PostingDate := LedgerEntryRecordRef.Field(4).Value();

                TempXMLBuffer.AddGroupElement('OtrMetodoPago');
                TempXMLBuffer.AddAttribute('MetPagoPol', PaymentMethod."SAT Payment Method Code");
                TempXMLBuffer.AddAttribute('Fecha', Format(PostingDate, 0, 9));
                TempXMLBuffer.AddAttribute('Benef', Name);
                TempXMLBuffer.AddAttribute('RFC', RFCNo);

                TempXMLBuffer.AddAttribute('Monto', FormatDecimal(Abs(Amount)));
                if CurrencyCode <> '' then begin
                    TempXMLBuffer.AddAttribute('Moneda', CurrencyCode);
                    TempXMLBuffer.AddAttribute('TipCamb', FormatDecimal(1 / AdjustedCurrencyFactor));
                end;
                TempXMLBuffer.GetParent();
            until LedgerEntryRecordRef.Next() = 0;
    end;

    local procedure FindUUIDCFDI(CustVendLedgerEntry: Variant): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SourceCodeSetup: Record "Source Code Setup";
        RecordRef: RecordRef;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        DocumentNo: Code[20];
        SourceCode: Code[10];
    begin
        SourceCodeSetup.Get();
        RecordRef.GetTable(CustVendLedgerEntry);
        DocumentType := RecordRef.Field(5).Value();
        DocumentNo := RecordRef.Field(6).Value();
        SourceCode := RecordRef.Field(28).Value();
        case SourceCode of
            SourceCodeSetup.Sales:
                case DocumentType of
                    DocumentType::Invoice:
                        if SalesInvoiceHeader.Get(DocumentNo) then
                            exit(SalesInvoiceHeader."Fiscal Invoice Number PAC");
                    DocumentType::"Credit Memo":
                        if SalesCrMemoHeader.Get(DocumentNo) then
                            exit(SalesCrMemoHeader."Fiscal Invoice Number PAC");
                end;
            SourceCodeSetup."Service Management":
                case DocumentType of
                    DocumentType::Invoice:
                        if ServiceInvoiceHeader.Get(DocumentNo) then
                            exit(ServiceInvoiceHeader."Fiscal Invoice Number PAC");
                    DocumentType::"Credit Memo":
                        if ServiceCrMemoHeader.Get(DocumentNo) then
                            exit(ServiceCrMemoHeader."Fiscal Invoice Number PAC");
                end;
            SourceCodeSetup.Purchases:
                case DocumentType of
                    DocumentType::Invoice:
                        if PurchInvHeader.Get(DocumentNo) then
                            exit(PurchInvHeader."Fiscal Invoice Number PAC");
                    DocumentType::"Credit Memo":
                        if PurchCrMemoHdr.Get(DocumentNo) then
                            exit(PurchCrMemoHdr."Fiscal Invoice Number PAC");
                end;
        end;
    end;

    local procedure FindCustVendDetails(LedgerEntryRecordRef: RecordRef; var CountryRegion: Code[10]; var RFCNo: Code[13]; var VATRegistrationNo: Text[20]; var Name: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CustVendNo: Code[20];
    begin
        CustVendNo := LedgerEntryRecordRef.Field(3).Value();
        if LedgerEntryRecordRef.Number = DATABASE::"Cust. Ledger Entry" then begin
            Customer.Get(CustVendNo);

            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

            CountryRegion := Customer."Country/Region Code";
            RFCNo := Customer."RFC No.";
            VATRegistrationNo := Customer."VAT Registration No.";
            Name := Customer.Name;
        end else begin
            Vendor.Get(CustVendNo);

            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

            CountryRegion := Vendor."Country/Region Code";
            RFCNo := Vendor."RFC No.";
            VATRegistrationNo := Vendor."VAT Registration No.";
            Name := Vendor.Name;
        end;
    end;

    local procedure SaveXMLToClient(var TempXMLBuffer: Record "XML Buffer" temporary; Year: Integer; Month: Integer; Type: Text): Boolean
    var
        CompanyInformation: Record "Company Information";
        DataCompression: Codeunit "Data Compression";
        XMLTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        XMLBufferReader: Codeunit "XML Buffer Reader";
        ServerTempFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        Result: Boolean;
        ClientFileName: Text;
    begin
        if TestFileName <> '' then
            TempXMLBuffer.Save(TestFileName)
        else begin
            CompanyInformation.Get();
            ClientFileName := CompanyInformation."RFC Number" + Format(Year) +
              Format(Month, 2, '<Integer,2><Filler Character,0>') + Type;
            XMLBufferReader.SaveToTempBlob(XMLTempBlob, TempXMLBuffer);
            XMLTempBlob.CreateInStream(ServerTempFileInStream);
            DataCompression.CreateZipArchive();
            DataCompression.AddEntry(ServerTempFileInStream, ClientFileName + '.xml');
            ZipTempBlob.CreateOutStream(ZipOutStream);
            DataCompression.SaveZipArchive(ZipOutStream);
            DataCompression.CloseZipArchive();
            ZipTempBlob.CreateInStream(ZipInStream);
            ClientFileName += '.zip';
            Result := DownloadFromStream(ZipInStream, '', '', '', ClientFileName);
            exit(Result);
        end;
    end;

    local procedure FormatDecimal(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    procedure InitializeRequest(FileName: Text)
    begin
        TestFileName := FileName;
    end;
}

