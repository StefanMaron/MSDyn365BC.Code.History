codeunit 139746 "VAT Group Representative Logic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        VATGroupRole: Enum "VAT Group Role";
        NotAllMembersSubmittedErr: Label 'Some VAT Group members have not submitted their VAT return for this period. Wait until all members have submitted before you continue.\n You can see the current submission on the VAT Group Submision page.';
        SuggestLinesBeforeErr: label 'You must run the Suggest Lines action before you include returns for the VAT group.';


    [Test]
    procedure TestVATPeriodsForRepresentative()
    var
        GroupVATApprovedMember: Record "VAT Group Approved Member";
        VATReturnPeriodList: TestPage "VAT Return Period List";
        MemberId: Guid;
        CurrentMemberCount: Integer;
        ExpectedText: Text;
    begin

        // [GIVEN] Current Role is Group Representative
        CreateVATReportSetupTable(VATGroupRole::Representative);

        // [GIVEN] We have at least 1 approved member
        MemberId := CreateVATGroupApprovedMember();

        // [GIVEN] There is a VAT Periods set up
        CreateVATReturnPeriod();

        // [GIVEN] There are VAT submissions for said period
        CreateVATGroupSubmissionHeader(DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), MemberId, '', CreateDateTime(DMY2Date(30, 1, 2020), Time()));

        // [WHEN] VAT Periods page is opened
        VATReturnPeriodList.OpenView();

        // [THEN] 
        Assert.IsTrue(VATReturnPeriodList."Group Member Submissions".Visible(), 'Control should be visible');

        // [THEN] Group member submissions column is shown with the correct number
        CurrentMemberCount := GroupVATApprovedMember.Count();
        ExpectedText := StrSubstNo('1 of %1 submitted', CurrentMemberCount);
        Assert.AreEqual(ExpectedText, VATReturnPeriodList."Group Member Submissions".Value(), 'wrong member submission count');
    end;


    [Test]
    procedure TestVATReturnGroupFlag()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportList: TestPage "VAT Report List";
        VATReport: TestPage "VAT Report";
    begin
        // [GIVEN] Current Role is Group Representative
        CreateVATReportSetupTable(VATGroupRole::Representative);

        // [GIVEN] We have at least a VAT Return
        CreateVATReportHeader(VATReportHeader, 'TEST', DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), 0);

        // [WHEN] We navigate to the list of vat returns
        VATReportList.OpenView();

        // [THEN] We can see the VAT Group Flag
        Assert.IsTrue(VATReportList."VAT Group Return".Visible(), 'the control must be visible');

        // [WHEN] We open an individual VAT Return
        VATReport.Trap();
        Page.Run(Page::"VAT Report", VATReportHeader);

        // [THEN] We can see the VAT Group Flag
        Assert.IsTrue(VATReport."VAT Group Return".Visible(), 'the control must be visible');
        Assert.IsTrue(VATReport."Include VAT Group".Visible(), 'the control must be visible');
    end;

    [Test]
    procedure TestIncludeVATGroupMembersNotSubmitted()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        MemberId: Guid;
    begin
        // [GIVEN] Current Role is Group Representative
        CreateVATReportSetupTable(VATGroupRole::Representative);

        // [GIVEN] We have at least 1 approved member
        MemberId := CreateVATGroupApprovedMember();

        // [GIVEN] We have at least one VAT Return
        VATReportHeader.DeleteAll();
        CreateVATReportHeader(VATReportHeader, 'TEST', DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), 0);

        // [GIVEN] We have no member VAT Group submissions for the same period as the VAT return

        // [WHEN] We Navigate to the VAT Return Page and click the Inluce VAT Group Action
        VATReport.Trap();
        Page.Run(Page::"VAT Report", VATReportHeader);
        asserterror VATReport."Include VAT Group".Invoke();
        Assert.ExpectedError(NotAllMembersSubmittedErr);
        // [THEN] An error will be shown
    end;

    [Test]
    procedure TestIncludeVATGroupNoSuggestLine()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        MemberId: Guid;
    begin
        // [GIVEN] Current Role is Group Representative
        CreateVATReportSetupTable(VATGroupRole::Representative);

        // [GIVEN] We have at least 1 approved member
        MemberId := CreateVATGroupApprovedMember();

        // [GIVEN] We have at least one VAT Return
        VATReportHeader.DeleteAll();
        CreateVATReportHeader(VATReportHeader, 'TEST1', DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), 0);

        // [GIVEN] There are VAT submissions for said period
        CreateVATGroupSubmissionHeader(DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), MemberId, '', CreateDateTime(DMY2Date(30, 1, 2020), Time()));

        // [WHEN] We Navigate to the VAT Return Page and click the Inluce VAT Group Action
        VATReport.Trap();
        Page.Run(Page::"VAT Report", VATReportHeader);

        // [THEN] An error will be shown
        asserterror VATReport."Include VAT Group".Invoke();
        Assert.ExpectedError(SuggestLinesBeforeErr);
    end;

    [Test]
    procedure TestIncludeVATGroupAmounts()
    var
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
        VATReport: TestPage "VAT Report";
        VATGroupMemberCalculation: TestPage "VAT Group Member Calculation";
        MemberId: Guid;
        VATGroupSubmissionId: Guid;
    begin
        // [GIVEN] Current Role is Group Representative
        CreateVATReportSetupTable(VATGroupRole::Representative);

        // [GIVEN] We have at least 1 approved member
        MemberId := CreateVATGroupApprovedMember();

        // [GIVEN] We have at least one VAT Return
        VATReportHeader.DeleteAll();
        CreateVATReportHeader(VATReportHeader, 'TEST10', DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), 0);
        VATStatementReportLine.DeleteAll();
        CreateVATStatementReportLine(VATStatementReportLine, VATReportHeader."No.", 1000, '001', '001', 100);
        CreateVATStatementReportLine(VATStatementReportLine, VATReportHeader."No.", 2000, '002', '002', 200);
        CreateVATStatementReportLine(VATStatementReportLine, VATReportHeader."No.", 3000, '003', '003', 300);

        // [GIVEN] There are VAT submissions for said period
        VATGroupSubmissionId := CreateVATGroupSubmissionHeader(DMY2Date(1, 1, 2020), DMY2Date(31, 1, 2020), MemberId, 'SUBMISSION1', CreateDateTime(DMY2Date(30, 1, 2020), Time()));
        CreateVATGroupSubmissionLine(100, '001', 'SUBMISSION1', VATGroupSubmissionId, 1, '001');
        CreateVATGroupSubmissionLine(200, '002', 'SUBMISSION1', VATGroupSubmissionId, 2, '002');
        CreateVATGroupSubmissionLine(300, '003', 'SUBMISSION1', VATGroupSubmissionId, 3, '003');

        // [WHEN] We Navigate to the VAT Return Page and click the Include VAT Group Action
        VATReport.Trap();
        VATGroupHelperFunctions.SetOriginalRepresentativeAmount(VATReportHeader);
        Page.Run(Page::"VAT Report", VATReportHeader);
        Assert.IsFalse(VATReport.VATReportLines."Group Amount".Visible(), 'control should not be visible');
        Assert.IsFalse(VATReport.VATReportLines."Representative Amount".Visible(), 'control should not be visible');
        VATReport."Include VAT Group".Invoke();

        // [THEN] New Columns Appear
        Assert.IsTrue(VATReport.VATReportLines."Group Amount".Visible(), 'control should be visible');
        Assert.IsTrue(VATReport.VATReportLines."Representative Amount".Visible(), 'control should be visible');

        // [THEN] the values are correctly compounded
        VATReport.VATReportLines.First();
        Assert.AreEqual(100, VATReport.VATReportLines."Group Amount".AsDecimal(), 'group amount does not match the vat submission line amount');
        Assert.AreEqual(100, VATReport.VATReportLines."Representative Amount".AsDecimal(), 'representative amount does not match the vat return line amount');
        Assert.AreEqual(200, VATReport.VATReportLines.Amount.AsDecimal(), 'group amount does not match the vat submission line amount');
        VATReport.VATReportLines.Next();

        Assert.AreEqual(200, VATReport.VATReportLines."Group Amount".AsDecimal(), 'group amount does not match the vat submission line amount');
        Assert.AreEqual(200, VATReport.VATReportLines."Representative Amount".AsDecimal(), 'representative amount does not match the vat return line amount');
        Assert.AreEqual(400, VATReport.VATReportLines.Amount.AsDecimal(), 'group amount does not match the vat submission line amount');
        VATReport.VATReportLines.Next();

        Assert.AreEqual(300, VATReport.VATReportLines."Group Amount".AsDecimal(), 'group amount does not match the vat submission line amount');
        Assert.AreEqual(300, VATReport.VATReportLines."Representative Amount".AsDecimal(), 'representative amount does not match the vat return line amount');
        Assert.AreEqual(600, VATReport.VATReportLines.Amount.AsDecimal(), 'group amount does not match the vat submission line amount');

        // [THEN] clicking on the group amount will open the VAT calculation page with proper values
        VATGroupMemberCalculation.Trap();
        VATReport.VATReportLines."Group Amount".Drilldown();
        VATGroupMemberCalculation.First();
        Assert.AreEqual(300, VATGroupMemberCalculation.Amount.AsDecimal(), 'the amount is wrong in the calculation');
        Assert.AreEqual('003', VATGroupMemberCalculation.BoxNo.Value(), 'the boxno is wrong in the calculation');
        Assert.AreEqual('SUBMISSION1', VATGroupMemberCalculation."VAT Group Submission No.".Value(), 'the vat group sub no. is wrong in the calculation');
        Assert.AreEqual(300, VATGroupMemberCalculation.Total.AsDecimal(), 'the total amount is wrong in the calculation');
    end;

    local procedure CreateVATGroupSubmissionHeader(StartDate: Date; EndDate: Date; GroupMemberId: Guid; No: Code[20]; SubmittedOn: DateTime): Guid
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        ID: Guid;
    begin
        ID := CreateGuid();

        VATGroupSubmissionHeader.ID := ID;
        VATGroupSubmissionHeader."Start Date" := StartDate;
        VATGroupSubmissionHeader."End Date" := EndDate;
        VATGroupSubmissionHeader."Group Member ID" := GroupMemberId;
        VATGroupSubmissionHeader."No." := No;
        VATGroupSubmissionHeader."Submitted On" := SubmittedOn;
        VATGroupSubmissionHeader.Insert();

        exit(ID);
    end;

    local procedure CreateVATGroupSubmissionLine(Amount: Decimal; BoxNo: Text[30]; VATGroupSubmissionNo: Code[20]; VATGroupSubmissionID: Guid; LineNo: Integer; RowNo: Code[10])
    var
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
    begin
        VATGroupSubmissionLine.Amount := Amount;
        VATGroupSubmissionLine."Box No." := BoxNo;
        VATGroupSubmissionLine."VAT Group Submission No." := VATGroupSubmissionNo;
        VATGroupSubmissionLine."VAT Group Submission ID" := VATGroupSubmissionID;
        VATGroupSubmissionLine."Line No." := LineNo;
        VATGroupSubmissionLine."Row No." := RowNo;
        VATGroupSubmissionLine.Insert();
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

    local procedure CreateVATGroupApprovedMember(): Guid
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        MemberId: Guid;
    begin
        VATGroupApprovedMember.DeleteAll();
        MemberId := CreateGuid();
        VATGroupApprovedMember.ID := MemberId;
        VATGroupApprovedMember.Insert();

        exit(MemberId);
    end;

    local procedure CreateVATReturnPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        VATReturnPeriod."No." := 'TEST';
        VATReturnPeriod."Start Date" := DMY2Date(1, 1, 2020);
        VATReturnPeriod."End Date" := DMY2Date(31, 1, 2020);
        VATReturnPeriod.Insert();
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

    local procedure CreateVATStatementReportLine(var VATStatementReportLine: Record "VAT Statement Report Line"; No: Code[20]; LineNo: Integer; BoxNo: Text[30]; RowNo: Code[10]; Amount: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATStatementReportLine."VAT Report No." := No;
        VATStatementReportLine."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATStatementReportLine.Amount := Amount;
        VATStatementReportLine."Line No." := LineNo;
        VATStatementReportLine."Box No." := BoxNo;
        VATStatementReportLine."Row No." := RowNo;
        VATStatementReportLine.Insert();
    end;
}