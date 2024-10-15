codeunit 144202 "Tax VIES Declarations"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTax: Codeunit "Library - Tax";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        FileNotExistErr: Label 'Exported file not exist.';

    local procedure Initialize()
    var
        VIESDeclarationHeader: Record "VIES Declaration Header";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        VIESDeclarationHeader.DeleteAll();
        VATRegistrationNoFormat.DeleteAll();
        LibraryTax.CreateStatReportingSetup();
        LibraryTax.SetVIESStatementInformation();

        isInitialized := true;
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        VIESDeclarationLine: Record "VIES Declaration Line";
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        CreateNormalVIESDeclaration(VIESDeclarationHeader, Month, Year);

        // 2. Exercise
        LibraryTax.RunSuggestVIESDeclarationLines(VIESDeclarationHeader);

        // 3. Verify
        VIESDeclarationLine.SetRange("VIES Declaration No.", VIESDeclarationHeader."No.");
        VIESDeclarationLine.SetRange("VAT Registration No.", SalesHdr."VAT Registration No.");
        VIESDeclarationLine.FindFirst;
        VIESDeclarationLine.TestField("Amount (LCY)", Round(SalesLn.Amount, 1, '>'));

        // 4. Tear Down
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader);
        VIESDeclarationHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler,RequestPageVIESDeclarationTestHandler')]
    [Scope('OnPrem')]
    procedure PrintingVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        CreateAndReleaseNormalVIESDeclaration(VIESDeclarationHeader, Month, Year);

        // 2. Exercise
        LibraryTax.PrintTestVIESDeclaration(VIESDeclarationHeader);

        // 3. Verify
        CheckTestVIESDeclrationReport(VIESDeclarationHeader."No.", SalesHdr."VAT Registration No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'VIES_Declaration_Line__Amount__LCY__', Round(SalesLn.Amount, 1, '>'));

        // 4. Tear Down
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader);
        VIESDeclarationHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler')]
    [Scope('OnPrem')]
    procedure ExportingVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        FileManagement: Codeunit "File Management";
        ClientFilePath: Text;
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        CreateNormalVIESDeclaration(VIESDeclarationHeader, Month, Year);
        LibraryTax.RunSuggestVIESDeclarationLines(VIESDeclarationHeader);
        LibraryTax.ReleaseVIESDeclaration(VIESDeclarationHeader);

        // 2. Exercise
        Commit();
        ClientFilePath := LibraryTax.ExportVIESDeclaration(VIESDeclarationHeader);

        // 3. Verify
        Assert.IsTrue(FileManagement.ClientFileExists(ClientFilePath), FileNotExistErr);

        // 4. Tear Down
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader);
        VIESDeclarationHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler,ModalPageVIESDeclarationLinesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingSubsequentVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader1: Record "VIES Declaration Header";
        VIESDeclarationHeader2: Record "VIES Declaration Header";
        VIESDeclarationLine: Record "VIES Declaration Line";
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        // create normal VIES Declaration
        CreateNormalVIESDeclaration(VIESDeclarationHeader1, Month, Year);
        LibraryTax.RunSuggestVIESDeclarationLines(VIESDeclarationHeader1);
        LibraryTax.ReleaseVIESDeclaration(VIESDeclarationHeader1);

        // create corrective VIES Declaration
        CreateCorrectiveVIESDeclaration(VIESDeclarationHeader2, VIESDeclarationHeader1."No.");

        // 2. Exercise
        LibraryVariableStorage.Enqueue(SalesHdr."VAT Registration No.");
        LibraryTax.RunGetCorrectionVIESDeclarationLines(VIESDeclarationHeader2);

        // 3. Verify
        VIESDeclarationLine.SetRange("VIES Declaration No.", VIESDeclarationHeader2."No.");
        VIESDeclarationLine.SetRange("VAT Registration No.", SalesHdr."VAT Registration No.");
        VIESDeclarationLine.FindSet();
        VIESDeclarationLine.TestField("Line Type", VIESDeclarationLine."Line Type"::Cancellation);
        VIESDeclarationLine.TestField("Amount (LCY)", Round(SalesLn.Amount, 1, '>'));

        VIESDeclarationLine.Next;
        VIESDeclarationLine.TestField("Line Type", VIESDeclarationLine."Line Type"::Correction);
        VIESDeclarationLine.TestField("Amount (LCY)", Round(SalesLn.Amount, 1, '>'));

        // 4. Tear Down
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader1);
        VIESDeclarationHeader1.Delete(true);

        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader2);
        VIESDeclarationHeader2.Delete(true);
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler,RequestPageVIESDeclarationTestHandler,ModalPageVIESDeclarationLinesHandler')]
    [Scope('OnPrem')]
    procedure PrintingSubsequentVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader1: Record "VIES Declaration Header";
        VIESDeclarationHeader2: Record "VIES Declaration Header";
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        CreateAndReleaseNormalVIESDeclaration(VIESDeclarationHeader1, Month, Year);
        LibraryVariableStorage.Enqueue(SalesHdr."VAT Registration No.");
        CreateAndReleaseCorrectiveVIESDeclaration(VIESDeclarationHeader2, VIESDeclarationHeader1."No.");

        // 2. Exercise
        LibraryTax.PrintTestVIESDeclaration(VIESDeclarationHeader2);

        // 3. Verify
        CheckTestVIESDeclrationReport(VIESDeclarationHeader2."No.", SalesHdr."VAT Registration No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VIES_Declaration_Line__Line_Type_', 'Cancellation');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'VIES_Declaration_Line__Amount__LCY__', Round(SalesLn.Amount, 1, '>'));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('VIES_Declaration_Line__Line_Type_', 'Correction');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'VIES_Declaration_Line__Amount__LCY__', Round(SalesLn.Amount, 1, '>'));

        // 4. Tear Down
        VIESDeclarationHeader1.Get(VIESDeclarationHeader1."No.");
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader1);
        VIESDeclarationHeader1.Delete(true);

        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader2);
        VIESDeclarationHeader2.Delete(true);
    end;

    [Test]
    [HandlerFunctions('RequestPageSuggestVIESDeclarationLinesHandler,ModalPageVIESDeclarationLinesHandler')]
    [Scope('OnPrem')]
    procedure ExportingSubsequentVIESDeclaration()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VIESDeclarationHeader1: Record "VIES Declaration Header";
        VIESDeclarationHeader2: Record "VIES Declaration Header";
        FileManagement: Codeunit "File Management";
        ClientFilePath: Text;
        Month: Integer;
        Year: Integer;
    begin
        // 1. Setup
        Initialize;

        CreateSalesInvoiceForVIESDeclaration(SalesHdr, SalesLn);

        Month := Date2DMY(SalesHdr."Posting Date", 2);
        Year := Date2DMY(SalesHdr."Posting Date", 3);

        CreateAndReleaseNormalVIESDeclaration(VIESDeclarationHeader1, Month, Year);
        LibraryVariableStorage.Enqueue(SalesHdr."VAT Registration No.");
        CreateAndReleaseCorrectiveVIESDeclaration(VIESDeclarationHeader2, VIESDeclarationHeader1."No.");

        // 2. Exercise
        Commit();
        ClientFilePath := LibraryTax.ExportVIESDeclaration(VIESDeclarationHeader2);

        // 3. Verify
        Assert.IsTrue(FileManagement.ClientFileExists(ClientFilePath), FileNotExistErr);

        // 4. Tear Down
        VIESDeclarationHeader1.Get(VIESDeclarationHeader1."No.");
        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader1);
        VIESDeclarationHeader1.Delete(true);

        LibraryTax.ReopenVIESDeclaration(VIESDeclarationHeader2);
        VIESDeclarationHeader2.Delete(true);
    end;

    local procedure CreateAndReleaseNormalVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header"; Month: Integer; Year: Integer)
    begin
        CreateNormalVIESDeclaration(VIESDeclarationHeader, Month, Year);
        LibraryTax.RunSuggestVIESDeclarationLines(VIESDeclarationHeader);
        LibraryTax.ReleaseVIESDeclaration(VIESDeclarationHeader);
    end;

    local procedure CreateAndReleaseCorrectiveVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header"; CorrectionDocumentNo: Code[20])
    begin
        CreateCorrectiveVIESDeclaration(VIESDeclarationHeader, CorrectionDocumentNo);
        LibraryTax.RunGetCorrectionVIESDeclarationLines(VIESDeclarationHeader);
        LibraryTax.ReleaseVIESDeclaration(VIESDeclarationHeader);
    end;

    local procedure CreateCorrectiveVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header"; CorrectedDeclarationNo: Code[20])
    begin
        CreateVIESDeclaration(VIESDeclarationHeader,
          VIESDeclarationHeader."Declaration Period"::Month,
          VIESDeclarationHeader."Declaration Type"::Corrective);
        VIESDeclarationHeader.Validate("Corrected Declaration No.", CorrectedDeclarationNo);
        VIESDeclarationHeader.Modify();
    end;

    local procedure CreateNormalVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header"; PeriodNo: Integer; Year: Integer)
    begin
        CreateVIESDeclaration(VIESDeclarationHeader,
          VIESDeclarationHeader."Declaration Period"::Month,
          VIESDeclarationHeader."Declaration Type"::Normal);
        VIESDeclarationHeader.Validate("Period No.", PeriodNo);
        VIESDeclarationHeader.Validate(Year, Year);
        VIESDeclarationHeader.Modify();
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLn, SalesHdr, LineType, LineNo, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; CustomerNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice, CustomerNo, LineType, LineNo);
    end;

    local procedure CreateSalesInvoiceForVIESDeclaration(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Validate("VIES Sales", true);
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Country/Region Code", 'CZ');
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code"));
        Customer.Validate("Registration No.", CopyStr(Customer."VAT Registration No.", 3));
        Customer.Modify();

        CreateSalesInvoice(
          SalesHdr, SalesLn, Customer."No.", SalesLn.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 2));
        PostSalesDocument(SalesHdr);
    end;

    local procedure CreateVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header"; DeclarationPeriod: Option; DeclarationType: Option)
    begin
        LibraryTax.CreateVIESDeclarationHeader(VIESDeclarationHeader);
        VIESDeclarationHeader.Validate("Declaration Period", DeclarationPeriod);
        VIESDeclarationHeader.Validate("Declaration Type", DeclarationType);
        VIESDeclarationHeader.Modify();
    end;

    local procedure CheckTestVIESDeclrationReport(VIESDeclarationNo: Code[20]; VATRegistrationNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VIES_Declaration_Line_VIES_Declaration_No_', VIESDeclarationNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'VIES_Declaration_Line_VIES_Declaration_No_', VIESDeclarationNo));
        LibraryReportDataset.SetRange('VIES_Declaration_Line__VAT_Registration_No__', VATRegistrationNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'VIES_Declaration_Line__VAT_Registration_No__', VATRegistrationNo));
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageVIESDeclarationLinesHandler(var VIESDeclarationLines: TestPage "VIES Declaration Lines")
    var
        VATRegistrationNo: Text;
    begin
        VATRegistrationNo := LibraryVariableStorage.DequeueText;
        VIESDeclarationLines.FindFirstField(VIESDeclarationLines."VAT Registration No.", VATRegistrationNo);
        VIESDeclarationLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageSuggestVIESDeclarationLinesHandler(var SuggestVIESDeclarationLines: TestRequestPage "Suggest VIES Declaration Lines")
    begin
        SuggestVIESDeclarationLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageVIESDeclarationTestHandler(var VIESDeclarationTest: TestRequestPage "VIES Declaration - Test")
    begin
        VIESDeclarationTest.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

