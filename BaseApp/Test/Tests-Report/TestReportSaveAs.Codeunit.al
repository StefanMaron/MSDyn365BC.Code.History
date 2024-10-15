codeunit 134607 "Test Report SaveAs"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Report Outbox]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestRdlcSaveAsPDF()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SaveAsType(REPORT::"Test Report - Default=RDLC", JobQueueEntry."Report Output Type"::PDF, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWordSaveAsPDF()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SaveAsType(REPORT::"Test Report - Default=Word", JobQueueEntry."Report Output Type"::PDF, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRdlcSaveAsWord()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SaveAsType(REPORT::"Test Report - Default=RDLC", JobQueueEntry."Report Output Type"::Word, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWordSaveAsWord()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SaveAsType(REPORT::"Test Report - Default=Word", JobQueueEntry."Report Output Type"::Word, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRdlcSaveAsExcel()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SaveAsType(REPORT::"Test Report - Default=RDLC", JobQueueEntry."Report Output Type"::Excel, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWordSaveAsExcel()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        asserterror SaveAsType(REPORT::"Test Report - Default=Word", JobQueueEntry."Report Output Type"::Excel, JobQueueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRdlcSaveAsPDFClassic()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('pdf');
        REPORT.SaveAsPdf(REPORT::"Test Report - Default=RDLC", FileName);
        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWordSaveAsPDFClassic()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('pdf');
        REPORT.SaveAsPdf(REPORT::"Test Report - Default=Word", FileName);
        FileManagement.DeleteServerFile(FileName);
    end;

    local procedure SaveAsType(ReportID: Integer; OutputType: Enum "Job Queue Report Output Type"; var JobQueueEntry: Record "Job Queue Entry")
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        with JobQueueEntry do begin
            Init();
            "Object Type to Run" := "Object Type to Run"::Report;
            "Object ID to Run" := ReportID;
            "Report Output Type" := OutputType;
            Description := Format(ReportID);
            "Run in User Session" := true;
            Insert(true);
        end;
        Commit();

        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        VerifyReportOutBox(JobQueueEntry);
    end;

    local procedure VerifyReportOutBox(var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.FindLast();
        Assert.AreEqual(JobQueueEntry.Description, ReportInbox.Description, '');
        ReportInbox.CalcFields("Report Output");
        Assert.IsTrue(ReportInbox."Report Output".HasValue, '');
        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::PDF:
                Assert.AreEqual(ReportInbox."Output Type"::PDF, ReportInbox."Output Type", '');
            JobQueueEntry."Report Output Type"::Word:
                Assert.AreEqual(ReportInbox."Output Type"::Word, ReportInbox."Output Type", '');
            JobQueueEntry."Report Output Type"::Excel:
                Assert.AreEqual(ReportInbox."Output Type"::Excel, ReportInbox."Output Type", '');
        end;

        // Cleanup
        ReportInbox.Delete();
    end;
}

