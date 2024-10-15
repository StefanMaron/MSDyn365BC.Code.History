codeunit 144021 "IT - CU 2015 Unit Test"
{
    // // [FEATURE] [CU2015] [Export] [Withholding Tax]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TextFile: BigText;
        CommunicationNumber: Integer;
        ConstReason: Option " ",A,B,C,D,E,G,H,I,L,L1,M,M1,M2,N,O,O1,P,Q,R,S,T,U,V,V1,V2,W,X,Y,ZO;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        WrongRecordFoundErr: Label 'Wrong record found.';
        EmptyFieldErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        BaseExcludedAmountTotalErr: Label 'Base - Excluded Amount total on lines for Withholding Tax Entry No. = %1 must be equal to Base - Excluded Amount on the Withholding Tax card for that entry (%2).', Comment = '%1=Entry number,%2=Amount.';

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithoutSigningOfficial()
    var
        VendorNo: Code[20];
    begin
        Initialize;

        VendorNo := CreateVendor;

        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        asserterror Export('');

        Assert.ExpectedError('You need to specify a Signing Company Official');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportEmptyTable()
    var
        SigningCompanyOfficialNo: Code[20];
    begin
        Initialize;

        LibraryVariableStorage.Enqueue(
          StrSubstNo('There were no Withholding Tax entries for the year %1.', Format(Date2DMY(WorkDate, 3))));
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        Export(SigningCompanyOfficialNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleEntry()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
        NonTaxableAmountByTreaty: Decimal;
    begin
        // [SCENARIO 228176] Export Withholding Tax should correctly fill all fields
        Initialize;

        // [GIVEN] Vendor "V"
        VendorNo := CreateVendor;

        // [GIVEN] Withholding Tax "WT" for "V"
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [GIVEN] Set non-zero "WT"."Non Taxable Amount By Treaty"
        NonTaxableAmountByTreaty := LibraryRandom.RandDec(100, 2);
        SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo, NonTaxableAmountByTreaty);

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] All fields are filled
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
        ValidateBlockValue(4, 'AU001005', ConstFormat::VP, NonTaxableAmountByTreaty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleEntryNonResidentVendor()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
        NonTaxableAmountByTreaty: Decimal;
    begin
        // [SCENARIO 228176] Export Withholding Tax with Non-Resident Vendor should not write "Non Taxable Amount By Treaty" in the 'AU001005' field
        Initialize;

        // [GIVEN] Vendor "V" with Resident = "Non-Resident"
        VendorNo := CreateNonResidentVendorNo;

        // [GIVEN] Withholding Tax for "V" with "Non Taxable Amount By Treaty"
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [GIVEN] Set non-zero "WT"."Non Taxable Amount By Treaty"
        NonTaxableAmountByTreaty := LibraryRandom.RandDec(100, 2);
        SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo, NonTaxableAmountByTreaty);

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] No 'AU001005' field in the exported file
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
        ValidateBlockValue(4, 'AU001005', ConstFormat::VP, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesWithSameReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        VendorNo := CreateVendor;

        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        Filename := Export(SigningCompanyOfficialNo);

        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntiesWithDifferentReason()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        VendorNo := CreateVendor;

        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::B, 0, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        Filename := Export(SigningCompanyOfficialNo);

        LoadFile(Filename);
        ValidateHeader(SigningCompanyOfficialNo);
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, ConstReason::A, 3, '', WithholdingTax."Non-Taxable Income Type"::"1");
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, ConstReason::B, 5, '', WithholdingTax."Non-Taxable Income Type"::"1");
        ValidateFooter(7, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithTaxRepresentative()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        VendorNo := CreateVendor;

        CreateTaxRepresentative;
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        Filename := Export(SigningCompanyOfficialNo);

        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesDiffPeriodsWithEmptyReason()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        WHTEntryNo: Integer;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current and previous periods with empty Reason should generate an error for the current period only
        Initialize;
        VendorNo := CreateVendor;

        // [GIVEN] Withholding Tax for current and previous periods with Reason = ""
        WHTEntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::" ", 0, WorkDate, WorkDate);
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::" ", -1, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [WHEN] Run Withholding Tax Export
        LibraryVariableStorage.Enqueue(WHTEntryNo);
        LibraryVariableStorage.Enqueue(WithholdingTax.FieldCaption(Reason));
        Export(SigningCompanyOfficialNo);

        // [THEN] Error log shows Error Message for empty Reason for current period
        // [THEN] No error shown for previous period
        // verification is done inside ErrorPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesPreviousPeriodWithEmptyReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current period and previous period with empty Reason
        Initialize;
        VendorNo := CreateVendor;

        // [GIVEN] Withholding Tax for current period with Reason = "A" and previous period with Reason Code = ""
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::" ", -1, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File exported with record for current period with Reason "A"
        // [THEN] Footer shows 1 record as total count
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleEntriesDiffPeriodsDiffReason()
    var
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 376054] Export Withholdind Tax in current and previous periods with different Reason
        Initialize;
        VendorNo := CreateVendor;

        // [GIVEN] Withholding Tax for current period with Reason Code = "A" and previous period with Reason Code = "B"
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::B, -1, WorkDate, WorkDate);
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [WHEN] Run Withholding Tax Export
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File exported with record for current period with Reason "A"
        // [THEN] Footer shows 1 record as total count
        ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo, VendorNo, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPreviousYearEntries()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        Filename: Text;
        EntryNo: Integer;
    begin
        // [SCENARIO 380480] If Related Date of withholding tax entries is not equal to the year specified in Certificazione Unica declatation export, then these entries should not be included in AU001018 and AU001019 parameters of line H

        Initialize;

        // [GIVEN] Withholding tax entry with Related Date in current year (e.g. the year 2018)
        VendorNo := CreateVendor;
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);

        // [GIVEN] Withholding tax entry with Related Date in previous year (e.g. the year 2017)
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, CalcDate('<-1Y>', WorkDate));
        WithholdingTax.Get(EntryNo);

        SigningCompanyOfficialNo := CreateCompanyOfficial;

        // [WHEN] Export Certificazione Unica declatation
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] Exported file does not contain the value in AU001018 and AU001019 of H-line
        LoadFile(Filename);
        asserterror ValidateBlockValue(4, 'AU001018', ConstFormat::VP, Format(WithholdingTax."Taxable Base")); // Check AU001018 in H-line
        Assert.ExpectedError(
          StrSubstNo('Assert.AreEqual failed. Expected:<%1> (Text). Actual:<> (Text).', WithholdingTax."Taxable Base"));

        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, ''); // Check AU001019 in H-line
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReplaceAU001019ByTaxableBase()
    var
        WithholdingTax: Record "Withholding Tax";
        Filename: Text;
    begin
        // [SCENARIO 380698] If "Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 in Withholding Tax record and user accepts replacement, then AU001019 should contain "Taxable Base"

        Initialize;

        // [GIVEN] Withholding tax entry 1 with Related Date in current year (e.g. the year 2018)
        // [GIVEN] Withholding tax entry 2 with Related Date in previous year (e.g. the year 2017)
        // [GIVEN] Withholding tax entry 2 has "Withholding Tax Amount" bigger than WithholdingTax."Taxable Base" + 1
        CreateWithholdingTaxInCurrentAndPreviousYears(WithholdingTax);

        // [GIVEN] Export Certificazione Unica declatation
        // [WHEN] Reply "Yes" to "Do you want to replace the witholding tax amount with the maximum allowed?"
        Filename := ExportCertificazioneUnica; // Meets ConfirmHandlerYes

        // [THEN] Exported file contains the value of Withholding tax entry 2 "Taxable Base" in AU001019 of H-line
        LoadFile(Filename);
        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, WithholdingTax."Taxable Base"); // Check AU001019 in H-line
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure FillAU001019ByWithholdingTaxAmount()
    var
        WithholdingTax: Record "Withholding Tax";
        Filename: Text;
    begin
        // [SCENARIO 380698] If "Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 in Withholding Tax record and user does not accept replacement, then AU001019 should contain "Withholding Tax Amount"

        Initialize;

        // [GIVEN] Withholding tax entry 1 with Related Date in current year (e.g. the year 2018)
        // [GIVEN] Withholding tax entry 2 with Related Date in previous year (e.g. the year 2017)
        // [GIVEN] Withholding tax entry 2 has "Withholding Tax Amount" bigger than WithholdingTax."Taxable Base" + 1
        CreateWithholdingTaxInCurrentAndPreviousYears(WithholdingTax);

        // [GIVEN] Export Certificazione Unica declatation
        // [WHEN] Reply "No" to "Do you want to replace the witholding tax amount with the maximum allowed?"
        Filename := ExportCertificazioneUnica; // Meets ConfirmHandlerNo

        // [THEN] Exported file contains the value of Withholding tax entry 2 "Withholding Tax Amount" in AU001019 of H-line
        LoadFile(Filename);
        ValidateBlockValue(4, 'AU001019', ConstFormat::VP, WithholdingTax."Withholding Tax Amount"); // Check AU001019 in H-line
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxReasonCodeOptionZO()
    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        WithholdingTax: Record "Withholding Tax";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 219573] WithholdingTax."Reason" option has value "ZO"

        // TAB 12113 "Tmp Withholding Contribution"
        TmpWithholdingContribution.Init();
        TmpWithholdingContribution.Validate(Reason, TmpWithholdingContribution.Reason::ZO);
        Assert.AreEqual('ZO', Format(TmpWithholdingContribution.Reason), '');

        // TAB 12116 "Withholding Tax"
        WithholdingTax.Init();
        WithholdingTax.Validate(Reason, WithholdingTax.Reason::ZO);
        Assert.AreEqual('ZO', Format(WithholdingTax.Reason), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxReasonCodeOptionGHI()
    var
        WithholdingTax: Record "Withholding Tax";
        VendorNo: Code[20];
        SigningCompanyOfficialNo: Code[20];
        Filename: Text;
    begin
        // [SCENARIO 223885] Record H in exported file contains field AU001002 only for reasons "G", "H", "I". Value of field AU001002 must be less then the year of the declaration.
        // [SCENARIO 233814] Export file with 4 different values of AU001006
        Initialize;

        // [GIVEN] Withholding tax entry with Reason = "G" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 1 in Withholding Tax
        VendorNo := CreateVendor;
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, ConstReason::G, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"1");

        // [GIVEN] Withholding tax entry with Reason = "H" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 2 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, ConstReason::H, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"2");

        // [GIVEN] Withholding tax entry with Reason = "I" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 5 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, ConstReason::I, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"5");

        // [GIVEN] Withholding tax entry with Reason = "ZO" and year 2017
        // [GIVEN] "Non-Taxable Income Type" = 6 in Withholding Tax
        CreateWithholdingTaxWithAU001006AndContributionEntry(
          VendorNo, ConstReason::ZO, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"6");

        // [WHEN] Export withholding taxes
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        Filename := Export(SigningCompanyOfficialNo);

        // [THEN] File contains Records H
        LoadFile(Filename);
        ValidateHeader(SigningCompanyOfficialNo);

        // [THEN] Record with "AU001001" = "G", field "AU001002" = 2016, "AU001006" = 1
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, ConstReason::G, 3, Format(Date2DMY(WorkDate, 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"1");

        // [THEN] Record with "AU001001" = "H", field "AU001002" = 2016, "AU001006" = 2
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, ConstReason::H, 5, Format(Date2DMY(WorkDate, 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"2");

        // [THEN] Record with "AU001001" = "I", field "AU001002" = 2016, "AU001006" = 5
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, ConstReason::I, 7, Format(Date2DMY(WorkDate, 3) - 1),
          WithholdingTax."Non-Taxable Income Type"::"5");

        // [THEN] Record with "AU001001" = "ZO", without field "AU001002", "AU001006" = 6
        ValidateRecordDAndH(
          VendorNo, SigningCompanyOfficialNo, ConstReason::ZO, 9, '', WithholdingTax."Non-Taxable Income Type"::"6");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportWithholdingTaxWithEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        SigningCompanyOfficialNo: Code[20];
        VendorNo: Code[20];
        WHTEntryNo: Integer;
    begin
        // [SCENARIO 233814] Error when export file with empty "Non-Taxable Income Type" in "Withholding Tax"
        Initialize;

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " "
        VendorNo := CreateVendor;
        WHTEntryNo :=
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            VendorNo, ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" ");

        // [WHEN] Export withholding taxes
        SigningCompanyOfficialNo := CreateCompanyOfficial;
        LibraryVariableStorage.Enqueue(WHTEntryNo);
        LibraryVariableStorage.Enqueue(WithholdingTax.FieldCaption("Non-Taxable Income Type"));
        Export(SigningCompanyOfficialNo);

        // [THEN] Error log shows Error Message for empty Non-Taxable Income Type
        // Verification is done inside ErrorPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithholdingTaxWithSplitBaseExcludedValue()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: array[2] of Record "Withholding Tax Line";
        FileName: Text;
        LineNo: Integer;
    begin
        // [SCENARIO 350177] Base - Excluded amount split in two lines with different Non-taxable income type is correctly exported in two separate lines
        Initialize();

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " " and Base - Excluded amount = "X+Y"
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Created Withholding tax lines for entry. Line 1 = Amount X and Non-taxable income type 1
        // [GIVEN] Line 2 = Amount Y and Non-taxable income type 2
        CreateBaseExcludedSplit(WithholdingTaxLine, WithholdingTax."Entry No.");

        // [WHEN] Run "Withholding tax export" codeunit
        FileName := Export(CreateCompanyOfficial());

        // [THEN] In the report there are 2 RecordH lines corresponding to Withholding Tax Entry, we skip 3 header lines
        LoadFile(FileName);
        LineNo := 4;

        // [THEN] First line has Total Amount = Withholding Tax Entry Total amount, Base Excluded Amount = X + WHT Entry Non-Taxable Amount and Non-taxable income type 1
        ValidateAmountsInRecordH(WithholdingTaxLine[1], WithholdingTax."Total Amount", WithholdingTax."Non Taxable Amount", LineNo);

        // [THEN] Second line has Total Amount = 0, Base Excluded Amount = Y and Non-Taxable income type 2
        ValidateAmountsInRecordH(WithholdingTaxLine[2], 0, 0, LineNo + 2);

        // Cleanup
        WithholdingTaxLine[1].Delete();
        WithholdingTaxLine[2].Delete();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ErrorPageHandlerWithExpectedErrorMessage')]
    [Scope('OnPrem')]
    procedure ExportWithholdingTaxWithSplitBaseExcludedValueErrorOnWrongAmount()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: array[2] of Record "Withholding Tax Line";
    begin
        // [SCENARIO 350177] Base - Excluded amount split in two lines with different Non-taxable income type is correctly exported in two separate lines
        Initialize();

        // [GIVEN] Withholding tax entry with Non-Taxable Income Type" = " " and Base - Excluded amount = "X+Y"
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Created Withholding tax lines for entry. Line 1 = Amount X and Non-taxable income type 1
        // [GIVEN] Line 2 = Amount Y + 50 and Non-taxable income type 2
        CreateBaseExcludedSplit(WithholdingTaxLine, WithholdingTax."Entry No.");
        WithholdingTaxLine[2]."Base - Excluded Amount" := WithholdingTaxLine[2]."Base - Excluded Amount" + LibraryRandom.RandDec(50, 2);
        WithholdingTaxLine[2].Modify();

        // [WHEN] Run "Withholding tax export" codeunit
        LibraryVariableStorage.Enqueue(StrSubstNo(
            BaseExcludedAmountTotalErr, WithholdingTax."Entry No.", WithholdingTax."Base - Excluded Amount"));
        Export(CreateCompanyOfficial());

        // [THEN] Error for Base - Excluded Amount is shown.
        // Validated in ErrorPageHandlerWithExpectedErrorMessage
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        WithholdingTaxLine[1].Delete();
        WithholdingTaxLine[2].Delete();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownOpensWithholdingTaxLines()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page opens on Base - Excluded Amount drilldown in Withholding Tax Card
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // UI Handled by WithholdingTaxLinesModalPageHandler

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownConfirmYesOnNonEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] If Non-taxable income type is not empty, confirm will pop up on Base - Excluded Amount drilldown in Withholding Tax Card
        // User presses Yes - Withholding tax lines page opens
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"7"));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // UI Handled by WithholdingTaxLinesModalPageHandler

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure WithholdingTaxDrilldownConfirmNoOnNonEmptyNonTaxableIncomeType()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] If Non-taxable income type is not empty, confirm will pop up on Base - Excluded Amount drilldown in Withholding Tax Card
        // User presses No - Withholding tax lines page opens
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::"7"));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User clicks on "Base - Excluded amount" drilldown
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page doesn't open

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithCheckTotal')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesDisplaysWithholdingTaxTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page displays correct Withholding Tax Card total
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base - ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [THEN] Withholding tax lines page opens
        // Total amount validated in WithholdingTaxLinesModalPageHandlerWithCheckTotal handler
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithLineEntry,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesWarningOnClosingWithWrongTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page will warn user that amount total is not correct when closing page
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base - ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount" + LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(WithholdingTax."Non-Taxable Income Type"::"7");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [WHEN] Withholding tax lines page opens Line is entered with a non-taxable income type and amount = X + 100
        // UI is handled by WithholdingTaxLinesModalPageHandlerWithLineEntry
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Closing Withholding tax page a confirm pops up with warning
        // UI is handled by ConfirmHandlerYes

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxLinesModalPageHandlerWithCorrectSplit')]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesSplitInTwoLinesWithCorrectTotal()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Withholding tax lines page will successfully close and create lines when split total correctly
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty and Base ExcludedAmount = X
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [GIVEN] User clicks on "Base - Excluded amount" drilldown
        LibraryVariableStorage.Enqueue(WithholdingTax."Base - Excluded Amount");
        WithholdingTaxCard."Base - Excluded Amount".DrillDown();

        // [WHEN] Withholding tax lines page opens. User splits the total amount of X correctly into two lines
        // UI is handled by WithholdingTaxLinesModalPageHandlerWithCorrectSplit
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Page closes with no warning. Two lines are created.
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", WithholdingTax."Entry No.");
        Assert.RecordCount(WithholdingTaxLine, 2);

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WithholdingTaxCardChangeNonTaxableIncomeTypeClearsLines()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 350177] Setting Non-taxable income type from empty to non-empty clears associated Withholding Tax Lines
        Initialize();

        // [GIVEN] Withholding tax entry with Non-taxable income type empty
        WithholdingTax.Get(
          CreateWithholdingTaxWithAU001006AndContributionEntry(
            CreateVendor(), ConstReason::A, 0, WorkDate, WorkDate, WithholdingTax."Non-Taxable Income Type"::" "));

        // [GIVEN] Withholding line was created for this entry
        CreateWithholdingTaxLine(WithholdingTaxLine, WithholdingTax."Entry No.", 10000, LibraryRandom.RandDec(100, 2), 0);

        // [GIVEN] Withholding Tax card page was open
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.Filter.SetFilter("Entry No.", Format(WithholdingTax."Entry No."));

        // [WHEN] User changes value of Non-taxable income type
        WithholdingTaxCard."Non-Taxable Income Type".SetValue(WithholdingTax."Non-Taxable Income Type"::"6");

        // [THEN] Withholding tax lines are cleared for this entry
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", WithholdingTax."Entry No.");
        Assert.RecordIsEmpty(WithholdingTaxLine);

        // Cleanup
        WithholdingTaxCard.Close();
    end;

    local procedure Initialize()
    var
        WithholdingTax: Record "Withholding Tax";
        Contributions: Record Contributions;
        IsInitialized: Boolean;
    begin
        WithholdingTax.DeleteAll();
        Contributions.DeleteAll();
        CommunicationNumber := LibraryRandom.RandIntInRange(1, 99999999);

        if IsInitialized then
            exit;

        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := LibraryUtility.GenerateGUID;
        CompanyInformation.County := LibraryUtility.GenerateGUID;
        CompanyInformation."Office Code" := 'abc';
        CompanyInformation.Modify();

        IsInitialized := true;
    end;

    local procedure CreateBaseExcludedSplit(var WithholdingTaxLine: array[2] of Record "Withholding Tax Line"; WHTEntryNo: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.Get(WHTEntryNo);
        CreateWithholdingTaxLine(
          WithholdingTaxLine[1], WHTEntryNo, 10000,
          Round(WithholdingTax."Base - Excluded Amount" / 3), WithholdingTax."Non-Taxable Income Type"::"6");
        CreateWithholdingTaxLine(
          WithholdingTaxLine[2], WHTEntryNo, 20000,
          WithholdingTax."Base - Excluded Amount" - WithholdingTaxLine[1]."Base - Excluded Amount",
          WithholdingTax."Non-Taxable Income Type"::"7");
    end;

    local procedure CalculateContributions(var WithholdingTax: Record "Withholding Tax"; EntryNo: Integer; var TempContributions: Record Contributions temporary)
    var
        Contributions: Record Contributions;
    begin
        with Contributions do begin
            SetRange("External Document No.", WithholdingTax."External Document No.");
            if not TempContributions.Get(EntryNo) then begin
                TempContributions.Init();
                TempContributions."Entry No." := EntryNo;
                TempContributions.Insert();
            end;

            if FindSet then
                repeat
                    TempContributions."Company Amount" += "Company Amount";
                    TempContributions."Free-Lance Amount" += "Free-Lance Amount";
                until Next = 0;
            TempContributions.Modify();
        end;
    end;

    local procedure CreateWithholdingTaxLine(var WithholdingTaxLine: Record "Withholding Tax Line"; WithholdingTaxEntryNo: Integer; WithholdingTaxLineNo: Integer; BaseExcludedAmount: Decimal; NonTaxableIncomeType: Option)
    begin
        WithholdingTaxLine.Init();
        WithholdingTaxLine."Base - Excluded Amount" := BaseExcludedAmount;
        WithholdingTaxLine."Non-Taxable Income Type" := NonTaxableIncomeType;
        WithholdingTaxLine."Withholding Tax Entry No." := WithholdingTaxEntryNo;
        WithholdingTaxLine."Line No." := WithholdingTaxLineNo;
        if WithholdingTaxLine.Insert() then;
    end;

    local procedure CreateCompanyOfficial(): Code[20]
    var
        CompanyOfficials: Record "Company Officials";
    begin
        with CompanyOfficials do begin
            if FindFirst then;
            "No." += LibraryUtility.GenerateGUID;
            "Fiscal Code" := LibraryUtility.GenerateGUID;
            "Appointment Code" := LibrarySpesometro.CreateAppointmentCode;
            "First Name" := LibraryUtility.GenerateGUID;
            "Last Name" := LibraryUtility.GenerateGUID;

            Insert;
            exit("No.");
        end;
    end;

    local procedure CreateContributions()
    var
        Contributions: Record Contributions;
    begin
        with Contributions do begin
            if FindLast then;
            "Entry No." += 1;
            Init;

            "Company Amount" := LibraryRandom.RandDec(100, 2);
            "Free-Lance Amount" := LibraryRandom.RandDec(100, 2);

            Insert;
        end;
    end;

    local procedure CreateTaxRepresentative()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Intermediary Date" := WorkDate;
        VATReportSetup.Modify();

        CompanyInformation.Validate("Tax Representative No.", CreateVendor);
        CompanyInformation.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        exit(LibrarySpesometro.CreateVendor(true, Vendor.Resident::Resident, false, true));
    end;

    local procedure CreateNonResidentVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        exit(LibrarySpesometro.CreateVendor(true, Vendor.Resident::"Non-Resident", false, true));
    end;

    local procedure CreateWithholdingTaxAndContributionEntry(VendorNo: Code[20]; WithholdingTaxReason: Option; CalcYear: Integer; Date: Date; RelatedDate: Date): Integer
    var
        WithholdingTax: Record "Withholding Tax";
        WHTEntryNo: Integer;
    begin
        WHTEntryNo :=
          CreateWithholdingTaxWithAU001006(
            VendorNo, WithholdingTaxReason, CalcYear, Date, RelatedDate, WithholdingTax."Non-Taxable Income Type"::"1");
        CreateContributions;

        exit(WHTEntryNo);
    end;

    local procedure CreateWithholdingTaxWithAU001006AndContributionEntry(VendorNo: Code[20]; WithholdingTaxReason: Option; CalcYear: Integer; Date: Date; RelatedDate: Date; NonTaxableIncomeType: Option " ","1","2","5","6"): Integer
    var
        WHTEntryNo: Integer;
    begin
        WHTEntryNo := CreateWithholdingTaxWithAU001006(VendorNo, WithholdingTaxReason, CalcYear, Date, RelatedDate, NonTaxableIncomeType);
        CreateContributions;

        exit(WHTEntryNo);
    end;

    local procedure CreateWithholdingTaxInCurrentAndPreviousYears(var WithholdingTax: Record "Withholding Tax")
    var
        VendorNo: Code[20];
        EntryNo: Integer;
    begin
        VendorNo := CreateVendor;
        CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, WorkDate, WorkDate);
        EntryNo := CreateWithholdingTaxAndContributionEntry(VendorNo, ConstReason::A, 0, CalcDate('<-1Y>', WorkDate), WorkDate);
        WithholdingTax.Get(EntryNo);
        WithholdingTax.Validate("Withholding Tax Amount", WithholdingTax."Taxable Base" + 2);
        WithholdingTax.Modify(true);
    end;

    local procedure CreateWithholdingTaxWithAU001006(VendorNo: Code[20]; WithholdingTaxReason: Option; CalcYear: Integer; Date: Date; RelatedDate: Date; NonTaxableIncomeType: Option " ","1","2","5","6"): Integer
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        with WithholdingTax do begin
            if FindLast then;
            "Entry No." += 1;
            Init;

            "Vendor No." := VendorNo;
            Reason := WithholdingTaxReason;

            "Total Amount" := LibraryRandom.RandDec(100, 2);
            "Non Taxable Amount By Treaty" := LibraryRandom.RandDec(100, 2);
            "Base - Excluded Amount" := LibraryRandom.RandDec(100, 2);
            "Non Taxable Amount" := LibraryRandom.RandDec(100, 2);
            "Taxable Base" := LibraryRandom.RandDec(100, 2);
            "Withholding Tax Amount" := LibraryRandom.RandDec(100, 2);
            Year := Date2DMY(Date, 3) + CalcYear;
            "Related Date" := RelatedDate;
            "Non-Taxable Income Type" := NonTaxableIncomeType;
            Insert;
        end;

        exit(WithholdingTax."Entry No.");
    end;

    local procedure SetWithholdingTaxNonTaxableAmountByTreaty(EntryNo: Integer; NonTaxableAmountByTreaty: Decimal)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.Get(EntryNo);
        WithholdingTax."Non Taxable Amount By Treaty" := NonTaxableAmountByTreaty;
        WithholdingTax.Modify();
    end;

    local procedure Export(SigningCompanyOfficialNo: Code[20]) Filename: Text
    var
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
    begin
        Filename := TemporaryPath + LibraryUtility.GenerateGUID + '.dcm';
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(WorkDate, 3), SigningCompanyOfficialNo, 1, CommunicationNumber);
    end;

    local procedure ExportCertificazioneUnica(): Text
    var
        WithholdingTaxExport: Codeunit "Withholding Tax Export";
        Filename: Text;
        SigningCompanyOfficialNo: Code[20];
    begin
        SigningCompanyOfficialNo := CreateCompanyOfficial;

        Filename := TemporaryPath + LibraryUtility.GenerateGUID + '.dcm';
        WithholdingTaxExport.SetServerFileName(Filename);
        WithholdingTaxExport.Export(Date2DMY(WorkDate, 3), SigningCompanyOfficialNo, 1, CommunicationNumber);

        exit(Filename);
    end;

    local procedure LoadFile(FileName: Text)
    var
        File: File;
        InStr: InStream;
    begin
        File.Open(FileName);
        File.CreateInStream(InStr);
        TextFile.Read(InStr);
    end;

    local procedure FormatToLength(Value: Variant; Length: Integer): Text
    begin
        exit(PadStr('', Length - StrLen(Format(Value)), '0') + Format(Value));
    end;

    local procedure ValidateAmountsInRecordH(WithholdingTaxLine: Record "Withholding Tax Line"; TotalAmount: Decimal; NonTaxableAmount: Decimal; LineNumber: Integer)
    begin
        if TotalAmount <> 0 then
            ValidateBlockValue(LineNumber, 'AU001004', ConstFormat::VP, TotalAmount);
        ValidateBlockValue(LineNumber, 'AU001006', ConstFormat::NP, Format(WithholdingTaxLine."Non-Taxable Income Type"));
        ValidateBlockValue(LineNumber, 'AU001007', ConstFormat::VP, WithholdingTaxLine."Base - Excluded Amount" + NonTaxableAmount);
    end;

    local procedure ValidateExportedWithholdingTaxWithOneReason(SigningCompanyOfficialNo: Code[20]; VendorNo: Code[20]; Filename: Text)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        LoadFile(Filename);
        ValidateHeader(SigningCompanyOfficialNo);
        ValidateRecordDAndH(VendorNo, SigningCompanyOfficialNo, ConstReason::A, 3, '', WithholdingTax."Non-Taxable Income Type"::"1");
        ValidateFooter(5, 1);
    end;

    local procedure ValidateBlockValue(LineNumber: Integer; FieldName: Text; Type: Option; ExpectedValue: Variant)
    var
        FlatFileManagement: Codeunit "Flat File Management";
        Expected: Text;
    begin
        if ExpectedValue.IsInteger or ExpectedValue.IsDecimal then
            Expected := FlatFileManagement.FormatNum(ExpectedValue, Type)
        else
            Expected := ExpectedValue;

        if Type = ConstFormat::AN then
            Expected := UpperCase(Expected);

        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNumber, FieldName), '<>', ' '), '');
    end;

    local procedure ValidateSpecialCategoryBlockValue(LineNumber: Integer; FieldName: Text; ExpectedValue: Option)
    var
        Vendor: Record Vendor;
        Expected: Text;
    begin
        Vendor."Special Category" := ExpectedValue;
        if ExpectedValue = Vendor."Special Category"::" " then
            Expected := ''
        else
            Expected := UpperCase(Format(Vendor."Special Category"));
        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNumber, FieldName), '<>', ' '), '');
    end;

    local procedure ValidateTextFileValue(LineNumber: Integer; Position: Integer; Length: Integer; Expected: Text)
    begin
        Assert.AreEqual(Expected, DelChr(LibrarySpesometro.ReadValue(TextFile, LineNumber, Position, Length), '<>', ' '), '');
    end;

    local procedure ValidateRecordDAndH(VendorNo: Code[20]; SigningCompanyOfficialNo: Code[20]; WithholdingTaxReason: Option; LineNumber: Integer; Year: Text; NonTaxableIncomeType: Option " ","1","2","5","6")
    var
        WithholdingTax: Record "Withholding Tax";
        TempWithholdingTax: Record "Withholding Tax" temporary;
        Vendor: Record Vendor;
        TempContributions: Record Contributions temporary;
        SigningCompanyOfficials: Record "Company Officials";
    begin
        Vendor.Get(VendorNo);
        SigningCompanyOfficials.Get(SigningCompanyOfficialNo);
        TempWithholdingTax.Init();
        with WithholdingTax do begin
            SetRange("Vendor No.", VendorNo);
            SetRange(Reason, WithholdingTaxReason);
            SetRange("Non-Taxable Income Type", NonTaxableIncomeType);
            FindSet();
            repeat
                TempWithholdingTax."Total Amount" += "Total Amount";
                TempWithholdingTax."Non Taxable Amount By Treaty" += "Non Taxable Amount By Treaty";
                TempWithholdingTax."Base - Excluded Amount" += "Base - Excluded Amount";
                TempWithholdingTax."Non Taxable Amount" += "Non Taxable Amount";
                TempWithholdingTax."Taxable Base" += "Taxable Base";
                TempWithholdingTax."Withholding Tax Amount" += "Withholding Tax Amount";
                CalculateContributions(WithholdingTax, 1, TempContributions);
            until Next = 0;
        end;
        TempWithholdingTax.Insert();

        // Validate D-Record
        ValidateTextFileValue(LineNumber, 1, 1, 'D');
        ValidateTextFileValue(LineNumber, 2, 16, CompanyInformation."Fiscal Code");
        ValidateTextFileValue(LineNumber, 18, 8, '00000001'); // We only export a single file
        ValidateTextFileValue(LineNumber, 26, 16, Vendor."Fiscal Code");

        ValidateBlockValue(LineNumber, 'DA001001', 0, CompanyInformation."Fiscal Code");

        ValidateBlockValue(LineNumber, 'DA001002', ConstFormat::AN, CompanyInformation.Name);
        ValidateBlockValue(LineNumber, 'DA001004', ConstFormat::AN, CompanyInformation.City);
        ValidateBlockValue(LineNumber, 'DA001005', ConstFormat::PR, CompanyInformation.County);
        ValidateBlockValue(LineNumber, 'DA001006', ConstFormat::AN, CompanyInformation."Post Code");
        ValidateBlockValue(LineNumber, 'DA001007', ConstFormat::AN, CompanyInformation.Address);
        ValidateBlockValue(LineNumber, 'DA001009', ConstFormat::AN, CompanyInformation."E-Mail");
        ValidateBlockValue(LineNumber, 'DA001011', ConstFormat::AN, CompanyInformation."Office Code");

        ValidateBlockValue(LineNumber, 'DA002001', ConstFormat::CF, Vendor."Contribution Fiscal Code");
        ValidateBlockValue(LineNumber, 'DA002002', ConstFormat::AN, Vendor."Last Name");
        ValidateBlockValue(LineNumber, 'DA002003', ConstFormat::AN, Vendor."First Name");
        ValidateBlockValue(LineNumber, 'DA002006', ConstFormat::AN, Vendor."Birth City");
        ValidateBlockValue(LineNumber, 'DA002007', ConstFormat::PN, Vendor."Birth County");
        ValidateSpecialCategoryBlockValue(LineNumber, 'DA002008', Vendor."Special Category");

        ValidateBlockValue(LineNumber, 'DA002030', ConstFormat::AN, '');

        ValidateBlockValue(LineNumber, 'DA003002', ConstFormat::CB, '1');

        // Validate H-Record
        ValidateTextFileValue(LineNumber + 1, 1, 1, 'H');
        ValidateTextFileValue(LineNumber + 1, 2, 16, CompanyInformation."Fiscal Code");
        ValidateTextFileValue(LineNumber + 1, 18, 8, '00000001'); // We only export a single file
        ValidateTextFileValue(LineNumber + 1, 26, 16, Vendor."Fiscal Code");

        ValidateBlockValue(LineNumber + 1, 'AU001001', 0, Format(WithholdingTax.Reason));
        ValidateBlockValue(LineNumber + 1, 'AU001002', 0, Year);
        ValidateBlockValue(LineNumber + 1, 'AU001004', ConstFormat::VP, TempWithholdingTax."Total Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001006', ConstFormat::NP, Format(NonTaxableIncomeType));
        ValidateBlockValue(LineNumber + 1, 'AU001007', ConstFormat::VP,
          TempWithholdingTax."Non Taxable Amount" + TempWithholdingTax."Base - Excluded Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001008', ConstFormat::VP, TempWithholdingTax."Taxable Base");
        ValidateBlockValue(LineNumber + 1, 'AU001010', ConstFormat::VP, '');

        ValidateBlockValue(LineNumber + 1, 'AU001020', ConstFormat::VP, TempContributions."Company Amount");
        ValidateBlockValue(LineNumber + 1, 'AU001021', ConstFormat::VP, TempContributions."Free-Lance Amount");
    end;

    local procedure ValidateHeader(SigningCompanyOfficialNo: Code[20])
    var
        SigningCompanyOfficials: Record "Company Officials";
        VendorTaxRepresentative: Record Vendor;
    begin
        SigningCompanyOfficials.Get(SigningCompanyOfficialNo);

        // Validate A-Record
        ValidateTextFileValue(1, 1, 1, 'A');

        ValidateTextFileValue(1, 16, 5, 'CUR21'); // TFS 390620

        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            ValidateTextFileValue(1, 21, 2, '10');
            ValidateTextFileValue(1, 23, 16, VendorTaxRepresentative."Fiscal Code")
        end else begin
            ValidateTextFileValue(1, 21, 2, '01');
            ValidateTextFileValue(1, 23, 16, CompanyInformation."Fiscal Code")
        end;

        // Validate B-Record
        ValidateTextFileValue(2, 1, 1, 'B');
        ValidateTextFileValue(2, 2, 16, CompanyInformation."Fiscal Code");

        ValidateTextFileValue(2, 309, 2, '1'); // TFS 390620
        ValidateTextFileValue(2, 311, 16, SigningCompanyOfficials."Fiscal Code");
        ValidateTextFileValue(2, 327, 2, SigningCompanyOfficials."Appointment Code");
        ValidateTextFileValue(2, 329, 24, SigningCompanyOfficials."Last Name");
        ValidateTextFileValue(2, 353, 20, SigningCompanyOfficials."First Name");
        ValidateTextFileValue(2, 373, 11, FormatToLength(CompanyInformation."Fiscal Code", 11));
        ValidateTextFileValue(2, 384, 18, '000000000000000000'); // TFS 390620
        ValidateTextFileValue(2, 402, 8, FormatToLength(CommunicationNumber, 8));
        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then
            ValidateTextFileValue(2, 412, 16, VendorTaxRepresentative."Fiscal Code");
    end;

    local procedure ValidateFooter(LineNo: Integer; NumHRecords: Integer)
    begin
        ValidateTextFileValue(LineNo, 1, 1, 'Z');

        ValidateTextFileValue(LineNo, 16, 9, '000000001'); // Number of B-Records
        ValidateTextFileValue(LineNo, 25, 9, '000000000'); // Number of C-Records
        ValidateTextFileValue(LineNo, 34, 9, '00000000' + Format(NumHRecords, 0, 1)); // Number of D-Records
        ValidateTextFileValue(LineNo, 43, 9, '000000000'); // Number of G-Records
        ValidateTextFileValue(LineNo, 52, 9, '00000000' + Format(NumHRecords, 0, 1)); // Number of H-Records
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText;
        Assert.AreEqual(ExpectedMessage, Message, '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Msg: Text)
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandler(var ErrorMessages: TestPage "Error Messages")
    var
        WithholdingTax: Record "Withholding Tax";
        RecRef: RecordRef;
    begin
        WithholdingTax.Get(LibraryVariableStorage.DequeueInteger);
        RecRef.GetTable(WithholdingTax);
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(EmptyFieldErr, LibraryVariableStorage.DequeueText, RecRef.RecordId));
        Assert.IsFalse(ErrorMessages.Next, WrongRecordFoundErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandlerWithExpectedErrorMessage(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.Description.AssertEquals(LibraryVariableStorage.DequeueText);
        Assert.IsFalse(ErrorMessages.Next, WrongRecordFoundErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandler(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithLineEntry(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines."Base - Excluded Amount".SetValue(LibraryVariableStorage.DequeueDecimal);
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(LibraryVariableStorage.DequeueInteger);
        WithholdingTaxLines.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithCheckTotal(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    begin
        WithholdingTaxLines."Total Base - Excluded Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal);
        WithholdingTaxLines.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxLinesModalPageHandlerWithCorrectSplit(var WithholdingTaxLines: TestPage "Withholding Tax Lines")
    var
        FirstLineAmount: Decimal;
        TotalAmount: Decimal;
        FirstLineType: Integer;
    begin
        TotalAmount := LibraryVariableStorage.DequeueDecimal();
        FirstLineAmount := Round(TotalAmount / 2);
        FirstLineType := LibraryRandom.RandInt(7);
        WithholdingTaxLines."Base - Excluded Amount".SetValue(FirstLineAmount);
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(FirstLineType);
        WithholdingTaxLines.Next();
        WithholdingTaxLines."Base - Excluded Amount".SetValue(TotalAmount - FirstLineAmount);
        WithholdingTaxLines."Non-Taxable Income Type".SetValue(FirstLineType + 1);
        WithholdingTaxLines.OK.Invoke();
    end;
}

