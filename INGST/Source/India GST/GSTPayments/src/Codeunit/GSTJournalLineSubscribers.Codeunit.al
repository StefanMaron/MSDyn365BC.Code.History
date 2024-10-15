codeunit 18243 "GST Journal Line Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'POS Out Of India', false, false)]
    local Procedure ValidatePOSOutOfIndia(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.POSOutOfIndia(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'POS as Vendor State', false, false)]
    local Procedure validatePOSasVendorState(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.POSasVendorState(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'GST Assessable Value', false, false)]
    local procedure validateGSTAssessableValue(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.GSTAssessableValue(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Custom Duty Amount', false, false)]
    local procedure validateCustomDutyAmount(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.CustomDutyAmount(rec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Sales Invoice Type', false, false)]
    local procedure validateSalesInvoiceType(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.SalesInvoiceType(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'GST on Advance Payment', false, false)]
    local Procedure validateGSTonAdvancePayment(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.GSTonAdvancePayment(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'GST Place of supply', false, false)]
    local Procedure ValidateGSTPlaceofSuppply(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.GSTPlaceofsuppply(rec, xrec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'GST Group Code', false, false)]
    local Procedure ValidateGSTGroupCode(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.GSTGroupCode(Rec, Xrec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'party Code', false, false)]
    local Procedure ValdiatePartyCode(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.partycode(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure ValidateLocationCode(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.LocationCode(rec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Amount', false, false)]
    local procedure ValidateAmount(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.amount(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Currency Code', false, false)]
    local Procedure ValidateCurrencyCode(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.CurrencyCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorBalAccount', '', false, false)]
    local procedure ValidateBalVendNo(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    begin
        GSTJournalLineValidations.BalVendNo(GenJournalLine, Vendor)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetCustomerBalAccount', '', false, false)]
    local procedure ValidateBalCustNo(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
        GSTJournalLineValidations.BalCustNo(GenJournalLine, Customer)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetGLBalAccount', '', false, false)]
    local Procedure ValidateBalGLAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
        GSTJournalLineValidations.BalGLAccountNo(GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateBalAccountNoOnBeforeAssignValue', '', false, false)]
    local procedure ValidateBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.BalAccountNo(GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Document Type', false, false)]
    local Procedure ValidateDocumentType(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.documenttype(rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'onafterinsertevent', '', false, false)]
    local procedure OnafterInsert(var Rec: Record "Gen. Journal Line")
    begin
        //GSTJournalLineValidations.AfterInsert(Rec)
    end;


    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeValidateEvent', 'Account Type', false, false)]
    local procedure ValidateAccountType(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.AccountType(Rec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'onbeforevalidateevent', 'Account no.', false, false)]
    local procedure OnbeforevalidateAccountNo(var Rec: Record "Gen. Journal Line")
    begin
        GSTJournalLineValidations.BeforeValidateAccountNo(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetGLAccount', '', false, false)]
    local procedure GLAccountInfo(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
        GSTJournalLineValidations.PopulateGSTInvoiceCrMemo(TRUE, FALSE, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetCustomerAccount', '', false, false)]
    local procedure ValidateCustAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
        GSTJournalLineValidations.CustAccount(GenJournalLine, customer)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorAccount', '', false, false)]
    local procedure ValidateVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    begin
        GSTJournalLineValidations.VendAccount(GenJournalLine, Vendor)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetFAAccount', '', false, false)]
    local Procedure ValidateFAAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
        GSTJournalLineValidations.FaAccount(GenJournalLine, FixedAsset);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterSetupNewLine', '', false, false)]
    local procedure Setupnewlinevalue(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        location: Record Location;
    begin
        GenJournalLine."Location Code" := GenJournalBatch."Location Code";
        IF Location.GET(GenJournalBatch."Location Code") then begin
            GenJournalLine."Location State Code" := Location."State Code";
            GenJournalLine."Location GST Reg. No." := Location."GST Registration No.";
            GenJournalLine."GST Input Service Distribution" := Location."GST Input Service Distributor";
        end;
    end;

    var
        GSTJournalLineValidations: Codeunit "GST Journal Line Validations";
}