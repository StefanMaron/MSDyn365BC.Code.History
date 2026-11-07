// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Test;
using System.Reflection;

codeunit 13925 "Library - E-Doc DE"
{
    Access = Internal;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        DefaultCoarseRoutingTxt: Label '99', Locked = true;

    procedure CreateValidRoutingNo(): Text[50]
    var
        FineRouting: Text[20];
        CheckDigit: Text[2];
    begin
        FineRouting := GenerateAlphanumFineRouting();
        CheckDigit := ComputeCheckDigit(DefaultCoarseRoutingTxt, FineRouting);
        exit(CopyStr(DefaultCoarseRoutingTxt + '-' + FineRouting + '-' + CheckDigit, 1, 50));
    end;

    procedure CreateAllocationValidationLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        AllocationAccount: Record "Allocation Account";
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);

        AllocationAccount.Init();
        AllocationAccount."No." := LibraryUtility.GenerateRandomCode(AllocationAccount.FieldNo("No."), Database::"Allocation Account");
        AllocationAccount.Name := AllocationAccount."No.";
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Insert(true);

        AllocAccountDistribution.Init();
        AllocAccountDistribution.Validate("Allocation Account No.", AllocationAccount."No.");
        AllocAccountDistribution."Line No." := 10000;
        AllocAccountDistribution.Validate("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocAccountDistribution.Validate("Destination Account Number", GLAccount."No.");
        AllocAccountDistribution.Share := 1;
        AllocAccountDistribution.Percent := 100;
        AllocAccountDistribution.Insert(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Allocation Account", AllocationAccount."No.", 1);
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
    end;

    procedure CreateServiceOutsideScopeDocument(SalesHeader: Record "Sales Header"; var ServiceHeader: Record "Service Header"; DifferentBreakdowns: Boolean)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        TaxGroup: Record "Tax Group";
    begin
        CreateServiceValidationHeader(SalesHeader, ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        VATPostingSetup.Validate("Tax Category", 'O');
        VATPostingSetup.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        ServiceHeader.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        ServiceHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ServiceHeader.Modify(true);

        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateServiceValidationLine(ServiceHeader, ServiceLine, GLAccount."No.");
        ServiceLine.Validate("Tax Group Code", TaxGroup.Code);
        ServiceLine.Modify(true);

        if DifferentBreakdowns then
            LibraryERM.CreateTaxGroup(TaxGroup);
        CreateServiceValidationLine(ServiceHeader, ServiceLine, GLAccount."No.");
        ServiceLine.Validate("Tax Group Code", TaxGroup.Code);
        ServiceLine.Modify(true);
    end;

    procedure CreateAndPostValidationServiceInvoice(SalesHeader: Record "Sales Header"; var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceValidationDocument(SalesHeader, ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    procedure CreateAndPostValidationServiceCrMemo(SalesHeader: Record "Sales Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceValidationDocument(SalesHeader, ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure CreateServiceValidationDocument(SalesHeader: Record "Sales Header"; var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateServiceValidationHeader(SalesHeader, ServiceHeader, DocumentType);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        ServiceHeader.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        ServiceHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ServiceHeader.Modify(true);
        CreateServiceValidationLine(ServiceHeader, ServiceLine, GLAccount."No.");
    end;

    local procedure CreateServiceValidationHeader(SalesHeader: Record "Sales Header"; var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        PEPPOL30Setup: Record "PEPPOL 3.0 Setup";
    begin
        PEPPOL30Setup.Get();
        PEPPOL30Setup."PEPPOL 3.0 Service Format" := PEPPOL30Setup."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - Service";
        PEPPOL30Setup.Modify();

        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, SalesHeader."Sell-to Customer No.");
        ServiceHeader."Bill-to Name" := SalesHeader."Bill-to Name";
        ServiceHeader."Bill-to Address" := SalesHeader."Bill-to Address";
        ServiceHeader."Bill-to City" := SalesHeader."Bill-to City";
        ServiceHeader."Bill-to Post Code" := SalesHeader."Bill-to Post Code";
        ServiceHeader."Bill-to Country/Region Code" := SalesHeader."Bill-to Country/Region Code";
        ServiceHeader."Ship-to Address" := SalesHeader."Ship-to Address";
        ServiceHeader."Ship-to City" := SalesHeader."Ship-to City";
        ServiceHeader."Ship-to Post Code" := SalesHeader."Ship-to Post Code";
        ServiceHeader."Ship-to Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
        ServiceHeader."Posting Date" := SalesHeader."Posting Date";
        ServiceHeader."Due Date" := SalesHeader."Due Date";
        ServiceHeader."Your Reference" := '';
        ServiceHeader."E-Mail" := SalesHeader."Sell-to E-Mail";
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceValidationLine(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; GLAccountNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccountNo);
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", 100);
        ServiceLine.Modify(true);
    end;

    local procedure GenerateAlphanumFineRouting(): Text[20]
    begin
        // CreateGuid() produces hex chars (0-9, A-F) which are valid alphanumeric fine routing characters
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{-}'), 1, 20));
    end;

    local procedure ComputeCheckDigit(CoarseRouting: Text; FineRouting: Text): Text[2]
    var
        NumericString: Text;
        Remainder: Integer;
        CheckDigitValue: Integer;
    begin
        NumericString := ConvertToNumericString(CoarseRouting + FineRouting) + '00';
        Remainder := ComputeMod97(NumericString);
        CheckDigitValue := 98 - Remainder;
        if CheckDigitValue < 10 then
            exit(CopyStr('0' + Format(CheckDigitValue), 1, 2));
        exit(CopyStr(Format(CheckDigitValue), 1, 2));
    end;

    local procedure ConvertToNumericString(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UpperInput: Text;
        Result: Text;
        Ch: Char;
        i: Integer;
    begin
        UpperInput := UpperCase(Input);
        for i := 1 to StrLen(UpperInput) do begin
            Ch := UpperInput[i];
            if TypeHelper.IsLatinLetter(Ch) then
                Result += Format(Ch - 55)
            else
                Result += Format(Ch - 48);
        end;
        exit(Result);
    end;

    local procedure ComputeMod97(NumericString: Text): Integer
    var
        Remainder: Integer;
        DigitValue: Integer;
        i: Integer;
    begin
        Remainder := 0;
        for i := 1 to StrLen(NumericString) do begin
            Evaluate(DigitValue, CopyStr(NumericString, i, 1));
            Remainder := (Remainder * 10 + DigitValue) mod 97;
        end;
        exit(Remainder);
    end;
}
