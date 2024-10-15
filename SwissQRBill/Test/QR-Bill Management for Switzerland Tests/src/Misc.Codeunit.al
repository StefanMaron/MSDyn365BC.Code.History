codeunit 148093 "Swiss QR-Bill Test Misc"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Swiss QR-Bill]
    end;

    var
        Assert: Codeunit Assert;
        Mgt: Codeunit "Swiss QR-Bill Mgt.";
        Library: Codeunit "Swiss QR-Bill Test Library";
        IBANType: Enum "Swiss QR-Bill IBAN Type";
        ReferenceType: Enum "Swiss QR-Bill Payment Reference Type";


    [Test]
    [Scope('OnPrem')]
    procedure QRBillSetupPage_UIVisibility()
    var
        QRBillSetup: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" fields visibility and editability
        with QRBillSetup do begin
            OpenEdit();
            Assert.IsTrue("Address Type".Visible(), '');
            Assert.IsTrue(UmlautCharsEncodeMode.Visible(), '');
            Assert.IsTrue(DefaultQRBillLayout.Visible(), '');
            Assert.IsTrue(LastUsedReferenceNo.Visible(), '');
            Assert.IsTrue(QRIBAN.Visible(), '');
            Assert.IsTrue(IBAN.Visible(), '');
            Assert.IsTrue(PaymentMethods.Visible(), '');
            Assert.IsTrue(DocumentTypes.Visible(), '');

            Assert.IsTrue(PaymentJnlTemplate.Visible(), '');
            Assert.IsTrue(PaymentJnlBatch.Visible(), '');

            Assert.IsTrue(SEPANonEuroExport.Visible(), '');
            Assert.IsTrue(OpenGLSetup.Visible(), '');
            Assert.IsTrue(SEPACT.Visible(), '');
            Assert.IsTrue(SEPADD.Visible(), '');
            Assert.IsTrue(SEPACAMT.Visible(), '');

            Assert.IsTrue("Address Type".Editable(), '');
            Assert.IsTrue(UmlautCharsEncodeMode.Editable(), '');
            Assert.IsTrue(DefaultQRBillLayout.Editable(), '');
            Assert.IsFalse(LastUsedReferenceNo.Editable(), '');
            Assert.IsFalse(QRIBAN.Editable(), '');
            Assert.IsFalse(IBAN.Editable(), '');
            Assert.IsFalse(PaymentMethods.Editable(), '');
            Assert.IsFalse(DocumentTypes.Editable(), '');

            Assert.IsTrue(PaymentJnlTemplate.Editable(), '');
            Assert.IsTrue(PaymentJnlBatch.Editable(), '');

            Assert.IsFalse(SEPANonEuroExport.Editable(), '');
            Assert.IsFalse(OpenGLSetup.Editable(), '');
            Assert.IsFalse(SEPACT.Editable(), '');
            Assert.IsFalse(SEPADD.Editable(), '');
            Assert.IsFalse(SEPACAMT.Editable(), '');
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CompanyInformationMPH')]
    procedure QRBillSetupPage_DrillDown_QRIBAN()
    var
        CompanyInfo: Record "Company Information";
        QRBillSetup: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down "QR-IBAN"
        Library.UpdateCompanyQRIBAN();
        CompanyInfo.Get();

        with QRBillSetup do begin
            OpenEdit();
            QRIBAN.AssertEquals(CompanyInfo."Swiss QR-Bill IBAN");
            QRIBAN.Drilldown();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CompanyInformationMPH')]
    procedure QRBillSetupPage_DrillDown_IBAN()
    var
        CompanyInfo: Record "Company Information";
        QRBillSetup: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down "IBAN"
        CompanyInfo.Get();

        with QRBillSetup do begin
            OpenEdit();
            IBAN.AssertEquals(CompanyInfo.IBAN);
            IBAN.Drilldown();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PaymentMethodsMPH')]
    procedure QRBillSetupPage_DrillDown_PmtMethods()
    var
        QRBillSetup: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down "Payment Methods"
        with QRBillSetup do begin
            OpenEdit();
            PaymentMethods.AssertEquals(Mgt.FormatQRPaymentMethodsCount(Mgt.CalcQRPaymentMethodsCount()));
            PaymentMethods.Drilldown();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReportsMPH')]
    procedure QRBillSetupPage_DrillDown_Reports()
    var
        SetupPage: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down Document Types
        with SetupPage do begin
            OpenEdit();
            DocumentTypes.AssertEquals(Mgt.FormatEnabledReportsCount(Mgt.CalcEnabledReportsCount()));
            DocumentTypes.Drilldown();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillLayoutMPH')]
    procedure QRBillSetupPage_LookUp_DefaultLayout()
    var
        SetupPage: TestPage "Swiss QR-Bill Setup";
        QRLayout: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and look up default layout
        QRLayout := Library.CreateQRLayout(IBANType::"QR-IBAN", ReferenceType::"QR Reference", '', '');
        Library.UpdateDefaultLayout(QRLayout);

        with SetupPage do begin
            OpenEdit();
            DefaultQRBillLayout.AssertEquals(QRLayout);
            DefaultQRBillLayout.Lookup();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GLSetupMPH')]
    procedure QRBillSetupPage_DrillDown_GLSetup()
    var
        GLSetup: Record "General Ledger Setup";
        SetupPage: TestPage "Swiss QR-Bill Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down SEPA Non-Euro Export
        GLSetup.Get();
        with SetupPage do begin
            OpenEdit();
            SEPANonEuroExport.AssertEquals(GLSetup."SEPA Non-Euro Export");
            OpenGLSetup.Drilldown();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QRBillSetupPage_DrillDown_SEPACT()
    var
        SetupPage: TestPage "Swiss QR-Bill Setup";
        BankExportImportSetupPage: TestPage "Bank Export/Import Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down SEPA CT
        with SetupPage do begin
            OpenEdit();
            SEPACT.AssertEquals(True);
            BankExportImportSetupPage.Trap();
            SEPACT.Drilldown();
            BankExportImportSetupPage."Processing Codeunit ID".AssertEquals(11520);
            BankExportImportSetupPage.Close();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QRBillSetupPage_DrillDown_SEPADD()
    var
        SetupPage: TestPage "Swiss QR-Bill Setup";
        BankExportImportSetupPage: TestPage "Bank Export/Import Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down SEPA DD
        with SetupPage do begin
            OpenEdit();
            SEPADD.AssertEquals(True);
            BankExportImportSetupPage.Trap();
            SEPADD.Drilldown();
            BankExportImportSetupPage."Processing Codeunit ID".AssertEquals(11530);
            BankExportImportSetupPage.Close();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QRBillSetupPage_DrillDown_SEPACAMT()
    var
        SetupPage: TestPage "Swiss QR-Bill Setup";
        BankExportImportSetupPage: TestPage "Bank Export/Import Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Setup" assert and drill down SEPA CAMT
        with SetupPage do begin
            OpenEdit();
            SEPACAMT.AssertEquals(True);
            BankExportImportSetupPage.Trap();
            SEPACAMT.Drilldown();
            BankExportImportSetupPage."Data Exch. Def. Code".AssertEquals('SEPA CAMT 054');
            BankExportImportSetupPage.Close();
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BillingInfoMPH')]
    procedure QRBillLayouts_LookUp_BillingInfo()
    var
        QRBillLayout: Record "Swiss QR-Bill Layout";
        LayoutPage: TestPage "Swiss QR-Bill Layout";
        QRLayout: Code[20];
        BillingInfo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Swiss QR-Bill Layout" assert and look up billing information
        BillingInfo := Library.CreateFullBillingInfo();
        QRLayout := Library.CreateQRLayout(IBANType::"QR-IBAN", ReferenceType::"QR Reference", '', BillingInfo);
        Library.UpdateDefaultLayout(QRLayout);

        QRBillLayout.SetRange(Code, QRLayout);
        LayoutPage.Trap();
        Page.Run(Page::"Swiss QR-Bill Layout", QRBillLayout);
        LayoutPage.BillingFormat.AssertEquals(BillingInfo);
        LayoutPage.BillingFormat.Lookup();
        LayoutPage.Close();
    end;

    [ModalPageHandler]
    procedure QRBillLayoutMPH(var QRBillLayoutPage: TestPage "Swiss QR-Bill Layout")
    begin
    end;

    [ModalPageHandler]
    procedure BillingInfoMPH(var BillingInfoPage: TestPage "Swiss QR-Bill Billing Info")
    begin
    end;

    [ModalPageHandler]
    procedure CompanyInformationMPH(var CompanyInformation: TestPage "Company Information")
    begin
    end;

    [ModalPageHandler]
    procedure PaymentMethodsMPH(var PaymentMethods: TestPage "Payment Methods")
    begin
    end;

    [ModalPageHandler]
    procedure ReportsMPH(var ReportsPage: TestPage "Swiss QR-Bill Reports")
    begin
    end;

    [ModalPageHandler]
    procedure GLSetupMPH(var GLSetupPage: TestPage "General Ledger Setup")
    begin
    end;
}
