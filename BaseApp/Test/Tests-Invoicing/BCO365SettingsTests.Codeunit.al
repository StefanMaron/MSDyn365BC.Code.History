codeunit 138949 "BC O365 Settings Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Settings] [UI]
    end;

    var
        GlobalTempCompanyInformation: Record "Company Information" temporary;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestSMTPDefaultProviderIsOffice365()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        BCO365EmailAccountSettings: TestPage "BC O365 Email Account Settings";
    begin
        // [GIVEN] An Invoicing user with no SMTP email setup
        LibraryLowerPermissions.SetInvoiceApp;
        SMTPMailSetup.DeleteAll;

        // [WHEN] The user opens settings
        BCO365EmailAccountSettings.OpenEdit;

        // [THEN] The default email provider is O365
        Assert.AreEqual(BCO365EmailAccountSettings."Email Provider".Value, 'Office 365', 'Unexpected Email provider.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressModalPageHandler,HandleModalMySettings,ChooseBrandColorModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestBusinessInformationWeb()
    var
        CompanyInformation: Record "Company Information";
        TempField: Record "Field" temporary;
        SystemActionTriggers: Codeunit "System Action Triggers";
        CompanyInfoRecRef1: RecordRef;
        CompanyInfoRecRef2: RecordRef;
    begin
        // [GIVEN] An Invoicing user
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        // [WHEN] The user opens settings from My Settings label
        // [THEN] MySettings page is open
        SystemActionTriggers.OpenSettings;
        // Handler executed

        // [THEN] Business Information page is visible and correctly populated in MySettings page
        CompanyInformation.Get;
        OpenSettingsAndVerifyBusinessInformation(CompanyInformation);

        // [WHEN] The user edits Business Informations
        FillRandomCompanyInformation(GlobalTempCompanyInformation);
        SetBusinessInformationInSettings(GlobalTempCompanyInformation);

        // [THEN] The Business Information is updated in the table
        CompanyInformation.Get;
        CompanyInfoRecRef1.GetTable(CompanyInformation);
        CompanyInfoRecRef2.GetTable(GlobalTempCompanyInformation);
        SetTempFieldsToExclude(TempField);
        Assert.RecordsAreEqualExceptCertainFields(CompanyInfoRecRef1,CompanyInfoRecRef2,TempField,'Records are different.');

        // [THEN] The Business Information is updated in the page
        OpenSettingsAndVerifyBusinessInformation(GlobalTempCompanyInformation);
        Clear(GlobalTempCompanyInformation);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    local procedure VerifyFullAddress(CompanyInformation: Record "Company Information"; FullAddress: Text)
    var
        CountryRegion: Record "Country/Region";
    begin
        if FullAddress = '' then
            exit;

        CountryRegion.Get(CompanyInformation."Country/Region Code");

        VerifyContains(FullAddress, CompanyInformation.Address);
        VerifyContains(FullAddress, CompanyInformation."Address 2");
        VerifyContains(FullAddress, CompanyInformation.City);
        VerifyContains(FullAddress, CompanyInformation."Post Code");
        VerifyContains(FullAddress, CompanyInformation.County);
        VerifyContains(FullAddress, CountryRegion.Name);
    end;

    local procedure VerifyContains(String: Text; Substring: Text)
    begin
        if Substring = '' then
            exit;

        Assert.IsSubstring(String, Substring);
    end;

    local procedure GetBrandColorName(BrandColorCode: Code[20]): Text
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if not O365BrandColor.Get(BrandColorCode) then
            O365BrandColor.FindFirst;

        exit(O365BrandColor.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChooseBrandColorModalPageHandler(var O365BrandColors: TestPage "O365 Brand Colors")
    begin
        O365BrandColors.GotoKey(GlobalTempCompanyInformation."Brand Color Code");
        O365BrandColors.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddressModalPageHandler(var O365Address: TestPage "O365 Address")
    begin
        O365Address.Address.Value := GlobalTempCompanyInformation.Address;
        O365Address."Address 2".Value := GlobalTempCompanyInformation."Address 2";
        O365Address.CountryRegionCode.Value := GlobalTempCompanyInformation."Country/Region Code";
        O365Address.City.Value := GlobalTempCompanyInformation.City;
        O365Address."Post Code".Value := GlobalTempCompanyInformation."Post Code";
        O365Address.County.Value := GlobalTempCompanyInformation.County;
        O365Address.OK.Invoke;
    end;

    local procedure OpenSettingsAndVerifyBusinessInformation(CompanyInformation: Record "Company Information")
    var
        BCO365MySettings: TestPage "BC O365 My Settings";
    begin
        BCO365MySettings.OpenEdit;

        with BCO365MySettings.Control20 do begin
            Assert.AreEqual(BrandColorName.Value, GetBrandColorName(CompanyInformation."Brand Color Code"), 'Unexpected brand color.');
            Assert.AreEqual("E-Mail".Value, CompanyInformation."E-Mail", 'Unexpected email.');
            Assert.AreEqual("VAT Registration No.".Value, CompanyInformation."VAT Registration No.", 'Unexpected VAT registration number.');
            Assert.AreEqual(Name.Value, CompanyInformation.Name, 'Unexpected company name.');
            Assert.AreEqual("Phone No.".Value, CompanyInformation."Phone No.", 'Unexpected phone number.');
            VerifyFullAddress(CompanyInformation, FullAddress.Value);
        end;

        BCO365MySettings.Close;
    end;

    local procedure SetBusinessInformationInSettings(CompanyInformation: Record "Company Information")
    var
        BCO365MySettings: TestPage "BC O365 My Settings";
    begin
        BCO365MySettings.OpenEdit;

        with BCO365MySettings.Control20 do begin
            BrandColorName.AssistEdit;
            "E-Mail".Value(CompanyInformation."E-Mail");
            "VAT Registration No.".Value(CompanyInformation."VAT Registration No.");
            Name.Value(CompanyInformation.Name);
            "Phone No.".Value(CompanyInformation."Phone No.");
            FullAddress.AssistEdit;
        end;

        BCO365MySettings.Close;
    end;

    local procedure FillRandomCompanyInformation(var OutputCompanyInformation: Record "Company Information")
    var
        O365BrandColor: Record "O365 Brand Color";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        O365BrandColor.Init;
        O365BrandColor.Code := CopyStr(LibraryRandom.RandText(MaxStrLen(O365BrandColor.Code)),
            1, MaxStrLen(O365BrandColor.Code));
        O365BrandColor.Name := CopyStr(O365BrandColor.Code, 1, MaxStrLen(O365BrandColor.Name));
        O365BrandColor.Insert;

        CountryRegion.Init;
        CountryRegion.Code := CopyStr(LibraryRandom.RandText(MaxStrLen(CountryRegion.Code)),
            1, MaxStrLen(CountryRegion.Code));
        CountryRegion.Name := CopyStr(CountryRegion.Code, 1, MaxStrLen(CountryRegion.Name));
        CountryRegion.Insert;

        CompanyInformation.Get;
        OutputCompanyInformation.Copy(CompanyInformation);

        with OutputCompanyInformation do begin
            Validate(Name, LibraryRandom.RandText(MaxStrLen(Name)));
            Validate(Address, LibraryRandom.RandText(MaxStrLen(Address)));
            Validate("Address 2", LibraryRandom.RandText(MaxStrLen("Address 2")));
            Validate("Country/Region Code", CountryRegion.Code);
            Validate(City, LibraryRandom.RandText(MaxStrLen(City)));
            Validate("Post Code", LibraryRandom.RandText(MaxStrLen("Post Code")));
            Validate(County, LibraryRandom.RandText(MaxStrLen(County)));
            Validate("Brand Color Code", O365BrandColor.Code);
            Validate("Phone No.", Format(LibraryRandom.RandInt(10 * MaxStrLen("Phone No.") - 1)));
            Validate("E-Mail",
              CopyStr(
                LibraryRandom.RandText(MaxStrLen("E-Mail") / 2 - 1) + '@' + LibraryRandom.RandText(MaxStrLen("E-Mail") / 2 - 1),
                1, MaxStrLen("E-Mail")
                )
              );

            "VAT Registration No." := UpperCase(LibraryRandom.RandText(MaxStrLen("VAT Registration No.")));
        end;
    end;

    local procedure SetTempFieldsToExclude(var TempField: Record "Field" temporary)
    var
        DummyCompanyInformation: Record "Company Information";
    begin
        TempField.Init;
        TempField.TableNo := DATABASE::"Company Information";
        TempField."No." := DummyCompanyInformation.FieldNo("Last Modified Date Time");
        TempField.Insert;
        TempField."No." := DummyCompanyInformation.FieldNo("Picture - Last Mod. Date Time");
        TempField.Insert;
        TempField."No." := DummyCompanyInformation.FieldNo("Created DateTime");
        TempField.Insert;
        TempField."No." := DummyCompanyInformation.FieldNo(Id);
        TempField.Insert;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleModalMySettings(var BCO365MySettings: TestPage "BC O365 My Settings")
    begin
        Assert.IsTrue(BCO365MySettings.Editable, 'MySettings page for Invoicing is not editable.');
    end;
}

