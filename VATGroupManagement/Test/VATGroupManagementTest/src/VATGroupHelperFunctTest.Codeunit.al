codeunit 139744 "VAT Group Helper Funct Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
        NoVATReportSetupErr: Label 'The VAT report setup was not found. You can create one on the VAT Report Setup page.';


    [Test]
    procedure TestSetOriginalRepresentativeAmountWithEmptyVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
    begin
        // [GIVEN] The VAT Report Setup table is empty
        VATReportSetup.DeleteAll();

        // [WHEN] Calling SetOriginalRepresentativeAmount
        // [THEN] An error should be thrown
        asserterror VATGroupHelperFunctions.SetOriginalRepresentativeAmount(VatReportHeader);
        Assert.AreEqual(NoVATReportSetupErr, GetLastErrorText(), 'The error message is incorrect.');
    end;

    [Test]
    procedure TestSetOriginalRepresentativeAmountWithMemberVATGroupRole()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        Amount: Integer;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        VatReportHeader.DeleteAll();
        VATStatementReportLine.DeleteAll();

        // [GIVEN] A VATReportHeader        
        CreateVATReportHeader(VatReportHeader, 'code1');

        // [GIVEN] A statement report line that is connected to the VAT report header
        Amount := 100;
        CreateVATStatementReportLine(VATStatementReportLine, VatReportHeader."No.", Amount);

        // [WHEN] Calling SetOriginalRepresentativeAmount
        VATGroupHelperFunctions.SetOriginalRepresentativeAmount(VatReportHeader);

        // [THEN] The statement report line should not be updated
        if VATStatementReportLine.Get(VATStatementReportLine."VAT Report No.",
            VATStatementReportLine."VAT Report Config. Code", VATStatementReportLine."Line No.") then
            ;
        Assert.AreNotEqual(Amount, VATStatementReportLine."Representative Amount",
            'The representative amount should not have been updated for a member role.');
    end;


    [Test]
    procedure TestSetOriginalRepresentativeAmountSunshineScenario()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        ConnectedVATStatementReportLine: Record "VAT Statement Report Line";
        DisconnectedVATStatementReportLine: Record "VAT Statement Report Line";
        AmountOnConnectedLine: Integer;
        AmountOnDisconnectedLine: Integer;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Representative
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Representative);

        VatReportHeader.DeleteAll();
        ConnectedVATStatementReportLine.DeleteAll();

        // [GIVEN] A VATReportHeader        
        CreateVATReportHeader(VatReportHeader, 'code1');

        // [GIVEN] A statement report line that is connected to the VAT report header
        AmountOnConnectedLine := 100;
        CreateVATStatementReportLine(ConnectedVATStatementReportLine, VatReportHeader."No.", AmountOnConnectedLine);

        // [GIVEN] A statement report line that is not connected to the VAT report header
        AmountOnDisconnectedLine := 1000;
        CreateVATStatementReportLine(DisconnectedVATStatementReportLine, 'code2', AmountOnDisconnectedLine);

        // [WHEN] Calling SetOriginalRepresentativeAmount
        VATGroupHelperFunctions.SetOriginalRepresentativeAmount(VatReportHeader);

        // [THEN] The statement report line that is connected to the header will be updated
        if ConnectedVATStatementReportLine.Get(ConnectedVATStatementReportLine."VAT Report No.",
            ConnectedVATStatementReportLine."VAT Report Config. Code", ConnectedVATStatementReportLine."Line No.") then
            ;
        Assert.AreEqual(AmountOnConnectedLine, ConnectedVATStatementReportLine."Representative Amount",
            'The representative amount was not updated correctly.');

        // [THEN] The statement report line that is not connected to the header will not be updated
        if DisconnectedVATStatementReportLine.Get(DisconnectedVATStatementReportLine."VAT Report No.",
            DisconnectedVATStatementReportLine."VAT Report Config. Code", DisconnectedVATStatementReportLine."Line No.") then
            ;
        Assert.AreNotEqual(AmountOnDisconnectedLine, DisconnectedVATStatementReportLine."Representative Amount",
            'The representative amount should not have been updated.');
    end;

    [Test]
    procedure TestCountApprovedMemberSubmissionsForPeriodWithNoApprovedMembers()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        Count: Integer;
    begin
        // [GIVEN] There are no entries in the VAT Group Approved Member table
        VATGroupApprovedMember.DeleteAll();

        // [WHEN] Calling CountApprovedMemberSubmissionsForPeriod
        Count := VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(0D, Today());

        // [THEN] Count is 0
        Assert.AreEqual(0, Count, 'The count should be 0, as there are no approved members.');
    end;

    [Test]
    procedure TestCountApprovedMemberSubmissionsForPeriodWithWrongDates()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID: Guid;
        Count: Integer;
    begin
        // [GIVEN] A VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] A group VAT submission header
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID);

        // [WHEN] Calling CountApprovedMemberSubmissionsForPeriod with dates for which there are 
        // no submission headers
        Count := VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(20200202D, Today());

        // [THEN] Count is 0
        Assert.AreEqual(0, Count,
            'The count should be 0, as there are no valid submission headers for the specified dates.');
    end;

    [Test]
    procedure TestCountApprovedMemberSubmissionsForWrongMemberId()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID: Guid;
        Count: Integer;
    begin
        // [GIVEN] A VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] A group VAT submission header
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(0D, 20190101D, CreateGuid());

        // [WHEN] Calling CountApprovedMemberSubmissionsForPeriod with dates for which there are 
        // submission headers
        Count := VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(0D, 20190101D);

        // [THEN] Count is 0
        Assert.AreEqual(0, Count,
            'The count should be 0, as there are no valid group member IDs for the submission headers.');
    end;

    [Test]
    procedure TestCountApprovedMemberSubmissionsForOneMember()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID: Guid;
        Count: Integer;
    begin
        // [GIVEN] A VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] 2 group VAT submission headers for the approved member
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID);
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID);

        // [WHEN] Calling CountApprovedMemberSubmissionsForPeriod with dates for which there are 
        // submission headers
        Count := VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(0D, 20190101D);

        // [THEN] Count is 1
        Assert.AreEqual(1, Count,
            'The count should be 1, as there is only one group member IDs with submission headers.');
    end;

    [Test]
    procedure TestCountApprovedMemberSubmissionsForTwoMembers()
    var
        VATGroupApprovedMember1: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID1: Guid;
        MemberID2: Guid;
        Count: Integer;
    begin
        // [GIVEN] 2 VAT Group Approved Members
        VATGroupApprovedMember1.DeleteAll();
        MemberID1 := CreateVATGroupApprovedMember();
        MemberID2 := CreateVATGroupApprovedMember();

        // [GIVEN] 2 group VAT submission headers for the the first member and one for the 
        // second member
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID1);
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID1);
        CreateVATGroupSubmissionHeader(0D, 20190101D, MemberID2);

        // [WHEN] Calling CountApprovedMemberSubmissionsForPeriod with the start and end dates
        // of the created submission headers
        Count := VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(0D, 20190101D);

        // [THEN] Count is 2, as we have 2 members with submission headers
        Assert.AreEqual(2, Count,
            'The count should be 2, as there are two group member IDs with submission headers.');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsWithNoApprovedMembers()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        SubmissionHeaderID: Guid;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        CreateVATReportHeader(VatReportHeader, 'code1');

        // [GIVEN] No VAT Group Approved Members
        VATGroupApprovedMember.DeleteAll();

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header should not get modified, as it is not linked
        // to a valid VAT Group Approved Member
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID) then
            Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should not have been modified');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsWithInvalidStartDate()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        SubmissionHeaderID: Guid;
        EndDate: Date;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        EndDate := Today();
        CreateVATReportHeader(VatReportHeader, 'code1', 0D, EndDate);

        // [GIVEN] A group VAT submission header with a different start date than that of the
        // report header's, but valid end date and VAT group return no.
        VATGroupSubmissionHeader.DeleteAll();
        SubmissionHeaderID := CreateVATGroupSubmissionHeader(20190101D, EndDate, CreateGuid(), '');

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header should not get modified, as it has a different
        // start date than the report header
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID) then
            Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should not have been modified');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsWithInvalidEndDate()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        SubmissionHeaderID: Guid;
        StartDate: Date;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        StartDate := 0D;
        CreateVATReportHeader(VatReportHeader, 'code1', StartDate, Today());

        // [GIVEN] A group VAT submission header with a different end date than that of the
        // report header's, but a valid start date and VAT group return no.
        VATGroupSubmissionHeader.DeleteAll();
        SubmissionHeaderID := CreateVATGroupSubmissionHeader(StartDate, 20190808D, CreateGuid(), '');

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header should not get modified, as it has a different
        // end date than the report header
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID) then
            Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should not have been modified');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsWithInvalidVATGroupReturnNo()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        SubmissionHeaderID: Guid;
        StartDate: Date;
        EndDate: Date;
        VATGroupReturnNo: Code[20];
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VatReportHeader, 'code1', StartDate, EndDate);

        // [GIVEN] A group VAT submission header with valid start and end dates, but an invalid
        // VAT group return no.
        VATGroupSubmissionHeader.DeleteAll();
        VATGroupReturnNo := 'code';
        SubmissionHeaderID := CreateVATGroupSubmissionHeader(StartDate, EndDate, CreateGuid(), VATGroupReturnNo);

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header should not get modified, as it has an invalid VAT
        // group return no.
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID) then
            Assert.AreEqual(VATGroupReturnNo, VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should not have been modified');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsForOneSubmissionHeader()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID: Guid;
        SubmissionHeaderID: Guid;
        VatReportHeaderNo: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        VatReportHeaderNo := 'code1';
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VatReportHeader, VatReportHeaderNo, StartDate, EndDate);

        // [GIVEN] A VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] A group VAT submission header for the approved member and with the start and end date
        // of the VAT report header
        VATGroupSubmissionHeader.DeleteAll();
        SubmissionHeaderID := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberID);

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header group return no. should be updated to VatReportHeaderNo
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID) then
            Assert.AreEqual(VatReportHeaderNo, VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should have been updated');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsForTwoSubmissionHeadersFromDifferentMembers()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID1: Guid;
        MemberID2: Guid;
        SubmissionHeaderID1: Guid;
        SubmissionHeaderID2: Guid;
        VatReportHeaderNo: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        VatReportHeaderNo := 'code1';
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VatReportHeader, VatReportHeaderNo, StartDate, EndDate);

        // [GIVEN] Two VAT Group Approved Members
        VATGroupApprovedMember.DeleteAll();
        MemberID1 := CreateVATGroupApprovedMember();
        MemberID2 := CreateVATGroupApprovedMember();

        // [GIVEN] Two group VAT submission headers for the approved members and with the start and end date
        // of the VAT report header
        VATGroupSubmissionHeader.DeleteAll();
        SubmissionHeaderID1 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberID1);
        SubmissionHeaderID2 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberID2);

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] The VAT Group Submission Header group return no. should be updated to VatReportHeaderNo
        // for both submission headers
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID1) then
            Assert.AreEqual(VatReportHeaderNo, VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should have been updated for the first submission header');
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID2) then
            Assert.AreEqual(VatReportHeaderNo, VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should have been updated for the second submission header');
    end;

    [Test]
    procedure TestMarkReleasedVATSubmissionsForTwoSubmissionHeadersFromTheSameMember()
    var
        VATReportSetup: Record "VAT Report Setup";
        VatReportHeader: Record "VAT Report Header";
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        MemberID: Guid;
        SubmissionHeaderID1: Guid;
        SubmissionHeaderID2: Guid;
        VatReportHeaderNo: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] A VATReportSetup entry with VAT Group Role - Member
        CreateVATReportSetupTable(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN] A VATReportHeader        
        VatReportHeader.DeleteAll();
        VatReportHeaderNo := 'code1';
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VatReportHeader, VatReportHeaderNo, StartDate, EndDate);

        // [GIVEN] A VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] Two group VAT submission headers for the same approved member and with the start and end date
        // of the VAT report header, but with different submitted on date times
        VATGroupSubmissionHeader.DeleteAll();
        SubmissionHeaderID1 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberID, 0DT);
        SubmissionHeaderID2 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberID, CreateDateTime(Today(), 0T));

        // [WHEN] Calling MarkReleasedVATSubmissions
        VATGroupHelperFunctions.MarkReleasedVATSubmissions(VatReportHeader);

        // [THEN] Only the second VAT Group Submission Header group return no. should be updated to VatReportHeaderNo,
        // as it has a greater Submitted On parameter
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID1) then
            Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should NOT have been updated for the first submission header');
        if VATGroupSubmissionHeader.Get(SubmissionHeaderID2) then
            Assert.AreEqual(VatReportHeaderNo, VATGroupSubmissionHeader."VAT Group Return No.",
                'The VAT Group Return No. should have been updated for the second submission header');
    end;

    [Test]
    procedure TestMarkReopenedVATSubmissions()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATReportHeaderNo: Code[20];
        ValidSubmissionHeader1: Guid;
        ValidSubmissionHeader2: Guid;
        InvalidSubmissionHeader: Guid;
    begin
        // [GIVEN] A VATReportHeader 
        VatReportHeader.DeleteAll();
        VatReportHeaderNo := 'code1';
        CreateVATReportHeader(VatReportHeader, VatReportHeaderNo);

        // [GIVEN] Three VAT Group Submission Headers - two corresponding to the VAT report header
        // defined above and one not
        ValidSubmissionHeader1 := CreateVATGroupSubmissionHeader(0D, Today(), CreateGuid(), VATReportHeaderNo);
        ValidSubmissionHeader2 := CreateVATGroupSubmissionHeader(0D, Today(), CreateGuid(), VATReportHeaderNo);
        InvalidSubmissionHeader := CreateVATGroupSubmissionHeader(0D, Today(), CreateGuid(), 'invalid code');

        // [WHEN] Calling MarkReopenedVATSubmissions
        VATGroupHelperFunctions.MarkReopenedVATSubmissions(VatReportHeader);

        // [THEN] The valid submission headers' VAT Group Return No. should be updated to ''
        VATGroupSubmissionHeader.Get(ValidSubmissionHeader1);
        Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
            'The first submission header should have been reopened');
        VATGroupSubmissionHeader.Get(ValidSubmissionHeader2);
        Assert.AreEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
            'The second submission header should have been reopened');

        // [THEN] The invalid submission header's VAT Group Return No. should NOT be updated to ''
        VATGroupSubmissionHeader.Get(InvalidSubmissionHeader);
        Assert.AreNotEqual('', VATGroupSubmissionHeader."VAT Group Return No.",
            'The third submission header should NOT have been reopened');
    end;

    [Test]
    procedure TestPrepareVATCalculationForNoApprovedMembers()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
    begin
        // [GIVEN] There are no VAT Group Approved Members
        VATGroupApprovedMember.DeleteAll();

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page is empty
        Assert.IsFalse(VATGroupMemberCalculation.First(), 'The page should be empty');
    end;

    [Test]
    procedure TestPrepareVATCalculationForReleasedStatusAndNoValidSubmissions()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId: Guid;
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] One VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Released status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VATReportHeader, 'code', StartDate, EndDate, VATReportHeader.Status::Released);

        // [GIVEN] No submission headers for the specified start date
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(20190101D, 20190202D, MemberId);

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page is empty
        Assert.IsFalse(VATGroupMemberCalculation.First(), 'The page should be empty');
    end;

    [Test]
    procedure TestPrepareVATCalculationForOpenStatusAndNoValidSubmissions()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId: Guid;
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] One VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberID := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Open status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        CreateVATReportHeader(VATReportHeader, 'code', StartDate, EndDate, VATReportHeader.Status::Open);

        // [GIVEN] No submission headers for the specified start date
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(20190101D, 20190202D, MemberId);

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page is empty
        Assert.IsFalse(VATGroupMemberCalculation.First(), 'The page should be empty');
    end;

    [Test]
    procedure TestPrepareVATCalculationForReleasedStatusAndNoValidSubmissionLines()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId1: Guid;
        MemberId2: Guid;
        StartDate: Date;
        EndDate: Date;
        VATReportHeaderNo: Code[20];
    begin
        // [GIVEN] Two VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberId1 := CreateVATGroupApprovedMember();
        MemberId2 := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Released status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        VATReportHeaderNo := 'code1';
        CreateVATReportHeader(VATReportHeader, VATReportHeaderNo, StartDate, EndDate, VATReportHeader.Status::Released);

        // [GIVEN] Two submission headers matching the report header and one that doesn't
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId1, VATReportHeaderNo);
        CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId2, VATReportHeaderNo);
        CreateVATGroupSubmissionHeader(20190101D, EndDate, MemberId2, VATReportHeaderNo);

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page is empty, since the headers do not have 
        // any corresponding lines
        Assert.IsFalse(VATGroupMemberCalculation.First(), 'The page should be empty');
    end;

    [Test]
    procedure TestPrepareVATCalculationForOpenStatusAndNoValidSubmissionLines()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId1: Guid;
        MemberId2: Guid;
        StartDate: Date;
        EndDate: Date;
        VATReportHeaderNo: Code[20];
    begin
        // [GIVEN] Two VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberId1 := CreateVATGroupApprovedMember();
        MemberId2 := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Open status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        VATReportHeaderNo := '';
        CreateVATReportHeader(VATReportHeader, VATReportHeaderNo, StartDate, EndDate, VATReportHeader.Status::Open);

        // [GIVEN] Two submission headers matching the report header and one that doesn't
        VATGroupSubmissionHeader.DeleteAll();
        CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId1, VATReportHeaderNo);
        CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId2, VATReportHeaderNo);
        CreateVATGroupSubmissionHeader(20190101D, EndDate, MemberId2, VATReportHeaderNo);

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page is empty, since the headers do not have 
        // any corresponding lines
        Assert.IsFalse(VATGroupMemberCalculation.First(), 'The page should be empty');
    end;

    [Test]
    procedure TestPrepareVATCalculationForReleasedStatusAndValidSubmissionLines()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId1: Guid;
        MemberId2: Guid;
        StartDate: Date;
        EndDate: Date;
        VATReportHeaderNo: Code[20];
        HeaderId1: Guid;
        HeaderId2: Guid;
        HeaderId3: Guid;
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        BoxNo1: Text[30];
        BoxNo2: Text[30];
        BoxNo3: Text[30];
        VATGroupSubmissionNo1: Code[20];
        VATGroupSubmissionNo2: Code[20];
        VATGroupSubmissionNo3: Code[20];
        SubmittedOn1: DateTime;
        SubmittedOn2: DateTime;
    begin
        // [GIVEN] Two VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberId1 := CreateVATGroupApprovedMember();
        MemberId2 := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Released status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        VATReportHeaderNo := 'code1';
        CreateVATReportHeader(VATReportHeader, VATReportHeaderNo, StartDate, EndDate, VATReportHeader.Status::Released);

        // [GIVEN] Two submission headers matching the report header and one that doesn't
        VATGroupSubmissionHeader.DeleteAll();
        SubmittedOn1 := CreateDateTime(20191212D, 0T);
        SubmittedOn2 := CreateDateTime(0D, 0T);
        HeaderId1 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId1, VATReportHeaderNo, SubmittedOn1);
        HeaderId2 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId2, VATReportHeaderNo, SubmittedOn2);
        HeaderId3 := CreateVATGroupSubmissionHeader(20190101D, EndDate, MemberId2, VATReportHeaderNo, SubmittedOn1);

        // [GIVEN] Submission lines for all 3 submission headers
        VATGroupSubmissionLine.DeleteAll();
        Amount1 := 1.25;
        Amount2 := 25.12;
        Amount3 := 13;
        BoxNo1 := 'Text1';
        BoxNo2 := 'Text2';
        BoxNo3 := 'Text3';
        VATGroupSubmissionNo1 := 'no1';
        VATGroupSubmissionNo2 := 'no2';
        VATGroupSubmissionNo3 := 'no3';
        CreateVATGroupSubmissionLine(Amount1, BoxNo1, VATGroupSubmissionNo1, HeaderId1, VATStatementReportLine."Row No.");
        CreateVATGroupSubmissionLine(Amount2, BoxNo2, VATGroupSubmissionNo2, HeaderId2, VATStatementReportLine."Row No.");
        CreateVATGroupSubmissionLine(Amount3, BoxNo3, VATGroupSubmissionNo3, HeaderId3, VATStatementReportLine."Row No.");

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page should not be empty
        Assert.IsTrue(VATGroupMemberCalculation.First(), 'The page should not be empty');

        // [THEN] There are 2 rows on the page, corresponding to the valid statement headers
        if VATGroupMemberCalculation.Amount.Value() = Format(Amount1) then begin
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount1, BoxNo1, '', VATGroupSubmissionNo1, SubmittedOn1);
            Assert.IsTrue(VATGroupMemberCalculation.Next(), 'The page should have a second record');
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount2, BoxNo2, '', VATGroupSubmissionNo2, SubmittedOn2);
        end else begin
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount2, BoxNo2, '', VATGroupSubmissionNo2, SubmittedOn2);
            Assert.IsTrue(VATGroupMemberCalculation.Next(), 'The page should have a second record');
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount1, BoxNo1, '', VATGroupSubmissionNo1, SubmittedOn1);
        end;

        // [THEN] There is no row on the page corresponding to the invalid statement header
        Assert.IsFalse(VATGroupMemberCalculation.Next(), 'There should not be a third row on the page');
    end;

    [Test]
    procedure TestPrepareVATCalculationForOpenStatusAndValidSubmissionLines()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId1: Guid;
        MemberId2: Guid;
        StartDate: Date;
        EndDate: Date;
        VATReportHeaderNo: Code[20];
        HeaderId1: Guid;
        HeaderId2: Guid;
        HeaderId3: Guid;
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        BoxNo1: Text[30];
        BoxNo2: Text[30];
        BoxNo3: Text[30];
        VATGroupSubmissionNo1: Code[20];
        VATGroupSubmissionNo2: Code[20];
        VATGroupSubmissionNo3: Code[20];
        SubmittedOn1: DateTime;
        SubmittedOn2: DateTime;
    begin
        // [GIVEN] Two VAT Group Approved Member
        VATGroupApprovedMember.DeleteAll();
        MemberId1 := CreateVATGroupApprovedMember();
        MemberId2 := CreateVATGroupApprovedMember();

        // [GIVEN] A VAT Report Header with Open status
        VATReportHeader.DeleteAll();
        StartDate := 0D;
        EndDate := Today();
        VATReportHeaderNo := 'code1';
        CreateVATReportHeader(VATReportHeader, VATReportHeaderNo, StartDate, EndDate, VATReportHeader.Status::Open);

        // [GIVEN] Two submission headers matching the report header and one that doesn't
        VATGroupSubmissionHeader.DeleteAll();
        SubmittedOn1 := CreateDateTime(20191212D, 0T);
        SubmittedOn2 := CreateDateTime(0D, 0T);
        HeaderId1 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId1, '', SubmittedOn1);
        HeaderId2 := CreateVATGroupSubmissionHeader(StartDate, EndDate, MemberId2, '', SubmittedOn2);
        HeaderId3 := CreateVATGroupSubmissionHeader(20190101D, EndDate, MemberId2, '', SubmittedOn1);

        // [GIVEN] Submission lines for all 3 submission headers
        VATGroupSubmissionLine.DeleteAll();
        Amount1 := 1.25;
        Amount2 := 25.12;
        Amount3 := 13;
        BoxNo1 := 'Text1';
        BoxNo2 := 'Text2';
        BoxNo3 := 'Text3';
        VATGroupSubmissionNo1 := 'no1';
        VATGroupSubmissionNo2 := 'no2';
        VATGroupSubmissionNo3 := 'no3';
        CreateVATGroupSubmissionLine(Amount1, BoxNo1, VATGroupSubmissionNo1, HeaderId1, VATStatementReportLine."Row No.");
        CreateVATGroupSubmissionLine(Amount2, BoxNo2, VATGroupSubmissionNo2, HeaderId2, VATStatementReportLine."Row No.");
        CreateVATGroupSubmissionLine(Amount3, BoxNo3, VATGroupSubmissionNo3, HeaderId3, VATStatementReportLine."Row No.");

        // [WHEN] Invoking PrepareVATCalculation
        VATGroupMemberCalculation.Trap();
        VATGroupHelperFunctions.PrepareVATCalculation(VATReportHeader, VATStatementReportLine);

        // [THEN] The VAT Group Member Calculation page should not be empty
        Assert.IsTrue(VATGroupMemberCalculation.First(), 'The page should not be empty');

        // [THEN] There are 2 rows on the page, corresponding to the valid statement headers
        if VATGroupMemberCalculation.Amount.Value() = Format(Amount1) then begin
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount1, BoxNo1, '', VATGroupSubmissionNo1, SubmittedOn1);
            Assert.IsTrue(VATGroupMemberCalculation.Next(), 'The page should have a second record');
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount2, BoxNo2, '', VATGroupSubmissionNo2, SubmittedOn2);
        end else begin
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount2, BoxNo2, '', VATGroupSubmissionNo2, SubmittedOn2);
            Assert.IsTrue(VATGroupMemberCalculation.Next(), 'The page should have a second record');
            VerifyVATGroupCalculation(VATGroupMemberCalculation, Amount1, BoxNo1, '', VATGroupSubmissionNo1, SubmittedOn1);
        end;

        // [THEN] There is no row on the page corresponding to the invalid statement header
        Assert.IsFalse(VATGroupMemberCalculation.Next(), 'There should not be a third row on the page');
    end;

    local procedure CreateVATReportSetupTable(VATGroupRole: Enum "VAT Group Role")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.DeleteAll();
        VATReportSetup."Primary key" := '';
        VATReportSetup."Group Representative Company" := CopyStr(CompanyName(), 1, MaxStrLen(VATReportSetup."Group Representative Company"));
        VATReportSetup."VAT Group Role" := VATGroupRole;
        VATReportSetup."Authentication Type" := VATReportSetup."Authentication Type"::WindowsAuthentication;
        VATReportSetup.Insert();
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; No: Code[20])
    begin
        VATReportHeader."No." := No;
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert();
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; No: Code[20]; StartDate: Date; EndDate: Date)
    begin
        VATReportHeader."No." := No;
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."Start Date" := StartDate;
        VATReportHeader."End Date" := EndDate;
        VATReportHeader.Insert();
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; No: Code[20]; StartDate: Date; EndDate: Date; Status: Option)
    begin
        VATReportHeader."No." := No;
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."Start Date" := StartDate;
        VATReportHeader."End Date" := EndDate;
        VATReportHeader.Status := Status;
        VATReportHeader.Insert();
    end;

    local procedure CreateVATStatementReportLine(var VATStatementReportLine: Record "VAT Statement Report Line"; No: Code[20]; Amount: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATStatementReportLine."VAT Report No." := No;
        VATStatementReportLine."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATStatementReportLine.Amount := Amount;
        VATStatementReportLine.Insert();
    end;

    local procedure CreateVATGroupApprovedMember(): Guid
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        MemberId: Guid;
    begin
        MemberId := CreateGuid();
        VATGroupApprovedMember.ID := MemberId;
        VATGroupApprovedMember.Insert();

        exit(MemberId);
    end;

    local procedure CreateVATGroupSubmissionHeader(StartDate: Date; EndDate: Date; GroupMemberId: Guid): Guid
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        ID: Guid;
    begin
        ID := CreateGuid();

        VATGroupSubmissionHeader.ID := ID;
        VATGroupSubmissionHeader."Start Date" := StartDate;
        VATGroupSubmissionHeader."End Date" := EndDate;
        VATGroupSubmissionHeader."Group Member ID" := GroupMemberId;
        VATGroupSubmissionHeader.Insert();

        exit(ID);
    end;

    local procedure CreateVATGroupSubmissionHeader(StartDate: Date; EndDate: Date; GroupMemberId: Guid; VATGroupReturnNo: Code[20]): Guid
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        ID: Guid;
    begin
        ID := CreateGuid();

        VATGroupSubmissionHeader.ID := ID;
        VATGroupSubmissionHeader."Start Date" := StartDate;
        VATGroupSubmissionHeader."End Date" := EndDate;
        VATGroupSubmissionHeader."Group Member ID" := GroupMemberId;
        VATGroupSubmissionHeader."VAT Group Return No." := VATGroupReturnNo;
        VATGroupSubmissionHeader.Insert();

        exit(ID);
    end;

    local procedure CreateVATGroupSubmissionHeader(StartDate: Date; EndDate: Date; GroupMemberId: Guid; SubmittedOn: DateTime): Guid
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        ID: Guid;
    begin
        ID := CreateGuid();

        VATGroupSubmissionHeader.ID := ID;
        VATGroupSubmissionHeader."Start Date" := StartDate;
        VATGroupSubmissionHeader."End Date" := EndDate;
        VATGroupSubmissionHeader."Group Member ID" := GroupMemberId;
        VATGroupSubmissionHeader."Submitted On" := SubmittedOn;
        VATGroupSubmissionHeader.Insert();

        exit(ID);
    end;

    local procedure CreateVATGroupSubmissionHeader(StartDate: Date; EndDate: Date; GroupMemberId: Guid; VATGroupReturnNo: Code[20]; SubmittedOn: DateTime): Guid
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        ID: Guid;
    begin
        ID := CreateGuid();

        VATGroupSubmissionHeader.ID := ID;
        VATGroupSubmissionHeader."Start Date" := StartDate;
        VATGroupSubmissionHeader."End Date" := EndDate;
        VATGroupSubmissionHeader."Group Member ID" := GroupMemberId;
        VATGroupSubmissionHeader."VAT Group Return No." := VATGroupReturnNo;
        VATGroupSubmissionHeader."Submitted On" := SubmittedOn;
        VATGroupSubmissionHeader.Insert();

        exit(ID);
    end;

    local procedure CreateVATGroupSubmissionLine(Amount: Decimal; BoxNo: Text[30]; VATGroupSubmissionNo: Code[20]; VATGroupSubmissionID: Guid; RowNo: Code[10])
    var
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
    begin
        VATGroupSubmissionLine.Amount := Amount;
        VATGroupSubmissionLine."Box No." := BoxNo;
        VATGroupSubmissionLine."VAT Group Submission No." := VATGroupSubmissionNo;
        VATGroupSubmissionLine."VAT Group Submission ID" := VATGroupSubmissionID;
        VATGroupSubmissionLine."Row No." := RowNo;
        VATGroupSubmissionLine.Insert();
    end;

    local procedure VerifyVATGroupCalculation(VATGroupMemberCalculation: TestPage "VAT Group Member Calculation"; Amount: Decimal; BoxNo: Text[30]; GroupMemberName: Text[250]; VATGroupSubmissionNo: Code[20]; SubmittedOn: DateTime)
    begin
        Assert.AreEqual(Format(Amount), VATGroupMemberCalculation.Amount.Value(), 'The amount is incorrect');
        Assert.AreEqual(Format(BoxNo), VATGroupMemberCalculation.BoxNo.Value(), 'The Box No. is incorrect');
        Assert.AreEqual(Format(GroupMemberName), VATGroupMemberCalculation."Group Member Name".Value(),
            'The Group Member Name is incorrect');
        Assert.AreEqual(Format(VATGroupSubmissionNo), VATGroupMemberCalculation."VAT Group Submission No.".Value(),
            'The VAT Group Submission No. is incorrect');
        Assert.AreEqual(SubmittedOn, VATGroupMemberCalculation.SubmittedOn.AsDateTime(),
            'The Submitted On field is incorrect');
    end;
}