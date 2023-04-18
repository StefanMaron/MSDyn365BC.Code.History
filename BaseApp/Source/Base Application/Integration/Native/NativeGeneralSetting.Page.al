#if not CLEAN20
page 2840 "Native - General Setting"
{
    Caption = 'nativeInvoicingGeneralSettings', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Native - Gen. Settings Buffer";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(primaryKey; "Primary Key")
                {
                    ApplicationArea = All;
                    Caption = 'primaryKey', Locked = true;
                    Editable = false;
                }
                field(currencySymbol; "Currency Symbol")
                {
                    ApplicationArea = All;
                    Caption = 'currencySymbol', Locked = true;
                    ToolTip = 'Specifies the currency symbol.';
                }
                field(paypalEmailAddress; "Paypal Email Address")
                {
                    ApplicationArea = All;
                    Caption = 'paypalEmailAddress', Locked = true;
                    ToolTip = 'Specifies the PayPal email address.';

                    trigger OnValidate()
                    var
                        dnRegex: DotNet Regex;
                        dnMatch: DotNet Match;
                    begin
                        dnMatch := dnRegex.Match("Paypal Email Address", EmailValidatorRegexTxt);
                        if ("Paypal Email Address" <> '') and (not dnMatch.Success) then
                            Error(EmailInvalidErr);

                        AssertCanChangePaypalSetup();
                    end;
                }
                field(countryRegionCode; "Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'countryRegionCode', Locked = true;
                }
                field(languageId; "Language Locale ID")
                {
                    ApplicationArea = All;
                    Caption = 'languageId', Locked = true;
                }
                field(languageCode; "Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'languageCode';
                    Editable = false;
                }
                field(languageDisplayName; "Language Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'languageDisplayName';
                    Editable = false;
                }
                field(defaultTaxId; "Default Tax ID")
                {
                    ApplicationArea = All;
                    Caption = 'defaultTaxId', Locked = true;
                }
                field(defaultTaxDisplayName; "Defauilt Tax Description")
                {
                    ApplicationArea = All;
                    Caption = 'defaultTaxDisplayName', Locked = true;
                }
                field(defaultPaymentTermsId; "Default Payment Terms ID")
                {
                    ApplicationArea = All;
                    Caption = 'defaultPaymentTermsId', Locked = true;
                }
                field(defaultPaymentTermsDisplayName; "Def. Pmt. Term Description")
                {
                    ApplicationArea = All;
                    Caption = 'defaultPaymentTermsDisplayName', Locked = true;
                }
                field(defaultPaymentMethodId; "Default Payment Method ID")
                {
                    ApplicationArea = All;
                    Caption = 'defaultPaymentMethodId', Locked = true;
                }
                field(defaultPaymentMethodDisplayName; "Def. Pmt. Method Description")
                {
                    ApplicationArea = All;
                    Caption = 'defaultPaymentMethodDisplayName', Locked = true;
                }
                field(amountRoundingPrecision; "Amount Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'amountRoundingPrecision', Locked = true;
                }
                field(unitAmountRoundingPrecision; "Unit-Amount Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'unitAmountRoundingPrecision', Locked = true;
                }
                field(quantityRoundingPrecision; "Quantity Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'quantityRoundingPrecision', Locked = true;
                }
                field(taxRoundingPrecision; "VAT/Tax Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'taxRoundingPrecision', Locked = true;
                }
                field(draftInvoiceFileName; DraftInvoiceFileName)
                {
                    ApplicationArea = All;
                    Caption = 'draftInvoiceFileName', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies template of PDF file name for draft sales invoices.';
                }
                field(postedInvoiceFileName; PostedInvoiceFileName)
                {
                    ApplicationArea = All;
                    Caption = 'postedInvoiceFileName', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies template of PDF file name for posted sales invoices.';
                }
                field(quoteFileName; QuoteFileName)
                {
                    ApplicationArea = All;
                    Caption = 'quoteFileName', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies template of PDF file name for sales quotes.';
                }
                field(taxableGroupId; TaxableGroupId)
                {
                    ApplicationArea = All;
                    Caption = 'taxableGroupId', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the taxable group ID.';
                }
                field(nonTaxableGroupId; NonTaxableGroupId)
                {
                    ApplicationArea = All;
                    Caption = 'nonTaxableGroupId', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the non-taxable group ID.';
                }
                field(enableSynchronization; EnableSync)
                {
                    ApplicationArea = All;
                    Caption = 'enableSynchronization', Locked = true;
                    ToolTip = 'Specifies whether Microsoft synchronization is enabled.';
                }
                field(enableSyncCoupons; EnableSyncCoupons)
                {
                    ApplicationArea = All;
                    Caption = 'enableSyncCoupons', Locked = true;
                }
                field(updateVersion; UpdateVersion)
                {
                    ApplicationArea = All;
                    Caption = 'updateVersion', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the update version for the tenant.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    begin
        if UnbindSubscription(NativeAPILanguageHandler) then;
        Clear(NativeAPILanguageHandler);
        BindSubscription(NativeAPILanguageHandler);

        SaveRecord();
        SetFileNameTemplates();
    end;

    trigger OnOpenPage()
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not EnvInfoProxy.IsInvoicing() then begin
            Insert();
            exit;
        end;

        BindSubscription(NativeAPILanguageHandler);
        LoadRecord();
        SetCalculatedFields();
    end;

    var
        EmailValidatorRegexTxt: Label '^[A-Z0-9a-z._%+-]+@(?:[A-Za-z0-9.-]+\.)+[A-Za-z]{2,64}$', Locked = true;
        EmailInvalidErr: Label 'Email address is not valid.';
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        PostedInvoiceFileName: Text[250];
        DraftInvoiceFileName: Text[250];
        QuoteFileName: Text[250];
        DocNoPlaceholderTxt: Label '{0}', Locked = true;
        UpdateVersion: Text[250];
        TaxableGroupId: Guid;
        NonTaxableGroupId: Guid;
        UpdateTxt: Label 'Update %1 - Build %2', Locked = true;
        CannotSetUpPaypalErr: Label 'You cannot change PayPal setup here. You can change the payment service in the Business center settings.', Comment = '"Business center" refers to Office 365 Business center, a suite of Microsoft Office products targeting small business (Microsoft Invoicing is one of these products).';

    local procedure SetCalculatedFields()
    begin
        SetFileNameTemplates();
        SetTaxRelatedFields();
        SetUpdateVersion();
    end;

    local procedure SetFileNameTemplates()
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        TempSalesHeader: Record "Sales Header" temporary;
        Language: Codeunit Language;
        NativeReports: Codeunit "Native - Reports";
        DocumentMailing: Codeunit "Document-Mailing";
        CurrentLanguageID: Integer;
    begin
        CurrentLanguageID := GlobalLanguage;
        GlobalLanguage(Language.GetLanguageIdOrDefault(Language.GetUserLanguageCode()));

        Clear(PostedInvoiceFileName);
        Clear(DraftInvoiceFileName);
        Clear(QuoteFileName);

        DocumentMailing.GetAttachmentFileName(
          PostedInvoiceFileName, DocNoPlaceholderTxt,
          TempSalesInvoiceHeader.GetDocTypeTxt(), NativeReports.PostedSalesInvoiceReportId());

        TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Invoice;
        DocumentMailing.GetAttachmentFileName(
          DraftInvoiceFileName, DocNoPlaceholderTxt,
          TempSalesHeader.GetDocTypeTxt(), NativeReports.DraftSalesInvoiceReportId());

        TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Quote;
        DocumentMailing.GetAttachmentFileName(
          QuoteFileName, DocNoPlaceholderTxt,
          TempSalesHeader.GetDocTypeTxt(), NativeReports.SalesQuoteReportId());

        GlobalLanguage(CurrentLanguageID);
    end;

    local procedure SetTaxRelatedFields()
    var
        TaxableTaxGroup: Record "Tax Group";
        NonTaxableTaxGroup: Record "Tax Group";
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if NativeEDMTypes.GetTaxGroupFromTaxable(true, TaxableTaxGroup) then
            TaxableGroupId := TaxableTaxGroup.SystemId
        else
            Clear(TaxableGroupId);

        if NativeEDMTypes.GetTaxGroupFromTaxable(false, NonTaxableTaxGroup) then
            NonTaxableGroupId := NonTaxableTaxGroup.SystemId
        else
            Clear(NonTaxableGroupId);
    end;

    local procedure SetUpdateVersion()
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        UpdateVersion := StrSubstNo(UpdateTxt, ApplicationSystemConstants.BuildBranch(), ApplicationSystemConstants.ApplicationBuild());
    end;

    [ServiceEnabled]
    procedure SyncBizProfile(var ActionContext: DotNet WebServiceActionContext)
    begin
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    procedure FixTemplates(var ActionContext: DotNet WebServiceActionContext)
    var
        O365SalesInitialSetup: Codeunit "O365 Sales Initial Setup";
    begin
        O365SalesInitialSetup.EnsureConfigurationTemplatateSelectionRuleExists(DATABASE::Customer);
        O365SalesInitialSetup.EnsureConfigurationTemplatateSelectionRuleExists(DATABASE::Item);
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    procedure FixIntegrationRecordIDs(var ActionContext: DotNet WebServiceActionContext)
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.ApiSetup();
        SetActionResponse(ActionContext);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo("Primary Key"), '');
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - General Setting");
    end;

    local procedure AssertCanChangePaypalSetup()
    var
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
        MsPayIsEnabled: Boolean;
    begin
        PaypalAccountProxy.GetMsPayIsEnabled(MsPayIsEnabled);

        if MsPayIsEnabled then
            Error(CannotSetUpPaypalErr);
    end;
}
#endif
