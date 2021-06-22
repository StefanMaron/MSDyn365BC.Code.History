codeunit 5343 "CRM Sales Order to Sales Order"
{
    TableNo = "CRM Salesorder";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateInNAV(Rec, SalesHeader);
    end;

    var
        CannotCreateSalesOrderInNAVTxt: Label 'The sales order cannot be created.';
        NoCRMAccountForOrderErr: Label 'Sales order %1 is created for %2 %3, which doesn''t correspond to an account in %4.', Comment = '%1=Dynamics CRM Sales Order Name, %2 - customer id type, %3 customer id, %4 - Microsoft Dynamics CRM';
        ItemDoesNotExistErr: Label '%1 The item %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name';
        NoCustomerErr: Label '%1 There is no potential customer defined on the %3 sales order %2.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=sales order title, %3 - Microsoft Dynamics CRM';
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMProductName: Codeunit "CRM Product Name";
        LastSalesLineNo: Integer;
        NotCoupledCustomerErr: Label '%1 There is no customer coupled to %3 account %2.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=account name, %3 - Microsoft Dynamics CRM';
        NotCoupledCRMProductErr: Label '%1 The %3 product %2 is not coupled to an item.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=product name, %3 - Microsoft Dynamics CRM';
        NotCoupledCRMResourceErr: Label '%1 The %3 resource %2 is not coupled to a resource.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=resource name, %3 - Microsoft Dynamics CRM';
        NotCoupledCRMSalesOrderErr: Label 'The %2 sales order %1 is not coupled.', Comment = '%1=sales order number, %2 - Microsoft Dynamics CRM';
        NotCoupledSalesHeaderErr: Label 'The sales order %1 is not coupled to %2.', Comment = '%1=sales order number, %2 - Microsoft Dynamics CRM';
        OverwriteCRMDiscountQst: Label 'There is a discount on the %2 sales order, which will be overwritten by %1 settings. You will have the possibility to update the discounts directly on the sales order, after it is created. Do you want to continue?', Comment = '%1 - product name, %2 - Microsoft Dynamics CRM';
        ResourceDoesNotExistErr: Label '%1 The resource %2 does not exist.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=product name';
        UnexpectedProductTypeErr: Label '%1 Unexpected value of product type code for product %2. The supported values are: sales inventory, services.', Comment = '%1= the text: "The Dynamics CRM Sales Order cannot be created.", %2=product name';
        ZombieCouplingErr: Label 'Although the coupling from %2 exists, the sales order had been manually deleted. If needed, please use the menu to create it again in %1.', Comment = '%1 - product name, %2 - Microsoft Dynamics CRM';
        MissingWriteInProductNoErr: Label '%1 %2 %3 contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.', Comment = '%1 - CRM product name,%2 - document type (order or quote), %3 - document number';
        MisingWriteInProductTelemetryMsg: Label 'The user is missing a default write-in product when creating a sales order from a %1 order.', Locked = true;
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        SuccessfullyCoupledSalesOrderTelemetryMsg: Label 'The user successfully coupled a sales order to a %1 order.', Locked = true;

    local procedure ApplySalesOrderDiscounts(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CRMDiscountAmount: Decimal;
    begin
        // No discounts to apply
        if (CRMSalesorder.DiscountAmount = 0) and (CRMSalesorder.DiscountPercentage = 0) then
            exit;

        // Attempt to set the discount, if NAV general and customer settings allow it
        // Using CRM discounts
        CRMDiscountAmount := CRMSalesorder.TotalLineItemAmount - CRMSalesorder.TotalAmountLessFreight;
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(CRMDiscountAmount, SalesHeader);

        // NAV settings (in G/L Setup as well as per-customer discounts) did not allow using the CRM discounts
        // Using NAV discounts
        // But the user will be able to manually update the discounts after the order is created in NAV
        if not Confirm(StrSubstNo(OverwriteCRMDiscountQst, PRODUCTNAME.Short, CRMProductName.SHORT), true) then
            Error('');
    end;

    local procedure CopyCRMOptionFields(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMAccount: Record "CRM Account";
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), CRMSalesorder.ShippingMethodCodeEnum)
        then
            SalesHeader.Validate(
              "Shipping Agent Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Shipping Agent Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), CRMSalesorder.PaymentTermsCodeEnum)
        then
            SalesHeader.Validate(
              "Payment Terms Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Payment Terms Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), CRMSalesorder.FreightTermsCodeEnum)
        then
            SalesHeader.Validate(
              "Shipment Method Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue, 1, MaxStrLen(SalesHeader."Shipment Method Code")));
    end;

    local procedure CopyBillToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    begin
        // If the Bill-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMSalesorder.BillTo_Line1 = '') and
            (CRMSalesorder.BillTo_Line2 = '') and
            (CRMSalesorder.BillTo_City = '') and
            (CRMSalesorder.BillTo_PostalCode = '') and
            (CRMSalesorder.BillTo_Country = '') and
            (CRMSalesorder.BillTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Bill-to Address", CopyStr(CRMSalesorder.BillTo_Line1, 1, MaxStrLen(SalesHeader."Bill-to Address")));
        SalesHeader.Validate("Bill-to Address 2", CopyStr(CRMSalesorder.BillTo_Line2, 1, MaxStrLen(SalesHeader."Bill-to Address 2")));
        SalesHeader.Validate("Bill-to City", CopyStr(CRMSalesorder.BillTo_City, 1, MaxStrLen(SalesHeader."Bill-to City")));
        SalesHeader.Validate("Bill-to Post Code", CopyStr(CRMSalesorder.BillTo_PostalCode, 1, MaxStrLen(SalesHeader."Bill-to Post Code")));
        SalesHeader.Validate(
          "Bill-to Country/Region Code", CopyStr(CRMSalesorder.BillTo_Country, 1, MaxStrLen(SalesHeader."Bill-to Country/Region Code")));
        SalesHeader.Validate("Bill-to County", CopyStr(CRMSalesorder.BillTo_StateOrProvince, 1, MaxStrLen(SalesHeader."Bill-to County")));
    end;

    local procedure CopyShipToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    begin
        // If the Ship-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMSalesorder.ShipTo_Line1 = '') and
            (CRMSalesorder.ShipTo_Line2 = '') and
            (CRMSalesorder.ShipTo_City = '') and
            (CRMSalesorder.ShipTo_PostalCode = '') and
            (CRMSalesorder.ShipTo_Country = '') and
            (CRMSalesorder.ShipTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Ship-to Address", CopyStr(CRMSalesorder.ShipTo_Line1, 1, MaxStrLen(SalesHeader."Ship-to Address")));
        SalesHeader.Validate("Ship-to Address 2", CopyStr(CRMSalesorder.ShipTo_Line2, 1, MaxStrLen(SalesHeader."Ship-to Address 2")));
        SalesHeader.Validate("Ship-to City", CopyStr(CRMSalesorder.ShipTo_City, 1, MaxStrLen(SalesHeader."Ship-to City")));
        SalesHeader.Validate("Ship-to Post Code", CopyStr(CRMSalesorder.ShipTo_PostalCode, 1, MaxStrLen(SalesHeader."Ship-to Post Code")));
        SalesHeader.Validate(
          "Ship-to Country/Region Code", CopyStr(CRMSalesorder.ShipTo_Country, 1, MaxStrLen(SalesHeader."Ship-to Country/Region Code")));
        SalesHeader.Validate("Ship-to County", CopyStr(CRMSalesorder.ShipTo_StateOrProvince, 1, MaxStrLen(SalesHeader."Ship-to County")));
    end;

    local procedure SetLineDescription(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineDescription: Text)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if StrLen(LineDescription) > MaxStrLen(SalesLine.Description) then begin
            SalesLine.Description := CopyStr(LineDescription, 1, MaxStrLen(SalesLine.Description));
            CreateExtendedDescriptionOrderLines(
              SalesHeader,
              CopyStr(
                LineDescription,
                MaxStrLen(SalesLine.Description) + 1));
        end else begin
            SalesReceivablesSetup.get();
            if (SalesLine."No." = SalesReceivablesSetup."Write-in Product No.") then
                SalesLine.Description := CopyStr(LineDescription, 1, MaxStrLen(SalesLine.Description));
        end;
    end;

    local procedure CoupledSalesHeaderExists(CRMSalesorder: Record "CRM Salesorder"): Boolean
    var
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVSalesHeaderRecordId: RecordID;
    begin
        if not IsNullGuid(CRMSalesorder.SalesOrderId) then
            if CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header", NAVSalesHeaderRecordId) then
                exit(SalesHeader.Get(NAVSalesHeaderRecordId));
    end;

    procedure CreateInNAV(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        CRMSalesorder.TestField(StateCode, CRMSalesorder.StateCode::Submitted);
        exit(CreateNAVSalesOrder(CRMSalesorder, SalesHeader));
    end;

    local procedure CreateNAVSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if IsNullGuid(CRMSalesorder.SalesOrderId) then
            exit;

        CreateSalesOrderHeader(CRMSalesorder, SalesHeader);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(SalesHeader.RecordId, CRMSalesorder.SalesOrderId);
        CreateSalesOrderNotes(CRMSalesorder, SalesHeader);
        CreateSalesOrderLines(CRMSalesorder, SalesHeader);
        ApplySalesOrderDiscounts(CRMSalesorder, SalesHeader);
        // Flag sales order has been submitted to NAV.
        SetLastBackOfficeSubmit(CRMSalesorder, Today);
        SendTraceTag('000083B', CrmTelemetryCategoryTok, VERBOSITY::Normal,
          StrSubstNo(SuccessfullyCoupledSalesOrderTelemetryMsg, CRMProductName.SHORT), DATACLASSIFICATION::SystemMetadata);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnBeforeDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure ClearLastBackOfficeSubmitOnSalesHeaderDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if CRMIntegrationManagement.IsCRMIntegrationEnabled then
            if CRMIntegrationRecord.FindIDFromRecordID(Rec.RecordId, CRMSalesorder.SalesOrderId) then begin
                if not CRMIntegrationManagement.IsWorkingConnection then
                    exit;
                if CRMSalesorder.Find then
                    if CRMSalesOrder.StateCode = CRMSalesOrder.StateCode::Submitted then
                        SetLastBackOfficeSubmit(CRMSalesorder, 0D);
            end;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnBeforeDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RemoveCouplingToCRMSalesOrderOnSalesHeaderDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // RunTrigger is expected to be false when deleting Sales Header after posting.
        // In this case, we should not change CRM Salesorder state here.
        if not RunTrigger then
            exit;

        if not (Rec."Document Type" = Rec."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if not CRMIntegrationRecord.FindIDFromRecordID(Rec.RecordId, CRMSalesorder.SalesOrderId) then
            exit;

        if CRMIntegrationRecord.RemoveCouplingToRecord(Rec.RecordId) then;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assemble-to-Order Link", 'OnBeforeSalesLineCheckAvailShowWarning', '', false, false)]
    local procedure OnBeforeSalesLineCheckAvailShowWarning(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    var
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        if not CRMIntegrationRecord.IsRecordCoupled(SalesHeader.RecordId()) then
            exit;

        IsHandled := true;
    end;

    local procedure CreateSalesOrderHeader(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CDSIntTableSubscriber: Codeunit "CDS Int. Table. Subscriber";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Validate(Status, SalesHeader.Status::Open);
        SalesHeader.InitInsert;
        GetCoupledCustomer(CRMSalesorder, Customer);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Your Reference", CopyStr(CRMSalesorder.OrderNumber, 1, MaxStrLen(SalesHeader."Your Reference")));
        SalesHeader.Validate("Currency Code", CRMSynchHelper.GetNavCurrencyCode(CRMSalesorder.TransactionCurrencyId));
        SalesHeader.Validate("Requested Delivery Date", CRMSalesorder.RequestDeliveryBy);
        CopyBillToInformationIfNotEmpty(CRMSalesorder, SalesHeader);
        CopyShipToInformationIfNotEmpty(CRMSalesorder, SalesHeader);
        CopyCRMOptionFields(CRMSalesorder, SalesHeader);
        SalesHeader.Validate("Payment Discount %", CRMSalesorder.DiscountPercentage);
        SalesHeader.Validate("External Document No.", CopyStr(CRMSalesorder.Name, 1, MaxStrLen(SalesHeader."External Document No.")));
        SalesHeader.Insert();

        // set company id and owner on CDS salesorder
        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            SourceRecordRef.GetTable(SalesHeader);
            DestinationRecordRef.GetTable(CRMSalesorder);
            CDSIntTableSubscriber.SetCompanyId(DestinationRecordRef);
            CDSIntTableSubscriber.SetOwnerId(SourceRecordRef, DestinationRecordRef);
            DestinationRecordRef.Modify();
        end;
    end;

    local procedure CreateSalesOrderNotes(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMAnnotation: Record "CRM Annotation";
        RecordLink: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
    begin
        CRMAnnotation.SetRange(ObjectId, CRMSalesorder.SalesOrderId);
        CRMAnnotation.SetRange(IsDocument, true);
        CRMAnnotation.SetRange(FileSize, 0);
        if CRMAnnotation.FindSet then
            repeat
                CreateNote(SalesHeader, CRMAnnotation, RecordLink);
                CRMAnnotationCoupling.CoupleRecordLinkToCRMAnnotation(RecordLink, CRMAnnotation);
            until CRMAnnotation.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateNote(SalesHeader: Record "Sales Header"; CRMAnnotation: Record "CRM Annotation"; var RecordLink: Record "Record Link")
    var
        RecordLinkManagement: Codeunit "Record Link Management";
        InStream: InStream;
        AnnotationText: Text;
    begin
        Clear(RecordLink);
        RecordLink."Record ID" := SalesHeader.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CRMAnnotation.Subject;
        CRMAnnotation.CalcFields(NoteText);
        CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
        InStream.Read(AnnotationText);
        RecordLinkManagement.WriteNote(RecordLink, AnnotationText);
        RecordLink.Created := CRMAnnotation.CreatedOn;
        RecordLink.Company := CompanyName;
        RecordLink.Insert();
    end;

    local procedure CreateSalesOrderLines(CRMSalesorder: Record "CRM Salesorder"; SalesHeader: Record "Sales Header")
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
    begin
        // If any of the products on the lines are not found in NAV, err
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId); // Get all sales order lines

        if CRMSalesorderdetail.FindSet then begin
            repeat
                InitializeSalesOrderLine(CRMSalesorderdetail, SalesHeader, SalesLine);
                SalesLine.Insert();
                if SalesLine."Qty. to Assemble to Order" <> 0 then
                    SalesLine.Validate("Qty. to Assemble to Order");
            until CRMSalesorderdetail.Next = 0;
        end else begin
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
        end;

        SalesLine.InsertFreightLine(CRMSalesorder.FreightAmount);
    end;

    procedure CreateExtendedDescriptionOrderLines(SalesHeader: Record "Sales Header"; FullDescription: Text)
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
    procedure CRMIsCoupledToValidRecord(CRMSalesorder: Record "CRM Salesorder"; NAVTableID: Integer): Boolean
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        exit(CRMIntegrationManagement.IsCRMIntegrationEnabled and
          CRMCouplingManagement.IsRecordCoupledToNAV(CRMSalesorder.SalesOrderId, NAVTableID) and
          CoupledSalesHeaderExists(CRMSalesorder));
    end;

    procedure GetCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder"; YourReference: Text[35]): Boolean
    begin
        CRMSalesorder.SetRange(OrderNumber, YourReference);
        exit(CRMSalesorder.FindFirst)
    end;

    procedure GetCoupledCRMSalesorder(SalesHeader: Record "Sales Header"; var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CoupledCRMId: Guid;
    begin
        if SalesHeader.IsEmpty then
            Error(NotCoupledSalesHeaderErr, SalesHeader."No.", CRMProductName.SHORT);

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CoupledCRMId) then
            Error(NotCoupledSalesHeaderErr, SalesHeader."No.", CRMProductName.SHORT);

        if CRMSalesorder.Get(CoupledCRMId) then
            exit;

        // If we reached this point, a zombie coupling exists but the sales order most probably was deleted manually by the user.
        CRMIntegrationRecord.RemoveCouplingToCRMID(CoupledCRMId, DATABASE::"Sales Header");
        Error(ZombieCouplingErr, PRODUCTNAME.Short, CRMProductName.SHORT);
    end;

    procedure GetCoupledCustomer(CRMSalesorder: Record "CRM Salesorder"; var Customer: Record Customer): Boolean
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVCustomerRecordId: RecordID;
        CRMAccountId: Guid;
    begin
        if IsNullGuid(CRMSalesorder.CustomerId) then
            Error(NoCustomerErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorder.Description, CRMProductName.SHORT);

        // Get the ID of the CRM Account associated to the sales order. Works for both CustomerType(s): account, contact
        if not GetCRMAccountOfCRMSalesOrder(CRMSalesorder, CRMAccount) then
            Error(NoCRMAccountForOrderErr, CRMSalesorder.Name, CRMSalesorder.CustomerIdType, CRMSalesorder.CustomerId, CRMProductName.SHORT);
        CRMAccountId := CRMAccount.AccountId;

        if not CRMIntegrationRecord.FindRecordIDFromID(CRMAccountId, DATABASE::Customer, NAVCustomerRecordId) then
            Error(NotCoupledCustomerErr, CannotCreateSalesOrderInNAVTxt, CRMAccount.Name, CRMProductName.SHORT);

        exit(Customer.Get(NAVCustomerRecordId));
    end;

    procedure GetCoupledSalesHeader(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVSalesHeaderRecordId: RecordID;
    begin
        if IsNullGuid(CRMSalesorder.SalesOrderId) then
            Error(NotCoupledCRMSalesOrderErr, CRMSalesorder.OrderNumber, CRMProductName.SHORT);

        // Attempt to find the coupled sales header
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header", NAVSalesHeaderRecordId) then
            Error(NotCoupledCRMSalesOrderErr, CRMSalesorder.OrderNumber, CRMProductName.SHORT);

        if SalesHeader.Get(NAVSalesHeaderRecordId) then
            exit(true);

        // If we reached this point, a zombie coupling exists but the sales order most probably was deleted manually by the user.
        CRMIntegrationRecord.RemoveCouplingToCRMID(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header");
        Error(ZombieCouplingErr, PRODUCTNAME.Short, CRMProductName.SHORT);
    end;

    procedure GetCRMAccountOfCRMSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var CRMAccount: Record "CRM Account"): Boolean
    var
        CRMContact: Record "CRM Contact";
    begin
        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::account then
            exit(CRMAccount.Get(CRMSalesorder.CustomerId));

        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::contact then
            if CRMContact.Get(CRMSalesorder.CustomerId) then
                exit(CRMAccount.Get(CRMContact.ParentCustomerId));
        exit(false);
    end;

    procedure GetCRMContactOfCRMSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var CRMContact: Record "CRM Contact"): Boolean
    begin
        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::contact then
            exit(CRMContact.Get(CRMSalesorder.CustomerId));
    end;

    local procedure InitNewSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LastSalesLineNo := LastSalesLineNo + 10000;
        SalesLine.Validate("Line No.", LastSalesLineNo);
    end;

    local procedure InitializeSalesOrderLine(CRMSalesorderdetail: Record "CRM Salesorderdetail"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CRMProduct: Record "CRM Product";
        InStream: InStream;
        CRMSalesOrderLineDescription: Text;
    begin
        InitNewSalesLine(SalesHeader, SalesLine);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then
            InitializeWriteInOrderLine(SalesLine)
        else begin
            CRMProduct.Get(CRMSalesorderdetail.ProductId);
            CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
            case CRMProduct.ProductTypeCode of
                CRMProduct.ProductTypeCode::SalesInventory:
                    InitializeSalesOrderLineFromItem(CRMProduct, SalesLine);
                CRMProduct.ProductTypeCode::Services:
                    InitializeSalesOrderLineFromResource(CRMProduct, SalesLine);
                else
                    Error(UnexpectedProductTypeErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
            end;
        end;

        CRMSalesorderdetail.CalcFields(Description);
        CRMSalesorderdetail.Description.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(CRMSalesOrderLineDescription);

        if CRMSalesOrderLineDescription = '' then
            CRMSalesOrderLineDescription := CRMSalesorderdetail.ProductDescription;
        SetLineDescription(SalesHeader, SalesLine, CRMSalesOrderLineDescription);

        SalesLine.Validate(Quantity, CRMSalesorderdetail.Quantity);
        SalesLine.Validate("Unit Price", CRMSalesorderdetail.PricePerUnit);
        SalesLine.Validate(Amount, CRMSalesorderdetail.BaseAmount);
        SalesLine.Validate(
          "Line Discount Amount",
          CRMSalesorderdetail.Quantity * CRMSalesorderdetail.VolumeDiscountAmount +
          CRMSalesorderdetail.ManualDiscountAmount);
    end;

    local procedure InitializeSalesOrderLineFromItem(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Item: Record Item;
        NAVItemRecordID: RecordID;
    begin
        // Attempt to find the coupled item
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Item, NAVItemRecordID) then
            Error(NotCoupledCRMProductErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.Name, CRMProductName.SHORT);

        if not Item.Get(NAVItemRecordID) then
            Error(ItemDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
    end;

    local procedure InitializeSalesOrderLineFromResource(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Resource: Record Resource;
        NAVResourceRecordID: RecordID;
    begin
        // Attempt to find the coupled resource
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Resource, NAVResourceRecordID) then
            Error(NotCoupledCRMResourceErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.Name, CRMProductName.SHORT);

        if not Resource.Get(NAVResourceRecordID) then
            Error(ResourceDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Resource);
        SalesLine.Validate("No.", Resource."No.");
    end;

    local procedure InitializeWriteInOrderLine(var SalesLine: Record "Sales Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
    begin
        SalesSetup.Get();
        if SalesSetup."Write-in Product No." = '' then begin
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            SendTraceTag('000083C', CrmTelemetryCategoryTok, VERBOSITY::Normal,
              StrSubstNo(MisingWriteInProductTelemetryMsg, CRMProductName.SHORT), DATACLASSIFICATION::SystemMetadata);
            Error(MissingWriteInProductNoErr, CRMProductName.SHORT, SalesLine."Document Type", SalesHeader."Your Reference");
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

    local procedure SetLastBackOfficeSubmit(var CRMSalesorder: Record "CRM Salesorder"; NewDate: Date)
    begin
        if CRMSalesorder.LastBackofficeSubmit <> NewDate then begin
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Active;
            CRMSalesorder.Modify(true);
            CRMSalesorder.LastBackofficeSubmit := NewDate;
            CRMSalesorder.Modify(true);
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
            CRMSalesorder.Modify(true);
        end;
    end;
}

