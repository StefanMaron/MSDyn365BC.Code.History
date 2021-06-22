table 2840 "Native - Gen. Settings Buffer"
{
    Caption = 'Native - Gen. Settings Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Currency Symbol"; Text[10])
        {
            Caption = 'Currency Symbol';
            DataClassification = SystemMetadata;
        }
        field(3; "Paypal Email Address"; Text[250])
        {
            Caption = 'Paypal Email Address';
            DataClassification = SystemMetadata;
        }
        field(4; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Language Locale ID"; Integer)
        {
            Caption = 'Language Locale ID';
            DataClassification = SystemMetadata;
        }
        field(6; "Language Code"; Text[50])
        {
            Caption = 'Language Code';
            DataClassification = SystemMetadata;
        }
        field(7; "Language Display Name"; Text[80])
        {
            Caption = 'Language Display Name';
            DataClassification = SystemMetadata;
        }
        field(50; "Default Tax ID"; Guid)
        {
            Caption = 'Default Tax ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51; "Defauilt Tax Description"; Text[100])
        {
            Caption = 'Defauilt Tax Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(52; "Default Payment Terms ID"; Guid)
        {
            Caption = 'Default Payment Terms ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(53; "Def. Pmt. Term Description"; Text[50])
        {
            Caption = 'Def. Pmt. Term Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(54; "Default Payment Method ID"; Guid)
        {
            Caption = 'Default Payment Method ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(55; "Def. Pmt. Method Description"; Text[50])
        {
            Caption = 'Def. Pmt. Method Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(56; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(57; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(58; "VAT/Tax Rounding Precision"; Decimal)
        {
            Caption = 'VAT/Tax Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(59; "Quantity Rounding Precision"; Decimal)
        {
            Caption = 'Quantity Rounding Precision';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60; EnableSync; Boolean)
        {
            Caption = 'EnableSync';
            DataClassification = SystemMetadata;
        }
        field(61; EnableSyncCoupons; Boolean)
        {
            Caption = 'EnableSyncCoupons';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordMustBeTemporaryErr: Label 'General Settings Buffer must be used as a temporary record.';
        CannotEnableCouponsSyncErr: Label 'Cannot enable coupons synchronization while Microsoft Graph synchronization is turned off.';
        CannotSetWebhookSubscriptionUserErr: Label 'Cannot set the webhook subscription user.';
        CannotGetCompanyInformationErr: Label 'Cannot get the company information.';
        SyncOnlyAllowedInSaasErr: Label 'Microsoft Graph synchronization is only allowed in SaaS.';
        SyncNotAllowedInDemoCompanyErr: Label 'Microsoft Graph synchronization is not allowed in a demo company.';
        SyncNotAllowedErr: Label 'Microsoft Graph synchronization is not allowed.';

    procedure LoadRecord()
    var
        CompanyInformation: Record "Company Information";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempNativeAPITaxSetup: Record "Native - API Tax Setup" temporary;
        MarketingSetup: Record "Marketing Setup";
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        DeleteAll();
        Clear(Rec);

        CompanyInformation.Get();
        "Country/Region Code" := CompanyInformation.GetCompanyCountryRegionCode;

        GeneralLedgerSetup.Get();
        "Currency Symbol" := GeneralLedgerSetup.GetCurrencySymbol;
        "Amount Rounding Precision" := GetNumberOfDecimals(GeneralLedgerSetup."Amount Rounding Precision");
        "Unit-Amount Rounding Precision" := GetNumberOfDecimals(GeneralLedgerSetup."Unit-Amount Rounding Precision");
        "Quantity Rounding Precision" := 5;
        // We hardcode these to 2/3 as they are like that in business center.
        if GeneralLedgerSetup.UseVat then
            "VAT/Tax Rounding Precision" := 2
        else
            "VAT/Tax Rounding Precision" := 3;

        PaypalAccountProxy.GetPaypalAccount("Paypal Email Address");

        TempNativeAPITaxSetup.LoadSetupRecords;
        TempNativeAPITaxSetup.SetRange(Default, true);
        if TempNativeAPITaxSetup.FindFirst then begin
            "Default Tax ID" := TempNativeAPITaxSetup.Id;
            "Defauilt Tax Description" := TempNativeAPITaxSetup.Description;
        end;

        GetLanguageInfo;
        GetPaymentInfo;

        if MarketingSetup.Get then begin
            EnableSync := MarketingSetup."Sync with Microsoft Graph";
            if EnableSync then begin
                O365SalesInitialSetup.Get();
                EnableSyncCoupons := O365SalesInitialSetup."Coupons Integration Enabled";
            end;
        end;

        Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SaveRecord()
    var
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
    begin
        if xRec."Currency Symbol" <> "Currency Symbol" then
            UpdateCurrencySymbol;

        if xRec."Paypal Email Address" <> "Paypal Email Address" then
            PaypalAccountProxy.SetPaypalAccount("Paypal Email Address", true);

        if xRec."Country/Region Code" <> "Country/Region Code" then
            UpdateCountryRegionCode;

        if xRec."Language Locale ID" <> "Language Locale ID" then
            UpdateLanguageId;

        if xRec.EnableSync <> EnableSync then
            UpdateSync;

        if xRec.EnableSyncCoupons <> EnableSyncCoupons then
            UpdateCouponsSync;
    end;

    local procedure UpdateCurrencySymbol()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if "Currency Symbol" <> GeneralLedgerSetup."Local Currency Symbol" then begin
            GeneralLedgerSetup.Validate("Local Currency Symbol", "Currency Symbol");
            GeneralLedgerSetup.Modify(true);
        end;
    end;

    local procedure UpdateCountryRegionCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" <> "Country/Region Code" then begin
            CompanyInformation.Validate("Country/Region Code", "Country/Region Code");
            CompanyInformation.Modify(true);
        end;
    end;

    local procedure UpdateLanguageId()
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId);
        if "Language Locale ID" <> UserPersonalization."Language ID" then begin
            UserPersonalization.Validate("Language ID", "Language Locale ID");
            UserPersonalization.Modify(true);
            GetLanguageInfo;
            GetPaymentInfo;
        end;
    end;

    local procedure UpdateSync()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        CheckSyncAllowed;

        MarketingSetup.Get();
        EnableSync := MarketingSetup."Sync with Microsoft Graph";

        if not EnableSync then
            EnableSyncCoupons := false;
    end;

    local procedure UpdateCouponsSync()
    var
        MarketingSetup: Record "Marketing Setup";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if EnableSyncCoupons then begin
            CheckSyncAllowed;
            MarketingSetup.Get();
            if not MarketingSetup."Sync with Microsoft Graph" then
                Error(CannotEnableCouponsSyncErr);
            if MarketingSetup.TrySetWebhookSubscriptionUser(UserSecurityId) then
                Error(CannotSetWebhookSubscriptionUserErr);
        end;
        O365SalesInitialSetup.Get();
        O365SalesInitialSetup."Coupons Integration Enabled" := EnableSyncCoupons;
        O365SalesInitialSetup.Modify(true);
    end;

    local procedure GetNumberOfDecimals(AmountRoundingPrecision: Decimal): Integer
    var
        "Count": Integer;
    begin
        Count := 0;

        if AmountRoundingPrecision >= 1 then
            exit(Count);

        repeat
            Count += 1;
            AmountRoundingPrecision := AmountRoundingPrecision * 10;
        until AmountRoundingPrecision >= 1;

        exit(Count);
    end;

    procedure GetPaymentInfo()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        O365SalesInitialSetup.Get();

        if PaymentTerms.Get(O365SalesInitialSetup."Default Payment Terms Code") then begin
            "Default Payment Terms ID" := PaymentTerms.Id;
            "Def. Pmt. Term Description" := PaymentTerms.GetDescriptionInCurrentLanguage;
        end;

        if PaymentMethod.Get(O365SalesInitialSetup."Default Payment Method Code") then begin
            "Default Payment Method ID" := PaymentMethod.Id;
            "Def. Pmt. Method Description" :=
              CopyStr(PaymentMethod.GetDescriptionInCurrentLanguage, 1, MaxStrLen("Def. Pmt. Method Description"));
        end;
    end;

    local procedure GetLanguageInfo()
    var
        UserPersonalization: Record "User Personalization";
        Language: Codeunit Language;
        LanguageName: Text;
    begin
        "Language Locale ID" := Language.GetDefaultApplicationLanguageId;

        if UserPersonalization.Get(UserSecurityId) then
            if UserPersonalization."Language ID" > 0 then
                "Language Locale ID" := UserPersonalization."Language ID";

        if TryGetCultureName("Language Locale ID", "Language Code") then;

        LanguageName := Language.GetWindowsLanguageName("Language Locale ID");

        if LanguageName <> '' then
            "Language Display Name" := LanguageName;
    end;

    [TryFunction]
    local procedure TryGetCultureName(CultureId: Integer; var CultureName: Text)
    var
        CultureInfo: DotNet CultureInfo;
    begin
        // <summary>
        // Retrieves the name of a culture by its id
        // </summary>
        // <remarks>This is a TryFunction</remarks>
        // <param name="CultureId">The id of the culture</param>
        // <param name="CultureName">Exit parameter that holds the name of the culture</param>

        CultureInfo := CultureInfo.CultureInfo(CultureId);
        CultureName := CultureInfo.Name;
    end;

    procedure CheckSyncAllowed()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
        WebhookManagement: Codeunit "Webhook Management";
    begin
        if WebhookManagement.IsSyncAllowed then
            exit;

        if not CompanyInformation.Get then
            Error(CannotGetCompanyInformationErr);

        if not EnvironmentInfo.IsSaaS then
            Error(SyncOnlyAllowedInSaasErr);

        if CompanyInformationMgt.IsDemoCompany then
            Error(SyncNotAllowedInDemoCompanyErr);

        Error(SyncNotAllowedErr);
    end;
}

