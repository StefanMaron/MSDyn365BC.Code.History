codeunit 134058 "ERM VAT Report Reopen Release"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [Release/Reopen] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        ReleaseError: Label 'Status should be Released';
        ReopenError: Label 'Status should be Open';
        MissingSetupError: Label 'This is not allowed because of the setup in the %1 window.';
        SubmitError: Label 'Status should be sumbitted';
        SubmitError2: Label 'Status must be equal to ''Released''  in %1', Comment = '%1=Table Caption;';

    [Test]
    [Scope('OnPrem')]
    procedure TestRelease()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportsConfiguration: Record "VAT Reports Configuration";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        VATReportsConfiguration.DeleteAll();
        CreateVATReportHeaderAndLines(VATReportHdr);
        VATReportReleaseReopen.Release(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Released, VATReportHdr.Status, ReleaseError);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopen()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr.Modify();
        VATReportReleaseReopen.Reopen(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Open, VATReportHdr.Status, ReopenError);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopenNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        VATReportHdr.Status := VATReportHdr.Status::Submitted;
        VATReportHdr.Modify();

        VATReportSetup.Get();
        VATReportSetup."Modify Submitted Reports" := false;
        VATReportSetup.Modify();

        asserterror VATReportReleaseReopen.Reopen(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(MissingSetupError, VATReportSetup.TableCaption()));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubmit()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);

        VATReportHdr.Status := VATReportHdr.Status::Released;
        VATReportHdr.Modify();
        VATReportReleaseReopen.Submit(VATReportHdr);

        Assert.AreEqual(VATReportHdr.Status::Submitted, VATReportHdr.Status, SubmitError);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubmitNotAllowed()
    var
        VATReportHdr: Record "VAT Report Header";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        CreateVATReportHeaderAndLines(VATReportHdr);
        asserterror VATReportReleaseReopen.Submit(VATReportHdr);
        Assert.ExpectedError(StrSubstNo(SubmitError2, VATReportHdr.TableCaption()));

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateOriginalReportNo()
    var
        VATReportHeader: array[2] of Record "VAT Report Header";
        i: Integer;
    begin
        // [SCENARIO 277069] "Original Report No" can be validated from a distinct "VAT Report Header"."No."

        for i := 1 to ArrayLen(VATReportHeader) do
            with VATReportHeader[i] do begin
                Init();
                "VAT Report Config. Code" := "VAT Report Config. Code"::"EC Sales List";
                "VAT Report Type" := "VAT Report Type"::Corrective;
                "No." := LibraryUtility.GenerateGUID();
                "Start Date" := WorkDate();
                "End Date" := WorkDate();
                Insert();
            end;

        VATReportHeader[2].Validate("Original Report No.", VATReportHeader[1]."No.");
        VATReportHeader[2].Modify(true);
    end;

    local procedure CreateVATReportHeaderAndLines(var VATReportHdr: Record "VAT Report Header")
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        VATReportSetup.Get();
        NoSeries.Init();
        NoSeries.FindFirst();
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        VATReportHdr."No." := 'Test';
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.Insert(true);

        VATStatementReportLine.Init();
        VATStatementReportLine."VAT Report No." := VATReportHdr."No.";
        VATStatementReportLine."Line No." := 1;
        VATStatementReportLine.Insert();
    end;

    local procedure TearDown()
    var
        VatReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATStatementReportLine.SetRange("VAT Report No.", 'Test');
        VATStatementReportLine.DeleteAll();

        VatReportHdr.SetRange("No.", 'Test');
        VatReportHdr.DeleteAll();

        VATReportSetup.Get();
        VATReportSetup."No. Series" := '';
        VATReportSetup.Modify();
    end;
}

