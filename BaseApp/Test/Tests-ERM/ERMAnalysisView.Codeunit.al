codeunit 134229 "ERM Analysis View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis View]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PageVerify: Label 'The TestPage is not open.';
        NotApplicableForCF: Label 'is not applicable for source type Cash Flow Account';

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisViewListPage()
    var
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // [SCENARIO 230452] Correct page of Analysis View List Sales Page open and closes without errors.

        // [GIVEN] Open and close Analysis View List Sales page.
        Initialize;
        AnalysisViewListSales.OpenView;
        AnalysisViewListSales.Close;

        // [WHEN] Close Analysis View List Sales page again.
        asserterror AnalysisViewListSales.Close;

        // [THEN] Error: Analysis View List Sales page is not open.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisViewListPurchasePage()
    var
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        // [SCENARIO 230453] Correct page of Analysis View List Purchase Page open and closes without errors.

        // [GIVEN] Open and close Analysis View List Purchase page.
        Initialize;
        AnalysisViewListPurchase.OpenView;
        AnalysisViewListPurchase.Close;

        // [WHEN] Close Analysis View List Purchase page again.
        asserterror AnalysisViewListPurchase.Close;

        // [THEN] Error: Analysis View List Purchase is not open.
        Assert.ExpectedError(PageVerify);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnPostingForCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4a] Check Include Budgets and Update on Posting for Cash Flow
        Initialize;

        // Setup
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"Cash Flow Account");

        // Verify
        asserterror AnalysisView.Validate("Include Budgets", true);
        Assert.ExpectedError(NotApplicableForCF);

        asserterror AnalysisView.Validate("Update on Posting", true);
        Assert.ExpectedError(NotApplicableForCF);

        AnalysisView.Validate("Include Budgets", false);
        AnalysisView.Validate("Update on Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnPostingForNotCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4b] Check Include Budgets and Update on Posting for NON Cash Flow
        Initialize;

        // Setup
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Verify
        AnalysisView.Validate("Include Budgets", true);
        AnalysisView.Validate("Update on Posting", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnChangeAccSourceToCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4c] Check Include Budgets and Update on Posting for case of change Account Source from NON Cash Flow to Cash Flow
        Initialize;

        // Verify
        CheckAccSourceChange(true, AnalysisView.FieldNo("Update on Posting"));
        CheckAccSourceChange(true, AnalysisView.FieldNo("Include Budgets"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIncludeBudgetsAndUpdateOnChangeAccSourceToNonCF()
    var
        AnalysisView: Record "Analysis View";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 4d] Check Include Budgets and Update on Posting for case of change Account Source from Cash Flow to NON Cash Flow
        Initialize;

        // Verify
        CheckAccSourceChange(false, AnalysisView.FieldNo("Update on Posting"));
        CheckAccSourceChange(false, AnalysisView.FieldNo("Include Budgets"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUpdateOnPostingForGL()
    var
        AnalysisView: Record "Analysis View";
        LastEntryNo: Integer;
    begin
        // [SCENARIO 5] Check Update on Posting for GL
        Initialize;

        // Setup
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Validate
        AnalysisView.Find;
        AnalysisView.TestField("Last Entry No.");
        LastEntryNo := AnalysisView."Last Entry No.";
        PostSalesOrder;
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
        AnalysisView.Find;
        AnalysisView.TestField("Last Entry No.");
        Assert.IsTrue(AnalysisView."Last Entry No." > LastEntryNo, 'Analysis View was not updated.');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionPageHandler,AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsViewPage()
    var
        AnalysisView: Record "Analysis View";
        AnalysisByDimensions: Page "Analysis by Dimensions";
    begin
        // [SCENARIO 6] Check Analysis By Dimensions page
        Initialize;

        // Setup
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account");

        // Execute
        AnalysisByDimensions.SetAnalysisViewCode(AnalysisView.Code);
        AnalysisByDimensions.Run;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Analysis View");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Analysis View");

        LibraryERMCountryData.CreateVATData;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Analysis View");
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountSource: Integer)
    begin
        with AnalysisView do begin
            Init;
            Code := Format(LibraryRandom.RandIntInRange(1, 10000));
            "Account Source" := AccountSource;
            if not Insert then
                Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithDimensions(var AnalysisView: Record "Analysis View"; AccountSource: Integer)
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        CreateAnalysisView(AnalysisView, AccountSource);
        AnalysisView."Update on Posting" := false;
        AnalysisView.Validate("Include Budgets", true);
        if Dimension.FindSet then
            repeat
                i := i + 1;
                case i of
                    1:
                        AnalysisView."Dimension 1 Code" := Dimension.Code;
                    2:
                        AnalysisView."Dimension 2 Code" := Dimension.Code;
                    3:
                        AnalysisView."Dimension 3 Code" := Dimension.Code;
                    4:
                        AnalysisView."Dimension 4 Code" := Dimension.Code;
                end;
            until (i = 4) or (Dimension.Next = 0);
        AnalysisView.Modify();
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);
    end;

    local procedure CheckAccSourceChange(TestFromNonCachFlowToCF: Boolean; FldNo: Integer)
    var
        AnalysisView: Record "Analysis View";
        ToAccountSource: Integer;
        FromAccountSource: Integer;
    begin
        with AnalysisView do begin
            if TestFromNonCachFlowToCF then begin
                FromAccountSource := "Account Source"::"G/L Account";
                ToAccountSource := "Account Source"::"Cash Flow Account";
            end else begin
                FromAccountSource := "Account Source"::"Cash Flow Account";
                ToAccountSource := "Account Source"::"G/L Account";
            end;

            // Setup
            CreateAnalysisView(AnalysisView, FromAccountSource);

            if FldNo = FieldNo("Update on Posting") then
                Validate("Update on Posting", TestFromNonCachFlowToCF)
            else
                Validate("Include Budgets", TestFromNonCachFlowToCF);

            // Verify
            if TestFromNonCachFlowToCF then begin
                asserterror Validate("Account Source", ToAccountSource);
                Assert.ExpectedError(NotApplicableForCF);
            end else
                Validate("Account Source", ToAccountSource);
        end;
    end;

    local procedure PostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionPageHandler(var AnalysisByDimensions: TestPage "Analysis by Dimensions")
    begin
        AnalysisByDimensions.ShowMatrix.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixPageHandler(var AnalysisByDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisByDimensionsMatrix.OK.Invoke;
    end;
}

