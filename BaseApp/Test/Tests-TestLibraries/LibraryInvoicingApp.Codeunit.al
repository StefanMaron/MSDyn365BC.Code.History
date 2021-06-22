codeunit 132220 "Library - Invoicing App"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        EmailProvider: Option "Office 365",Other;

    [Scope('OnPrem')]
    procedure CreateInvoice(): Code[20]
    begin
        exit(CreateInvoiceWithItemPriceExclTax(LibraryRandom.RandDec(100, 2)));
    end;

    [Scope('OnPrem')]
    procedure CreateInvoiceWithItemPriceExclTax(ItemPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365InvoiceList: TestPage "BC O365 Invoice List";
    begin
        BCO365SalesInvoice.Trap;
        BCO365InvoiceList.OpenEdit;
        BCO365InvoiceList._NEW_TEMP_.Invoke;
        BCO365SalesInvoice."Sell-to Customer Name".Value(CreateCustomerWithEmail);

        BCO365SalesInvoice.Lines.Description.Value(CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(
          ItemPrice + ItemPrice * FindVATPercentage(BCO365SalesInvoice.Lines.VATProductPostingGroupDescription.Value));

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesInvoice."Sell-to Customer Name".Value);
        SalesHeader.FindFirst;

        BCO365SalesInvoice.Close;
        exit(SalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer() CustomerName: Text[50]
    var
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := LibraryUtility.GenerateGUID;
        BCO365SalesCustomerCard.Name.Value(CustomerName);
        BCO365SalesCustomerCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithEmail() CustomerName: Text[50]
    var
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := LibraryUtility.GenerateGUID;
        BCO365SalesCustomerCard.Name.Value(CustomerName);
        BCO365SalesCustomerCard."E-Mail".Value('invoicing@microsoft.com');
        BCO365SalesCustomerCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateBlockedCustomer(var Customer: Record Customer)
    var
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        CustomerName: Text;
    begin
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := LibraryUtility.GenerateGUID;
        BCO365SalesCustomerCard.Name.Value(CustomerName);
        BCO365SalesCustomerCard.Close;
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst;
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithAddress() CustomerName: Text[50]
    var
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        BCO365SalesCustomerCard.OpenNew;
        CustomerName := LibraryUtility.GenerateGUID;
        BCO365SalesCustomerCard.Name.Value(CustomerName);
        BCO365SalesCustomerCard.Address.Value(LibraryUtility.GenerateRandomText(50));
        BCO365SalesCustomerCard."Address 2".Value(LibraryUtility.GenerateRandomText(50));
        BCO365SalesCustomerCard.City.Value(LibraryUtility.GenerateGUID); // Cities ending with * might cause errors (e.g. text<*)
        BCO365SalesCustomerCard."Post Code".Value(LibraryUtility.GenerateRandomText(20));
        BCO365SalesCustomerCard.County.Value(LibraryUtility.GenerateRandomText(30));
        BCO365SalesCustomerCard.CountryRegionCode.Value('DK');
        BCO365SalesCustomerCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateInvoiceFromEstimate(EstimateNo: Code[20]) InvoiceNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, EstimateNo);
        BCO365SalesInvoice.Trap;
        BCO365SalesQuote.MakeToInvoice.Invoke;
        BCO365SalesInvoice.Close;

        SalesHeader.SetRange("Quote No.", EstimateNo);
        SalesHeader.FindFirst;
        InvoiceNo := SalesHeader."No.";
    end;

    [Scope('OnPrem')]
    procedure CreateItem() ItemDescription: Text[50]
    var
        O365ItemCard: TestPage "O365 Item Card";
    begin
        O365ItemCard.OpenNew;
        ItemDescription := LibraryUtility.GenerateGUID;
        O365ItemCard.Description.Value(ItemDescription);
        O365ItemCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateBcItem() ItemDescription: Text[50]
    var
        BCO365ItemCard: TestPage "BC O365 Item Card";
    begin
        BCO365ItemCard.OpenNew;
        ItemDescription := LibraryUtility.GenerateGUID;
        BCO365ItemCard.Description.Value(ItemDescription);
        BCO365ItemCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithPrice() ItemDescription: Text[50]
    var
        BCO365ItemCard: TestPage "BC O365 Item Card";
    begin
        BCO365ItemCard.OpenNew;
        BCO365ItemCard."Unit Price".Value(Format(LibraryRandom.RandDecInRange(100, 200, 2)));
        ItemDescription := LibraryUtility.GenerateGUID;
        BCO365ItemCard.Description.Value(ItemDescription);
        BCO365ItemCard.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateEstimate() EstimateNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value(CreateCustomerWithEmail);

        BCO365SalesQuote.Lines.Description.Value(CreateItem);
        BCO365SalesQuote.Lines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesQuote."Sell-to Customer Name".Value);
        SalesHeader.FindFirst;

        BCO365SalesQuote.Close;
        EstimateNo := SalesHeader."No.";
    end;

    [Scope('OnPrem')]
    procedure CreateAcceptedEstimate() AcceptedEstimate: Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        AcceptedEstimate := CreateEstimate;
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, AcceptedEstimate);
        BCO365SalesQuote."Quote Accepted".SetValue(true);
        BCO365SalesQuote.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateExpiredEstimate() ExpiredEstimate: Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        ExpiredEstimate := CreateEstimate;
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, ExpiredEstimate);
        BCO365SalesQuote."Quote Valid Until Date".SetValue(WorkDate - 10);
        BCO365SalesQuote.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateEstimateWithCustomerAndItemsInline() EstimateNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value(LibraryUtility.GenerateRandomAlphabeticText(20, 1));

        BCO365SalesQuote.Lines.Description.Value(LibraryUtility.GenerateRandomAlphabeticText(20, 1));
        BCO365SalesQuote.Lines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesQuote."Sell-to Customer Name".Value);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.FindLast;

        BCO365SalesQuote.Close;
        EstimateNo := SalesHeader."No.";
    end;

    [Scope('OnPrem')]
    procedure CreateInvoiceWithCustomerAndItemsInline(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryUtility.GenerateRandomAlphabeticText(20, 1));

        BCO365SalesInvoice.Lines.Description.Value(LibraryUtility.GenerateRandomAlphabeticText(20, 1));
        BCO365SalesInvoice.Lines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesInvoice."Sell-to Customer Name".Value);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindLast;

        BCO365SalesInvoice.Close;
        exit(SalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCountryRegion(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Validate(Code, CountryRegionCode);
        CountryRegion.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(50), 1, MaxStrLen(CountryRegion.Name)));
        CountryRegion.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentInstructions(Name: Text; PaymentInstructions: Text): Integer
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        BCO365PaymentInstrCard: TestPage "BC O365 Payment Instr. Card";
    begin
        BCO365PaymentInstrCard.OpenEdit;
        BCO365PaymentInstrCard.NameControl.Value(Name);
        BCO365PaymentInstrCard.PaymentInstructionsControl.Value(PaymentInstructions);
        BCO365PaymentInstrCard.OK.Invoke;
        O365PaymentInstructions.SetRange(Name, Name);
        O365PaymentInstructions.SetRange("Payment Instructions", PaymentInstructions);
        O365PaymentInstructions.FindFirst;
        exit(O365PaymentInstructions.Id);
    end;

    [Scope('OnPrem')]
    procedure UpdatePaymentInstructions(PaymentInstructionsId: Integer; Name: Text; PaymentInstructions: Text)
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        TestPageBCO365PaymentInstrCard: TestPage "BC O365 Payment Instr. Card";
        BCO365PaymentInstrCard: Page "BC O365 Payment Instr. Card";
    begin
        O365PaymentInstructions.Get(PaymentInstructionsId);
        TestPageBCO365PaymentInstrCard.Trap;
        BCO365PaymentInstrCard.SetPaymentInstructionsOnPage(O365PaymentInstructions);
        BCO365PaymentInstrCard.Run;
        if BCO365PaymentInstrCard.Caption = '' then; // Avoid precal bug
        TestPageBCO365PaymentInstrCard.NameControl.Value(Name);
        TestPageBCO365PaymentInstrCard.PaymentInstructionsControl.Value(PaymentInstructions);
        TestPageBCO365PaymentInstrCard.OK.Invoke;
    end;

    [Scope('OnPrem')]
    procedure AddAttachmentToSalesHeader(var SalesHeader: Record "Sales Header"; MinSizeKb: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        O365SalesDocAttachments: TestPage "O365 Sales Doc. Attachments";
        FileName: Text;
    begin
        // Initialize the incoming document attachment for invoicing
        O365SalesDocAttachments.Trap;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
            BCO365SalesInvoice.OpenEdit;
            BCO365SalesInvoice.GotoRecord(SalesHeader);
            BCO365SalesInvoice.NoOfAttachments.DrillDown;
        end else begin
            BCO365SalesQuote.OpenEdit;
            BCO365SalesQuote.GotoRecord(SalesHeader);
            BCO365SalesQuote.NoOfAttachmentsValueTxt.DrillDown;
        end;
        O365SalesDocAttachments.Close;

        SalesHeader.Find;

        FileName := FindOrCreateFileToAttach(MinSizeKb);

        // Manually upload the file
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", SalesHeader."Incoming Document Entry No.");
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := SalesHeader."Incoming Document Entry No.";
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Name := LibraryUtility.GenerateGUID;
        IncomingDocumentAttachment.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure AddAttachmentToPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; MinSizeKb: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        O365PostedSalesInvAtt: TestPage "O365 Posted Sales Inv. Att.";
        FileName: Text;
    begin
        // Initialize the incoming document attachment for invoicing
        O365PostedSalesInvAtt.Trap;
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        BCO365PostedSalesInvoice.NoOfAttachments.DrillDown;
        O365PostedSalesInvAtt.Close;

        SalesInvoiceHeader.Find;

        FileName := FindOrCreateFileToAttach(MinSizeKb);

        // Manually upload the file
        IncomingDocumentAttachment.SetRange("Document No.", SalesInvoiceHeader."No.");
        IncomingDocumentAttachment.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Document No." := SalesInvoiceHeader."No.";
        IncomingDocumentAttachment."Posting Date" := SalesInvoiceHeader."Posting Date";
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Name := LibraryUtility.GenerateGUID;
        IncomingDocumentAttachment.Modify(true);
    end;

    local procedure FindOrCreateFileToAttach(MinSizeKb: Integer) FileName: Text
    var
        NameValueBuffer: Record "Name/Value Buffer";
        FileManagement: Codeunit "File Management";
        SystemIOFile: DotNet File;
        DirectoryPath: Text;
        DummyDate: Date;
        DummyTime: Time;
        FileSize: BigInteger;
    begin
        if MinSizeKb <= 0 then begin
            FileName := FileManagement.ServerTempFileName('.pdf');
            SystemIOFile.WriteAllText(FileName, 'Microsoft! NAV! ');
            exit(FileName);
        end;

        // Finds any file to attach that is big enough
        DirectoryPath := FileManagement.CombinePath(ApplicationPath, '../../App/Demotool/Pictures/');
        FileManagement.GetServerDirectoryFilesList(NameValueBuffer, DirectoryPath);
        if NameValueBuffer.FindSet then
            repeat
                if NameValueBuffer.Name <> '' then begin
                    FileManagement.GetServerFileProperties(NameValueBuffer.Name, DummyDate, DummyTime, FileSize);
                    if (FileSize div 1024) > MinSizeKb then
                        FileName := FileManagement.CombinePath(DirectoryPath, NameValueBuffer.Name);
                end;
            until NameValueBuffer.Next = 0;

        if FileName = '' then
            Error('');
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesInvoice.OpenView;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        exit(BCO365SalesInvoice.AmountInclVAT2.AsDEcimal);
    end;

    [Scope('OnPrem')]
    procedure GetEstimateAmount(InvoiceNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        BCO365SalesQuote.OpenView;
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, InvoiceNo);
        exit(BCO365SalesQuote.AmountInclVAT2.AsDEcimal);
    end;

    [Scope('OnPrem')]
    procedure AddLineToInvoice(InvoiceNo: Code[20]; ItemDescription: Text[50]): Code[20]
    var
        DummySalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(DummySalesHeader."Document Type"::Invoice, InvoiceNo);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value := ItemDescription;
        BCO365SalesInvoice.Lines.LineQuantity.Value := Format(LibraryRandom.RandIntInRange(1, 100));
        BCO365SalesInvoice.Close;

        exit(InvoiceNo);
    end;

    [Scope('OnPrem')]
    procedure DisableC2Graph()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetupEmailTable()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if SMTPMailSetup.Get then
            SMTPMailSetup.Delete();

        SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := 'smtp.office365.com';
        SMTPMailSetup."User ID" := 'testuser@domain.com';
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup.SetPassword('TestPasssword');
        SMTPMailSetup.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetupEmail()
    var
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
        O365EmailSetupWizard: TestPage "O365 Email Setup Wizard";
    begin
        O365EmailAccountSettings.OpenEdit;
        O365EmailSetupWizard.Trap;
        O365EmailAccountSettings.AdvancedEmailSetupLbl.DrillDown;

        with O365EmailSetupWizard do begin
            "Email Provider".SetValue(EmailProvider::Other);
            ActionNext.Invoke; // Enter credentials page
            "SMTP Server".SetValue('localhost');
            "SMTP Server Port".SetValue(8081);
            "Secure Connection".SetValue(false);
            "User ID".SetValue('testuser@domain.com');
            Password.SetValue('TestPassword');
            ActionNext.Invoke; // That's it page
            ActionFinish.Invoke;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetupEmailFromBC()
    var
        BCO365Settings: TestPage "BC O365 Settings";
    begin
        BCO365Settings.OpenEdit;
        BCO365Settings.SmtpMailPage."Email Provider".SetValue(EmailProvider::Other);
        BCO365Settings.SmtpMailPage."SMTP Server".SetValue('localhost');
        BCO365Settings.SmtpMailPage."SMTP Server Port".SetValue(8081);
        BCO365Settings.SmtpMailPage."Secure Connection".SetValue(false);
        BCO365Settings.SmtpMailPage.FromAccount.SetValue('testuser@domain.com');
        BCO365Settings.SmtpMailPage.Password.SetValue('TestPassword');
        BCO365Settings.Close;
    end;

    [Scope('OnPrem')]
    procedure SendInvoice(InvoiceNo: Code[20]) PostedInvoiceNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        BCO365SalesInvoice.Post.Invoke;

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", InvoiceNo);
        if SalesInvoiceHeader.FindFirst then
            PostedInvoiceNo := SalesInvoiceHeader."No.";
    end;

    [Scope('OnPrem')]
    procedure ReSendInvoice(PostedInvoiceNo: Code[20])
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenEdit;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        O365PostedSalesInvoice.Send.Invoke;
    end;

    [Scope('OnPrem')]
    procedure SendEstimate(EstimateNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        O365SalesQuote.OpenEdit;
        O365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, EstimateNo);
        O365SalesQuote.EmailQuote.Invoke;
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceFromEstimate(EstimateNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        O365SalesQuote.OpenEdit;
        O365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, EstimateNo);
        O365SalesQuote.Post.Invoke;
        if SalesInvoiceHeader.FindLast then
            exit(SalesInvoiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure FindVATPercentage(VATProductPostingGroupDescription: Text[50]): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.SetRange(Description, VATProductPostingGroupDescription);
        VATProductPostingGroup.FindFirst;
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.FindFirst;
        exit(VATPostingSetup."VAT %" / 100);
    end;
}

