#if not CLEAN20
codeunit 2800 "Native - Setup APIs"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        if not GuiAllowed then
            exit;

        // SetupApis;
        InsertNativeInvoicingWebServices(false);
        Commit();
    end;

    var
        ApiPrefixTxt: Label 'nativeInvoicing', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure SetupApis()
    var
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        NativeEDMTypes.UpdateEDMTypes();
    end;

    procedure InsertNativeInvoicingWebServices(AllTenants: Boolean)
    begin
        InsertNativeInvoicingODataWebService(PAGE::"Native - KPIs Entity", ApiPrefixTxt + 'KPIs', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Customer Entity", ApiPrefixTxt + 'Customers', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Item Entity", ApiPrefixTxt + 'Items', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Sales Inv. Entity", ApiPrefixTxt + 'SalesInvoices', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Sales Inv. Overview", ApiPrefixTxt + 'SalesInvoiceOverview', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Sales Quotes", ApiPrefixTxt + 'SalesQuotes', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Tax Area", ApiPrefixTxt + 'TaxAreas', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Tax Group Entity", ApiPrefixTxt + 'TaxGroups', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Tax Rates", ApiPrefixTxt + 'TaxRates', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Units of Measure", ApiPrefixTxt + 'UnitsOfMeasure', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Payment Terms", ApiPrefixTxt + 'PaymentTerms', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Payment Methods", ApiPrefixTxt + 'PaymentMethods', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Attachments", ApiPrefixTxt + 'Attachments', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - General Setting", ApiPrefixTxt + 'GeneralSettings', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Email Setting", ApiPrefixTxt + 'EmailSetting', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native Country/Regions Entity", ApiPrefixTxt + 'CountryRegion', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - PDFs", ApiPrefixTxt + 'PDFs', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Email Preview", ApiPrefixTxt + 'EmailPreview', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Export Invoices", ApiPrefixTxt + 'ExportInvoices', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Sales Tax Setup", ApiPrefixTxt + 'SalesTaxSetup', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - VAT Setup", ApiPrefixTxt + 'VATSetup', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Languages", ApiPrefixTxt + 'Languages', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Sync Services Setting", ApiPrefixTxt + 'SyncServicesSetting', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - QBO Sync Auth", ApiPrefixTxt + 'QBOSyncAuth', AllTenants);
        InsertNativeInvoicingODataWebService(PAGE::"Native - Contact", ApiPrefixTxt + 'Contacts', AllTenants);
    end;

    local procedure InsertNativeInvoicingODataWebService(PageNumber: Integer; ServiceName: Text; AllTenants: Boolean)
    var
        DummyWebService: Record "Web Service";
        DummyTenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        if AllTenants then
            WebServiceManagement.CreateWebService(DummyWebService."Object Type"::Page, PageNumber, ServiceName, true)
        else
            WebServiceManagement.CreateTenantWebService(DummyTenantWebService."Object Type"::Page, PageNumber, ServiceName, true);
    end;

    procedure CreatePaymentRegistrationSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        with PaymentRegistrationSetup do begin
            if Get(UserId) then
                exit;
            if Get() then begin
                "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                Insert(true);
                Commit();
                exit;
            end;
        end;
    end;

    procedure GetAPIPrefix(): Text
    begin
        exit(ApiPrefixTxt);
    end;
}
#endif
