codeunit 144137 "UT REP Free Invoice"
{
    // 1. Purpose of the test is to verify On After Get Record trigger of Sales Invoice Line for Report ID 206 - Sales Invoice when Free Type is Only VAT Amt.
    // 2. Purpose of the test is to verify On After Get Record trigger of Sales Invoice Line for Report ID 206 - Sales Invoice when Free Type is Total Amt.
    // 
    // Covers Test Cases for WI - 346250
    // -----------------------------------------------------------------------------------
    // Test Function Name                                                           TFS ID
    // -----------------------------------------------------------------------------------
    // OnAfterGetRecordFreeTypeTotalAmtSalesInvoice            156345,156347,156349,156351
    // OnAfterGetRecordFreeTypeOnlyVATAmtSalesInvoice          156346,156348,156350,156352

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FreeInvoiceTxt: Label 'FREE INVOICE';
        FreeInvoiceCap: Label 'FreeInvoiceCaption';
        FreeInvVATAmtCap: Label 'FreeInvVATAmt';
        FreeInvTxtCap: Label 'FreeInvTxt';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePostedSalesInvoice(PaymentMethodCode: Code[10]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode;
        SalesInvoiceHeader."Payment Method Code" := PaymentMethodCode;
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine.Amount := LibraryRandom.RandDec(100, 2);
        SalesInvoiceLine."Amount Including VAT" := LibraryRandom.RandDecInRange(100, 200, 2);
        SalesInvoiceLine.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure CreatePaymentMethod(FreeType: Option): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10;
        PaymentMethod."Free Type" := FreeType;
        PaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure VerifyValuesOnXML(FreeInvText: Text; VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(FreeInvoiceCap, Format(FreeInvoiceTxt));
        LibraryReportDataset.AssertElementWithValueExists(FreeInvVATAmtCap, VATAmount);
        LibraryReportDataset.AssertElementWithValueExists(FreeInvTxtCap, FreeInvText);
    end;

}

