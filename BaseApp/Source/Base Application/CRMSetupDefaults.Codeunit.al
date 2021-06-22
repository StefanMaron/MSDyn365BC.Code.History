codeunit 5334 "CRM Setup Defaults"
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryNameTok: Label ' %1 - %2 synchronization job.', Comment = '%1 = The Integration Table Name to synchronized (ex. CUSTOMER), %2 = CRM product name';
        IntegrationTablePrefixTok: Label 'Common Data Service', Comment = 'Product name', Locked = true;
        CustomStatisticsSynchJobDescTxt: Label 'Customer Statistics - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderSynchJobDescTxt: Label 'Sales Order Status - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderNotesSynchJobDescTxt: Label 'Sales Order Notes - %1 synchronization job', Comment = '%1 = CRM product name';
        CRMProductName: Codeunit "CRM Product Name";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        AutoCreateSalesOrdersTxt: Label 'Automatically create sales orders from sales orders that are submitted in %1.', Comment = '%1 = CRM product name';
        AutoProcessQuotesTxt: Label 'Automatically process sales quotes from sales quotes that are activated in %1.', Comment = '%1 = CRM product name';
        IntegrationTableMappingLbl: Label 'CRM INTEG', Locked = true;

    procedure ResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ConnectionName: Text;
        EnqueueJobQueEntries: Boolean;
    begin
        EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData;
        ConnectionName := RegisterTempConnectionIfNeeded(CRMConnectionSetup, TempCRMConnectionSetup);
        if ConnectionName <> '' then
            SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName, true);

        ResetUnitOfMeasureUoMScheduleMapping('UNIT OF MEASURE', EnqueueJobQueEntries);
        ResetItemProductMapping('ITEM-PRODUCT', EnqueueJobQueEntries);
        ResetResourceProductMapping('RESOURCE-PRODUCT', EnqueueJobQueEntries);
        ResetCustomerPriceGroupPricelevelMapping('CUSTPRCGRP-PRICE', EnqueueJobQueEntries);
        ResetSalesPriceProductPricelevelMapping('SALESPRC-PRODPRICE', EnqueueJobQueEntries);
        ResetSalesInvoiceHeaderInvoiceMapping('POSTEDSALESINV-INV', EnqueueJobQueEntries);
        ResetSalesInvoiceLineInvoiceMapping('POSTEDSALESLINE-INV');
        ResetOpportunityMapping('OPPORTUNITY');
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', EnqueueJobQueEntries);
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts");
        end;

        CDSSetupDefaults.RemoveCustomerContactLinkJobQueueEntries();
        RecreateStatisticsJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Create Sales Orders" then
            RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Process Sales Quotes" then
            RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntries);

        if CRMIntegrationManagement.IsCRMSolutionInstalled then
            ResetCRMNAVConnectionData;

        ResetDefaultCRMPricelevel(CRMConnectionSetup);
        OnAfterResetConfiguration(CRMConnectionSetup);

        if ConnectionName <> '' then
            TempCRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure ResetItemProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        IsHandled: Boolean;
    begin
        OnBeforeResetItemProductMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';
        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::SalesInventory);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Description),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Volume > Stock Volume
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Volume"),
          CRMProduct.FieldNo(StockVolume),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Gross Weight > Stock Weight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Gross Weight"),
          CRMProduct.FieldNo(StockWeight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor Item No. > Vendor part number
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor Item No."),
          CRMProduct.FieldNo(VendorPartNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Inventory > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Inventory),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Base Unit of Measure > DefaultUoMScheduleId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Base Unit of Measure"),
          CRMProduct.FieldNo(DefaultUoMScheduleId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetResourceProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        IsHandled: Boolean;
    begin
        OnBeforeResetResourceProductMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Resource, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';
        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::Services);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Name),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Capacity > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Capacity),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice",
          CRMInvoice.FieldNo(InvoiceId), CRMInvoice.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'OPPORTUNITY';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMInvoice.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Invoice", CRMInvoice.TableCaption, CRMInvoice.GetView));
            IntegrationTableMapping.Modify();
        end;

        // "No." > InvoiceNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("No."),
          CRMInvoice.FieldNo(InvoiceNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMInvoice.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMInvoice.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Salesperson Code"),
          CRMInvoice.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Currency Code"),
          CRMInvoice.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Due Date" > DueDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Due Date"),
          CRMInvoice.FieldNo(DueDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Name"),
          CRMInvoice.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address"),
          CRMInvoice.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address 2"),
          CRMInvoice.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to City"),
          CRMInvoice.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Country/Region Code"),
          CRMInvoice.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Post Code"),
          CRMInvoice.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to County"),
          CRMInvoice.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipment Date"),
          CRMInvoice.FieldNo(DateDelivered),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Name"),
          CRMInvoice.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address"),
          CRMInvoice.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address 2"),
          CRMInvoice.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to City"),
          CRMInvoice.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Country/Region Code"),
          CRMInvoice.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Post Code"),
          CRMInvoice.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to County"),
          CRMInvoice.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo(Amount),
          CRMInvoice.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Amount Including VAT"),
          CRMInvoice.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Invoice Discount Amount"),
          CRMInvoice.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipping Agent Code"),
          CRMInvoice.FieldNo(ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Payment Terms Code"),
          CRMInvoice.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetSalesInvoiceLineInvoiceMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesInvoiceLineInvoiceMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), CRMInvoicedetail.FieldNo(ModifiedOn),
          '', '', false);
        IntegrationTableMapping."Dependency Filter" := 'POSTEDSALESINV-INV';
        IntegrationTableMapping.Modify();

        // Quantity -> Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Quantity),
          CRMInvoicedetail.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Line Discount Amount" -> "Manual Discount Amount"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Line Discount Amount"),
          CRMInvoicedetail.FieldNo(ManualDiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Unit Price" > PricePerUnit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Unit Price"),
          CRMInvoicedetail.FieldNo(PricePerUnit),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // TRUE > IsPriceOverridden
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0,
          CRMInvoicedetail.FieldNo(IsPriceOverridden),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '1', true, false);

        // Amount -> BaseAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Amount),
          CRMInvoicedetail.FieldNo(BaseAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" -> ExtendedAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Amount Including VAT"),
          CRMInvoicedetail.FieldNo(ExtendedAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
    end;

    local procedure ResetSalesOrderMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesOrderMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Header", DATABASE::"CRM Salesorder",
          CRMSalesorder.FieldNo(SalesOrderId), CRMSalesorder.FieldNo(ModifiedOn),
          '', '', true);
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Header", SalesHeader.TableCaption, SalesHeader.GetView));
        IntegrationTableMapping."Dependency Filter" := 'OPPORTUNITY';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMSalesorder.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Salesorder", CRMSalesorder.TableCaption, CRMSalesorder.GetView));
            IntegrationTableMapping.Modify();
        end;

        // "No." > OrderNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("No."),
          CRMSalesorder.FieldNo(OrderNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMSalesorder.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMSalesorder.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Salesperson Code"),
          CRMSalesorder.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Currency Code"),
          CRMSalesorder.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Name"),
          CRMSalesorder.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address"),
          CRMSalesorder.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address 2"),
          CRMSalesorder.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to City"),
          CRMSalesorder.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Country/Region Code"),
          CRMSalesorder.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Post Code"),
          CRMSalesorder.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to County"),
          CRMSalesorder.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Last Shipment Date"),
          CRMSalesorder.FieldNo(DateFulfilled),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Name"),
          CRMSalesorder.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address"),
          CRMSalesorder.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address 2"),
          CRMSalesorder.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to City"),
          CRMSalesorder.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Country/Region Code"),
          CRMSalesorder.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Post Code"),
          CRMSalesorder.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to County"),
          CRMSalesorder.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo(Amount),
          CRMSalesorder.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Amount Including VAT"),
          CRMSalesorder.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Invoice Discount Amount"),
          CRMSalesorder.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Shipping Agent Code"),
          CRMSalesorder.FieldNo(ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Payment Terms Code"),
          CRMSalesorder.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Requested Delivery Date" -> RequestDeliveryBy
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Requested Delivery Date"),
          CRMSalesorder.FieldNo(RequestDeliveryBy),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesOrderMappingConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        EnqueueJobQueueEntries: Boolean;
    begin
        EnqueueJobQueueEntries := CRMConnectionSetup.DoReadCRMData;
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', EnqueueJobQueueEntries);
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts")
        end else
            DeleteSalesOrderSyncMappingAndJobQueueEntries('SALESORDER-ORDER');
    end;

    local procedure ResetCustomerPriceGroupPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetCustomerPriceGroupPricelevelMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel",
          CRMPricelevel.FieldNo(PriceLevelId), CRMPricelevel.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'CURRENCY';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMPricelevel.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Pricelevel", CRMPricelevel.TableCaption, CRMPricelevel.GetView));
            IntegrationTableMapping.Modify();
        end;

        // Code > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          CustomerPriceGroup.FieldNo(Code),
          CRMPricelevel.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure ResetSalesPriceProductPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesPrice: Record "Sales Price";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesPriceProductPricelevelMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), CRMProductpricelevel.FieldNo(ModifiedOn),
          '', '', false);

        SalesPrice.Reset();
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetFilter("Sales Code", '<>''''');
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Price", SalesPrice.TableCaption, SalesPrice.GetView));

        IntegrationTableMapping."Dependency Filter" := 'CUSTPRCGRP-PRICE|ITEM-PRODUCT';
        IntegrationTableMapping.Modify();

        // "Sales Code" > PriceLevelId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Sales Code"),
          CRMProductpricelevel.FieldNo(PriceLevelId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Currency Code"),
          CRMProductpricelevel.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // >> PricingMethodCode = CurrencyAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMProductpricelevel.FieldNo(PricingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMProductpricelevel.PricingMethodCode::CurrencyAmount), false, false);

        // "Unit Price" > Amount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Unit Price"),
          CRMProductpricelevel.FieldNo(Amount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        IsHandled: Boolean;
    begin
        OnBeforeResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule",
          CRMUomschedule.FieldNo(UoMScheduleId), CRMUomschedule.FieldNo(ModifiedOn),
          '', '', true);

        // Code > BaseUoM Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          UnitOfMeasure.FieldNo(Code),
          CRMUomschedule.FieldNo(BaseUoMName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    local procedure ResetOpportunityMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        CDSCompany: Record "CDS Company";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetOpportunityMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Opportunity, DATABASE::"CRM Opportunity",
          CRMOpportunity.FieldNo(OpportunityId), CRMOpportunity.FieldNo(ModifiedOn),
          '', '', false);
        IntegrationTableMapping."Dependency Filter" := 'CONTACT';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMOpportunity.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Opportunity", CRMOpportunity.TableCaption, CRMOpportunity.GetView));
            IntegrationTableMapping.Modify();
        end;

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo(Description),
          CRMOpportunity.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Contact No." > ParentContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Contact No."),
          CRMOpportunity.FieldNo(ParentContactId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // OwnerId = systemuser
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMOpportunity.FieldNo(OwnerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMOpportunity.OwnerIdType::systemuser), false, false);

        // Salesperson Code > OwnerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Salesperson Code"),
          CRMOpportunity.FieldNo(OwnerId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);
        SetIntegrationFieldMappingNotNull;

        // "Estimated Value (LCY)" > EstimatedValue
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Value (LCY)"),
          CRMOpportunity.FieldNo(EstimatedValue),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Estimated Closing Date" > EstimatedCloseDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Closing Date"),
          CRMOpportunity.FieldNo(EstimatedCloseDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        CRMIntegrationTableSynch.SynchOption(IntegrationTableMapping);
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertIntegrationTableMapping(IntegrationTableMapping, MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
        SynchOnlyCoupledRecords, IsHandled);

        if IsHandled then
            exit;

        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
          SynchOnlyCoupledRecords, GetDefaultDirection(TableNo), IntegrationTablePrefixTok);
    end;

    local procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IsHandled: Boolean;
    begin
        OnBeforeInsertIntegrationFieldMapping(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection, ConstValue,
          ValidateField, ValidateIntegrationTableField, IsHandled);

        if IsHandled then
            exit;

        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
          ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    procedure SetIntegrationFieldMappingClearValueOnFailedSync()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast;
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        IntegrationFieldMapping.Modify();
    end;

    procedure SetIntegrationFieldMappingNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast;
        IntegrationFieldMapping."Not Null" := true;
        IntegrationFieldMapping.Modify();
    end;

    procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            Init;
            Clear(ID); // "Job Queue - Enqueue" is to define new ID
            "Earliest Start Date/Time" := CurrentDateTime + 1000;
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId;
            "Run in User Session" := false;
            "Notify On Success" := false;
            "Maximum No. of Attempts to Run" := 2;
            "Job Queue Category Code" := IntegrationTableMappingLbl;
            Status := Status::Ready;
            "Rerun Delay (sec.)" := 30;
            Description :=
              CopyStr(
                StrSubstNo(
                  JobQueueEntryNameTok, IntegrationTableMapping.GetTempDescription, CRMProductName.SHORT), 1, MaxStrLen(Description));
            exit(CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry))
        end;
    end;

    local procedure RecreateStatisticsJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Statistics Job",
          30,
          StrSubstNo(CustomStatisticsSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Order Status Update Job",
          7,
          StrSubstNo(CustomSalesOrderSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Notes Synch Job",
          5,
          StrSubstNo(CustomSalesOrderNotesSynchJobDescTxt, CRMProductName.SHORT),
          false);
    end;

    procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
            SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
            DeleteTasks;

            InitRecurringJob(IntervalInMinutes);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Integration Synch. Job Runner";
            "Record ID to Process" := IntegrationTableMapping.RecordId;
            "Run in User Session" := false;
            Description :=
              CopyStr(StrSubstNo(JobQueueEntryNameTok, IntegrationTableMapping.Name, CRMProductName.SHORT), 1, MaxStrLen(Description));
            "Maximum No. of Attempts to Run" := 10;
            Status := Status::Ready;
            "Rerun Delay (sec.)" := 30;
            "Inactivity Timeout Period" := InactivityTimeoutPeriod;
            if ShouldRecreateJobQueueEntry then
                CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry)
            else
                Insert(true);
        end;
    end;

    procedure ResetCRMNAVConnectionData()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.SetCRMNAVConnectionUrl(GetUrl(CLIENTTYPE::Web));
        CRMIntegrationManagement.SetCRMNAVODataUrlCredentials(
          CRMIntegrationManagement.GetItemAvailabilityWebServiceURL, '', '');
    end;

    procedure RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Create Sales Orders",
          30,
          StrSubstNo(AutoCreateSalesOrdersTxt, CRMProductName.SHORT),
          false);
    end;

    procedure RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Process Sales Quotes",
          30,
          StrSubstNo(AutoProcessQuotesTxt, CRMProductName.SHORT),
          false);
    end;

    local procedure RecreateJobQueueEntry(EnqueueJobQueEntry: Boolean; CodeunitId: Integer; MinutesBetweenRun: Integer; EntryDescription: Text; StatusReady: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CodeunitId);
            DeleteTasks;

            InitRecurringJob(MinutesBetweenRun);
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CodeunitId;
            Description := CopyStr(EntryDescription, 1, MaxStrLen(Description));
            "Maximum No. of Attempts to Run" := 2;
            if StatusReady then
                Status := Status::Ready
            else begin
                Status := Status::"On Hold with Inactivity Timeout";
                "Inactivity Timeout Period" := MinutesBetweenRun;
            end;
            "Rerun Delay (sec.)" := 30;
            if EnqueueJobQueEntry then
                CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry)
            else
                Insert(true);
        end;
    end;

    procedure DeleteAutoCreateSalesOrdersJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
            DeleteTasks;
        end;
    end;

    local procedure DeleteSalesOrderSyncMappingAndJobQueueEntries(IntegrationTableMappingName: Code[20])
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Order Status Update Job");
        JobQueueEntry.DeleteTasks;
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Notes Synch Job");
        JobQueueEntry.DeleteTasks;

        if IntegrationTableMapping.Get(IntegrationTableMappingName) then begin
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
            JobQueueEntry.DeleteTasks;
            IntegrationTableMapping.Delete();
        end;
    end;

    procedure DeleteAutoProcessSalesQuotesJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Auto Process Sales Quotes");
            DeleteTasks;
        end;
    end;

    procedure GetAddPostedSalesDocumentToCRMAccountWallConfig(): Boolean
    begin
        exit(true);
    end;

    procedure GetAllowNonSecureConnections(): Boolean
    begin
        // Most OnPrem solutions uses http if running in a private domain. CRM Server only demands https if the system has been
        // configured with internet connectivity, which is not the default. NAV Should not contrain the connection to CRM if the system
        // admin has configured the CRM service to be on a private domain only.
        exit(true);
    end;

    procedure GetCRMTableNo(NAVTableID: Integer): Integer
    var
        CDSTableNo: Integer;
        handled: Boolean;
    begin
        OnGetCDSTableNo(NavTableId, CDSTableNo, handled);
        if handled then
            exit(CDSTableNo);

        case NAVTableID of
            DATABASE::Contact:
                exit(DATABASE::"CRM Contact");
            DATABASE::Currency:
                exit(DATABASE::"CRM Transactioncurrency");
            DATABASE::Customer:
                exit(DATABASE::"CRM Account");
            DATABASE::"Customer Price Group":
                exit(DATABASE::"CRM Pricelevel");
            DATABASE::Item,
          DATABASE::Resource:
                exit(DATABASE::"CRM Product");
            DATABASE::"Sales Invoice Header":
                exit(DATABASE::"CRM Invoice");
            DATABASE::"Sales Invoice Line":
                exit(DATABASE::"CRM Invoicedetail");
            DATABASE::"Sales Price":
                exit(DATABASE::"CRM Productpricelevel");
            DATABASE::"Salesperson/Purchaser":
                exit(DATABASE::"CRM Systemuser");
            DATABASE::"Unit of Measure":
                exit(DATABASE::"CRM Uomschedule");
            DATABASE::Opportunity:
                exit(DATABASE::"CRM Opportunity");
            DATABASE::"Sales Header":
                exit(DATABASE::"CRM Salesorder");
            DATABASE::"Record Link":
                exit(DATABASE::"CRM Annotation");
        end;
    end;

    procedure GetDefaultDirection(NAVTableID: Integer): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IsHandled: Boolean;
    begin
        OnBeforeGetDefaultDirection(NAVTableID, IntegrationTableMapping.Direction, IsHandled);
        if IsHandled then
            exit(IntegrationTableMapping.Direction);

        case NAVTableID of
            DATABASE::Contact,
          DATABASE::Customer,
          DATABASE::Item,
          DATABASE::Resource,
          DATABASE::Opportunity:
                exit(IntegrationTableMapping.Direction::Bidirectional);
            DATABASE::Currency,
          DATABASE::"Customer Price Group",
          DATABASE::"Sales Invoice Header",
          DATABASE::"Sales Invoice Line",
          DATABASE::"Sales Price",
          DATABASE::"Unit of Measure":
                exit(IntegrationTableMapping.Direction::ToIntegrationTable);
            DATABASE::"Payment Terms",
          DATABASE::"Shipment Method",
          DATABASE::"Shipping Agent",
          DATABASE::"Salesperson/Purchaser":
                exit(IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    procedure GetProductQuantityPrecision(): Integer
    begin
        exit(2);
    end;

    procedure GetNameFieldNo(TableID: Integer): Integer
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        FieldNo: Integer;
    begin
        OnBeforeGetNameFieldNo(TableID, FieldNo);
        if FieldNo <> 0 then
            exit(FieldNo);
        case TableID of
            DATABASE::Contact:
                exit(Contact.FieldNo(Name));
            DATABASE::"CRM Contact":
                exit(CRMContact.FieldNo(FullName));
            DATABASE::Currency:
                exit(Currency.FieldNo(Code));
            DATABASE::"CRM Transactioncurrency":
                exit(CRMTransactioncurrency.FieldNo(ISOCurrencyCode));
            DATABASE::Customer:
                exit(Customer.FieldNo(Name));
            DATABASE::"CRM Account":
                exit(CRMAccount.FieldNo(Name));
            DATABASE::"Customer Price Group":
                exit(CustomerPriceGroup.FieldNo(Code));
            DATABASE::"CRM Pricelevel":
                exit(CRMPricelevel.FieldNo(Name));
            DATABASE::Item:
                exit(Item.FieldNo("No."));
            DATABASE::Resource:
                exit(Resource.FieldNo("No."));
            DATABASE::"CRM Product":
                exit(CRMProduct.FieldNo(ProductNumber));
            DATABASE::"Salesperson/Purchaser":
                exit(SalespersonPurchaser.FieldNo(Name));
            DATABASE::"CRM Systemuser":
                exit(CRMSystemuser.FieldNo(FullName));
            DATABASE::"Unit of Measure":
                exit(UnitOfMeasure.FieldNo(Code));
            DATABASE::"CRM Uomschedule":
                exit(CRMUomschedule.FieldNo(Name));
            DATABASE::Opportunity:
                exit(Opportunity.FieldNo(Description));
            DATABASE::"CRM Opportunity":
                exit(CRMOpportunity.FieldNo(Name));
        end;
    end;

    procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, false));
    end;

    procedure GetPrioritizedMappingList(var NameValueBuffer: Record "Name/Value Buffer")
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        NextPriority: Integer;
    begin
        NextPriority := 1;

        // 1) From CRM Systemusers
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, 0, DATABASE::"CRM Systemuser");
        // 2) From Currency
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Currency, 0);
        // 3) From Unit of measure
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::"Unit of Measure", 0);
        // 4) To/From Customers/CRM Accounts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Customer, DATABASE::"CRM Account");
        // 5) To/From Contacts/CRM Contacts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Contact, DATABASE::"CRM Contact");
        // 6) From Items to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Item, DATABASE::"CRM Product");
        // 7) From Resources to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Resource, DATABASE::"CRM Product");

        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetFilter("Parent Name", '=''''');
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, NextPriority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next = 0;
    end;

    local procedure AddPrioritizedMappingsToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; TableID: Integer; IntegrationTableID: Integer)
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            Reset;
            SetRange("Delete After Synchronization", false);
            if TableID > 0 then
                SetRange("Table ID", TableID);
            if IntegrationTableID > 0 then
                SetRange("Integration Table ID", IntegrationTableID);
            SetRange("Int. Table UID Field Type", Field.Type::GUID);
            if FindSet then
                repeat
                    AddPrioritizedMappingToList(NameValueBuffer, Priority, Name);
                until Next = 0;
        end;
    end;

    local procedure AddPrioritizedMappingToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; MappingName: Code[20])
    begin
        with NameValueBuffer do begin
            SetRange(Value, MappingName);

            if not FindFirst then begin
                Init;
                ID := Priority;
                Name := Format(Priority);
                Value := MappingName;
                Insert;
                Priority := Priority + 1;
            end;

            Reset;
        end;
    end;

    procedure GetTableIDCRMEntityNameMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        AddEntityTableMapping('systemuser', DATABASE::"Salesperson/Purchaser", TempNameValueBuffer);
        AddEntityTableMapping('systemuser', DATABASE::"CRM Systemuser", TempNameValueBuffer);

        AddEntityTableMapping('account', DATABASE::Customer, TempNameValueBuffer);
        AddEntityTableMapping('account', DATABASE::"CRM Account", TempNameValueBuffer);

        AddEntityTableMapping('contact', DATABASE::Contact, TempNameValueBuffer);
        AddEntityTableMapping('contact', DATABASE::"CRM Contact", TempNameValueBuffer);

        AddEntityTableMapping('product', DATABASE::Item, TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::Resource, TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::"CRM Product", TempNameValueBuffer);

        AddEntityTableMapping('salesorder', DATABASE::"Sales Header", TempNameValueBuffer);
        AddEntityTableMapping('salesorder', DATABASE::"CRM Salesorder", TempNameValueBuffer);

        AddEntityTableMapping('invoice', DATABASE::"Sales Invoice Header", TempNameValueBuffer);
        AddEntityTableMapping('invoice', DATABASE::"CRM Invoice", TempNameValueBuffer);

        AddEntityTableMapping('opportunity', DATABASE::Opportunity, TempNameValueBuffer);
        AddEntityTableMapping('opportunity', DATABASE::"CRM Opportunity", TempNameValueBuffer);

        // Only NAV
        AddEntityTableMapping('pricelevel', DATABASE::"Customer Price Group", TempNameValueBuffer);
        AddEntityTableMapping('transactioncurrency', DATABASE::Currency, TempNameValueBuffer);
        AddEntityTableMapping('uomschedule', DATABASE::"Unit of Measure", TempNameValueBuffer);

        // Only CRM
        AddEntityTableMapping('incident', DATABASE::"CRM Incident", TempNameValueBuffer);
        AddEntityTableMapping('quote', DATABASE::"CRM Quote", TempNameValueBuffer);

        OnAddEntityTableMapping(TempNameValueBuffer);
    end;

    local procedure AddEntityTableMapping(CRMEntityTypeName: Text; TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        OnBeforeAddEntityTableMapping(CRMEntityTypeName, TableID, TempNameValueBuffer);
        with TempNameValueBuffer do begin
            Init;
            ID := Count + 1;
            Name := CopyStr(CRMEntityTypeName, 1, MaxStrLen(Name));
            Value := Format(TableID);
            Insert;
        end;
    end;

    local procedure RegisterTempConnectionIfNeeded(CRMConnectionSetup: Record "CRM Connection Setup"; var TempCRMConnectionSetup: Record "CRM Connection Setup" temporary) ConnectionName: Text
    begin
        if CRMConnectionSetup."Is User Mapping Required" then begin
            ConnectionName := Format(CreateGuid);
            TempCRMConnectionSetup.TransferFields(CRMConnectionSetup);
            TempCRMConnectionSetup."Is User Mapping Required" := false;
            TempCRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        end;
    end;

    local procedure ResetDefaultCRMPricelevel(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        CRMConnectionSetup.Find;
        Clear(CRMConnectionSetup."Default CRM Price List ID");
        CRMConnectionSetup.Modify();
    end;

    local procedure SetIntegrationTableFilterForCRMProduct(var IntegrationTableMapping: Record "Integration Table Mapping"; CRMProduct: Record "CRM Product"; ProductTypeCode: Option)
    var
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
    begin
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMProduct.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        CRMProduct.SetRange(ProductTypeCode, ProductTypeCode);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Product", CRMProduct.TableCaption, CRMProduct.GetView));
        IntegrationTableMapping.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetCustomerAccountMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSTableNo(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetItemProductMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetResourceProductMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesInvoiceHeaderInvoiceMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesInvoiceLineInvoiceMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesOrderMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetCustomerPriceGroupPricelevelMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesPriceProductPricelevelMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetUnitOfMeasureUoMScheduleMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetOpportunityMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; var MappingName: Code[20]; var TableNo: Integer; var IntegrationTableNo: Integer; var IntegrationTableUIDFieldNo: Integer; var IntegrationTableModifiedFieldNo: Integer; var TableConfigTemplateCode: Code[10]; var IntegrationTableConfigTemplateCode: Code[10]; var SynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertIntegrationFieldMapping(var IntegrationTableMappingName: Code[20]; var TableFieldNo: Integer; var IntegrationTableFieldNo: Integer; var SynchDirection: Option; var ConstValue: Text; var ValidateField: Boolean; var ValidateIntegrationTableField: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultDirection(NAVTableId: Integer; var DefaultDirection: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNameFieldNo(TableId: Integer; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddEntityTableMapping(var CRMEntityTypeName: Text; var TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
    end;
}


