codeunit 139742 "VAT Group Submit To Repr. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";

    [Test]
    procedure TestVATReportSetupMissing()
    var
        VATReportSetup: Record "VAT Report Setup";
        NoVATReportSetupErr: Label 'The VAT report setup was not found. You can create one on the VAT Report Setup page.';
    begin
        // [WHEN] The "VAT Report Setup" table is empty 
        VATReportSetup.DeleteAll();

        // [THEN] A error is expected
        asserterror Codeunit.Run(Codeunit::"VAT Group Submit To Represent.");
        Assert.ExpectedError(NoVATReportSetupErr);
    end;

    [Test]
    procedure TestFailureInSend()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportCouldNotSubmitMsg: Label 'One or more errors were found. You must resolve all the errors before you can proceed.';
    begin
        // [WHEN] The "VAT Report Setup" table is configured but the API URL is wrong
        InitVATReportSetupTable();
        VATReportSetup.FindFirst();
        VATReportSetup."Group Representative Company" := 'TestWrongName';
        VATReportSetup.Modify();

        // [THEN] A error is expected
        asserterror Codeunit.Run(Codeunit::"VAT Group Submit To Represent.");
        Assert.ExpectedError(VATReportCouldNotSubmitMsg);
    end;

    [Test]
    procedure TestFailureInSendMissingApprovedMember()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportHeader: Record "VAT Report Header";
        VATReportCouldNotSubmitMsg: Label 'One or more errors were found. You must resolve all the errors before you can proceed.';
    begin
        // [GIVEN] The "VAT Report Setup" table is configured but the API URL is wrong
        InitVATReportSetupTable();
        VATReportSetup.FindFirst();
        VATReportSetup."Group Member ID" := CreateGuid();
        VATReportSetup.Modify();

        // [GIVEN] The "VAT Report Header" table is configured
        InitVATReportHeader();

        // [GIVEN] The Status of a VAT Report is Open (Default Status)
        VATReportHeader.FindFirst();
        Assert.AreEqual(VATReportHeader.Status, VATReportHeader.Status::Open, 'Status should be Open');

        // [WHEN] The submission is sent
        asserterror Codeunit.Run(Codeunit::"VAT Group Submit To Represent.", VATReportHeader);

        Assert.ExpectedError(VATReportCouldNotSubmitMsg);
    end;

    [Test]
    procedure TestSuccessfulSend()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
    begin
        // [GIVEN] The "VAT Report Setup" table is configured
        InitVATReportSetupTable();

        // [GIVEN] The "VAT Group Approved Member" contains the member ID of the current submission.
        InitVATGroupApprovedMemberTable();
        Commit();

        // [GIVEN] The "VAT Report Header" table is configured
        InitVATReportHeader();

        // [GIVEN] The Status of a VAT Report is Open (Default Status)
        VATReportHeader.FindFirst();
        Assert.AreEqual(VATReportHeader.Status, VATReportHeader.Status::Open, 'Status should be Open');

        // [WHEN] The submission is sent
        Codeunit.Run(Codeunit::"VAT Group Submit To Represent.", VATReportHeader);

        // [THEN] The Status should be Submitted
        VATReportHeader.FindFirst();
        Assert.AreEqual(VATReportHeader.Status, VATReportHeader.Status::Submitted, 'Status should be Submitted');

        //[THEN] There should be submissions in the VAT Group Submission table and lines.
        Assert.RecordIsNotEmpty(VATGroupSubmissionHeader);

        VATGroupSubmissionLine.SetFilter("VAT Group Submission No.", VATReportHeader."No.");
        Assert.RecordIsNotEmpty(VATGroupSubmissionLine);

        if VATGroupSubmissionHeader.FindSet() then
            VATGroupSubmissionHeader.DeleteAll(true);
    end;

    local procedure InitVATReportSetupTable()
    var
        VATReportSetup: Record "VAT Report Setup";
        TmpURL: Text;
    begin
        TmpURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '');

        VATReportSetup.DeleteAll();
        VATReportSetup."Primary key" := '';
        VATReportSetup."Group Representative API URL" := CopyStr(TmpURL, 1, StrPos(TmpURL, '/api/') - 1);
        VATReportSetup."Group Representative Company" := CompanyName();
        VATReportSetup."VAT Group Role" := VATReportSetup."VAT Group Role"::Member;
        VATReportSetup."Authentication Type" := VATReportSetup."Authentication Type"::WindowsAuthentication;
        VATReportSetup."Group Member ID" := '54198086-7f01-46ff-b0f6-2f29c5eb5792';
        VATReportSetup.Insert();
    end;

    local procedure InitVATReportHeader()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.DeleteAll();

        VATReportHeader."No." := LibraryRandom.RandText(20);
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."Start Date" := Today();
        VATReportHeader."End Date" := Today();
        VATReportHeader.Insert();
        InitVATReportLines(VATReportHeader);
        InitVATReportLines(VATReportHeader);
    end;

    local procedure InitVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        VATStatementReportLine."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code";
        VATStatementReportLine."VAT Report No." := VATReportHeader."No.";
        VATStatementReportLine."Line No." := LibraryRandom.RandInt(1000000);
        VATStatementReportLine."Row No." := '00' + Format(LibraryRandom.RandInt(9));
        VATStatementReportLine.Description := CopyStr(LibraryRandom.RandText(100), 1, 100);
        VATStatementReportLine."Box No." := Format(LibraryRandom.RandInt(1000));
        VATStatementReportLine.Amount := LibraryRandom.RandDecInRange(0, 1000000, 2);
        VATStatementReportLine.Insert();
    end;

    local procedure InitVATGroupApprovedMemberTable()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
    begin
        VATGroupApprovedMember.ID := '54198086-7f01-46ff-b0f6-2f29c5eb5792';
        VATGroupApprovedMember."Group Member Name" := 'test user';
        VATGroupApprovedMember.Insert();
    end;
}