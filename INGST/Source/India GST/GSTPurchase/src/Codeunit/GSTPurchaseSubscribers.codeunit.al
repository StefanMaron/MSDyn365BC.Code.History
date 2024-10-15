codeunit 18080 "GST Purchase Subscribers"
{
    //CopyDocument 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchLineFromPurchLineBuffer', '', false, false)]
    local procedure CallTaxEngineOnAfterCopyPurchLineFromPurchLineBuffer(var ToPurchLine: Record "Purchase Line"; RecalculateLines: Boolean)
    var
        TaxTransactionValueFrom: Record "Tax Transaction Value";
        TaxTransactionValueTo: Record "Tax Transaction Value";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        if not RecalculateLines then
            CalculateTax.CallTaxEngineOnPurchaseLine(ToPurchLine, ToPurchLine);
    end;

    // Purchase Line Jurisdiction Type
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure OnAfterValidateLocationCodePurchase(var Rec: Record "Purchase Line")
    begin
        UpdateGSTJurisdictionType(Rec);
    end;
    // Check Fields for Import Vendr
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Purch.-Post", 'OnBeforePostLines', '', false, false)]
    local procedure CheckBillofEntryValues(PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Invoice then
            CheckBillOfEntry(PurchHeader);
    end;

    //Check Accounting Period
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterConfirmPost', '', false, false)]
    local procedure CheckAccountignPeriod(PurchaseHeader: Record "Purchase Header")
    begin
        CheckPostingDate(PurchaseHeader);
        CheckUnregisteredVendorCondition(PurchaseHeader);
    end;

    //Check Accounting Period - Post Preview
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnRunPreviewOnBeforePurchPostRun', '', false, false)]
    local procedure CheckAccountignPeriodPostPreview(PurchaseHeader: Record "Purchase Header")
    begin
        CheckPostingDate(PurchaseHeader);
        CheckUnregisteredVendorCondition(PurchaseHeader);
    end;

    //Invoice Discount Calculation
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch - Calc Disc. By Type", 'OnAfterResetRecalculateInvoiceDisc', '', False, False)]
    local procedure ReCalculateGST(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                CalculateTax.CallTaxEngineOnPurchaseLine(PurchaseLine, PurchaseLine);
            Until PurchaseLine.Next() = 0;

    end;

    //Purchase Quote to Order
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Purch.-Quote to Order", 'OnBeforeInsertPurchOrderHeader', '', false, false)]
    local procedure CopyQuoteInfotoOrder(var PurchOrderHeader: Record "Purchase Header"; PurchQuoteHeader: Record "Purchase Header")
    begin
        PurchOrderHeader."Location GST Reg. No." := PurchQuoteHeader."Location GST Reg. No.";
        PurchOrderHeader."Location State Code" := PurchQuoteHeader."Location State Code";
    end;

    //Purchase Header Validations
    [EventSubscriber(ObjectType::table, database::"Purchase header", 'OnAfterCopyBuyFromVendorFieldsFromVendor', '', false, false)]
    local procedure CopyVendorInf(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        VendorInfo(PurchaseHeader, Vendor);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase header", 'OnValidatePurchaseHeaderPayToVendorNo', '', false, false)]
    local procedure CopypaytoVendorInf(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PaytoVendorInfo(PurchaseHeader, Vendor);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase header", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure UpdateGstLocationCode(var Rec: Record "Purchase Header")
    begin
        GstLocationCode(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'GST Vendor Type', false, false)]
    local procedure ValidateGSTVendorType(var Rec: Record "Purchase Header")
    begin
        GSTVendorType(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnBeforeValidateEvent', 'Order Address Code', false, false)]
    local procedure ValidateOrderAddressCode(var Rec: Record "Purchase Header")
    begin
        OrderAddressCode(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase header", 'OnAfterCopyBuyFromVendorAddressFieldsFromVendor', '', false, false)]
    local procedure UpdateBuyFromGSTInfo(var PurchaseHeader: Record "Purchase Header"; BuyFromVendor: Record Vendor)
    begin
        BuyFromGSTInfo(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'Invoice Type', false, false)]
    local procedure ValidateInvoiceType(var Rec: Record "Purchase Header")
    begin
        InvoiceType(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'Location GST Reg. No.', false, false)]
    local procedure ValidateLocationGSTRegNo(var Rec: Record "Purchase Header")
    begin
        LocationGSTRegNo(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'Bill to-Location(POS)', false, false)]
    local procedure ValidateBilltoLocationPOS(var Rec: Record "Purchase Header")
    begin
        BilltoLocationPOS(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'POS as Vendor State', false, false)]
    local procedure ValidatePOSVedorState(var Rec: Record "Purchase Header")
    begin
        POSVedorState(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'POS Out Of India', false, false)]
    local procedure ValidatePOSoutIndia(var Rec: Record "Purchase Header")
    begin
        POSOutIndia(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'Without Bill Of Entry', false, false)]
    local procedure ValidateWithoutBillOfEntry(var Rec: Record "Purchase Header")
    begin
        WithoutBillOfEntry(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Purchase Header", 'OnAfterValidateEvent', 'order address code', false, false)]
    local procedure AfterValidateOrderAddressCode(var Rec: Record "Purchase Header")
    begin
        AfterOrderAddressCode(Rec);
    end;

    //PurchaseLine Validations
    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'GST Group Code', false, false)]
    local procedure ValidateGSTGroupCode(var Rec: Record "Purchase Line")
    begin
        GSTGroupCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Exempted', false, false)]
    local procedure ValidateExempted(var Rec: Record "Purchase Line")
    begin
        Exempted(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Custom Duty Amount', false, false)]

    local procedure ValidateCustomDutyAmount(var Rec: Record "Purchase Line")
    begin
        CustomDutyAmount(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Source Document No.', false, false)]
    local procedure ValidateSourceDocumentNo(var Rec: Record "Purchase Line")
    begin
        Rec.TestField(Supplementary);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Source Document Type', false, false)]
    local procedure ValidateSourceDocumentType(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
    begin
        if Rec."Source Document Type" <> xRec."Source Document Type" then
            Rec."Source Document No." := '';
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'GST Assessable Value', false, false)]

    local procedure ValidateGSTAssessableValue(var Rec: Record "Purchase Line")
    begin
        GSTAssessableValue(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Non-GST Line', false, false)]
    local procedure ValidateNONGSTLine(var Rec: Record "Purchase Line")
    begin
        NONGSTLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'GST Reverse Charge', false, false)]
    local procedure ValidateGSTReverseCharge(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        GetPurcasehHeader(PurchaseHeader, Rec);
        if xRec."GST Reverse Charge" and Not Rec."GST Reverse Charge" then
            PurchaseHeader.TestField("Invoice Type", PurchaseHeader."Invoice Type"::" ");
    end;


    [EventSubscriber(ObjectType::Table, database::"Purchase Line", 'OnAfterValidateEvent', 'Supplementary', false, false)]
    local procedure ValidateSupplementary(var Rec: Record "Purchase Line")
    begin
        Supplementary(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignGLAccountValues', '', false, false)]
    local procedure AssignGLAccValue(var Purchline: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
        GLAccValue(Purchline, GLAccount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure AssignItemValue(var Purchline: Record "Purchase Line"; Item: Record Item)
    begin
        ItemValue(Purchline, Item);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignFixedAssetValues', '', false, false)]
    local procedure AssignFAValue(var Purchline: Record "Purchase Line"; FixedAsset: Record "Fixed Asset")
    begin
        FAValue(Purchline, FixedAsset);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemChargeValues', '', false, false)]
    local procedure AssignItemChargeValue(var Purchline: Record "Purchase Line"; ItemCharge: Record "Item Charge")
    begin
        ItemChargeValue(Purchline, ItemCharge);
    end;

    // Vendor Subscribers

    [EventSubscriber(ObjectType::table, database::vendor, 'OnAfterValidateEvent', 'GST Registration No.', false, false)]
    local procedure ValidateVendGSTRegistrationNo(var Rec: Record Vendor)
    begin
        vendGSTRegistrationNo(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::vendor, 'OnAfterValidateEvent', 'GST Vendor Type', false, false)]
    local procedure ValidateVendGSTVEndorType(var Rec: Record Vendor)
    begin
        GSTVendorType(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::vendor, 'OnAfterValidateEvent', 'Associated Enterprises', false, false)]
    local procedure ValidateAssociatedEnterprises(var Rec: Record Vendor)
    begin

        if Rec."Associated Enterprises" then
            Rec.TestField("GST Vendor Type", "GST Vendor Type"::Import);
    end;

    [EventSubscriber(ObjectType::table, database::vendor, 'OnAfterValidateEvent', 'Aggregate Turnover', false, false)]
    local procedure validateAggregateTurnover(var Rec: Record Vendor)
    begin
        if Rec."GST Vendor Type" <> Rec."GST Vendor Type"::Unregistered then
            Error(AggTurnoverErr);
    end;

    [EventSubscriber(ObjectType::table, database::Vendor, 'OnAfterValidateEvent', 'ARN No.', false, false)]
    local procedure validateARNNo(var Rec: Record Vendor)
    begin
        VendARNNo(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::Vendor, 'OnAfterValidateEvent', 'State Code', false, false)]
    local procedure ValidateVendStateCode(var Rec: Record Vendor)
    begin
        VendStateCode(Rec);
    end;

    //Order Address Validation
    [EventSubscriber(ObjectType::table, database::"Order Address", 'OnAfterValidateEvent', 'State', false, false)]
    procedure ValidateOrderaddressState(var Rec: Record "Order Address")
    begin
        OrderaddressState(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Order Address", 'OnAfterValidateEvent', 'GST Registration No.', false, false)]
    local procedure ValidateOrderAddressGSTRegistrationNo(var Rec: Record "Order Address")
    begin
        OrderAddressGSTRegistrationNo(Rec);
    end;

    [EventSubscriber(ObjectType::table, database::"Order Address", 'OnAfterValidateEvent', 'ARN No.', false, false)]
    local procedure ValidateOrderAssressARNNo(var Rec: Record "Order Address")
    begin
        OrderAddressARNNo(Rec);
    end;

    //Order Address Validation - Definition
    local procedure OrderaddressState(var OrderAddress: Record "Order Address")
    var
        Vendor: Record Vendor;
    begin
        if OrderAddress.State = '' then
            OrderAddress."GST Registration No." := '';
        Vendor.Get(OrderAddress."Vendor No.");
        if Vendor."GST Vendor Type" <> Vendor."GST Vendor Type"::Exempted then
            OrderAddress."GST Registration No." := '';
        if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Import then
            OrderAddress.TestField(State, '')
        else
            if Vendor."GST Vendor Type" = Vendor."GST Vendor Type"::Unregistered then
                OrderAddress.TestField(State);
        if Vendor."GST Vendor Type" <> Vendor."GST Vendor Type"::Import then
            Vendor."Associated Enterprises" := false;
    end;

    local procedure OrderAddressGSTRegistrationNo(var OrderAddress: Record "Order Address")
    var
        Vendor: Record Vendor;
    begin
        OrderAddress.TestField(State);
        OrderAddress.TestField(Address);

        Vendor.Get(OrderAddress."Vendor No.");
        if Vendor."P.A.N. No." <> '' then
            GSTValidation.CheckGSTRegistrationNo(OrderAddress.State, OrderAddress."GST Registration No.", Vendor."P.A.N. No.")
        else
            if OrderAddress."GST Registration No." <> '' then
                Error(PANvendErr);

        if (OrderAddress."GST Registration No." <> '') or (OrderAddress."ARN No." <> '') then
            if Vendor."GST Vendor Type" in [
                Vendor."GST Vendor Type"::Unregistered,
                Vendor."GST Vendor Type"::Import]
            then
                Error(GSTRegNoErr);

        if Not (Vendor."GST Vendor Type" in [
            Vendor."GST Vendor Type"::Import,
            Vendor."GST Vendor Type"::Unregistered])
        then
            if OrderAddress."ARN No." = '' then
                OrderAddress.TestField("GST Registration No.");
    end;

    local procedure OrderAddressARNNo(var OrderAddress: Record "Order Address")
    var
        Vendor: Record Vendor;
    begin
        if Not (Vendor."GST Vendor Type" in [
                Vendor."GST Vendor Type"::Import,
                Vendor."GST Vendor Type"::Unregistered])
        then
            if OrderAddress."GST Registration No." = '' then
                OrderAddress.TestField("ARN No.");
    end;

    //Purchase Header validations - Definition
    local procedure AfterOrderAddressCode(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        DocTye: Text;
        DocTypeEnum: Enum "Document Type Enum";
    begin
        DocTye := Format(PurchaseHeader."Document Type");
        Evaluate(DocTypeEnum, DocTye);
        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
        PurchaseHeader."Vendor GST Reg. No." := Vendor."GST Registration No.";
        CheckReferenceInvoiceNo(DocTypeEnum, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader."POS Out Of India" := false;
    end;

    local procedure BuyFromGSTInfo(
        var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader."GST Order Address State" := '';
        PurchaseHeader."Order Address GST Reg. No." := '';
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine."Order Address Code" := PurchaseHeader."Order Address Code";
                PurchaseLine."Buy-From GST Registration No" := PurchaseHeader."Vendor GST Reg. No.";
                PurchaseLine.Modify()
            until PurchaseLine.Next() = 0;
    end;

    local procedure OrderAddressCode(var PurchaseHeader: Record "Purchase Header")
    var
        OrderAddr: Record "Order Address";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        if PurchaseHeader."Order Address Code" <> '' then begin
            OrderAddr.Get(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Order Address Code");
            PurchaseHeader."GST Order Address State" := OrderAddr.State;
            if PurchaseHeader."GST Vendor Type" in ["GST Vendor Type"::Registered, "GST Vendor Type"::Composite,
                                     "GST Vendor Type"::SEZ, "GST Vendor Type"::Exempted]
            then
                if OrderAddr."GST Registration No." = '' then
                    if OrderAddr."ARN No." = '' then
                        Error(OrderAddGSTARNErr);
            PurchaseHeader."Order Address GST Reg. No." := OrderAddr."GST Registration No.";
            PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
            if PurchaseHeader."GST Vendor Type" = "GST Vendor Type"::Unregistered then
                PurchaseHeader.TestField("GST Order Address State");

            if PurchaseHeader."GST Vendor Type" in [
                "GST Vendor Type"::Registered,
                "GST Vendor Type"::Composite,
                "GST Vendor Type"::SEZ,
                "GST Vendor Type"::Exempted]
            then
                if PurchaseHeader."Vendor GST Reg. No." = '' then
                    if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then
                        if Vendor."ARN No." = '' then
                            Error(VendGSTARNErr);
            if PurchaseLine.FindSet() then
                repeat
                    PurchaseLine."Order Address Code" := PurchaseHeader."Order Address Code";
                    PurchaseLine."Buy-From GST Registration No" := PurchaseHeader."Order Address GST Reg. No.";
                    PurchaseLine.Modify()
                until PurchaseLine.Next() = 0;
        end;
    end;

    local procedure GSTVendorType(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.TestField("GST Vendor Type", Vendor."GST Vendor Type");
        if PurchaseHeader."GST Vendor Type" in [
            "GST Vendor Type"::Registered,
            "GST Vendor Type"::Composite,
            "GST Vendor Type"::Exempted,
            "GST Vendor Type"::SEZ]
        then
            if Vendor."GST Registration No." = '' then
                if Vendor."ARN No." = '' then
                    Error(GSTARNErr);
        if PurchaseHeader."POS as Vendor State" then
            if Not (PurchaseHeader."GST Vendor Type" = "GST Vendor Type"::Registered) then
                Error(POSasVendorErr, PurchaseHeader."GST Vendor Type");
    end;

    local procedure InvoiceType(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Invoice Type" = PurchaseHeader."Invoice Type"::"Non-GST" then
            if PurchaseHeader."GST Invoice" then
                Error(NonGSTInvTypeErr);
        if PurchaseHeader."Invoice Type" = PurchaseHeader."Invoice Type"::"Self Invoice" then
            if Not (PurchaseHeader."GST Vendor Type" = "GST Vendor Type"::Unregistered) and
                Not CheckReverseChargeGSTRegistered(PurchaseHeader)
            then
                Error(SelfInvoiceTypeErr);

        CheckReverseChargeGSTRegistered(PurchaseHeader);

        if PurchaseHeader."Invoice Type" = PurchaseHeader."Invoice Type"::Supplementary then
            SetSupplementaryInLine(PurchaseHeader."Document Type", PurchaseHeader."No.", true)
        else
            SetSupplementaryInLine(PurchaseHeader."Document Type", PurchaseHeader."No.", false);

        if PurchaseHeader."Reference Invoice No." <> '' then
            if Not (PurchaseHeader."Invoice Type" in [
                PurchaseHeader."Invoice Type"::"Debit Note",
                PurchaseHeader."Invoice Type"::Supplementary])
            then
                Error(ReferenceNoErr);
    end;

    local procedure CheckReverseChargeGSTRegistered(var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::Registered)
            and Not (PurchaseHeader."Invoice Type" in [
                PurchaseHeader."Invoice Type"::" ",
                PurchaseHeader."Invoice Type"::"Non-GST"])
        then begin
            PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
            PurchaseLine.Setrange("GST Reverse Charge", true);
            if Not PurchaseLine.IsEmpty() then
                exit(true);
            Error(InvoiceTypRegVendErr);
        end;
    end;

    local procedure SetSupplementaryInLine(
        DocumentType: enum "Purchase Document Type";
                          DocumentNo: Code[20];
                          Supplementary: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Setrange("Document Type", DocumentType);
        PurchaseLine.Setrange("Document No.", DocumentNo);
        if PurchaseLine.FindSet(true, false) then
            repeat
                PurchaseLine.Supplementary := Supplementary;
                PurchaseLine.Modify(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure LocationGSTRegNo(var PurchaseHeader: Record "Purchase Header")
    var
        GSTRegistrationNos: Record "GST Registration Nos.";
        DocTye: Text;
        DocTypeEnum: Enum "Document Type Enum";
    begin
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
        if Not PurchaseHeader."POS as Vendor State" then
            if GSTRegistrationNos.Get(PurchaseHeader."Location GST Reg. No.") then begin
                PurchaseHeader."Location State Code" := GSTRegistrationNos."State Code";
                PurchaseHeader."GST Input Service Distribution" := GSTRegistrationNos."Input Service Distributor";
            end else begin
                PurchaseHeader."Location State Code" := '';
                PurchaseHeader."GST Input Service Distribution" := false;
            end;
        if PurchaseHeader."POS as Vendor State" then
            if PurchaseHeader."Order Address Code" <> '' then
                PurchaseHeader."Location State Code" := PurchaseHeader."GST Order Address State"
            else
                PurchaseHeader."Location State Code" := PurchaseHeader.State;
        DocTye := Format(PurchaseHeader."Document Type");
        Evaluate(DocTypeEnum, DocTye);
        CheckReferenceInvoiceNo(DocTypeEnum, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader."POS Out Of India" := false;
    end;

    local procedure CheckReferenceInvoiceNo(DocType: Enum "Document Type Enum"; DocNo: Code[20];
                                                         BuyFromVendNo: Code[20])
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
    begin
        ReferenceInvoiceNo.Setrange("Document No.", DocNo);
        ReferenceInvoiceNo.Setrange("Document Type", DocType);
        ReferenceInvoiceNo.Setrange("Source No.", BuyFromVendNo);
        ReferenceInvoiceNo.Setrange(Verified, true);
        if Not ReferenceInvoiceNo.IsEmpty() then
            Error(ReferenceInvoiceErr);
    end;

    local procedure BilltoLocationPOS(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        Location: Record Location;
    begin
        PurchSetup.Get();
        PurchaseLine.reset();
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        if PurchaseHeader."Bill to-Location(POS)" <> '' then begin
            if PurchaseHeader."Bill to-Location(POS)" = PurchaseHeader."Location Code" then
                Error(LocationErr);
            Location.Get(PurchaseHeader."Bill to-Location(POS)");
            PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
            PurchaseHeader."Location State Code" := Location."State Code";
            PurchaseHeader."GST Input Service Distribution" := Location."GST Input Service Distributor";
            if PurchaseLine.FindSet() then
                repeat
                    PurchaseLine."Bill to-Location(POS)" := PurchaseHeader."Bill to-Location(POS)";
                    PurchaseLine.Modify();
                until PurchaseLine.Next() = 0;
        end else
            if Location.Get(PurchaseHeader."Location Code") then begin
                PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
                PurchaseHeader."Location State Code" := Location."State Code";
                PurchaseHeader."GST Input Service Distribution" := Location."GST Input Service Distributor";
                if PurchaseLine.FindSet() then
                    repeat
                        PurchaseLine."Bill to-Location(POS)" := '';
                        PurchaseLine.Modify();
                    until PurchaseLine.Next() = 0;
            end;
        if PurchaseHeader."POS as Vendor State" then
            if PurchaseHeader."Order Address Code" <> '' then
                PurchaseHeader."Location State Code" := PurchaseHeader."GST Order Address State"
            else
                PurchaseHeader."Location State Code" := PurchaseHeader.State;
    end;

    local procedure POSVedorState(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        if Not (PurchaseHeader."GST Vendor Type" = "GST Vendor Type"::Registered) then
            Error(POSasVendorErr, PurchaseHeader."GST Vendor Type");

        if PurchaseHeader."Currency Code" <> '' then
            Error(CurrencyCodePOSErr, PurchaseHeader."Currency Code");

        PurchaseHeader.TestField("POS Out Of India", false);
        if PurchaseHeader."POS as Vendor State" then
            if PurchaseHeader."Order Address Code" <> '' then
                PurchaseHeader."Location State Code" := PurchaseHeader."GST Order Address State"
            else
                PurchaseHeader."Location State Code" := PurchaseHeader.State;

        if Not PurchaseHeader."POS as Vendor State" then
            if PurchaseHeader."Location Code" = '' then begin
                PurchaseHeader."Location GST Reg. No." := '';
                PurchaseHeader."Location State Code" := '';
            end else
                if PurchaseHeader."Bill to-Location(POS)" = '' then begin
                    if Location.Get(PurchaseHeader."Location Code") then
                        PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
                    PurchaseHeader."Location State Code" := Location."State Code";
                end else
                    if Location.Get(PurchaseHeader."Bill to-Location(POS)") then begin
                        PurchaseHeader."Location State Code" := Location."State Code";
                        PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
                        PurchaseHeader."GST Input Service Distribution" := Location."GST Input Service Distributor";
                    end;

        if PurchaseHeader."POS as Vendor State" then begin
            PurchaseLine.reset();
            PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
            PurchaseLine.Setfilter(PurchaseLine.Type, '<>%1', PurchaseLine.Type::"G/L Account");
            if Not PurchaseLine.IsEmpty() then
                Error(TypeErr, PurchaseLine.Type);
        end;
    end;

    local procedure POSOutIndia(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PartyType: enum "Party Type";
        GSTCustType: enum "GST Customer Type";
        DocType: Text;
        DocTypeEnum: Enum "Document Type Enum";
    begin
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
        PurchaseHeader.TestField("GST Vendor Type", "GST Vendor Type"::Registered);
        PurchaseHeader.TestField("POS as Vendor State", false);
        DocType := Format(PurchaseHeader."Document Type");
        Evaluate(DocTypeEnum, DocType);
        CheckReferenceInvoiceNo(DocTypeEnum, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");

        if Not PurchaseHeader."GST Invoice" then
            Error(POSGSTStructErr);

        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseHeader."GST Order Address State" <> '' then
                    GSTValidation.VerifyPOSOutOfIndia(
                        PartyType::Vendor,
                        PurchaseHeader."Location State Code",
                        PurchaseHeader."GST Order Address State",
                        PurchaseHeader."GST Vendor Type",
                        GSTCustType::" ")
                else
                    GSTValidation.VerifyPOSOutOfIndia(
                        PartyType::Vendor,
                        PurchaseHeader."Location State Code",
                        PurchaseHeader.State,
                        PurchaseHeader."GST Vendor Type",
                        GSTCustType::" ");

                PurchaseLine.Validate(Quantity);
                PurchaseLine.Validate("Unit Cost");
            until PurchaseLine.Next() = 0
        else
            GSTValidation.VerifyPOSOutOfIndia(
              PartyType::Vendor, PurchaseHeader."Location State Code", PurchaseHeader.State, PurchaseHeader."GST Vendor Type", GSTCustType::" ");
    end;

    local procedure WithoutBillOfEntry(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."GST Vendor Type" <> "GST Vendor Type"::SEZ then
            Error(SEZWboeErr, PurchaseHeader.FieldName("Without Bill Of Entry"));
    end;

    //PurchaseLine Validations - Definition
    local procedure GSTGroupCode(var PurchaseLine: Record "Purchase Line")
    var
        GSTGroup: Record "GST Group";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.TestStatusOpen();
        PurchaseLine.TestField("Work Tax Nature Of Deduction", '');
        PurchaseLine.TestField("Non-GST Line", false);
        PurchaseLine.Validate("GST Reverse Charge", false);

        if GSTGroup.Get(PurchaseLine."GST Group Code") then begin
            PurchaseLine."GST Group Type" := GSTGroup."GST Group Type";
            GetPurcasehHeader(PurchaseHeader, PurchaseLine);
            if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::Import then
                PurchaseLine."GST Reverse Charge" := true;

            if PurchaseHeader."GST Vendor Type" in [
                PurchaseHeader."GST Vendor Type"::Registered,
                PurchaseHeader."GST Vendor Type"::Unregistered,
                PurchaseHeader."GST Vendor Type"::SEZ]
            then
                PurchaseLine.Validate("GST Reverse Charge", GSTGroup."Reverse Charge");

            if (PurchaseLine."GST Group Type" = "GST Group Type"::Service) or
                (PurchaseLine.Type = Type::"Charge (Item)")
            then begin
                PurchaseLine.TestField("Custom Duty Amount", 0);
                PurchaseLine.TestField("GST Assessable Value", 0);
            end;
        end;
    end;

    local procedure Exempted(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.TestStatusOpen();
        CheckExemptedStatus(PurchaseLine);
        PurchaseLine.TestField("Quantity Received", 0);
        PurchaseLine.TestField("Return Qty. Shipped", 0);
        PurchaseLine.TestField("Quantity Invoiced", 0);
        GetPurcasehHeader(PurchaseHeader, PurchaseLine);
        if (PurchaseHeader."Applies-to Doc. No." <> '') or (PurchaseHeader."Applies-to ID" <> '') then
            Error(AppliesToDocErr);
    end;

    local procedure CustomDutyAmount(var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        GetPurcasehHeader(PurchaseHeader, PurchaseLine);
        if Not PurchaseHeader."GST Invoice" then
            exit;
        if PurchaseLine."Document Type" in ["Document Type Enum"::"Credit Memo", "Document Type Enum"::"Return Order"] then
            PurchaseLine.TestField("Custom Duty Amount", 0);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        if Not (Vendor."GST Vendor Type" in [Vendor."GST Vendor Type"::Import, Vendor."GST Vendor Type"::SEZ]) then
            Error(GSTVendorTypeErr, Vendor."GST Vendor Type"::Import, Vendor."GST Vendor Type"::SEZ);
        if (PurchaseLine."GST Group Type" <> "GST Group Type"::Goods) or (PurchaseLine.Type = Type::"Charge (Item)") then
            PurchaseLine.TestField("Custom Duty Amount", 0);
    end;

    local procedure GSTAssessableValue(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        GetPurcasehHeader(PurchaseHeader, PurchaseLine);
        if Not PurchaseHeader."GST Invoice" then
            exit;
        if PurchaseLine."Document Type" in ["Document Type Enum"::"Credit Memo", "Document Type Enum"::"Return Order"] then
            PurchaseLine.TestField("GST Assessable Value", 0);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        if Not (Vendor."GST Vendor Type" in [Vendor."GST Vendor Type"::Import, Vendor."GST Vendor Type"::SEZ]) then
            Error(GSTVendorTypeErr, Vendor."GST Vendor Type"::Import, Vendor."GST Vendor Type"::SEZ);
        if (PurchaseLine."GST Group Type" <> "GST Group Type"::Goods) or (PurchaseLine.Type = Type::"Charge (Item)") then
            PurchaseLine.TestField("GST Assessable Value", 0);
    end;

    local procedure NONGSTLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.TestStatusOpen();
        if PurchaseLine."Non-GST Line" then begin
            PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            if Not PurchaseHeader."GST Invoice" then
                Error(NGLStructErr);
            PurchaseLine."GST Group Code" := '';
        end;
    end;

    local procedure Supplementary(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        GetPurcasehHeader(PurchaseHeader, PurchaseLine);
        if Not PurchaseLine.Supplementary then
            PurchaseLine."Source Document No." := '';
        if PurchaseHeader."Invoice Type" = PurchaseHeader."Invoice Type"::Supplementary then
            PurchaseLine.TestField(Supplementary)
        else
            PurchaseLine.TestField(Supplementary, false);
    end;

    local procedure VendorInfo(
        var PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor)
    var
        Location: Record Location;
    begin
        if PurchaseHeader."Location Code" <> '' then begin
            Location.Get(PurchaseHeader."Location Code");
            PurchaseHeader.Trading := Location."Trading Location";
        end;

        PurchaseHeader.Validate("GST Vendor Type", Vendor."GST Vendor Type");
        if PurchaseHeader."Reference Invoice No." <> '' then
            PurchaseHeader."Reference Invoice No." := '';
        PurchaseHeader."Associated Enterprises" := Vendor."Associated Enterprises";
    end;

    local procedure PaytoVendorInfo(
        var PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor)
    begin
        PurchaseHeader."Vendor GST Reg. No." := PayToVendor."GST Registration No.";
        PurchaseHeader.State := PayToVendor."State Code";
        PurchaseHeader."GST Vendor Type" := PayToVendor."GST Vendor Type";
    end;

    local procedure GstLocationCode(var PurchaseHeader: Record "Purchase Header")
    var
        DocType: text;
        DocTypeEnum: Enum "Document Type Enum";
    begin
        DocType := Format(PurchaseHeader."Document Type");
        Evaluate(DocTypeEnum, DocType);
        CheckLocationCode(PurchaseHeader);
        CheckReferenceInvoiceNo(
            DocTypeEnum,
            PurchaseHeader."No.",
            PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure GLAccValue(
        var PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account")
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.Get(GLAccount."GST Group Code") then;
        UpdatePurchLineForGST(
            GLAccount."GST Credit",
            GLAccount."GST Group Code",
            GSTGroup."GST Group Type",
            GLAccount."HSN/SAC Code",
            GLAccount.Exempted,
            PurchaseLine);
    end;

    local procedure ItemValue(var PurchaseLine: Record "Purchase Line"; Item: Record Item)
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.Get(Item."GST Group Code") then;
        UpdatePurchLineForGST(
            Item."GST Credit",
            Item."GST Group Code",
            GSTGroup."GST Group Type",
            Item."HSN/SAC Code",
            Item.Exempted,
            PurchaseLine);
    end;

    local procedure FAValue(var PurchaseLine: Record "Purchase Line"; FixedAsset: Record "Fixed Asset")
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.Get(FixedAsset."GST Group Code") then;
        UpdatePurchLineForGST(
            FixedAsset."GST Credit",
            FixedAsset."GST Group Code",
            GSTGroup."GST Group Type",
            FixedAsset."HSN/SAC Code",
            FixedAsset.Exempted,
            PurchaseLine);
    end;

    local procedure ItemChargeValue(
        var PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge")
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.Get(ItemCharge."GST Group Code") then;
        UpdatePurchLineForGST(
            ItemCharge."GST Credit",
            ItemCharge."GST Group Code",
            GSTGroup."GST Group Type",
            ItemCharge."HSN/SAC Code",
            ItemCharge.Exempted,
            PurchaseLine);
    end;

    local procedure UpdatePurchLineForGST(
        GSTCredit: Enum "GST Credit";
                       GSTGrpCode: Code[20];
                       GSTGrpType: Enum "GST Group Type";
                       HSNSACCode: Code[10];
                       GSTExempted: Boolean;
        var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        GSTGroup: Record "GST Group";
    begin
        GetPurcasehHeader(PurchaseHeader, PurchaseLine);
        if PurchaseHeader."POS as Vendor State" then
            if Not (PurchaseLine.Type = Type::"G/L Account") then
                Error(TypeErr, PurchaseLine.Type);
        PurchaseLine."GST Credit" := GSTCredit;
        PurchaseLine."GST Group Code" := GSTGrpCode;
        PurchaseLine."GST Group Type" := GSTGrpType;
        PurchaseLine.Exempted := GSTExempted;
        PurchaseLine."HSN/SAC Code" := HSNSACCode;

        UpdateGSTJurisdictionType(PurchaseLine);

        PurchaseLine."GST Reverse Charge" :=
          PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import];
        if GSTGroup.Get(PurchaseLine."GST Group Code") and
           (PurchaseHeader."GST Vendor Type" in [
               PurchaseHeader."GST Vendor Type"::Registered,
               PurchaseHeader."GST Vendor Type"::Unregistered,
               PurchaseHeader."GST Vendor Type"::SEZ])
        then
            PurchaseLine."GST Reverse Charge" := GSTGroup."Reverse Charge";

        if (PurchaseHeader."GST Invoice") and (PurchaseHeader."GST Input Service Distribution") then begin
            if PurchaseLine.Type in [Type::"Fixed Asset", Type::"Charge (Item)", Type::Item] then
                Error(ChargeItemErr, PurchaseLine.Type);
            if (PurchaseLine."GST Group Code" <> '') and (PurchaseLine."GST Group Type" <> "GST Group Type"::Service) then
                Error(TypeISDErr, PurchaseLine.Type, PurchaseLine.FIELDNAME("GST Group Type"), "GST Group Type"::Service);
        end;

        PurchaseLine."Order Address Code" := PurchaseHeader."Order Address Code";
        if PurchaseLine."Order Address Code" <> '' then
            PurchaseLine."Buy-From GST Registration No" := PurchaseHeader."Order Address GST Reg. No."
        else
            PurchaseLine."Buy-From GST Registration No" := PurchaseHeader."Vendor GST Reg. No.";
        PurchaseLine."Bill to-Location(POS)" := PurchaseHeader."Bill to-Location(POS)";
        if PurchaseLine."Bill to-Location(POS)" <> '' then
            PurchaseLine."Bill to-Location(POS)" := PurchaseHeader."Bill to-Location(POS)"
        else
            PurchaseLine."Bill to-Location(POS)" := '';
        if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::Unregistered
        then
            PurchaseLine."GST Reverse Charge" := true;
    end;

    local procedure CheckExemptedStatus(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::Exempted then
            PurchaseLine.TestField(Exempted);
    end;

    local procedure CheckLocationCode(var PurchaseHeader: Record "Purchase Header")
    var
        Location: Record Location;
    begin
        if Not PurchaseHeader."POS as Vendor State" then begin
            if PurchaseHeader."Location Code" = '' then begin
                PurchaseHeader."Location GST Reg. No." := '';
                PurchaseHeader."Location State Code" := '';
            end else begin
                Location.get(PurchaseHeader."Location Code");
                PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
                PurchaseHeader."Location State Code" := Location."State Code";
            end;

            if PurchaseHeader."Bill to-Location(POS)" <> '' then begin
                Location.Get(PurchaseHeader."Bill to-Location(POS)");
                PurchaseHeader."Location State Code" := Location."State Code";
                PurchaseHeader."Location GST Reg. No." := Location."GST Registration No.";
                PurchaseHeader."GST Input Service Distribution" := Location."GST Input Service Distributor";
            end;
        end else
            if PurchaseHeader."Order Address Code" <> '' then
                PurchaseHeader."Location State Code" := PurchaseHeader."GST Order Address State"
            else
                PurchaseHeader."Location State Code" := PurchaseHeader.State;
        if Location.get(PurchaseHeader."Location Code") then
            PurchaseHeader."GST Input Service Distribution" := Location."GST Input Service Distributor";
    end;

    local procedure GetPurcasehHeader(
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase line")
    var
        Currency: Record Currency;
    begin
        PurchaseLine.TestField("Document No.");
        if (PurchaseLine."Document Type" <> PurchaseHeader."Document Type") or
            (PurchaseLine."Document No." <> PurchaseHeader."No.")
        then begin
            if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
                exit;
            if PurchaseHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                PurchaseHeader.TestField("Currency Factor");
                Currency.Get(PurchaseHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

    end;

    //Vendor Validation - Definition
    local procedure VendGSTRegistrationNo(var Vendor: Record Vendor)
    begin
        if Vendor."GST Registration No." <> '' then begin
            Vendor.TestField("State Code");
            if (Vendor."P.A.N. No." <> '') and (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") then
                GSTValidation.CheckGSTRegistrationNo(
                    Vendor."State Code",
                    Vendor."GST Registration No.",
                    Vendor."P.A.N. No.")
            else
                if Vendor."GST Registration No." <> '' then
                    Error(PANErr);

            if Vendor."GST Vendor Type" = "GST Vendor Type"::" " then
                Vendor."GST Vendor Type" := "GST Vendor Type"::Registered
            else
                if Not (Vendor."GST Vendor Type" in [
                    "GST Vendor Type"::Registered,
                    "GST Vendor Type"::Composite,
                    "GST Vendor Type"::Exempted,
                    "GST Vendor Type"::SEZ])
                then
                    Vendor."GST Vendor Type" := "GST Vendor Type"::Registered
        end else
            if Vendor."ARN No." = '' then
                Vendor."GST Vendor Type" := "GST Vendor Type"::" ";
    end;

    local procedure GSTVendorType(var Vendor: Record Vendor)
    begin
        if Vendor."GST Vendor Type" = "GST Vendor Type"::" " then begin
            Vendor."GST Registration No." := '';
            exit;
        end;
        if Vendor."GST Vendor Type" in [
            "GST Vendor Type"::Registered,
            "GST Vendor Type"::Composite,
            "GST Vendor Type"::SEZ,
            "GST Vendor Type"::Exempted]
        then begin
            if Vendor."GST Registration No." = '' then
                if Vendor."ARN No." = '' then
                    Error(GSTARNErr);
        end else begin
            Vendor."GST Registration No." := '';
            Vendor."ARN No." := '';
            if Vendor."GST Vendor Type" = "GST Vendor Type"::Import then
                Vendor.TestField("State Code", '')
            else
                if Vendor."GST Vendor Type" = "GST Vendor Type"::Unregistered then
                    Vendor.TestField("State Code");
            if Vendor."GST Vendor Type" <> "GST Vendor Type"::Import then
                Vendor."Associated Enterprises" := false;
        end;

        if Vendor."GST Registration No." <> '' then begin
            Vendor.TestField("State Code");

            if (Vendor."P.A.N. No." <> '') and (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") then
                GSTValidation.CheckGSTRegistrationNo(
                    Vendor."State Code",
                    Vendor."GST Registration No.",
                    Vendor."P.A.N. No.")
            else
                if Vendor."GST Registration No." <> '' then
                    Error(PANErr);
        end;
    end;

    local procedure VendARNNo(var Vendor: Record Vendor)
    begin
        if (Vendor."ARN No." = '') and (Vendor."GST Registration No." = '') then
            if Not (Vendor."GST Vendor Type" in [
                "GST Vendor Type"::Import,
                "GST Vendor Type"::Unregistered])
            then
                Vendor."GST Vendor Type" := "GST Vendor Type"::" ";

        if Vendor."GST Vendor Type" in [
            "GST Vendor Type"::Import,
            "GST Vendor Type"::Unregistered]
        then
            Vendor.TestField("ARN No.", '');
    end;

    local procedure VendStateCode(var Vendor: Record Vendor)
    begin
        if Not (Vendor."GST Vendor Type" in [
            "GST Vendor Type"::Import,
            "GST Vendor Type"::Unregistered])
        then
            Vendor.TestField("GST Registration No.", '');

        if Vendor."GST Vendor Type" = "GST Vendor Type"::Import then
            Error(GSTVendTypeErr, Vendor."GST Vendor Type");
    end;

    local procedure CheckBillOfEntry(VAR PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Not (PurchaseHeader."GST Vendor Type" IN [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) then
            exit;
        if Not (PurchaseHeader."Document Type" IN ["Document Type Enum"::Order, "Document Type Enum"::Invoice]) then
            exit;
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Setrange("GST Group Type", PurchaseLine."GST Group Type"::Goods);
        PurchaseLine.Setfilter(Type, '<>%1&<>%2', PurchaseLine.Type::" ", PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.Setfilter("GST Assessable Value", '%1', 0);
        if Not PurchaseLine.ISEMPTY() then
            Error(GSTAssessableErr, PurchaseHeader."Document Type", PurchaseHeader."No.");

        if PurchaseHeader."Without Bill Of Entry" then
            exit;
        PurchaseLine.RESET();
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Setfilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.Setfilter("Qty. to Invoice", '<>%1', 0);
        PurchaseLine.Setrange("GST Group Type", PurchaseLine."GST Group Type"::Goods);
        if PurchaseLine.FindFirst() then begin
            PurchaseHeader.get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            PurchaseHeader.TestField("Bill of Entry Date");
            PurchaseHeader.TestField("Bill of Entry No.");
            PurchaseHeader.TestField("Bill of Entry Value");
        end;
    end;

    local procedure CheckPostingDate(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        PurchaseLine.Reset();
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Setfilter(Type, '<>%1', PurchaseLine.Type::" ");
        if PurchaseLine.FindSet() then
            repeat
                if not TaxTypeSetup.GET() then
                    exit;
                TaxTypeSetup.TestField(Code);
                TaxTransactionValue.SetRange("Tax Type", TaxTypeSetup.Code);
                TaxTransactionValue.Setrange("Tax Record ID", PurchaseLine.RecordId);
                TaxTransactionValue.Setfilter(Percent, '<>%1', 0);
                if Not TaxTransactionValue.IsEmpty() then
                    CheckGSTAccountingPeriod(PurchaseHeader."Posting Date");
            Until PurchaseLine.Next() = 0;
    end;

    local procedure CheckUnregisteredVendorCondition(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TaxTypeSetup: Record "Tax Type Setup";
        Vendor: Record Vendor;
    begin
        PurchaseLine.Reset();
        PurchaseLine.Setrange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Setrange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Setfilter(Type, '<>%1', PurchaseLine.Type::" ");
        if PurchaseLine.FindSet() then
            repeat
                if not TaxTypeSetup.Get() then
                    exit;
                if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then;
                if (PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::Unregistered) and
                   (PurchaseLine."GST Jurisdiction Type" = PurchaseLine."GST Jurisdiction Type"::Interstate) and
                   (Vendor."Aggregate Turnover" = Vendor."Aggregate Turnover"::"More than 20 lakh") and
                   (PurchaseLine."GST Group Type" = PurchaseLine."GST Group Type"::Service)
                then
                    Error(IGSTAggTurnoverErr);
            until PurchaseLine.Next() = 0;
    end;

    local procedure GetLastClosedSubAccPeriod(): Date
    Var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        TaxAccountingPeriod.Setrange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.Setrange(Closed, TRUE);
        if TaxAccountingPeriod.FindLast() then
            exit(TaxAccountingPeriod."Starting Date");
    end;

    local procedure CheckGSTAccountingPeriod(PostingDate: Date)
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
        LastClosedDate: Date;
    begin
        LastClosedDate := GetLastClosedSubAccPeriod();

        TaxAccountingPeriod.Reset();
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        TaxAccountingPeriod.Setrange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.Setfilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod.FindLast() then begin
            TaxAccountingPeriod.Setfilter("Starting Date", '>=%1', PostingDate);
            if Not TaxAccountingPeriod.FindFirst() then
                Error(AccountingPeriodErr, PostingDate);
            if LastClosedDate <> 0D then
                if PostingDate < CALCDATE('<1M>', LastClosedDate) then
                    Error(
                        PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                        CALCDATE('<1M>', LastClosedDate));
        end else
            Error(AccountingPeriodErr, PostingDate);

        TaxAccountingPeriod.Setrange(Closed, FALSE);
        TaxAccountingPeriod.Setfilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod.FindLast() then begin
            TaxAccountingPeriod.Setfilter("Starting Date", '>=%1', PostingDate);
            if Not TaxAccountingPeriod.FindFirst() then
                if LastClosedDate <> 0D then
                    if PostingDate < CALCDATE('<1M>', LastClosedDate) then
                        Error(
                            PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                            CALCDATE('<1M>', LastClosedDate));
            TaxAccountingPeriod.TestField(Closed, FALSE);
        end else
            if LastClosedDate <> 0D then
                if PostingDate < CALCDATE('<1M>', LastClosedDate) then
                    Error(
                        PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                        CALCDATE('<1M>', LastClosedDate));
    end;

    local procedure UpdateGSTJurisdictionType(Var PurchaseLine: Record "Purchase Line")
    Var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseHeader.get(PurchaseLine."Document Type", PurchaseLine."Document No.") then begin
            if PurchaseHeader."GST Vendor Type" In [PurchaseHeader."GST Vendor Type"::SEZ, PurchaseHeader."GST Vendor Type"::Import] then begin
                PurchaseLine."GST Jurisdiction Type" := PurchaseLine."GST Jurisdiction Type"::Interstate;
                exit;
            end;
            if PurchaseHeader."POS Out Of India" then begin
                PurchaseLine."GST Jurisdiction Type" := PurchaseLine."GST Jurisdiction Type"::Interstate;
                exit;
            end;
            if PurchaseHeader."Location State Code" <> PurchaseHeader."State" then
                PurchaseLine."GST Jurisdiction Type" := PurchaseLine."GST Jurisdiction Type"::Interstate
            else
                if PurchaseHeader."Location State Code" = PurchaseHeader."State" then
                    PurchaseLine."GST Jurisdiction Type" := PurchaseLine."GST Jurisdiction Type"::Intrastate
                else
                    if (PurchaseHeader."Location State Code" <> '') and (PurchaseHeader."State" = '') then
                        PurchaseLine."GST Jurisdiction Type" := PurchaseLine."GST Jurisdiction Type"::Interstate;
        end;
    end;


    var
        GSTValidation: Codeunit "GST Base Validation";
        GSTARNErr: Label 'Either GST Registration No. or ARN No. should have a value.';
        POSasVendorErr: Label 'POS as Vendor State is only applicable for Registered vendor, current vendor is %1.', Comment = '%1 = GST Vendor Type';
        ReferenceNoErr: Label 'Selected Document No does Not exit for Reference Invoice No.';
        SelfInvoiceTypeErr: label 'GST Vendor Type must be Unregistered or Registered Reverse Charge for Invoice Type : Self-Invoice.';
        InvoiceTypRegVendErr: Label 'You can select Invoice Type for Registered Vendor in Reverse Charge Transactions only.';
        NonGSTInvTypeErr: Label 'You canNot enter Non-GST Invoice Type for any GST document.';
        LocationErr: label 'Bill To-Location and Location code must Not be same.';
        ReferenceInvoiceErr: Label 'Document is attached with Reference Invoice No. Please delete attached Reference Invoice No.';
        CurrencyCodePOSErr: label 'Currency code should be blank for POS as Vendor State, current value is %1.', Comment = '%1 = Currency Code';
        TypeErr: label 'POS as Vendor state is only applicable for G/L Account, the current value is %1.', Comment = '%1 = Type';
        POSGSTStructErr: Label 'You can Not select POS Out Of India field without GST Invoice Selection.';
        AppliesToDocErr: label 'You must remove Applies-to Doc No. before modifying Exempted value.';
        GSTVendorTypeErr: label 'GST Vendor Type must be %1 or %2.', Comment = '%1 = Import ; %2 = SEZ';
        NGLStructErr: label 'You can select Non-GST Line field in transaction only for GST related structure.';
        ChargeItemErr: label 'You canNot select %1 when GST Input Service Distribution is checked.', Comment = '%1 = Type';
        TypeISDErr: label 'You must select %1 whose %2 is %3 when GST Input Service Distribution is checked.', Comment = '%1 = Type , %2 = GST Group Type , %3 = Service';
        SEZWboeErr: Label '%1 is applicable on for SEZ Vendors.', Comment = '%1= Without Bill Of Entry';
        AggTurnoverErr: label 'You can change Aggregate Turnover only for Unregistered Vendor.';
        PANErr: label 'PAN No. must be entered.';
        GSTVendTypeErr: label 'State code should be empty,if GST Vendor Type %1.', Comment = '%1 = GST Vendor Type';
        VendGSTARNErr: label ' Either Vendor GST Registration No. or ARN No. should have a value.';
        OrderAddGSTARNErr: label ' Either GST Registration No. or ARN No. should have a value.';
        PANVendErr: Label 'PAN No. must be entered in Vendor.';
        GSTRegNoErr: Label 'You canNot select GST Reg. No. for selected Vendor Type.';
        GSTAssessableErr: Label 'GST Assessable Value must have a value in Purchase Line Document Type %1 and Document No %2.', Comment = '%1 = Document Type , %2 = Document No.';
        AccountingPeriodErr: Label 'GST Accounting Period does Not exist for the given Date %1.', Comment = '%1 = Posting Date';
        PeriodClosedErr: Label 'Accounting Period has been closed till %1, Document Posting Date must be greater than or equal to %2.', Comment = '%1 = Last Closed Date ; %2 = Document Posting Date';
        IGSTAggTurnoverErr: Label 'Interstate transaction cannot be calculated against Unregistered Vendor whose aggregate turnover is more than 20 Lakhs.';
}
