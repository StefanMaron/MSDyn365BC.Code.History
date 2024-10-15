codeunit 5348 "CRM Quote to Sales Quote"
{
    TableNo = "CRM Quote";

    trigger OnRun()
    var
        CDSCompany: Record "CDS Company";
        SalesHeader: Record "Sales Header";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            if (Rec.CompanyId <> EmptyGuid) and (Rec.CompanyId <> CDSCompany.CompanyId) then
                exit;

        ProcessInNAV(Rec, SalesHeader);
    end;

    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        UnableToFindOrderErr: Label 'Converting the sales quote to a sales order failed.';
        UnableToFindCrmOrderErr: Label 'Unable to find Dynamics 365 Sales order that corresponds to this quote.';
        UnableToFindOrderTelemetryErr: Label 'Converting the sales quote to a sales order failed.', Locked = true;
        CRMOrderFoundButUnsubmittedTelemetryMsg: Label 'Dynamics 365 Sales order %1 corresponding to the quote %2 found, but it is not submitted.', Locked = true;
        OrderCreatedFromQuoteTelemetryTxt: Label 'Converting the sales quote to a sales order succeeded.', Locked = true;
        UnableToFindCrmOrderTelemetryErr: Label 'Unable to find Dynamics 365 Sales order that corresponds to this quote.', Locked = true;
        UpdatedQuoteNoOnExistingOrderTelemetryTxt: Label 'Updated Quote No. on the existing order that corresponds to this quote.', Locked = true;
        CannotCreateSalesQuoteInNAVTxt: Label 'The sales quote cannot be created.';
        CannotFindCRMAccountForQuoteErr: Label 'The %2 account for %2 sales quote %1 does not exist.', Comment = '%1=CDS Sales Order Name, %2 - CDS service name';
        ItemDoesNotExistErr: Label '%1 The item %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name';
        NoCustomerErr: Label '%1 There is no potential customer defined on the %3 sales quote %2.', Comment = '%1= the text: "The sales quote cannot be created.", %2=sales order title, %3 - CDS service name';
        NotCoupledCustomerErr: Label '%1 There is no customer coupled to %3 account %2.', Comment = '%1= the text: "The sales quote cannot be created.", %2=account name, %3 - CDS service name';
        NotCoupledCRMProductErr: Label '%1 The %3 product %2 is not coupled to an item.', Comment = '%1= the text: "The sales quote cannot be created.", %2=product name, %3 - CDS service name';
        NotCoupledCRMResourceErr: Label '%1 The %3 resource %2 is not coupled to a resource.', Comment = '%1= the text: "The sales quote cannot be created.", %2=resource name, %3 - CDS service name';
        ResourceDoesNotExistErr: Label '%1 The resource %2 does not exist.', Comment = '%1= the text: "The sales quote cannot be created.", %2=product name';
        UnexpectedProductTypeErr: Label '%1 Unexpected value of product type code for product %2. The supported values are: sales inventory, services.', Comment = '%1= the text: "The sales quote cannot be created.", %2=product name';
        CRMProductName: Codeunit "CRM Product Name";
        LastSalesLineNo: Integer;
        MissingWriteInProductNoErr: Label '%1 %2 %3 contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.', Comment = '%1 - CDS service name,%2 - document type (order or quote), %3 - document number';
        MisingWriteInProductTelemetryMsg: Label 'The user is missing a default write-in product when creating a sales quote from a %1 quote.', Locked = true;
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        SuccessfullyCoupledSalesQuoteTelemetryMsg: Label 'The user successfully coupled a sales quote to a %1 quote.', Locked = true;

    procedure ProcessInNAV(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        if CRMQuote.StateCode = CRMQuote.StateCode::Active then
            exit(ProcessActiveQuote(CRMQuote, SalesHeader));

        exit(ProcessWonQuote(CRMQuote, SalesHeader));
    end;

    local procedure ProcessActiveQuote(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RevisionedCRMQuote: Record "CRM Quote";
        RecordId: RecordID;
        OpType: Option Create,Update;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(CRMQuote.QuoteId, DATABASE::"Sales Header", RecordId) then
            exit(false);

        if CRMQuote.RevisionNumber = 0 then
            exit(CreateOrUpdateNAVQuote(CRMQuote, SalesHeader, OpType::Create));

        RevisionedCRMQuote.Reset();
        RevisionedCRMQuote.SetRange(QuoteNumber, CRMQuote.QuoteNumber);
        RevisionedCRMQuote.SetRange(StateCode, RevisionedCRMQuote.StateCode::Closed);
        RevisionedCRMQuote.SetRange(StatusCode, RevisionedCRMQuote.StatusCode::Revised);
        if RevisionedCRMQuote.FindSet then
            repeat
                if CRMIntegrationRecord.FindRecordIDFromID(RevisionedCRMQuote.QuoteId, DATABASE::"Sales Header", RecordId) then begin
                    GetSalesHeaderByRecordId(RecordId, SalesHeader);
                    CRMIntegrationRecord.Get(RevisionedCRMQuote.QuoteId, SalesHeader.SystemId);
                    CRMIntegrationRecord.Delete(true);
                    exit(CreateOrUpdateNAVQuote(CRMQuote, SalesHeader, OpType::Update));
                end;
            until RevisionedCRMQuote.Next = 0;

        exit(CreateOrUpdateNAVQuote(CRMQuote, SalesHeader, OpType::Create));
    end;

    local procedure ProcessWonQuote(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header"): Boolean
    var
        QuoteCRMIntegrationRecord: Record "CRM Integration Record";
        WonQuoteCRMIntegrationRecord: Record "CRM Integration Record";
        OrderCRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesOrder: Record "CRM Salesorder";
        OrderSalesHeader: Record "Sales Header";
        BlankGuid: Guid;
        OpType: Option Create,Update;
        IsOrderCreated: Boolean;
        IsCRMOrderSubmitted: Boolean;
        YourReferenceFilter: Text;
    begin
        if CRMQuote.StateCode = CRMQuote.StateCode::Won then begin
            QuoteCRMIntegrationRecord.Reset();
            QuoteCRMIntegrationRecord.SetRange("CRM ID", CRMQuote.QuoteId);
            if not QuoteCRMIntegrationRecord.FindFirst() then begin
                CreateOrUpdateNAVQuote(CRMQuote, SalesHeader, OpType::Create);
                QuoteCRMIntegrationRecord.Get(CRMQuote.QuoteId, SalesHeader.SystemId)
            end;
            if not WonQuoteCRMIntegrationRecord.Get(CRMQuote.QuoteId, BlankGuid) then begin
                CRMSalesOrder.SetRange(QuoteId, CRMQuote.QuoteId);
                if not CRMSalesOrder.FindFirst() then begin
                    Session.LogMessage('0000D6P', UnableToFindCrmOrderTelemetryErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                    Error(UnableToFindCrmOrderErr);
                end;

                IsOrderCreated := OrderCRMIntegrationRecord.FindByCRMID(CRMSalesOrder.SalesOrderId);
                IsCRMOrderSubmitted := (CRMSalesOrder.StateCode = CRMSalesOrder.StateCode::Submitted);

                if SalesHeader.GetBySystemId(QuoteCRMIntegrationRecord."Integration ID") then begin
                    if not IsOrderCreated then
                        if IsCRMOrderSubmitted then begin
                            CODEUNIT.Run(CODEUNIT::"CRM Sales Order to Sales Order", CRMSalesOrder);
                            YourReferenceFilter := CopyStr(CRMSalesOrder.orderNumber, 1, MaxStrLen(OrderSalesHeader."Your Reference"));
                            OrderSalesHeader.SetRange("Your Reference", YourReferenceFilter);
                            if not OrderSalesHeader.FindFirst() then begin
                                Session.LogMessage('0000D6L', UnableToFindOrderTelemetryErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                                Error(UnableToFindOrderErr)
                            end else begin
                                IsOrderCreated := true;
                                Session.LogMessage('0000D6M', OrderCreatedFromQuoteTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                            end
                        end else
                            Session.LogMessage('0000DI3', StrSubstNo(CRMOrderFoundButUnsubmittedTelemetryMsg, CRMQuote.QuoteId, CRMSalesOrder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok)
                    else
                        OrderSalesHeader.GetBySystemId(OrderCRMIntegrationRecord."Integration ID");

                    if IsOrderCreated then begin
                        if OrderSalesHeader."Quote No." <> SalesHeader."No." then begin
                            OrderSalesHeader."Quote No." := SalesHeader."No.";
                            OrderSalesHeader.Modify();
                            Session.LogMessage('0000D6N', UpdatedQuoteNoOnExistingOrderTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                        end;
                        ManageSalesQuoteArchive(SalesHeader)
                    end else begin
                        SalesHeader.Status := SalesHeader.Status::Released;
                        SalesHeader.Modify();
                    end;
                end;

                WonQuoteCRMIntegrationRecord.Init();
                WonQuoteCRMIntegrationRecord.Validate("CRM ID", CRMQuote.QuoteId);
                WonQuoteCRMIntegrationRecord.Validate("Integration ID", BlankGuid);
                WonQuoteCRMIntegrationRecord.Insert(true);
            end;
            exit(true)
        end;
        exit(false)
    end;

    local procedure CreateOrUpdateNAVQuote(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header"; OpType: Option Create,Update): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if IsNullGuid(CRMQuote.QuoteId) then
            exit;

        if OpType = OpType::Update then
            ManageSalesQuoteArchive(SalesHeader);

        CreateOrUpdateSalesQuoteHeader(CRMQuote, SalesHeader, OpType);
        CreateOrUpdateSalesQuoteLines(CRMQuote, SalesHeader);
        CreateOrUpdateSalesQuoteNotes(CRMQuote, SalesHeader);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(SalesHeader.RecordId, CRMQuote.QuoteId);
        if OpType = OpType::Create then
            Session.LogMessage('0000839', StrSubstNo(SuccessfullyCoupledSalesQuoteTelemetryMsg, CRMProductName.CDSServiceName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        exit(true);
    end;

    local procedure CreateOrUpdateSalesQuoteHeader(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header"; OpType: Option Create,Update)
    var
        Customer: Record Customer;
    begin
        if OpType = OpType::Create then begin
            SalesHeader.Init();
            SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
            SalesHeader.Validate(Status, SalesHeader.Status::Open);
            SalesHeader.InitInsert;
        end else
            if SalesHeader.Status = SalesHeader.Status::Released then
                SalesHeader.Validate(Status, SalesHeader.Status::Open);

        GetCoupledCustomer(CRMQuote, Customer);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Your Reference", CopyStr(CRMQuote.QuoteNumber, 1, MaxStrLen(SalesHeader."Your Reference")));
        SalesHeader.Validate("Currency Code", CRMSynchHelper.GetNavCurrencyCode(CRMQuote.TransactionCurrencyId));
        SalesHeader.Validate("Requested Delivery Date", CRMQuote.RequestDeliveryBy);
        CopyBillToInformationIfNotEmpty(CRMQuote, SalesHeader);
        CopyShipToInformationIfNotEmpty(CRMQuote, SalesHeader);
        CopyCRMOptionFields(CRMQuote, SalesHeader);
        SalesHeader.Validate("Payment Discount %", CRMQuote.DiscountPercentage);
        SalesHeader.Validate("External Document No.", CopyStr(CRMQuote.Name, 1, MaxStrLen(SalesHeader."External Document No.")));
        SalesHeader.Validate("Quote Valid Until Date", CRMQuote.EffectiveTo);

        if OpType = OpType::Create then
            SalesHeader.Insert(true)
        else
            SalesHeader.Modify(true);
    end;

    local procedure CreateOrUpdateSalesQuoteNotes(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header")
    var
        CRMAnnotation: Record "CRM Annotation";
    begin
        CRMAnnotation.SetRange(ObjectId, CRMQuote.QuoteId);
        CRMAnnotation.SetRange(IsDocument, false);
        if CRMAnnotation.FindSet then
            repeat
                CreateNote(SalesHeader, CRMAnnotation);
            until CRMAnnotation.Next = 0;
    end;

    local procedure CreateOrUpdateSalesQuoteLines(CRMQuote: Record "CRM Quote"; SalesHeader: Record "Sales Header")
    var
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesLine: Record "Sales Line";
    begin
        // If any of the products on the lines are not found in NAV, err
        CRMQuotedetail.SetRange(QuoteId, CRMQuote.QuoteId); // Get all sales quote lines

        if CRMQuotedetail.FindSet then begin
            repeat
                InitializeSalesQuoteLine(CRMQuotedetail, SalesHeader, SalesLine);
                SalesLine.Insert();
                if SalesLine."Qty. to Assemble to Order" <> 0 then
                    SalesLine.Validate("Qty. to Assemble to Order");
            until CRMQuotedetail.Next = 0;
        end else begin
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
        end;

        SalesLine.InsertFreightLine(CRMQuote.FreightAmount);
    end;

    procedure GetCoupledCustomer(CRMQuote: Record "CRM Quote"; var Customer: Record Customer): Boolean
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVCustomerRecordId: RecordID;
        CRMAccountId: Guid;
    begin
        if IsNullGuid(CRMQuote.CustomerId) then
            Error(NoCustomerErr, CannotCreateSalesQuoteInNAVTxt, CRMQuote.Description, CRMProductName.CDSServiceName());

        // Get the ID of the CRM Account associated to the sales quote. Works for both CustomerType(s): account, contact
        if not GetCRMAccountOfCRMQuote(CRMQuote, CRMAccount) then
            Error(CannotFindCRMAccountForQuoteErr, CRMQuote.Name, CRMProductName.CDSServiceName());
        CRMAccountId := CRMAccount.AccountId;

        if not CRMIntegrationRecord.FindRecordIDFromID(CRMAccountId, DATABASE::Customer, NAVCustomerRecordId) then
            Error(NotCoupledCustomerErr, CannotCreateSalesQuoteInNAVTxt, CRMAccount.Name, CRMProductName.CDSServiceName());

        exit(Customer.Get(NAVCustomerRecordId));
    end;

    procedure GetCRMAccountOfCRMQuote(CRMQuote: Record "CRM Quote"; var CRMAccount: Record "CRM Account"): Boolean
    var
        CRMContact: Record "CRM Contact";
    begin
        if CRMQuote.CustomerIdType = CRMQuote.CustomerIdType::account then
            exit(CRMAccount.Get(CRMQuote.CustomerId));

        if CRMQuote.CustomerIdType = CRMQuote.CustomerIdType::contact then
            if CRMContact.Get(CRMQuote.CustomerId) then
                exit(CRMAccount.Get(CRMContact.ParentCustomerId));
        exit(false);
    end;

    local procedure CopyCRMOptionFields(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header")
    var
        CRMAccount: Record "CRM Account";
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), CRMQuote.ShippingMethodCodeEnum.AsInteger()) or
           CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCode), CRMQuote.ShippingMethodCode)
        then
            SalesHeader.Validate(
              "Shipping Agent Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Shipping Agent Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), CRMQuote.PaymentTermsCodeEnum.AsInteger()) or
           CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCode), CRMQuote.PaymentTermsCode)
        then
            SalesHeader.Validate(
              "Payment Terms Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Payment Terms Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), CRMQuote.FreightTermsCodeEnum.AsInteger()) or
           CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCode), CRMQuote.FreightTermsCode)
        then
            SalesHeader.Validate(
              "Shipment Method Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Shipment Method Code")));
    end;

    local procedure CopyBillToInformationIfNotEmpty(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header")
    begin
        // If the Bill-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMQuote.BillTo_Line1 = '') and
            (CRMQuote.BillTo_Line2 = '') and
            (CRMQuote.BillTo_City = '') and
            (CRMQuote.BillTo_PostalCode = '') and
            (CRMQuote.BillTo_Country = '') and
            (CRMQuote.BillTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Bill-to Address", Format(CRMQuote.BillTo_Line1, MaxStrLen(SalesHeader."Bill-to Address")));
        SalesHeader.Validate("Bill-to Address 2", Format(CRMQuote.BillTo_Line2, MaxStrLen(SalesHeader."Bill-to Address 2")));
        SalesHeader.Validate("Bill-to City", Format(CRMQuote.BillTo_City, MaxStrLen(SalesHeader."Bill-to City")));
        SalesHeader.Validate("Bill-to Post Code", Format(CRMQuote.BillTo_PostalCode, MaxStrLen(SalesHeader."Bill-to Post Code")));
        SalesHeader.Validate(
          "Bill-to Country/Region Code", Format(CRMQuote.BillTo_Country, MaxStrLen(SalesHeader."Bill-to Country/Region Code")));
        SalesHeader.Validate("Bill-to County", Format(CRMQuote.BillTo_StateOrProvince, MaxStrLen(SalesHeader."Bill-to County")));
    end;

    local procedure InitNewSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LastSalesLineNo := LastSalesLineNo + 10000;
        SalesLine.Validate("Line No.", LastSalesLineNo);
    end;

    local procedure InitializeWriteInQuoteLine(var SalesLine: Record "Sales Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
    begin
        SalesSetup.Get();
        if SalesSetup."Write-in Product No." = '' then begin
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            Session.LogMessage('000083A', StrSubstNo(MisingWriteInProductTelemetryMsg, CRMProductName.CDSServiceName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            Error(MissingWriteInProductNoErr, CRMProductName.CDSServiceName(), SalesLine."Document Type", SalesHeader."Your Reference");
        end;
        SalesSetup.Validate("Write-in Product No.");
        case SalesSetup."Write-in Product Type" of
            SalesSetup."Write-in Product Type"::Item:
                SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesSetup."Write-in Product Type"::Resource:
                SalesLine.Validate(Type, SalesLine.Type::Resource);
        end;
        SalesLine.Validate("No.", SalesSetup."Write-in Product No.");
    end;

    local procedure InitializeSalesQuoteLineFromItem(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Item: Record Item;
        NAVItemRecordID: RecordID;
    begin
        // Attempt to find the coupled item
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Item, NAVItemRecordID) then
            Error(NotCoupledCRMProductErr, CannotCreateSalesQuoteInNAVTxt, CRMProduct.Name, CRMProductName.CDSServiceName());

        if not Item.Get(NAVItemRecordID) then
            Error(ItemDoesNotExistErr, CannotCreateSalesQuoteInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
    end;

    local procedure InitializeSalesQuoteLineFromResource(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Resource: Record Resource;
        NAVResourceRecordID: RecordID;
    begin
        // Attempt to find the coupled resource
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Resource, NAVResourceRecordID) then
            Error(NotCoupledCRMResourceErr, CannotCreateSalesQuoteInNAVTxt, CRMProduct.Name, CRMProductName.CDSServiceName());

        if not Resource.Get(NAVResourceRecordID) then
            Error(ResourceDoesNotExistErr, CannotCreateSalesQuoteInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Resource);
        SalesLine.Validate("No.", Resource."No.");
    end;

    local procedure InitializeSalesQuoteLine(CRMQuotedetail: Record "CRM Quotedetail"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CRMProduct: Record "CRM Product";
    begin
        InitNewSalesLine(SalesHeader, SalesLine);

        if IsNullGuid(CRMQuotedetail.ProductId) then
            InitializeWriteInQuoteLine(SalesLine)
        else begin
            CRMProduct.Get(CRMQuotedetail.ProductId);
            CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
            case CRMProduct.ProductTypeCode of
                CRMProduct.ProductTypeCode::SalesInventory:
                    InitializeSalesQuoteLineFromItem(CRMProduct, SalesLine);
                CRMProduct.ProductTypeCode::Services:
                    InitializeSalesQuoteLineFromResource(CRMProduct, SalesLine);
                else
                    Error(UnexpectedProductTypeErr, CannotCreateSalesQuoteInNAVTxt, CRMProduct.ProductNumber);
            end;
        end;
        SetLineDescription(SalesHeader, SalesLine, CRMQuoteDetail);

        SalesLine.Validate(Quantity, CRMQuotedetail.Quantity);
        SalesLine.Validate("Unit Price", CRMQuotedetail.PricePerUnit);
        SalesLine.Validate(Amount, CRMQuotedetail.BaseAmount);
        SalesLine.Validate(
          "Line Discount Amount",
          CRMQuotedetail.Quantity * CRMQuotedetail.VolumeDiscountAmount +
          CRMQuotedetail.ManualDiscountAmount);
    end;

    local procedure CopyShipToInformationIfNotEmpty(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header")
    begin
        // If the Ship-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMQuote.ShipTo_Line1 = '') and
            (CRMQuote.ShipTo_Line2 = '') and
            (CRMQuote.ShipTo_City = '') and
            (CRMQuote.ShipTo_PostalCode = '') and
            (CRMQuote.ShipTo_Country = '') and
            (CRMQuote.ShipTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Ship-to Address", Format(CRMQuote.ShipTo_Line1, MaxStrLen(SalesHeader."Ship-to Address")));
        SalesHeader.Validate("Ship-to Address 2", Format(CRMQuote.ShipTo_Line2, MaxStrLen(SalesHeader."Ship-to Address 2")));
        SalesHeader.Validate("Ship-to City", Format(CRMQuote.ShipTo_City, MaxStrLen(SalesHeader."Ship-to City")));
        SalesHeader.Validate("Ship-to Post Code", Format(CRMQuote.ShipTo_PostalCode, MaxStrLen(SalesHeader."Ship-to Post Code")));
        SalesHeader.Validate(
          "Ship-to Country/Region Code", Format(CRMQuote.ShipTo_Country, MaxStrLen(SalesHeader."Ship-to Country/Region Code")));
        SalesHeader.Validate("Ship-to County", Format(CRMQuote.ShipTo_StateOrProvince, MaxStrLen(SalesHeader."Ship-to County")));
    end;

    local procedure CreateNote(SalesHeader: Record "Sales Header"; CRMAnnotation: Record "CRM Annotation")
    var
        RecordLink: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        RecordLinkManagement: Codeunit "Record Link Management";
        InStream: InStream;
        AnnotationText: Text;
    begin
        RecordLink."Record ID" := SalesHeader.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CRMAnnotation.Subject;
        CRMAnnotation.CalcFields(NoteText);

        CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
        InStream.Read(AnnotationText);

        RecordLinkManagement.WriteNote(RecordLink, CRMAnnotationCoupling.ExtractNoteText(AnnotationText));
        RecordLink.Created := CRMAnnotation.CreatedOn;
        RecordLink.Company := CompanyName;
        RecordLink.Insert(true);
    end;

    local procedure SetLineDescription(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var CRMQuoteDetail: Record "CRM Quotedetail");
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineDescriptionInStream: InStream;
        ExtendedDescription: Text;
        CRMQuoteLineDescription: Text;
    begin
        CRMQuotedetail.CalcFields(Description);
        CRMQuotedetail.Description.CreateInStream(LineDescriptionInStream, TEXTENCODING::UTF16);
        LineDescriptionInStream.ReadText(CRMQuoteLineDescription);
        if CRMQuoteLineDescription = '' then
            CRMQuoteLineDescription := CRMQuotedetail.ProductDescription;
        ExtendedDescription := CRMQuoteLineDescription;

        // in case of write-in product - write the description directly in the main sales line description
        if SalesReceivablesSetup.Get() then
            if SalesLine."No." = SalesReceivablesSetup."Write-in Product No." then begin
                SalesLine.Description := CopyStr(CRMQuoteLineDescription, 1, MaxStrLen(SalesLine.Description));
                if StrLen(CRMQuoteLineDescription) > MaxStrLen(SalesLine.Description) then
                    ExtendedDescription := CopyStr(CRMQuoteLineDescription, MaxStrLen(SalesLine.Description) + 1)
                else
                    ExtendedDescription := '';
            end;

        // in case of inventory item - write the item name in the main line and create extended lines with the extended description
        CreateExtendedDescriptionQuoteLines(SalesHeader, ExtendedDescription);

        // in case of line descriptions with multple lines, add all lines of the line descirption
        while not LineDescriptionInStream.EOS() do begin
            LineDescriptionInStream.ReadText(ExtendedDescription);
            CreateExtendedDescriptionQuoteLines(SalesHeader, ExtendedDescription);
        end;
    end;

    procedure CreateExtendedDescriptionQuoteLines(SalesHeader: Record "Sales Header"; FullDescription: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        while StrLen(FullDescription) > 0 do begin
            InitNewSalesLine(SalesHeader, SalesLine);

            SalesLine.Validate(Description, CopyStr(FullDescription, 1, MaxStrLen(SalesLine.Description)));
            SalesLine.Insert();
            FullDescription := CopyStr(FullDescription, MaxStrLen(SalesLine.Description) + 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure ManageSalesQuoteArchive(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        RecordLink: Record "Record Link";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.DeleteAll();
        RecordLink.SetRange("Record ID", SalesHeader.RecordId);
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.DeleteAll();
        if SalesHeader.Find() then begin
            SalesHeader.Status := SalesHeader.Status::Released;
            SalesHeader.Modify();
        end;
    end;

    local procedure GetSalesHeaderByRecordId(RecordID: RecordID; var SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        RecRef := RecordID.GetRecord;
        RecRef.SetTable(SalesHeader);
        SalesHeader.Find;
    end;
}

