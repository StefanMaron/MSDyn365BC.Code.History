codeunit 139740 "VAT Group Retr. From Sub Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestVATStatementReportLineMissing()
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
        SuggestLinesBeforeErr: label 'You must run the Suggest Lines action before you include returns for the VAT group.';
    begin
        // [WHEN] The table "VAT Statement Report Line" is empty
        VATStatementReportLine.DeleteAll();

        // [WHEN] Running the codeunit "VAT Group Retrieve From Sub."
        // [THEN] An error is expected
        asserterror Codeunit.Run(Codeunit::"VAT Group Retrieve From Sub.");
        Assert.ExpectedError(SuggestLinesBeforeErr);
    end;

    [Test]
    procedure TestVATGroupRetrieveFromSubExecution()
    var
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        ID: Guid;
        ID2: Guid;
    begin
        ID := CreateGuid();
        ID2 := CreateGuid();

        // [WHEN] The tables are correctly configured
        InitVATReportHeader();
        InitVATStatementReportLine();
        InitVATGroupApprovedMember(ID);
        InitVATGroupSubmissionHeader(ID, ID2);
        InitVATGroupSubmissionLine(ID2);

        // [WHEN] Running the codeunit "VAT Group Retrieve From Sub."
        VATReportHeader.FindFirst();
        Codeunit.Run(Codeunit::"VAT Group Retrieve From Sub.", VATReportHeader);

        // [THEN] The Amount in the table "VAT Statement Report Line" is correctly updated
        VATStatementReportLine.FindFirst();
        Assert.AreEqual(VATStatementReportLine.Amount, 328, 'The Amount should be 328');
    end;

    local procedure InitVATGroupSubmissionHeader(ID: Guid; ID2: Guid)
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
    begin
        VATGroupSubmissionHeader.DeleteAll();

        VATGroupSubmissionHeader.ID := ID2;
        VATGroupSubmissionHeader."Group Member ID" := ID;
        VATGroupSubmissionHeader."Submitted On" := CurrentDateTime();
        VATGroupSubmissionHeader."Start Date" := Today();
        VATGroupSubmissionHeader."End Date" := Today();
        VATGroupSubmissionHeader."VAT Group Return No." := '';
        VATGroupSubmissionHeader.Insert();
    end;

    local procedure InitVATGroupSubmissionLine(ID2: Guid)
    var
        VATGroupSubmissionLine: Record "VAT Group Submission Line";
    begin
        VATGroupSubmissionLine.DeleteAll();
        VATGroupSubmissionLine."VAT Group Submission ID" := ID2;
        VATGroupSubmissionLine."Line No." := 1;
        VATGroupSubmissionLine."Box No." := 'TestBoxNo';
        VATGroupSubmissionLine.Amount := 128;
        VATGroupSubmissionLine.Insert();

    end;

    local procedure InitVATGroupApprovedMember(ID: Guid)
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
    begin
        VATGroupApprovedMember.DeleteAll();

        VATGroupApprovedMember.ID := ID;
        VATGroupApprovedMember.Insert();
    end;

    local procedure InitVATStatementReportLine()
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        VATStatementReportLine.DeleteAll();

        VATStatementReportLine."VAT Report No." := 'TestNo';
        VATStatementReportLine."VAT Report Config. Code" := VATStatementReportLine."VAT Report Config. Code"::"VAT Report";
        VATStatementReportLine."Line No." := 1;
        VATStatementReportLine.Amount := 100;
        VATStatementReportLine."Representative Amount" := 200;
        VATStatementReportLine."Box No." := 'TestBoxNo';
        VATStatementReportLine.Insert();
    end;

    local procedure InitVATReportHeader()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.DeleteAll();

        VATReportHeader."No." := 'TestNo';
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."Start Date" := Today();
        VATReportHeader."End Date" := Today();
        VATReportHeader.Insert();
    end;
}