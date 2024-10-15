codeunit 134058 "ERM VAT Report Reopen Release"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [Release/Reopen]
    end;

    var
        Assert: Codeunit Assert;
        ReleaseError: Label 'Status should be Released';
        ReopenError: Label 'Status should be Open';
        MissingSetupError: Label 'This is not allowed because of the setup in the %1 window.';
        SubmitError: Label 'Status should be sumbitted';
        SubmitError2: Label 'Status must be equal to ''Released''  in %1', Comment = '%1=Table Caption;';

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
        Assert.ExpectedError(StrSubstNo(MissingSetupError, VATReportSetup.TableCaption));

        TearDown;
    end;

    local procedure CreateVATReportHeaderAndLines(var VATReportHdr: Record "VAT Report Header")
    var
        VatReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
    begin
        VATReportSetup.Get();
        NoSeries.Init();
        NoSeries.FindFirst;
        VATReportSetup."No. Series" := NoSeries.Code;
        VATReportSetup.Modify();

        VATReportHdr."No." := 'Test';
        VATReportHdr.Status := VATReportHdr.Status::Open;
        VATReportHdr.Insert(true);

        VatReportLine.Init();
        VatReportLine."VAT Report No." := VATReportHdr."No.";
        VatReportLine."Line No." := 1;
        VatReportLine.Insert();
    end;

    local procedure TearDown()
    var
        VatReportHdr: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportLine.SetRange("VAT Report No.", 'Test');
        VATReportLine.DeleteAll();

        VatReportHdr.SetRange("No.", 'Test');
        VatReportHdr.DeleteAll();

        VATReportSetup.Get();
        VATReportSetup."No. Series" := '';
        VATReportSetup.Modify();
    end;
}

