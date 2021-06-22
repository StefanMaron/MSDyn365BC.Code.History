codeunit 138962 "BC O365 Payment Instr. Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Payment Instruction]
    end;

    var
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        DatasetFileName: Text;
        IsInitialized: Boolean;
        DefaultPaymentTermsTxt: Label 'Please make checks payable to %1.';
        PaymentIsUsedErr: Label 'You cannot delete the Payment Instructions because at least one invoice', Comment = '%1: Document type and number';
        CannotDeleteDefaultErr: Label 'You cannot delete the default Payment Instructions.';
        DoYouWantToDeleteQst: Label 'Are you sure you want to delete the payment instructions?';

    [Test]
    [Scope('OnPrem')]
    procedure OneDefaultPaymentDetailExistsByDefault()
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
    begin
        LibraryLowerPermissions.SetInvoiceApp;
        O365PaymentInstructions.SetRange(Default, true);
        Assert.AreEqual(1, O365PaymentInstructions.Count, 'Expected exactly one default payment detail');
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultPaymentInstructionsOnPostedInvoice()
    var
        Company: Record Company;
        PostedInvoiceNo: Code[20];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A sent invoice
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [WHEN] The posted invoice is being saved to XML
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains payment Instructions
        Company.Get(CompanyName);
        VerifyPaymentInstructionsInReport(StrSubstNo(DefaultPaymentTermsTxt, Company."Display Name"));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler,BCO365PaymentInstructionsCardPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateDefaultPaymentInstructionsInSettingsSendInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365PaymentInstructions: Record "O365 Payment Instructions";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        BCO365Settings: TestPage "BC O365 Settings";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The default payment Instructions have been updated from settings
        O365PaymentInstructions.SetRange(Default, true);
        O365PaymentInstructions.FindFirst;
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(NewPaymentDetailName);
        LibraryVariableStorage.Enqueue(NewPaymentDetailDescription);
        BCO365Settings.OpenEdit;
        BCO365Settings."Payment instructions".FindFirstField(
          GetPaymentInstructionsInCurrentLanguage, O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage);
        BCO365Settings."Payment instructions".Edit.Invoke;

        // [WHEN] A draft invoice is created
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [THEN] The draft invoice references the updated default payment Instructions
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'Wrong payment detail name on draft invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] The draft invoice is sent
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);

        // [THEN] The sent invoice references the updated default payment Instructions
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        Assert.AreEqual(
          NewPaymentDetailName, BCO365PostedSalesInvoice."Payment Instructions Name".Value, 'Wrong payment detail name on draft invoice');
        BCO365PostedSalesInvoice.Close;

        // [WHEN] The posted invoice is being saved to XML
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains payment Instructions
        VerifyPaymentInstructionsInReport(NewPaymentDetailDescription);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler,BCO365PaymentInstructionsListPageHandler')]
    [Scope('OnPrem')]
    procedure UpdatePaymentInstructionsOnInvoice()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new payment Instructions have been created
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.CreatePaymentInstructions(NewPaymentDetailName, NewPaymentDetailDescription);

        // [WHEN] A draft invoice is created
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [THEN] The draft invoice references the updated default payment Instructions
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        Assert.AreNotEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value,
          'New payment detail created should not be default on the invoice');

        // [GIVEN] The newly creted payment detail is set on the invoice
        LibraryVariableStorage.Enqueue(NewPaymentDetailName);
        BCO365SalesInvoice.PaymentInstructionsName.AssistEdit;
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'New payment detail should be set on the invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] The draft invoice is sent
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);

        // [THEN] The sent invoice references the updated default payment Instructions
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        Assert.AreEqual(
          NewPaymentDetailName, BCO365PostedSalesInvoice."Payment Instructions Name".Value, 'Wrong payment detail name on draft invoice');
        BCO365PostedSalesInvoice.Close;

        // [WHEN] The posted invoice is being saved to XML
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains payment Instructions
        VerifyPaymentInstructionsInReport(NewPaymentDetailDescription);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteDefaultPaymentInstructions()
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
    begin
        LibraryLowerPermissions.SetInvoiceApp;
        O365PaymentInstructions.SetRange(Default, true);
        O365PaymentInstructions.FindFirst;
        asserterror O365PaymentInstructions.Delete(true);
        Assert.ExpectedError(CannotDeleteDefaultErr);
    end;

    [Test]
    [HandlerFunctions('BCO365PaymentInstructionsListPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteNonDefaultPaymentInstructionAssignedToInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365PaymentInstructions: Record "O365 Payment Instructions";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new payment Instructions have been created
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.CreatePaymentInstructions(NewPaymentDetailName, NewPaymentDetailDescription);

        // [GIVEN] A draft invoice with payment the new payment instructions assigned
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [GIVEN] The draft invoice references the updated default payment Instructions
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);

        // [GIVEN] The newly creted payment detail is set on the invoice
        LibraryVariableStorage.Enqueue(NewPaymentDetailName);
        BCO365SalesInvoice.PaymentInstructionsName.AssistEdit;
        BCO365SalesInvoice.Close;

        // [WHEN] The new payment instruction is deleted
        O365PaymentInstructions.SetRange(Name, NewPaymentDetailName);
        O365PaymentInstructions.FindFirst;
        asserterror O365PaymentInstructions.Delete(true);
        Assert.ExpectedError(PaymentIsUsedErr);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCO365PaymentInstructionsListPageHandler,DeletePaymentInstructionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteNonDefaultPaymentInstructionAssignedToPostedInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365PaymentInstructions: Record "O365 Payment Instructions";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new payment Instructions have been created
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.CreatePaymentInstructions(NewPaymentDetailName, NewPaymentDetailDescription);

        // [GIVEN] A posted invoice using this payment instruction
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        LibraryVariableStorage.Enqueue(NewPaymentDetailName);
        BCO365SalesInvoice.PaymentInstructionsName.AssistEdit;
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'New payment detail should be set on the invoice');
        BCO365SalesInvoice.Close;
        LibraryInvoicingApp.SendInvoice(InvoiceNo);

        // [WHEN] The new payment instruction is deleted
        // [THEN] No error occurs
        O365PaymentInstructions.SetRange(Name, NewPaymentDetailName);
        O365PaymentInstructions.FindFirst;
        O365PaymentInstructions.Delete(true);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyDefaultPaymentInstructionsAlreadyAssignedToInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365PaymentInstructions: Record "O365 Payment Instructions";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
        PaymentInstructionId: Integer;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        O365PaymentInstructions.SetRange(Default, true);
        O365PaymentInstructions.FindFirst;
        PaymentInstructionId := O365PaymentInstructions.Id;

        // [GIVEN] A draft invoice is created
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [WHEN] The default payment instruction is modified
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.UpdatePaymentInstructions(PaymentInstructionId, NewPaymentDetailName, NewPaymentDetailDescription);

        // [THEN] The invoice is updated with the new name
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'updated payment detail should be set on the invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] The invoice is posted and saved to XML
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains the updated payment Instructions
        VerifyPaymentInstructionsInReport(NewPaymentDetailDescription);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyDefaultPaymentInstructionsAlreadyAssignedToPostedInvoice()
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        PostedInvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
        OriginalPaymentDetailDescription: Text;
        PaymentInstructionId: Integer;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        O365PaymentInstructions.SetRange(Default, true);
        O365PaymentInstructions.FindFirst;
        PaymentInstructionId := O365PaymentInstructions.Id;
        OriginalPaymentDetailDescription := O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage;

        // [GIVEN] A draft invoice is created for this payment instruction
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [WHEN] The default payment instruction is modified
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.UpdatePaymentInstructions(PaymentInstructionId, NewPaymentDetailName, NewPaymentDetailDescription);

        // [WHEN] The invoice is saved to XML
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains the original payment Instructions
        VerifyPaymentInstructionsInReport(OriginalPaymentDetailDescription);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler,BCO365PaymentInstructionsListPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyNonDefaultPaymentInstructionsAssignedToInvoice()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
        PaymentInstructionId: Integer;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new payment Instructions have been created
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        PaymentInstructionId := LibraryInvoicingApp.CreatePaymentInstructions(NewPaymentDetailName, NewPaymentDetailDescription);

        // [GIVEN] A draft invoice is created for this payment instruction
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        LibraryVariableStorage.Enqueue(NewPaymentDetailName);
        BCO365SalesInvoice.PaymentInstructionsName.AssistEdit;
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'New payment detail should be set on the invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] The default payment instruction is modified
        NewPaymentDetailName := LibraryUtility.GenerateGUID;
        NewPaymentDetailDescription := LibraryUtility.GenerateGUID;
        LibraryInvoicingApp.UpdatePaymentInstructions(PaymentInstructionId, NewPaymentDetailName, NewPaymentDetailDescription);

        // [THEN] The invoice is updated with the new name
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        Assert.AreEqual(
          NewPaymentDetailName, BCO365SalesInvoice.PaymentInstructionsName.Value, 'updated payment detail should be set on the invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] The invoice is posted and saved to XML
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);
        SaveInvoiceToXML(PostedInvoiceNo);

        // [THEN] The posted invoice contains the updated payment Instructions
        VerifyPaymentInstructionsInReport(NewPaymentDetailDescription);
    end;

    local procedure Initialize()
    var
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryInvoicingApp.SetupEmailTable;

        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        BindSubscription(TestProxyNotifMgtExt);

        IsInitialized := true;
    end;

    local procedure SaveInvoiceToXML(PostedInvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesInvoiceHeader.SetRecFilter;
        Commit();
        REPORT.RunModal(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
    end;

    local procedure RecallPostedInvoiceNotification(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
    end;

    local procedure VerifyPaymentInstructionsInReport(ExpectedPaymentDetailValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempPaymentDetailXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(DatasetFileName);
        if TempXMLBuffer.FindNodesByXPath(TempPaymentDetailXMLBuffer, 'PaymentInstructions_Txt') then begin
            Assert.AreEqual(1, TempPaymentDetailXMLBuffer.Count, 'Bad number of payment Instructions found in the report');
            TempPaymentDetailXMLBuffer.FindFirst;
            Assert.AreEqual(ExpectedPaymentDetailValue, TempPaymentDetailXMLBuffer.Value, 'Wrong payment Instructions in report');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        DatasetFileName := LibraryReportDataset.GetFileName;
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, DatasetFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BCO365PaymentInstructionsCardPageHandler(var BCO365PaymentInstructionsCard: TestPage "BC O365 Payment Instr. Card")
    var
        NewPaymentDetailName: Text;
        NewPaymentDetailDescription: Text;
    begin
        NewPaymentDetailName := LibraryVariableStorage.DequeueText;
        NewPaymentDetailDescription := LibraryVariableStorage.DequeueText;

        BCO365PaymentInstructionsCard.NameControl.Value(NewPaymentDetailName);
        BCO365PaymentInstructionsCard.PaymentInstructionsControl.Value(NewPaymentDetailDescription);
        BCO365PaymentInstructionsCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BCO365PaymentInstructionsListPageHandler(var BCO365PaymentInstructionsList: TestPage "BC O365 Payment Instr. List")
    var
        PaymentDetailName: Text;
    begin
        PaymentDetailName := LibraryVariableStorage.DequeueText;
        BCO365PaymentInstructionsList.FindFirstField(NameText, PaymentDetailName);
        BCO365PaymentInstructionsList.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeletePaymentInstructionsConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(DoYouWantToDeleteQst, Question, '');
        Reply := true;
    end;
}

