codeunit 18143 "GST Sales Validation"
{
    //CopyDocument 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesLineBuffer', '', false, false)]
    local procedure CallTaxEngineOnAfterCopySalesLineFromSalesLineBuffer(var ToSalesLine: Record "Sales Line"; RecalculateLines: Boolean)
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        if not RecalculateLines then
            CalculateTax.CallTaxEngineOnSalesLine(ToSalesLine, ToSalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Tax", 'OnAfterValidateSalesLineFields', '', false, false)]
    local procedure AssignUnitPricePIT(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        TaxTypeSetup: Record "Tax Type Setup";
        TaxTransactionValue: Record "Tax Transaction Value";
        GSTBaseAmt: Decimal;
    begin
        if not SalesLine."Price Inclusive of Tax" then
            exit;

        if not TaxTypeSetup.Get() then
            exit;

        SalesLine."Total UPIT Amount" := SalesLine."Unit Price Incl. of Tax" * SalesLine.Quantity - SalesLine."Line Discount Amount";
        if (SalesLine."Unit Price Incl. of Tax" = 0) or (SalesLine."Total UPIT Amount" = 0) then
            exit;

        TaxTransactionValue.SetRange("Tax Type", TaxTypeSetup.Code);
        TaxTransactionValue.SetRange("Tax Record ID", SalesLine.RecordId);
        TaxTransactionValue.SetRange("Value Type", TaxTransactionValue."Value Type"::COMPONENT);
        TaxTransactionValue.SetRange(TaxTransactionValue."Value ID", 10);
        if TaxTransactionValue.FindFirst() then begin
            GSTBaseAmt := RoundGSTBaseAmount(TaxTransactionValue.Amount);
            if GSTBaseAmt = 0 then
                exit;
            SalesLine."Unit Price" := Round((GSTBaseAmt + SalesLine."Line Discount Amount") / SalesLine.Quantity);
            SalesLine."Line Amount" := GSTBaseAmt;
            SalesLine.Amount := GSTBaseAmt;
            SalesLine."Amount Including VAT" := GSTBaseAmt;
            SalesLine."Recalculate Invoice Disc." := false;
            SalesLine."Outstanding Amount" := GSTBaseAmt;
            SalesLine."Outstanding Amount (LCY)" := GSTBaseAmt;
            if SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.") then
                if SalesHeader."Currency Code" <> '' then
                    SalesLine."Outstanding Amount (LCY)" := Round(GSTBaseAmt / SalesHeader."Currency Factor");
            SalesLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterUpdateAmountsDone', '', false, false)]
    local procedure UpdateTotalUPITAmount(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line")
    begin
        if not SalesLine."Price Inclusive of Tax" then
            exit;

        SalesLine."Total UPIT Amount" := SalesLine."Unit Price Incl. of Tax" * SalesLine.Quantity - SalesLine."Line Discount Amount";
    end;

    local procedure RoundGSTBaseAmount(GSTBaseAmount: Decimal): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        GSTRoundingPrecision: Decimal;
        GSTInvRoundingDirection: Text[1];
    begin
        GLSetup.get();
        Case GLSetup."GST Rounding Type" of
            GLSetup."GST Rounding Type"::Nearest:
                GSTInvRoundingDirection := '=';
            GLSetup."GST Rounding Type"::Up:
                GSTInvRoundingDirection := '>';
            GLSetup."GST Rounding Type"::Down:
                GSTInvRoundingDirection := '<';
        end;
        if GLSetup."GST Rounding Precision" = 0 then
            GSTRoundingPrecision := 0.01
        else
            GSTRoundingPrecision := GLSetup."GST Rounding Precision";
        exit(Round(GSTBaseAmount, GSTRoundingPrecision, GSTInvRoundingDirection));
    end;

    //AssignPrice Inclusice of Tax
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Price Calc. Mgt.", 'OnAfterFindSalesLineItemPrice', '', false, false)]
    Local Procedure AssignPriceInclusiveTax(var SalesLine: Record "Sales Line"; var TempSalesPrice: Record "Sales Price")
    Begin
        SalesLine."Price Inclusive of Tax" := TempSalesPrice."Price Inclusive of Tax";

        SalesLine."Unit Price Incl. of Tax" := 0;
        SalesLine."Total UPIT Amount" := 0;
        if SalesLine."Price Inclusive of Tax" then begin
            SalesLine."Unit Price Incl. of Tax" := TempSalesPrice."Unit Price";
            SalesLine."Total UPIT Amount" := SalesLine."Unit Price Incl. of Tax" * SalesLine.Quantity - SalesLine."Line Discount Amount";
        end;
    End;

    //Check Accounting Period
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnAfterConfirmPost', '', false, false)]
    Local procedure CheckAccountignPeriod(var SalesHeader: Record "Sales Header")
    Begin
        CheckPostingDate(SalesHeader);
    End;

    //Check Accounting Period - Post Preview
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnRunPreviewOnAfterSetPostingFlags', '', false, false)]
    Local procedure CheckAccountignPeriodPostPreview(var SalesHeader: Record "Sales Header")
    Begin
        CheckPostingDate(SalesHeader);
    End;

    //Sales Quote to Sales Order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnBeforeModifySalesOrderHeader', '', false, false)]
    Local procedure CopyInfotoSalesOrder(SalesQuoteHeader: Record "Sales Header"; Var SalesOrderHeader: Record "Sales Header")
    Begin
        SalesOrderHeader."Location GST Reg. No." := SalesQuoteHeader."Location GST Reg. No.";
        SalesOrderHeader."Location State Code" := SalesQuoteHeader."Location State Code";
    End;

    //Invoice Discount Calculation
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales - Calc Discount By Type", 'OnAfterResetRecalculateInvoiceDisc', '', False, False)]
    local procedure ReCalculateGST(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        CalculateTax: Codeunit "Calculate Tax";
    Begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        If SalesLine.FindSet() Then
            Repeat
                CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);
            Until SalesLine.Next() = 0;
    end;

    //Sales Header Subscribers
    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'GST Customer Type', false, false)]
    Local procedure UpdateInvoieType(Var Rec: Record "Sales Header")
    Begin
        GSTInvoiceType(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'GST Without Payment Of Duty', false, false)]
    Local procedure ValidateGSTWithoutPaymentOfDuty(Var Rec: Record "Sales Header")
    Begin
        GSTWithoutPaymentOfDuty(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Invoice Type', false, false)]
    Local procedure ValidateInvoiceType(Var Rec: Record "Sales Header")
    Begin
        InvoiceType(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'E-Commerce Merchant Id', false, false)]
    Local procedure validateEcommerceMerchantId(Var Rec: Record "Sales Header")
    Begin
        EcommerceMerchantId(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Location GST Reg. No.', false, false)]
    Local procedure ValidateLocationGSTRegNo(Var Rec: Record "Sales Header")
    Begin
        LocationGSTRegNo(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Bill Of Export Date', false, false)]
    Local procedure validateBillOfExportDate(Var Rec: Record "Sales Header")
    Begin
        BillOfExportDate(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Bill Of Export No.', false, false)]
    Local procedure validateBillOfExportNo(Var Rec: Record "Sales Header")
    Begin
        BillOfExportNo(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'POS Out Of India', false, false)]
    Local procedure ValidatePOSOutOfIndia(Var Rec: Record "Sales Header")

    Begin
        POSOutOfIndia(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnBeforeInitRecord', '', false, false)]
    Local Procedure UpdateTradingInfo(Var SalesHeader: Record "Sales Header")
    Begin
        TradingInfo(SalesHeader)
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterInitRecord', '', false, false)]
    Local procedure UpdateInvoiceType(Var SalesHeader: Record "Sales Header")
    Begin
        InvoiceType(SalesHeader);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterCopySellToCustomerAddressFieldsFromCustomer', '', false, false)]
    Local procedure UpdateSelltoStateCode(Var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    Begin
        SelltoStateCode(SalesHeader, SellToCustomer);
    End;


    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    Local procedure ValidateSelltoCustNo(Var Rec: Record "Sales Header"; Var xRec: Record "Sales Header")
    Begin
        SelltoCustNo(Rec, xRec);
        AssignInvoiceType(rec);
    End;


    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterCheckBillToCust', '', false, false)]
    Local procedure UpdateBilltoCustinfo(Var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    Begin
        BilltoCustinfo(SalesHeader);
        AssignInvoiceType(SalesHeader);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterSetFieldsBilltoCustomer', '', false, false)]
    Local procedure UpdateBilltoNatureOfSupply(Var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    Begin
        BilltoNatureOfSupply(SalesHeader, Customer);

    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr', '', false, false)]
    Local procedure UpdateShipToAddrfields(Var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address")
    Begin
        ShipToAddrfields(SalesHeader, ShipToAddress);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    Local procedure UpdateCustomerFields(Var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)

    Begin
        CustomerFields(SalesHeader);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales header", 'OnAfterValidateEvent', 'Location Code', false, false)]
    Local procedure UpdateLocationinfo(Var Rec: Record "Sales Header")
    Begin
        Locationinfo(Rec);
    End;

    //Sales Line Subscribers
    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'GST Place Of Supply', false, false)]
    Local procedure ValidateGSTPlaceOfSupply(Var Rec: Record "Sales Line")
    Begin
        GSTPlaceOfSupply(Rec);
    End;

    [EventSubscriber(ObjectType::table, database::"Sales line", 'onaftervalidateevent', 'GST Assessable Value (LCY)', false, false)]
    Local Procedure AssignGSTAssessableValueFCY(var Rec: Record "Sales Line")
    Begin
        ExchangeAmtLCYToFCY(Rec);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'GST Group Code', false, false)]
    Local procedure ValidateGSTGroupCode(Var Rec: Record "Sales Line")
    Begin
        GSTGroupCode(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'Exempted', false, false)]
    Local procedure ValidateExepmted(Var Rec: Record "Sales Line")
    Begin
        Exepmted(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'GST On Assessable Value', false, false)]
    Local procedure ValidateGSTOnAssessableValue(Var Rec: Record "Sales Line")
    Begin
        GSTOnAssessableValue(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'GST Assessable Value (LCY)', false, false)]
    Local procedure ValidateGSTAssessableValueLCY(Var Rec: Record "Sales Line")
    Begin
        GSTAssessableValueLCY(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales line", 'OnAfterValidateEvent', 'Non-GST Line', false, false)]
    Local procedure ValidateNonGSTLine(Var Rec: Record "Sales Line")
    Begin
        NonGSTLine(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignGLAccountValues', '', False, False)]
    Local procedure AssignGLAccValue(Var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account")
    Begin
        GLAccValue(SalesLine, GLAccount);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterCopyFromItem', '', False, False)]
    Local procedure AssignItemValue(Var SalesLine: Record "Sales Line"; Item: Record Item)
    Begin
        ItemValue(SalesLine, Item);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignResourceValues', '', False, False)]
    Local procedure AssignResourceValue(Var SalesLine: Record "Sales Line"; Resource: Record Resource)
    Begin
        ResourceValue(SalesLine, Resource);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignFixedAssetValues', '', False, False)]
    Local procedure AssignFAValue(Var SalesLine: Record "Sales Line"; FixedAsset: Record "Fixed Asset")
    Begin
        FAValue(SalesLine, FixedAsset);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemChargeValues', '', False, False)]
    Local procedure AssignItemChargeValue(Var SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge")
    Begin
        ItemChargeValue(SalesLine, ItemCharge);
    End;

    //Ship-to Address Validation
    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnAfterValidateEvent', 'State', false, false)]
    Local procedure ValidateState(Var Rec: Record "Ship-to Address")
    Begin
        state(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", 'OnAfterValidateEvent', 'GST Registration No.', false, false)]
    Local procedure validateShiptoAddGSTRegistrationNo(Var Rec: Record "Ship-to Address")
    Begin
        ShiptoAddGSTRegistrationNo(Rec);
    End;

    //Customer - Subscribers 
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'GST Registration No.', False, False)]
    Local procedure ValidateGSTRegistrationNo(Var Rec: Record Customer)
    Begin
        CustGSTRegistrationNo(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'GST Registration Type', False, False)]
    Local procedure ValidateCustGSTRegistrationType(Var Rec: Record Customer)
    Begin
        CustGSTRegistrationType(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'GST Customer Type', False, False)]
    Local procedure ValidateCustGSTCustomerType(Var Rec: Record Customer)
    Begin
        CustGSTCustomerType(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'ARN No.', False, False)]
    Local procedure ValidateCustARNNo(Var Rec: Record Customer)
    Begin
        CustARNNo(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'P.A.N. No.', False, False)]
    Local procedure ValidateCustPANNo(Var Rec: Record Customer; Var xRec: Record Customer)
    Begin
        CustPANNo(Rec);
    End;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'State Code', False, False)]
    Local procedure validateStateCode(Var Rec: Record Customer)
    Begin
        CustStateCode(Rec);
    End;

    //Sales Header Validation - Definition
    Local procedure GSTInvoiceType(Var SalesHeader: Record "Sales Header")
    Begin
        Case SalesHeader."GST Customer Type" Of
            "GST Customer Type"::" ",
            "GST Customer Type"::Registered,
            "GST Customer Type"::Unregistered:
                SalesHeader."Invoice Type" := SalesHeader."Invoice Type"::Taxable;
            "GST Customer Type"::Export,
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit":
                SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::Export);
            "GST Customer Type"::Exempted:
                SalesHeader."Invoice Type" := SalesHeader."Invoice Type"::"Bill Of Supply";
        End;
    End;

    Local procedure GSTWithoutPaymentOfDuty(Var SalesHeader: Record "Sales Header")
    Begin
        if not (SalesHeader."GST Customer Type" in [
            "GST Customer Type"::Export,
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit"])
        Then
            Error(GSTPaymentDutyErr);
    End;

    Local procedure TradingInfo(Var SalesHeader: Record "Sales Header")
    Var
        CompanyInfo: Record "Company Information";
    Begin
        CompanyInfo.Get();
        SalesHeader.Trading := CompanyInfo."Trading Co.";
    End;

    Local procedure InvoiceType(Var SalesHeader: Record "Sales Header")
    Var
        SalesLine: Record "Sales Line";
        PostingNoSeries: Record "Posting No. Series";
        Record: Variant;
    Begin
        Record := SalesHeader;
        if SalesHeader."Invoice Type" = SalesHeader."Invoice Type"::"Non-GST" Then
            If SalesHeader."GST Invoice" Then
                Error(NonGSTInvTypeErr);
        CheckShippedDocument(SalesHeader);
        if SalesHeader."GST Customer Type" <> "GST Customer Type"::Exempted Then Begin
            if CheckAllLinesExemptedSales(SalesHeader) Then
                CheckInvoiceType(SalesHeader)
            else Begin
                SalesLine.RESET();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                if not SalesLine.IsEmpty() Then
                    SalesHeader.TestField("Invoice Type", SalesHeader."Invoice Type"::"Bill Of Supply");
            End;
        End else
            CheckInvoiceType(SalesHeader);
        if SalesHeader."Document Type" in ["Document Type Enum"::Order, "Document Type Enum"::Invoice] Then
            //GetPostInvoiceNoSeries //TODO
            PostingNoSeries.GetPostingNoSeriesCode(record)
        else
            if SalesHeader."Document Type" in [
                "Document Type Enum"::"Credit Memo",
                "Document Type Enum"::"Return Order"]
            Then
                //GetPostedCrMemoNoSeries; //TODO
                PostingNoSeries.GetPostingNoSeriesCode(record);

        UpdateInvoiceTypeLine(SalesHeader);
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and (SalesHeader."Reference Invoice No." <> '') Then
            if not (SalesHeader."Invoice Type" in [
                SalesHeader."Invoice Type"::"Debit Note",
                SalesHeader."Invoice Type"::Supplementary])
            Then
                Error(ReferenceNoErr);

        if SalesHeader."Document Type" in ["Document Type Enum"::Order, "Document Type Enum"::Invoice] Then
            ReferenceInvoiceNoValidation(SalesHeader);
    End;

    Local procedure CheckAllLinesExemptedSales(SalesHeader: Record "Sales Header"): Boolean
    Var
        SalesLine: Record "Sales Line";
        SalesLine1: Record "Sales Line";
    Begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine1.COPYFILTERS(SalesLine);
        SalesLine1.SetRange(Exempted, true);
        if SalesLine.COUNT() <> SalesLine1.COUNT() Then
            exit(true);
    End;

    Local procedure CheckInvoiceType(SalesHeader: Record "Sales Header")
    Begin
        Case SalesHeader."GST Customer Type" Of
            "GST Customer Type"::" ",
            "GST Customer Type"::Registered,
            "GST Customer Type"::Unregistered:
                if SalesHeader."Invoice Type" in [SalesHeader."Invoice Type"::"Bill Of Supply", SalesHeader."Invoice Type"::Export] Then
                    Error(InvoiceTypeErr, SalesHeader."Invoice Type", SalesHeader."GST Customer Type");
            "GST Customer Type"::Export,
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit":
                if SalesHeader."Invoice Type" in [SalesHeader."Invoice Type"::"Bill Of Supply", SalesHeader."Invoice Type"::Taxable] Then
                    Error(InvoiceTypeErr, SalesHeader."Invoice Type", SalesHeader."GST Customer Type");
            "GST Customer Type"::Exempted:
                if SalesHeader."Invoice Type" in [
                    SalesHeader."Invoice Type"::"Debit Note",
                    SalesHeader."Invoice Type"::Export,
                    SalesHeader."Invoice Type"::Taxable]
                Then
                    Error(InvoiceTypeErr, SalesHeader."Invoice Type", SalesHeader."GST Customer Type");
        End;
    End;

    Local procedure EcommerceMerchantId(Var SalesHeader: Record "Sales Header")
    Var
        eCommerceMerchant: Record "E-Commerce Merchant";
    Begin
        eCommerceMerchant.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        eCommerceMerchant.SetRange("Company GST Reg. No.", SalesHeader."Location GST Reg. No.");
        if eCommerceMerchant.FINDFIRST() Then
            SalesHeader.TestField("e-Commerce Merchant Id", eCommerceMerchant."Merchant Id");
    End;

    Local procedure LocationGSTRegNo(Var SalesHeader: Record "Sales Header")
    Var
        GSTRegistrationNos: Record "GST Registration Nos.";
    Begin
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
        if GSTRegistrationNos.GET(SalesHeader."Location GST Reg. No.") Then
            SalesHeader."Location State Code" := GSTRegistrationNos."State Code"
        else
            SalesHeader."Location State Code" := '';
        ReferenceInvoiceNoValidation(SalesHeader);
        SalesHeader."POS Out Of India" := False;
    End;

    Local procedure POSOutOfIndia(Var SalesHeader: Record "Sales Header")
    Var
        SalesLine: Record "Sales Line";
    Begin
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
        ReferenceInvoiceNoValidation(SalesHeader);
        if not SalesHeader."GST Invoice" Then
            Error(POSGSTStructErr);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() Then
            repeat
                if SalesLine."GST Place Of Supply" <> SalesLine."GST Place Of Supply"::"Location Address" Then
                    GSTValidation.VerifyPOSOutOfIndia(
                        "Party Type"::Customer,
                        SalesHeader."Location State Code",
                        GetPlaceOfSupplyStateCode(SalesLine),
                        "GST VEndor Type"::" ",
                        SalesHeader."GST Customer Type")
                else
                    Error(GSTPlaceOfSuppErr);
                SalesLine.Validate(Quantity);
                SalesLine.Validate("Unit Cost");
            until SalesLine.Next() = 0;

        GSTValidation.VerifyPOSOutOfIndia(
          "Party Type"::Customer,
          SalesHeader."Location State Code",
          SalesHeader."GST Bill-to State Code",
          "GST VEndor Type"::" ",
          SalesHeader."GST Customer Type");
    End;

    Local procedure BillOfExportDate(Var SalesHeader: Record "Sales Header")
    Begin
        SalesHeader.TestField("GST Customer Type", SalesHeader."GST Customer Type"::Export);
    End;

    Local procedure BillOfExportNo(Var SalesHeader: Record "Sales Header")
    Begin
        SalesHeader.TestField("GST Customer Type", SalesHeader."GST Customer Type"::Export);
    End;

    Local procedure ReferenceInvoiceNoValidation(SalesHeader: Record "Sales Header")
    Var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        DocTye: Text;
        DocTypeEnum: Enum "Document Type Enum";
    Begin
        DocTye := Format(SalesHeader."Document Type");
        Evaluate(DocTypeEnum, DocTye);
        ReferenceInvoiceNo.SetRange("Document Type", DocTypeEnum);
        ReferenceInvoiceNo.SetRange("Document No.", SalesHeader."No.");
        ReferenceInvoiceNo.SetRange("Source Type", ReferenceInvoiceNo."Source Type"::Customer);
        ReferenceInvoiceNo.SetRange("Source No.", SalesHeader."Sell-to Customer No.");
        ReferenceInvoiceNo.SetRange(Verified, true);
        if not ReferenceInvoiceNo.IsEmpty() Then
            Error(RefErr);
    End;

    Local procedure GetPlaceOfSupplyStateCode(SalesLine: Record "Sales Line"): Code[10]
    Var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        PlaceOfSupplyStateCode: Code[10];
    Begin
        SalesSetup.GET();
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        Case SalesLine."GST Place Of Supply" Of
            "GST Place Of Supply"::"Bill-to Address":
                PlaceOfSupplyStateCode := SalesHeader."GST Bill-to State Code";
            "GST Place Of Supply"::"Ship-to Address":
                PlaceOfSupplyStateCode := SalesHeader."GST Ship-to State Code";
            "GST Place Of Supply"::"Location Address":
                PlaceOfSupplyStateCode := SalesHeader."Location State Code";
            "GST Place Of Supply"::" ":
                if SalesSetup."GST DepEndency Type" = SalesSetup."GST DepEndency Type"::"Bill-to Address" Then
                    PlaceOfSupplyStateCode := SalesHeader."GST Bill-to State Code"
                else
                    if SalesSetup."GST DepEndency Type" = SalesSetup."GST DepEndency Type"::"Ship-to Address" Then
                        PlaceOfSupplyStateCode := SalesHeader."GST Ship-to State Code"
        End;
        exit(PlaceOfSupplyStateCode);
    End;

    Local procedure UpdateInvoiceTypeLine(SalesHeader: Record "Sales Header")
    Var
        SalesLine: Record "Sales Line";
    Begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet(true, false) Then
            repeat
                SalesLine."Invoice Type" := SalesHeader."Invoice Type";
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    End;

    Local procedure CheckShippedDocument(Var SalesHeader: record "Sales header")
    Var
        SalesLine: Record "Sales Line";
    Begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Qty. Shipped (Base)", '<>%1', 0);
        if not SalesLine.IsEmpty() Then
            Error(ShippedInvoiceTypeErr);
    End;

    //Sales Line Validation Definition
    Local procedure GSTPlaceOfSupply(Var SalesLine: Record "Sales Line")
    Var
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    Begin
        SalesLine.TestField("Quantity Shipped", 0);
        SalesLine.TestField("Quantity Invoiced", 0);
        SalesLine.TestField("Return Qty. Received", 0);
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.TestField("POS Out Of India", False);
        if SalesLine."GST Place Of Supply" = "GST Place Of Supply"::"Ship-to Address" Then Begin
            SalesHeader.TestField("Ship-to Code");
            SalesHeader.TestField("POS Out Of India", False);
            if SalesHeader."Ship-to GST Reg. No." = '' Then
                if ShipToAddress.GET(SalesLine."Sell-to Customer No.", SalesHeader."Ship-to Code") Then
                    if not (SalesHeader."GST Customer Type" in [
                        SalesHeader."GST Customer Type"::Unregistered,
                        SalesHeader."GST Customer Type"::Export])
                    Then
                        if ShipToAddress."ARN No." = '' Then
                            Error(ShipToGSTARNErr);
        End;
    End;


    Local procedure GSTGroupCode(Var SalesLine: Record "Sales Line")
    Var
        GSTGroup: Record "GST Group";
        SalesSetup: Record "Sales & Receivables Setup";
        GSTDependencyType: Text;
    Begin
        SalesLine.TestStatusOpen();
        SalesLine.TestField("Non-GST Line", False);
        if GSTGroup.GET(SalesLine."GST Group Code") Then Begin
            if GSTGroup."Reverse Charge" Then
                Error(GSTGroupReverseChargeErr, SalesLine."GST Group Code");
            SalesLine."GST Place Of Supply" := GSTGroup."GST Place Of Supply";
            SalesLine."GST Group Type" := GSTGroup."GST Group Type";
        End;
        if SalesLine."GST Place Of Supply" = "GST Place Of Supply"::" " Then Begin
            SalesSetup.GET();
            GSTDependencyType := Format(SalesSetup."GST DepEndency Type");
            Evaluate(SalesLine."GST Place Of Supply", GSTDependencyType);
        End;
        SalesLine."HSN/SAC Code" := '';
        SalesLine."GST On Assessable Value" := False;
        SalesLine."GST Assessable Value (LCY)" := 0;
    End;

    Local procedure Exepmted(Var SalesLine: Record "Sales Line")
    Var
        SalesHeader: Record "Sales Header";
    Begin
        SalesLine.TestField("Quantity Shipped", 0);
        SalesLine.TestField("Quantity Invoiced", 0);
        SalesLine.TestField("Return Qty. Received", 0);
        GetSalesHeader2(SalesHeader, SalesLine);
        if (SalesHeader."Applies-to Doc. No." <> '') or (SalesHeader."Applies-to ID" <> '') Then
            Error(AppliesToDocErr);
    End;

    Local procedure GSTOnAssessableValue(Var SalesLine: Record "Sales Line")
    Var
        GSTGroup: Record "GST Group";
    Begin
        SalesLine.TestField("Currency Code");
        SalesLine.TestField("GST Group Code");
        if GSTGroup.GET(SalesLine."GST Group Code") Then
            GSTGroup.TestField("GST Group Type", GSTGroup."GST Group Type"::Goods);
        if SalesLine.Type = Type::"Charge (Item)" Then
            SalesLine.TestField("GST On Assessable Value", False);
        SalesLine."GST Assessable Value (LCY)" := 0;
    End;

    Local procedure GSTAssessableValueLCY(Var SalesLine: Record "Sales Line")
    Begin
        SalesLine.TestField("GST On Assessable Value", true);
    End;

    Local procedure NonGSTLine(Var SalesLine: Record "Sales Line")
    Var
        SalesHeader: Record "Sales Header";
    Begin
        if SalesLine."Non-GST Line" Then Begin
            SalesLine.TestStatusOpen();
            SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
            if not salesheader."GST Invoice" Then
                Error(NGLStructErr);
            SalesLine."GST Group Code" := '';
            SalesLine."HSN/SAC Code" := '';
            SalesLine."GST On Assessable Value" := False;
            SalesLine."GST Assessable Value (LCY)" := 0;
        End;
    End;

    Local procedure GetSalesHeader2(
        Var SalesHeader: Record "Sales Header";
        Var SalesLine: record "Sales Line")
    Var
        Currency: Record Currency;
    Begin
        SalesLine.TestField("Document No.");
        if (SalesLine."Document Type" <> SalesHeader."Document Type") or
            (SalesLine."Document No." <> SalesHeader."No.")
        Then Begin
            SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
            if SalesHeader."Currency Code" = '' Then
                Currency.InitRoundingPrecision()
            else Begin
                SalesHeader.TestField("Currency Factor");
                Currency.GET(SalesHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            End;
        End;
    End;

    Local procedure SelltoStateCode(Var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    Begin
        if SalesHeader."GST Customer Type" in [
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::Export,
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit"]
        Then
            SalesHeader.State := ''
        else
            SalesHeader.State := SellToCustomer."State Code";
    End;

    Local procedure SelltoCustNo(Var Rec: Record "Sales Header"; Var xRec: Record "Sales Header")
    Begin
        if Rec."Invoice Type" = Rec."Invoice Type"::" " Then
            Rec."Invoice Type" := Rec."Invoice Type"::Taxable;

        if Rec."Reference Invoice No." <> '' Then
            Rec."Reference Invoice No." := '';

        if (Rec."GST Customer Type" <> "GST Customer Type"::" ") and (xRec."Sell-to Customer No." <> Rec."Sell-to Customer No.") Then
            Rec.Validate("Invoice Type");
    End;

    Local procedure BilltoCustinfo(Var SalesHeader: Record "Sales Header")
    Var
        Customer: Record Customer;
    Begin
        GetCust2(SalesHeader."Bill-to Customer No.", SalesHeader, Customer);
        SalesHeader."GST Customer Type" := Customer."GST Customer Type";
        SalesHeader."GST Bill-to State Code" := '';
        SalesHeader."GST Without Payment Of Duty" := False;
        SalesHeader."Customer GST Reg. No." := '';
        if SalesHeader."GST Customer Type" <> "GST Customer Type"::" " Then
            Customer.TestField(Address);

        if not (SalesHeader."GST Customer Type" = "GST Customer Type"::Export) Then
            SalesHeader."GST Bill-to State Code" := Customer."State Code";

        if not (SalesHeader."GST Customer Type" in ["GST Customer Type"::Export]) Then
            SalesHeader."Customer GST Reg. No." := Customer."GST Registration No.";

        if SalesHeader."GST Customer Type" = "GST Customer Type"::Unregistered Then
            SalesHeader."Nature Of Supply" := SalesHeader."Nature Of Supply"::B2C;
    End;

    Local procedure BilltoNatureOfSupply(Var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    Begin
        SalesHeader."GST Customer Type" := Customer."GST Customer Type";
        if SalesHeader."GST Customer Type" = "GST Customer Type"::Unregistered Then
            SalesHeader."Nature Of Supply" := SalesHeader."Nature Of Supply"::B2C;
    End;

    Local procedure ShipToAddrfields(Var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address")
    Begin
        if SalesHeader."GST Customer Type" <> "GST Customer Type"::" " Then
            if SalesHeader."GST Customer Type" in [
                "GST Customer Type"::Exempted,
                "GST Customer Type"::"Deemed Export",
                "GST Customer Type"::"SEZ Development",
                "GST Customer Type"::"SEZ Unit",
                "GST Customer Type"::Registered]
            Then Begin
                ShipToAddress.TestField(State);
                if ShipToAddress."GST Registration No." = '' Then
                    if ShipToAddress."ARN No." = '' Then
                        Error(ShiptoGSTARNErr);
                SalesHeader."GST Ship-to State Code" := ShipToAddress.State;
                SalesHeader."Ship-to GST Reg. No." := ShipToAddress."GST Registration No.";
            End;
    End;

    Local procedure CustomerFields(Var SalesHeader: Record "Sales Header")
    Var
        ShipToAddr: Record "Ship-to Address";
    Begin
        if SalesHeader."Document Type" in ["Document Type Enum"::"Credit Memo", "Document Type Enum"::"Return Order"] Then
            if ShipToAddr.GET(SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code") Then Begin
                if not (SalesHeader."GST Customer Type" in [
                    "GST Customer Type"::Export,
                    "GST Customer Type"::"Deemed Export",
                    "GST Customer Type"::"SEZ Development",
                    "GST Customer Type"::"SEZ Unit"])
                Then Begin
                    ShipToAddr.TestField(State);
                    SalesHeader."GST Ship-to State Code" := ShipToAddr.State;
                End;
                if not (SalesHeader."GST Customer Type" in ["GST Customer Type"::Export]) Then Begin
                    ShipToAddr.TestField(State);
                    SalesHeader."Ship-to GST Reg. No." := ShipToAddr."GST Registration No.";
                End;
            End;
    End;

    Local procedure Locationinfo(Var SalesHeader: Record "Sales Header")
    Var
        Location: Record Location;
    Begin
        if SalesHeader."Location Code" = '' Then Begin
            SalesHeader."Location GST Reg. No." := '';
            SalesHeader."Location State Code" := '';
        End else Begin
            Location.Get(SalesHeader."Location Code");
            SalesHeader."Location GST Reg. No." := Location."GST Registration No.";
            SalesHeader."Location State Code" := Location."State Code";
        End;
        if SalesHeader."Location Code" <> '' Then
            //GetPostInvoiceNoSeries(Rec); ////TODO
            SalesHeader."Location State Code" := Location."State Code";
        ReferenceInvoiceNoValidation(SalesHeader);
    End;

    Procedure GetPostInvoiceNoSeries(Var SalesHeader: Record "Sales Header")
    Var
        PostingNoseries: record "Posting No. Series";
        VariantRec: Variant;
    Begin
        VariantRec := SalesHeader;
        PostingNoseries.GetPostingNoSeriesCode(VariantRec);
    End;

    Local procedure GLAccValue(Var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account")
    Var
        SalesHeader: record "Sales Header";
    Begin
        Salesheader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine."Invoice Type" := SalesHeader."Invoice Type";
        UpdateGSTPlaceOfSupply(
            GLAccount."HSN/SAC Code",
            GLAccount."GST Group Code",
            GLAccount.Exempted,
            GLAccount."GST Credit", SalesLine);
    End;

    Local procedure ItemValue(Var SalesLine: Record "Sales Line"; Item: Record Item)
    Var
        SalesHeader: record "Sales Header";
    Begin
        if not Salesheader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;
        SalesLine."Invoice Type" := SalesHeader."Invoice Type";
        UpdateGSTPlaceOfSupply(
            Item."HSN/SAC Code",
            Item."GST Group Code",
            Item.Exempted,
            item."GST Credit",
            SalesLine);
    End;

    Local procedure ResourceValue(Var SalesLine: Record "Sales Line"; Resource: Record Resource)
    Var
        SalesHeader: record "Sales Header";
    Begin
        Salesheader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine."Invoice Type" := SalesHeader."Invoice Type";
        UpdateGSTPlaceOfSupply(
            Resource."HSN/SAC Code",
            Resource."GST Group Code",
            Resource.Exempted,
            Resource."GST Credit",
            SalesLine);
    End;

    Local procedure FAValue(Var SalesLine: Record "Sales Line"; FixedAsset: Record "Fixed Asset")
    Var
        SalesHeader: record "Sales Header";
    Begin
        Salesheader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine."Invoice Type" := SalesHeader."Invoice Type";
        UpdateGSTPlaceOfSupply(
            FixedAsset."HSN/SAC Code",
            FixedAsset."GST Group Code",
            FixedAsset.Exempted,
            FixedAsset."GST Credit",
            SalesLine);
    End;

    Local procedure ItemChargeValue(Var SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge")
    Var
        SalesHeader: record "Sales Header";
    Begin
        Salesheader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine."Invoice Type" := SalesHeader."Invoice Type";
        UpdateGSTPlaceOfSupply(
            ItemCharge."HSN/SAC Code",
            ItemCharge."GST Group Code",
            ItemCharge.Exempted,
            ItemCharge."GST Credit",
            SalesLine);
    End;

    [EventSubscriber(ObjectType::Table, database::"Sales Line", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure OnAfterValidateEventLocationCode(var Rec: Record "Sales Line")
    begin
        UpdateGSTJurisdictionType(Rec);
    end;

    Local procedure UpdateGSTPlaceOfSupply(
        HSNSACCode: Code[10];
        GSTGroupCode: Code[20];
        GSTExempted: Boolean;
        GSTCredit: Enum "GST Credit";
        Var SalesLine: Record "Sales Line")
    Var
        SalesSetup: Record "Sales & Receivables Setup";
        GSTGroup: Record "GST Group";
        GSTdependencyType: text;
        GSTPlaceofSuppplyEnum: enum "GST Place Of Supply";
    Begin
        SalesLine."HSN/SAC Code" := HSNSACCode;
        SalesLine."GST Group Code" := GSTGroupCode;
        SalesLine."GST Credit" := GSTcredit;
        SalesLine.Exempted := GSTExempted;
        SalesSetup.GET();
        GSTdependencyType := format(SalesSetup."GST DepEndency Type");
        Evaluate(GSTPlaceofSuppplyEnum, GSTdependencyType);
        SalesLine."GST Place Of Supply" := GSTPlaceofSuppplyEnum;
        if GSTGroup.GET(GSTGroupCode) Then Begin
            if GSTGroup."Reverse Charge" Then
                Error(GSTGroupReverseChargeErr, GSTGroupCode);
            SalesLine."GST Group Type" := GSTGroup."GST Group Type";
            if GSTGroup."GST Place Of Supply" <> GSTGroup."GST Place Of Supply"::" " Then
                SalesLine."GST Place Of Supply" := GSTGroup."GST Place Of Supply";
        End;
        UpdateGSTJurisdictionType(SalesLine)
    End;

    Local procedure GetCust2(
        CustNo: Code[20];
        Var SalesHeader: Record "Sales Header";
        Var Customer: record customer)
    Begin
        if not ((SalesHeader."Document Type" = "Document Type Enum"::Quote) and (CustNo = '')) Then Begin
            if CustNo <> Customer."No." Then
                Customer.GET(CustNo);
        End else
            CLEAR(Customer);
    End;

    //Ship-to Address Validation
    Local procedure State(Var ShiptoAddress: Record "Ship-to Address")
    Begin
        if ShiptoAddress.State = '' Then
            ShiptoAddress."GST Registration No." := '';
    End;

    Local procedure ShiptoAddGSTRegistrationNo(Var ShiptoAddress: Record "Ship-to Address")
    Var
        Customer: Record Customer;
    Begin
        ShiptoAddress.TestField(State);
        ShiptoAddress.TestField(Address);
        Customer.GET(ShiptoAddress."Customer No.");
        if Customer."P.A.N. No." <> '' Then
            GSTValidation.CheckGSTRegistrationNo(ShiptoAddress.State, ShiptoAddress."GST Registration No.", Customer."P.A.N. No.")
        else
            if ShiptoAddress."GST Registration No." <> '' Then
                Error(PANCustErr);
    End;

    //Customer Validations - Definition
    Local procedure CustGSTRegistrationNo(Var Customer: Record Customer)
    Begin
        if Customer."GST Registration No." <> '' Then
            if Customer."GST Registration Type" = "GST Registration Type"::GSTIN Then Begin
                Customer.TestField("State Code");
                if (Customer."P.A.N. No." <> '') and (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") Then
                    GSTValidation.CheckGSTRegistrationNo(
                        Customer."State Code",
                        Customer."GST Registration No.",
                        Customer."P.A.N. No.")
                else
                    if Customer."GST Registration No." <> '' Then
                        Error(PANErr);

                if Customer."GST Customer Type" = "GST Customer Type"::" " Then
                    Customer."GST Customer Type" := "GST Customer Type"::Registered
                else
                    if not (Customer."GST Customer Type" in [
                        "GST Customer Type"::Registered,
                        "GST Customer Type"::Exempted,
                        "GST Customer Type"::"SEZ Development",
                        "GST Customer Type"::"SEZ Unit"])
                    Then
                        Customer."GST Customer Type" := "GST Customer Type"::Registered;
            End else
                Customer."GST Customer Type" := "GST Customer Type"::" "
        else
            if Customer."ARN No." = '' Then
                Customer."GST Customer Type" := "GST Customer Type"::" ";
    End;

    Local procedure CustGSTRegistrationType(Var Customer: Record Customer)
    Begin
        if not (Customer."GST Customer Type" in ["GST Customer Type"::Registered, "GST Customer Type"::" "]) and
            not (Customer."GST Registration Type" = "GST Registration Type"::GSTIN) Then
            Error(GSTCustRegErr);
        if (Customer."P.A.N. No." <> '') and (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") Then
            GSTValidation.CheckGSTRegistrationNo(Customer."State Code", Customer."GST Registration No.", Customer."P.A.N. No.")
        else
            if Customer."GST Registration No." <> '' Then
                Error(PANErr);
    End;

    Local procedure CustGSTCustomerType(Var Customer: Record Customer)
    Begin
        if Customer."GST Customer Type" = "GST Customer Type"::" " Then Begin
            Customer."GST Registration No." := '';
            exit;
        End;
        Customer.TestField(Address);

        if not (Customer."GST Customer Type" in ["GST Customer Type"::Registered]) and not
           (Customer."GST Registration Type" = "GST Registration Type"::GSTIN)
        Then
            Error(GSTCustRegErr);

        if Customer."GST Customer Type" in [
            "GST Customer Type"::Registered,
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::Exempted,
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit"]
        Then
            if Customer."GST Registration No." = '' Then
                if Customer."ARN No." = '' Then
                    Error(GSTARNErr);

        if (Customer."GST Customer Type" in [
            "GST Customer Type"::Registered,
            "GST Customer Type"::Unregistered,
            "GST Customer Type"::Exempted,
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit"])
        Then
            Customer.TestField("State Code")
        else
            if Customer."GST Customer Type" <> "GST Customer Type"::"Deemed Export" Then
                Customer.TestField("State Code", '');

        if not (Customer."GST Customer Type" in [
            "GST Customer Type"::Registered,
            "GST Customer Type"::Exempted,
            "GST Customer Type"::"Deemed Export",
            "GST Customer Type"::"SEZ Development",
            "GST Customer Type"::"SEZ Unit"])
        Then Begin
            Customer."GST Registration No." := '';
            Customer."ARN No." := '';
        End;

        if Customer."GST Registration No." <> '' Then Begin
            Customer.TestField("State Code");
            if (Customer."P.A.N. No." <> '') and (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") Then
                GSTValidation.CheckGSTRegistrationNo(
                    Customer."State Code",
                    Customer."GST Registration No.",
                    Customer."P.A.N. No.")
            else
                if Customer."GST Registration No." <> '' Then
                    Error(PANErr);
        End;
    End;

    Local procedure CustARNNo(Var Customer: Record Customer)
    Begin
        if (Customer."ARN No." = '') and (Customer."GST Registration No." = '') Then
            if not (Customer."GST Customer Type" in [
                "GST Customer Type"::Export,
                "GST Customer Type"::Unregistered])
            Then
                Customer."GST Customer Type" := "GST Customer Type"::" ";

        if Customer."GST Customer Type" in [
            "GST Customer Type"::Export,
            "GST Customer Type"::Unregistered]
        Then
            Customer.TestField("ARN No.", '');
    End;

    Local procedure CustPANNo(Var Customer: Record Customer)
    Begin
        if (Customer."GST Registration No." <> '') and
            (Customer."P.A.N. No." <> COPYSTR(Customer."GST Registration No.", 3, 10))
        Then
            Error(SamePANErr);

        CheckGSTRegBlankInRef(Customer);
    End;

    Local procedure CheckGSTRegBlankInRef(Var Customer: Record Customer)
    Var
        ShipToAddress: Record "Ship-to Address";
    Begin
        ShipToAddress.SetRange("Customer No.", Customer."No.");
        ShipToAddress.SetFilter("GST Registration No.", '<>%1', '');
        if ShipToAddress.FindSet() Then
            repeat
                if Customer."P.A.N. No." <> COPYSTR(ShipToAddress."GST Registration No.", 3, 10) Then
                    Error(GSTPANErr, ShipToAddress.Code);
            until ShipToAddress.Next() = 0;
    End;

    Local procedure CustStateCode(Var Customer: Record Customer)
    Begin
        Customer.TestField("GST Registration No.", '');
        if Customer."GST Customer Type" in [
            "GST Customer Type"::Registered,
            "GST Customer Type"::Exempted,
            "GST Customer Type"::Unregistered]
        Then
            Customer.TestField("State Code")
        else
            if not (Customer."GST Customer Type" in [
                "GST Customer Type"::"Deemed Export",
                "GST Customer Type"::" ",
                "GST Customer Type"::"SEZ Development",
                "GST Customer Type"::"SEZ Unit"])
            Then
                Customer.TestField("State Code", '');
    End;

    Local procedure AssignInvoiceType(Var SalesHeader: Record "Sales Header")
    Begin
        Case SalesHeader."GST Customer Type" Of
            SalesHeader."GST Customer Type"::" ", SalesHeader."GST Customer Type"::Registered, SalesHeader."GST Customer Type"::Unregistered:
                SalesHeader."Invoice Type" := SalesHeader."Invoice Type"::Taxable;
            "GST Customer Type"::Export, "GST Customer Type"::"Deemed Export",
          SalesHeader."GST Customer Type"::"SEZ Development", SalesHeader."GST Customer Type"::"SEZ Unit":
                SalesHeader.VALIDATE("Invoice Type", SalesHeader."Invoice Type"::Export);
            SalesHeader."GST Customer Type"::Exempted:
                SalesHeader."Invoice Type" := SalesHeader."Invoice Type"::"Bill Of Supply";
        End;
    End;

    Local procedure ExchangeAmtLCYToFCY(Var SalesLine: Record "Sales Line")
    var
        CurrExChangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine."GST Assessable Value (FCY)" :=
         CurrExChangeRate.ExchangeAmtLCYToFCY
        (SalesHeader."Posting Date", SalesHeader."Currency Code",
        SalesLine."GST Assessable Value (LCY)", SalesHeader."Currency Factor");
    End;

    Local Procedure CheckPostingDate(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxTypeSetup: Record "Tax Type Setup";
    Begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        SalesLine.Reset();
        SalesLine.Setrange("Document Type", SalesHeader."Document Type");
        SalesLine.Setrange("Document No.", SalesHeader."No.");
        SalesLine.Setfilter(Type, '<>%1', SalesLine.Type::" ");
        If SalesLine.FindSet() Then
            Repeat
                TaxTransactionValue.Setrange("Tax Type", TaxTypeSetup.Code);
                TaxTransactionValue.Setrange("Tax Record ID", SalesLine.RecordId);
                TaxTransactionValue.Setfilter(Percent, '<>%1', 0);
                If Not TaxTransactionValue.IsEmpty() Then
                    CheckGSTAccountingPeriod(SalesHeader."Posting Date");
            Until SalesLine.Next() = 0;

    End;

    LOCAL Procedure GetLastClosedSubAccPeriod(): Date
    Var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
    Begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        TaxAccountingPeriod.Setrange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.Setrange(Closed, TRUE);
        If TaxAccountingPeriod.FindLast() Then
            Exit(TaxAccountingPeriod."Starting Date");
    End;

    Local Procedure CheckGSTAccountingPeriod(PostingDate: Date)
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
        LastClosedDate: Date;
    Begin
        LastClosedDate := GetLastClosedSubAccPeriod();

        TaxAccountingPeriod.Reset();
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        TaxAccountingPeriod.Setrange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccountingPeriod.Setfilter("Starting Date", '<=%1', PostingDate);
        If TaxAccountingPeriod.FindLast() Then Begin
            TaxAccountingPeriod.Setfilter("Starting Date", '>=%1', PostingDate);
            If Not TaxAccountingPeriod.FindFirst() Then
                Error(AccountingPeriodErr, PostingDate);
            If LastClosedDate <> 0D Then
                If PostingDate < CALCDATE('<1M>', LastClosedDate) Then
                    Error(
                       PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                        CALCDATE('<1M>', LastClosedDate));
        End Else
            Error(AccountingPeriodErr, PostingDate);


        TaxAccountingPeriod.Setrange(Closed, FALSE);
        TaxAccountingPeriod.Setfilter("Starting Date", '<=%1', PostingDate);
        If TaxAccountingPeriod.FindLast() Then Begin
            TaxAccountingPeriod.Setfilter("Starting Date", '>=%1', PostingDate);
            If Not TaxAccountingPeriod.FindFirst() Then
                If LastClosedDate <> 0D Then
                    If PostingDate < CALCDATE('<1M>', LastClosedDate) Then
                        Error(
                           PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                            CALCDATE('<1M>', LastClosedDate));
            TaxAccountingPeriod.TESTFIELD(Closed, FALSE);
        END ELSE
            If LastClosedDate <> 0D Then
                If PostingDate < CALCDATE('<1M>', LastClosedDate) Then
                    Error(
                        PeriodClosedErr, CALCDATE('<-1D>', CALCDATE('<1M>', LastClosedDate)),
                        CALCDATE('<1M>', LastClosedDate));
    End;

    Local Procedure UpdateGSTJurisdictionType(Var SalesLine: Record "Sales Line")
    Var
        SalesHeader: Record "Sales Header";
    Begin

        IF SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.") Then Begin
            If SalesHeader."POS Out Of India" Then Begin
                SalesLine."GST Jurisdiction Type" := SalesLine."GST Jurisdiction Type"::Interstate;
                Exit;
            End;
            If SalesHeader."Invoice Type" = SalesHeader."Invoice Type"::Export Then Begin
                SalesLine."GST Jurisdiction Type" := SalesLine."GST Jurisdiction Type"::Interstate;
                Exit;
            End;
            If SalesHeader."Location State Code" <> SalesHeader."State" Then
                SalesLine."GST Jurisdiction Type" := SalesLine."GST Jurisdiction Type"::Interstate
            Else
                If SalesHeader."Location State Code" = SalesHeader."State" Then
                    SalesLine."GST Jurisdiction Type" := SalesLine."GST Jurisdiction Type"::Intrastate
                Else
                    if (SalesHeader."Location State Code" <> '') and (SalesHeader."State" = '') Then
                        SalesLine."GST Jurisdiction Type" := SalesLine."GST Jurisdiction Type"::Interstate;
        End;
    End;

    Var
        GSTValidation: codeunit "GST Base Validation";
        RefErr: Label 'Document is attached with Reference Invoice No. Please delete attached Reference Invoice No.';
        ReferenceNoErr: label 'Selected Document No does not exit for Reference Invoice No.';
        GSTPaymentDutyErr: Label 'You can only select GST without payment Of Duty in Export or Deemed Export Customer.';
        NonGSTInvTypeErr: Label 'You cannot enter Non-GST Invoice Type for any GST document.';
        POSGSTStructErr: label 'You can not select POS Out Of India field without GST Structure.';
        AppliesToDocErr: label 'You must remove Applies-to Doc No. before modifying Exempted value';
        NGLStructErr: label 'You can select Non-GST Line field in transaction only for GST related structure.';
        GSTPlaceOfSuppErr: label 'You can not select POS Out Of India field on header if GST Place Of Supply is Location Address.';
        ShippedInvoiceTypeErr: label 'You can not change the Invoice Type for Shipped Document.';
        ShipToGSTARNErr: label 'Either Ship-To Address GST Registration No. or ARN No. in Ship-To Address should have a value.';
        GSTGroupReverseChargeErr: label 'GST Group Code %1 with Reverse Charge cannot be selected for Sales transactions.', Comment = '%1 = GSTGroupCode';
        PANCustErr: label 'PAN No. must be entered in Customer.';
        PANErr: Label 'PAN No. must be entered.';
        GSTCustRegErr: label 'GST Customer type format Blank & Registered is allowed to select when GST Registration Type is UID or GID.';
        GSTPANErr: label 'Please update GST Registration No. to blank in the record %1 from Ship To Address.', Comment = '%1 = ShipToAddress';
        GSTARNErr: label 'Either GST Registration No. or ARN No. should have a value.';
        InvoiceTypeErr: label 'You can not select the Invoice Type %1 for GST Customer Type %2.', Comment = '%1 = Invoice Type ; %2 = GST Customer Type';
        SamePANErr: label 'From postion 3 to 12 in GST Registration No. should be same as it is in PAN No. so delete and Then update it.';
        AccountingPeriodErr: Label 'GST Accounting Period does Not exist for the given Date %1.', Comment = '%1 = Posting Date';
        PeriodClosedErr: Label 'Accounti        ng Period has been closed till %1, Document Posting Date must be greater than or equal to %2.',
        Comment = '%1 = Last Closed Date ; %2 = Document Posting Date';
}