codeunit 138929 "O365 HTML Templates"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [HTML Template] [Cover Letter]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        ReportSelectionsNotFoundErr: Label 'Report Selections %1 not found.';
        ValueNotFoundErr: Label ' %1 value not found.', Comment = '%1 - name of element';
        DocumentMailing: Codeunit "Document-Mailing";
        IsInitialized: Boolean;
        ValueSholdNotExistErr: Label ' %1 value should not exist.', Comment = '%1 - name of element';
        YourInvoiceTxt: Label 'Your Invoice';
        YourEstimateTxt: Label 'Your Estimate';
        EstimateMailTextTxt: Label 'As promised, here is our estimate. Please see the attached estimate for details.';
        InvoiceMailTextTxt: Label 'Thank you for your business. Your invoice is attached to this message.';
        DummyImageFormat: Option Bmp,Jpeg,Png,Tiff;
        InvalidImgFormatErr: Label 'Invalid image format.';
        InvalidReturnValueErr: Label 'Invalid return value.';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EstimateCoverLetterCompanyInfoPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Estimate cover letter body contains company information data
        Initialize;

        // [GIVEN] Prepare company info data and sales quote
        PrepareCompanyInfoScenario(SalesHeader, SalesHeader."Document Type"::Quote);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File contains Company Information data
        VerifyCompanyInfoData(HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EstimateCoverLetterDocumentPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
        MailTo: Text;
        EmailBodyText: Text;
    begin
        // [SCENARIO] Estimate cover letter body contains document data
        Initialize;

        // [GIVEN] Invoicing App permissions
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created quote
        CreateSalesDocument(SalesHeader."Document Type"::Quote, SalesHeader);
        SalesHeader.Validate("Quote Valid Until Date", SalesHeader."Due Date");
        SalesHeader.Modify;

        // [GIVEN] Mail to address
        MailTo := MockMailTo;

        // [GIVEN] Customer with the same name as on the sales header
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        EmailBodyText := DocumentMailing.GetEmailBody(SalesHeader."No.", ReportSelections.Usage::"S.Quote", Customer."No.");
        HTMLText :=
          LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MailTo, EmailBodyText));

        // [THEN] File contains document data: 'Your Estimate', customer name, quote number, valid until date and total amount
        SalesHeader.CalcFields("Amount Including VAT");
        VerifyDocumentPartData(
          HTMLText, YourEstimateTxt, SalesHeader."Sell-to Customer Name", MailTo, SalesHeader."No.",
          SalesHeader."Quote Valid Until Date", SalesHeader."Amount Including VAT", EstimateMailTextTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EstimateCoverLetterSocialsPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365SocialNetwork: Record "O365 Social Network";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Estimate cover letter body contains socials data
        Initialize;

        // [GIVEN] Prepare sales quote and set of socials
        PrepareSocialsScenario(SalesHeader, O365SocialNetwork, SalesHeader."Document Type"::Quote);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File contains created social networks data
        VerifySocialsPart(O365SocialNetwork, HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EstimateCoverLetterSocialsWithoutURL()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365SocialNetwork: Record "O365 Social Network";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Socials without URL do not go to estimate cover letter
        Initialize;

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created quote
        CreateSalesDocument(SalesHeader."Document Type"::Quote, SalesHeader);

        // [GIVEN] Set of social networks created with empty URL
        CreateSocials(O365SocialNetwork);
        O365SocialNetwork.ModifyAll(URL, '');

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File does not contain created social networks data
        VerifyNoSocialsPart(O365SocialNetwork, HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure EstimateCoverLetterSocialsWithoutImage()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365SocialNetwork: Record "O365 Social Network";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Socials without URL do not go to estimate cover letter
        Initialize;

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created quote
        CreateSalesDocument(SalesHeader."Document Type"::Quote, SalesHeader);

        // [GIVEN] Set of social networks created with no media ref (or invalid)
        CreateSocials(O365SocialNetwork);
        O365SocialNetwork.ModifyAll("Media Resources Ref", '');
        O365SocialNetwork.FindFirst;
        O365SocialNetwork."Media Resources Ref" := 'INVALID';
        O365SocialNetwork.Modify;

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File does not contain created social networks data
        VerifyNoSocialsPart(O365SocialNetwork, HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DraftInvoiceCoverLetterCompanyInfoPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Draft invoice cover letter body contains address data
        Initialize;

        // [GIVEN] Prepare company info data and sales invoice
        PrepareCompanyInfoScenario(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File contains Company Information data
        VerifyCompanyInfoData(HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DraftInvoiceCoverLetterDocumentPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        HTMLText: Text;
        MailTo: Text;
        EmailBodyText: Text;
    begin
        // [SCENARIO] Draft invoice cover letter body contains document data
        Initialize;

        // [GIVEN] Invoicing App permissions
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created sales invoice
        CreateSalesDocument(SalesHeader."Document Type"::Invoice, SalesHeader);
        // [GIVEN] Customer with the same name as on the sales header
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // [GIVEN] Mail to address
        MailTo := MockMailTo;

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Invoice Draft");
        EmailBodyText := DocumentMailing.GetEmailBody(SalesHeader."No.", ReportSelections.Usage::"S.Invoice Draft", Customer."No.");
        HTMLText :=
          LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MailTo, EmailBodyText));

        // [THEN] File contains document data: 'Your Invoice', customer name, quote number, due date and total amount
        SalesHeader.CalcFields("Amount Including VAT");
        VerifyDocumentPartData(
          HTMLText, YourInvoiceTxt, SalesHeader."Sell-to Customer Name", MailTo, SalesHeader."No.",
          SalesHeader."Due Date", SalesHeader."Amount Including VAT", InvoiceMailTextTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure DraftInvoiceCoverLetterSocialsPart()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365SocialNetwork: Record "O365 Social Network";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Draft invoice cover letter body contains socials data
        Initialize;

        // [GIVEN] Prepare sales invoice and set of socials
        PrepareSocialsScenario(SalesHeader, O365SocialNetwork, SalesHeader."Document Type"::Invoice);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Invoice Draft");
        HTMLText := LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MockMailTo, ''));

        // [THEN] File contains created social networks data
        VerifySocialsPart(O365SocialNetwork, HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SentInvoiceCoverLetterCompanyInfoPart()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Estimate cover letter body contains address data
        Initialize;

        // [GIVEN] Company Information with Name, Address, Address 2, Post Code, City, County, Country Code and Phone No.
        InitCompanyInfoData;

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Posted sales invoice
        CreatePostedSalesDocument(SalesInvoiceHeader);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Invoice");
        HTMLText :=
          LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesInvoiceHeader, MockMailTo, ''));

        // [THEN] File contains Company Information data
        VerifyCompanyInfoData(HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SentInvoiceCoverLetterDocumentPart()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        HTMLText: Text;
        MailTo: Text;
        EmailBodyText: Text;
    begin
        // [SCENARIO] Sent invoice cover letter body contains document data
        Initialize;

        // [GIVEN] Invoicing App permissions
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Posted sales invoice
        CreatePostedSalesDocument(SalesInvoiceHeader);
        // [GIVEN] Customer with the same name as on the sales header
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [GIVEN] Mail to address
        MailTo := MockMailTo;

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Invoice");
        EmailBodyText := DocumentMailing.GetEmailBody(SalesInvoiceHeader."No.", ReportSelections.Usage::"S.Invoice", Customer."No.");
        HTMLText :=
          LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesInvoiceHeader, MailTo, EmailBodyText));

        // [THEN] File contains document data: 'Your Invoice', customer name, quote number, due date and total amount
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyDocumentPartData(
          HTMLText, YourInvoiceTxt, SalesInvoiceHeader."Sell-to Customer Name", MailTo, SalesInvoiceHeader."No.",
          SalesInvoiceHeader."Due Date", SalesInvoiceHeader."Amount Including VAT", InvoiceMailTextTxt);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SentInvoiceCoverLetterSocialsPart()
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365SocialNetwork: Record "O365 Social Network";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
    begin
        // [SCENARIO] Sent invoice cover letter body contains socials data
        Initialize;

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Posted sales invoice
        CreatePostedSalesDocument(SalesInvoiceHeader);

        // [GIVEN] Set of social networks created
        CreateSocials(O365SocialNetwork);

        // [WHEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Invoice");
        HTMLText :=
          LoadHTMLFile(O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesInvoiceHeader, MockMailTo, ''));

        // [THEN] File contains created social networks data
        VerifySocialsPart(O365SocialNetwork, HTMLText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SocialsURLConverstBackSlashToSlash()
    var
        DummyO365SocialNetwork: Record "O365 Social Network";
        Url: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 214846] Backslashes used for social url converted to slashes
        Initialize;

        // [GIVEN] Socials URL https:\\facebook.com\microsoft where backslashes used instead of slashes
        Url := 'https:\\facebook.com\microsoft';

        // [WHEN] URL is being entered to the social
        DummyO365SocialNetwork.Init;
        DummyO365SocialNetwork.Validate(URL, CopyStr(Url, 1, MaxStrLen(DummyO365SocialNetwork.URL)));

        // [THEN] URL https://facebook.com/microsoft has backslashes converted to slashes
        DummyO365SocialNetwork.TestField(URL, 'https://facebook.com/microsoft');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SocialsURLWithoutPrefix()
    var
        DummyO365SocialNetwork: Record "O365 Social Network";
        Url: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215922] Missed Socials URL http prefix is added during the URL validation
        Initialize;

        // [GIVEN] Socials URL facebook.com/microsoft
        Url := 'facebook.com/microsoft';

        // [WHEN] URL is being entered to the social
        DummyO365SocialNetwork.Init;
        DummyO365SocialNetwork.Validate(URL, CopyStr(Url, 1, MaxStrLen(DummyO365SocialNetwork.URL)));

        // [THEN] URL = http://facebook.com/microsoft
        DummyO365SocialNetwork.TestField(URL, 'http://facebook.com/microsoft');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure SocialsURLWithPrefixHttp()
    var
        DummyO365SocialNetwork: Record "O365 Social Network";
        Url: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215922] Socials URL with http prefix is not changed during the URL validation
        Initialize;

        // [GIVEN] Socials URL facebook.com/microsoft
        Url := 'http://facebook.com/microsoft';

        // [WHEN] URL is being entered to the social
        DummyO365SocialNetwork.Init;
        DummyO365SocialNetwork.Validate(URL, CopyStr(Url, 1, MaxStrLen(DummyO365SocialNetwork.URL)));

        // [THEN] URL = http://facebook.com/microsoft
        DummyO365SocialNetwork.TestField(URL, 'http://facebook.com/microsoft');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_Bmp()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc makes proper string for Bmp image
        Initialize;

        // [GIVEN] TempBlob record with Bmp image
        CreateTempBLOBImage(TempBlob, DummyImageFormat::Bmp);

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns string with Bmp image format
        VerifyImageSourceFormat(HtmlImgSrc, 'Bmp');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_Jpeg()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc makes proper string for Jpeg image
        Initialize;

        // [GIVEN] TempBlob record with Jpeg image
        CreateTempBLOBImage(TempBlob, DummyImageFormat::Jpeg);

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns string with Jpeg image format
        VerifyImageSourceFormat(HtmlImgSrc, 'Jpeg');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_Png()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc makes proper string for Png image
        Initialize;

        // [GIVEN] TempBlob record with Png image
        CreateTempBLOBImage(TempBlob, DummyImageFormat::Png);

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns string with Png image format
        VerifyImageSourceFormat(HtmlImgSrc, 'Png');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_Tiff()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc makes proper string for Tiff image
        Initialize;

        // [GIVEN] TempBlob record with Tiff image
        CreateTempBLOBImage(TempBlob, DummyImageFormat::Tiff);

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns string with Tiff image format
        VerifyImageSourceFormat(HtmlImgSrc, 'Tiff');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_EmptyBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc returns empty string for empty BLOB
        Initialize;

        // [GIVEN] TempBlob record with empty blob

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns empty string
        Assert.AreEqual('', HtmlImgSrc, InvalidReturnValueErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLImageScr_NotImageBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageHelpers: Codeunit "Image Helpers";
        OutStream: OutStream;
        InStream: InStream;
        HtmlImgSrc: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARO 215330] TempBlob.GetHTMLImgSrc returns empty string for non image BLOB value
        Initialize;

        // [GIVEN] TempBlob record which contains some text
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(Format(CreateGuid));

        // [WHEN] Function TempBlob.GetHTMLImgSrc is being called
        TempBlob.CreateInStream(InStream);
        HtmlImgSrc := ImageHelpers.GetHTMLImgSrc(InStream);

        // [THEN] It returns empty string
        Assert.AreEqual('', HtmlImgSrc, InvalidReturnValueErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure ReplaceBodySentTo()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        HTMLText: Text;
        MailTo: Text;
        NewMailTo: Text;
        EmailBodyFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215925] Unit test for ReplaceBodySentTo function
        Initialize;

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created quote
        CreateSalesDocument(SalesHeader."Document Type"::Quote, SalesHeader);
        SalesHeader.Validate("Quote Valid Until Date", SalesHeader."Due Date");
        SalesHeader.Modify;

        // [GIVEN] Initial email address aaa@aaa.com
        MailTo := MockMailTo;
        // [GIVEN] New email address bbb@bbb.com
        NewMailTo := MockMailTo;

        // [GIVEN] Email body file is being created
        FindReportSelection(ReportSelections, ReportSelections.Usage::"S.Quote");
        EmailBodyFileName := O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(ReportSelections, SalesHeader, MailTo, '');

        // [WHEN] ReplaceBodySentTo function is being run to replace aaa@aaa.com by bbb@bbb.com
        O365HTMLTemplMgt.ReplaceBodyFileSendTo(EmailBodyFileName, MailTo, NewMailTo);
        HTMLText := LoadHTMLFile(EmailBodyFileName);

        // [THEN] File contains new email address bbb@bbb.com
        VerifyValueExists(HTMLText, NewMailTo, 'Email address');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure HTMLEncodedValue()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        DocumentMailing: Codeunit "Document-Mailing";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        BodyText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 216661] Local language values should be displayed correctly
        Initialize;

        // [GIVEN] Invoicing App permissions
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        // [GIVEN] Run codeunit O365 Sales Initial Setup
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [GIVEN] Created quote
        CreateSalesDocument(SalesHeader."Document Type"::Quote, SalesHeader);

        // [GIVEN] Mock French langeuage customer name
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Name := 'Ce courriel a été envoyé à';
        Customer.Modify(true);
        SalesHeader."Sell-to Customer Name" := Customer.Name;
        SalesHeader.Modify;

        // [WHEN] Email body file is being created
        BodyText := DocumentMailing.GetEmailBody(SalesHeader."No.", ReportSelections.Usage::"S.Quote", Customer."No.");

        // [THEN] File contains French language customer name
        VerifyValueExists(BodyText, Customer.Name, 'Customer name');
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        DisableStockoutWarning;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;
        BindSubscription(LibraryJobQueue);
        IsInitialized := true;
    end;

    local procedure FindReportSelection(var ReportSelections: Record "Report Selections"; Usage: Integer)
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.SetRange("Email Body Layout Type", ReportSelections."Email Body Layout Type"::"HTML Layout");
        Assert.IsTrue(
          ReportSelections.FindFirst,
          StrSubstNo(ReportSelectionsNotFoundErr, ReportSelections.GetFilters));
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init;
        CountryRegion.Validate(Code, CopyStr(GetGUIDValue(MaxStrLen(CountryRegion.Code)), 1, MaxStrLen(CountryRegion.Code)));
        CountryRegion.Validate(Name, CopyStr(GetGUIDValue(MaxStrLen(CountryRegion.Name)), 1, MaxStrLen(CountryRegion.Name)));
        CountryRegion.Insert(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateTempBLOBImage(var TempBlob: Codeunit "Temp Blob"; ImgFormat: Integer)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);

        case ImgFormat of
            DummyImageFormat::Bmp:
                Bitmap.Save(InStr, ImageFormat.Bmp);
            DummyImageFormat::Jpeg:
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            DummyImageFormat::Png:
                Bitmap.Save(InStr, ImageFormat.Png);
            DummyImageFormat::Tiff:
                Bitmap.Save(InStr, ImageFormat.Tiff);
        end;
        Bitmap.Dispose;
    end;

    local procedure CreatePostedSalesDocument(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1, 99999, 2));
        SalesLine.Modify;

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocument(DocumentType: Option; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1, 99999, 2));
        SalesLine.Modify;
    end;

    local procedure ClearSocials()
    var
        O365SocialNetwork: Record "O365 Social Network";
    begin
        O365SocialNetwork.DeleteAll;
    end;

    local procedure CreateSocials(var O365SocialNetwork: Record "O365 Social Network")
    var
        i: Integer;
    begin
        ClearSocials;

        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateSocialNetwork(O365SocialNetwork);
    end;

    local procedure CreateSocialNetwork(var O365SocialNetwork: Record "O365 Social Network")
    begin
        O365SocialNetwork.Init;
        O365SocialNetwork.Code := CopyStr(GetGUIDValue(MaxStrLen(O365SocialNetwork.Code)), 1, MaxStrLen(O365SocialNetwork.Code));
        O365SocialNetwork.Name := CopyStr(GetGUIDValue(MaxStrLen(O365SocialNetwork.Name)), 1, MaxStrLen(O365SocialNetwork.Name));
        O365SocialNetwork.URL := CopyStr(GetGUIDValue(MaxStrLen(O365SocialNetwork.URL)), 1, MaxStrLen(O365SocialNetwork.URL));
        O365SocialNetwork."Media Resources Ref" := GetNewPngMediaResourcesRef;
        O365SocialNetwork.Insert;
    end;

    local procedure GetNewPngMediaResourcesRef() MediaResourcesRef: Code[50]
    var
        TempBlob: Codeunit "Temp Blob";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        Bitmap: DotNet Bitmap;
        ImageFormat: DotNet ImageFormat;
        InStream: InStream;
    begin
        MediaResourcesRef := Format(CreateGuid);

        TempBlob.CreateInStream(InStream);
        Bitmap := Bitmap.Bitmap(100, 100);
        Bitmap.Save(InStream, ImageFormat.Png);

        MediaResourcesMgt.InsertMediaFromInstream(MediaResourcesRef, InStream);
        Bitmap.Dispose;
    end;

    local procedure DisableStockoutWarning()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesSetup do begin
            Get;
            Validate("Stockout Warning", false);
            Modify;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure DisableTaskOnBeforeJobQueueScheduleTask(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true
    end;

    local procedure GetGUIDValue(Length: Integer): Text
    begin
        exit(CopyStr(Format(CreateGuid), 1, Length));
    end;

    local procedure InitCompanyInfoData()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        CompanyInformation.Name :=
          CopyStr(GetGUIDValue(MaxStrLen(CompanyInformation.Name)), 1, MaxStrLen(CompanyInformation.Name));
        CompanyInformation.Address :=
          CopyStr(GetGUIDValue(MaxStrLen(CompanyInformation.Address)), 1, MaxStrLen(CompanyInformation.Address));
        CompanyInformation."Address 2" :=
          CopyStr(GetGUIDValue(MaxStrLen(CompanyInformation."Address 2")), 1, MaxStrLen(CompanyInformation."Address 2"));
        CompanyInformation."Post Code" :=
          CopyStr(GetGUIDValue(10), 1, MaxStrLen(CompanyInformation."Post Code"));
        CompanyInformation.City :=
          CopyStr(GetGUIDValue(10), 1, MaxStrLen(CompanyInformation.City));
        CompanyInformation.County :=
          CopyStr(GetGUIDValue(10), 1, MaxStrLen(CompanyInformation.County));
        CompanyInformation."Country/Region Code" := CreateCountryRegion;
        CompanyInformation."Phone No." :=
          CopyStr(GetGUIDValue(MaxStrLen(CompanyInformation."Phone No.")), 1, MaxStrLen(CompanyInformation."Phone No."));
        CompanyInformation.Modify;
    end;

    local procedure LoadHTMLFile(FileName: Text) HTMLText: Text
    var
        HTMLFile: File;
        InStream: InStream;
        TextLine: Text;
    begin
        HTMLFile.Open(FileName);
        HTMLFile.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.ReadText(TextLine, 1000);
            HTMLText := HTMLText + TextLine;
        end;
        HTMLFile.Close;
    end;

    local procedure MockMailTo(): Text[30]
    begin
        exit(GetGUIDValue(30));
    end;

    local procedure PrepareCompanyInfoScenario(var SalesHeader: Record "Sales Header"; DocumentType: Integer)
    begin
        InitCompanyInfoData;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");
        CreateSalesDocument(DocumentType, SalesHeader);
    end;

    local procedure PrepareSocialsScenario(var SalesHeader: Record "Sales Header"; var O365SocialNetwork: Record "O365 Social Network"; DocumentType: Integer)
    begin
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");
        CreateSalesDocument(DocumentType, SalesHeader);
        CreateSocials(O365SocialNetwork);
    end;

    local procedure VerifyValueExists(HTMLText: Text; ExpectedValue: Text; ElementName: Text)
    begin
        Assert.IsTrue(StrPos(HTMLText, ExpectedValue) <> 0, StrSubstNo(ValueNotFoundErr, ElementName));
    end;

    local procedure VerifyValueDoesNotExist(HTMLText: Text; ExpectedValue: Text; ElementName: Text)
    begin
        Assert.IsTrue(StrPos(HTMLText, ExpectedValue) = 0, StrSubstNo(ValueSholdNotExistErr, ElementName));
    end;

    local procedure VerifyCompanyInfoData(HTMLText: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        VerifyValueExists(HTMLText, CompanyInformation.Name, CompanyInformation.FieldName(Name));
        VerifyValueExists(HTMLText, CompanyInformation.Address, CompanyInformation.FieldName(Address));
        VerifyValueExists(HTMLText, CompanyInformation."Address 2", CompanyInformation.FieldName("Address 2"));
        VerifyValueExists(HTMLText, CompanyInformation.City, CompanyInformation.FieldName(City));
        VerifyValueExists(HTMLText, CompanyInformation."Post Code", CompanyInformation.FieldName("Post Code"));
        VerifyValueExists(HTMLText, CompanyInformation.County, CompanyInformation.FieldName(County));
        VerifyValueExists(HTMLText, CompanyInformation."Phone No.", CompanyInformation.FieldName("Phone No."));
    end;

    local procedure VerifyDocumentPartData(HTMLText: Text; DocumentName: Text; CustomerName: Text; MailTo: Text; DocumentNo: Text; DocumentDate: Date; TotalAmount: Decimal; MailText: Text)
    begin
        VerifyValueExists(HTMLText, DocumentName, 'Document name');
        VerifyValueExists(HTMLText, CustomerName, 'Customer Name');
        VerifyValueExists(HTMLText, MailTo, 'Mail to');
        VerifyValueExists(HTMLText, DocumentNo, 'Document number');
        VerifyValueExists(HTMLText, Format(DocumentDate), 'Document date');
        VerifyValueExists(HTMLText, Format(TotalAmount), 'Total amount');
        VerifyValueExists(HTMLText, MailText, 'Mail text');
    end;

    local procedure VerifyImageSourceFormat(ImageSoruceAsText: Text; ExpectedImageFormat: Text)
    begin
        Assert.IsFalse(StrPos(ImageSoruceAsText, ExpectedImageFormat) = 0, InvalidImgFormatErr);
    end;

    local procedure VerifySocialsPart(var O365SocialNetwork: Record "O365 Social Network"; HTMLText: Text)
    begin
        if O365SocialNetwork.FindSet then
            repeat
                VerifyValueExists(HTMLText, O365SocialNetwork.Name, O365SocialNetwork.FieldName(Name));
                VerifyValueExists(HTMLText, O365SocialNetwork.URL, O365SocialNetwork.FieldName(URL));
            until O365SocialNetwork.Next = 0;
    end;

    local procedure VerifyNoSocialsPart(var O365SocialNetwork: Record "O365 Social Network"; HTMLText: Text)
    begin
        if O365SocialNetwork.FindSet then
            repeat
                VerifyValueDoesNotExist(HTMLText, O365SocialNetwork.Name, O365SocialNetwork.FieldName(Name));
                VerifyValueDoesNotExist(HTMLText, O365SocialNetwork.URL, O365SocialNetwork.FieldName(URL));
            until O365SocialNetwork.Next = 0;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

