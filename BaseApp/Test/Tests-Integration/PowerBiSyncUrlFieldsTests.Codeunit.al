codeunit 134238 "PowerBI-Sync URL fields tests"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The object will be removed with obsoleted field G/L Bank Account No.';
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Power BI]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";

    // table 6302 "Power BI Report Buffer"

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportBuffer_Validate_EmbedUrlToReportEmbedUrl()
    var
        DummyPowerBiReportBuffer: Record "Power BI Report Buffer";
    begin
        Validate_Short_Into_Long(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportBuffer_Validate_ReportEmbedUrlToEmbedUrl()
    var
        DummyPowerBiReportBuffer: Record "Power BI Report Buffer";
    begin
        Validate_Long_Into_Short(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportBuffer_Insert()
    var
        DummyPowerBiReportBuffer: Record "Power BI Report Buffer";
    begin
        Insert_Long_Into_Short(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl)
            );

        Insert_Short_Into_Long(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportBuffer_Modify()
    var
        DummyPowerBiReportBuffer: Record "Power BI Report Buffer";
    begin
        Modify_Long_Into_Short(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl)
            );

        Modify_Short_Into_Long(DummyPowerBiReportBuffer.RecordId().TableNo(),
            DummyPowerBiReportBuffer.FieldNo(EmbedUrl),
            DummyPowerBiReportBuffer.FieldNo(ReportEmbedUrl)
            );
    end;

    // table 6301 "Power BI Report Configuration"

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportConfig_Validate_EmbedUrlToReportEmbedUrl()
    var
        DummyPowerBiReportConfig: Record "Power BI Report Configuration";
    begin
        Validate_Short_Into_Long(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportConfig_Validate_ReportEmbedUrlToEmbedUrl()
    var
        DummyPowerBiReportConfig: Record "Power BI Report Configuration";
    begin
        Validate_Long_Into_Short(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportConfig_Insert()
    var
        DummyPowerBiReportConfig: Record "Power BI Report Configuration";
    begin
        Insert_Long_Into_Short(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl)
            );

        Insert_Short_Into_Long(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl)
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportConfig_Modify()
    var
        DummyPowerBiReportConfig: Record "Power BI Report Configuration";
    begin
        Modify_Long_Into_Short(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl)
            );

        Modify_Short_Into_Long(DummyPowerBiReportConfig.RecordId().TableNo(),
            DummyPowerBiReportConfig.FieldNo(EmbedUrl),
            DummyPowerBiReportConfig.FieldNo(ReportEmbedUrl)
            );
    end;

    // table 6307 "Power BI Report Uploads"

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportUpl_Validate_EmbedUrlToReportEmbedUrl()
    var
        DummyPowerBiReportUploads: Record "Power BI Report Uploads";
    begin
        Validate_Short_Into_Long(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url")
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportUpl_Validate_ReportEmbedUrlToEmbedUrl()
    var
        DummyPowerBiReportUploads: Record "Power BI Report Uploads";
    begin
        Validate_Long_Into_Short(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Embed Url")
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportUploads_Insert()
    var
        DummyPowerBiReportUploads: Record "Power BI Report Uploads";
    begin
        Insert_Long_Into_Short(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Embed Url")
            );

        Insert_Short_Into_Long(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url")
            );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sync_PowerBiReportUploads_Modify()
    var
        DummyPowerBiReportUploads: Record "Power BI Report Uploads";
    begin
        Modify_Long_Into_Short(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Embed Url")
            );

        Modify_Short_Into_Long(DummyPowerBiReportUploads.RecordId().TableNo(),
            DummyPowerBiReportUploads.FieldNo("Embed Url"),
            DummyPowerBiReportUploads.FieldNo("Report Embed Url")
            );
    end;

    // Local procedures

    local procedure Validate_Short_Into_Long(TableNumberToTest: Integer; ShortFieldNumber: Integer; LongFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record: validate twice and then set empty
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        TempText := '';
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Temporary record: validate twice and then set empty
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        TempText := '';
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);
    end;

    local procedure Validate_Long_Into_Short(TableNumberToTest: Integer; LongFieldNumber: Integer; ShortFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record: validate twice and then set empty
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');

        TempText := '';
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Temporary record: validate twice and then set empty
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');

        TempText := '';
        Validate_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);
    end;

    local procedure Insert_Short_Into_Long(TableNumberToTest: Integer; ShortFieldNumber: Integer; LongFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
        TempText2: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record: set field and insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Temporary record: set field and insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record: set field and insert with trigger
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Insert(true);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record: validate, change and then insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText2 := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText2);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText); // If the values are different, keep the long one
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText); // If the values are different, keep the long one

        // Non-temporary record: validate, change and then insert with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText2 := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText2);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText2); // If the values are different, keep the long one
        Assert_Field(RecordRefToProcess, ShortFieldNumber, ''); // If the values are different, keep the long one
    end;

    local procedure Insert_Long_Into_Short(TableNumberToTest: Integer; LongFieldNumber: Integer; ShortFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record: set field and insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Temporary record: set field and insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-Temporary record: set field and insert with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');

        // Non-temporary record: set field and insert with trigger
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(true);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record: validate, change and then insert
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record: validate, change and then insert with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, false);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Insert(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');
    end;

    local procedure Modify_Short_Into_Long(TableNumberToTest: Integer; ShortFieldNumber: Integer; LongFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
        TempText2: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record empty: set field and modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Temporary record empty: set field and modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record empty: set field and modify with trigger
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(true);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record: validate, change and then modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText2 := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText2);
        RecordRefToProcess.Modify(false); // Both fields changed, the longer one wins
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record: validate, modify, change and then modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);
    end;

    local procedure Modify_Long_Into_Short(TableNumberToTest: Integer; LongFieldNumber: Integer; ShortFieldNumber: Integer)
    var
        RecordRefToProcess: RecordRef;
        LongFieldMaxLen: Integer;
        ShortFieldMaxLen: Integer;
        TempText: Text;
    begin
        // Initialize
        RecordRefToProcess.Open(TableNumberToTest, false);
        LongFieldMaxLen := RecordRefToProcess.Field(LongFieldNumber).Length();
        ShortFieldMaxLen := RecordRefToProcess.Field(ShortFieldNumber).Length();

        // Non-temporary record empty: set field and modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record empty: set field and modify with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');

        // Temporary record empty: set field and modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, true);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, LongFieldNumber, TempText);

        // Non-temporary record empty: set field and modify with trigger
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(true);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record: validate, change and then modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record: validate, change and then modify with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');

        // Non-temporary record: validate, modify, change and then modify
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);

        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, TempText);

        // Non-temporary record: validate, modify, change and then modify with overflow
        Clear(RecordRefToProcess);
        RecordRefToProcess.Open(TableNumberToTest, false);
        CreateRecordForTable(RecordRefToProcess, true);
        TempText := LibraryRandom.RandText(ShortFieldMaxLen);
        Validate_Fld(RecordRefToProcess, ShortFieldNumber, TempText);
        RecordRefToProcess.Modify(false);

        TempText := LibraryRandom.RandText(LongFieldMaxLen);
        SetValue_Fld(RecordRefToProcess, LongFieldNumber, TempText);
        RecordRefToProcess.Modify(false);
        Assert_Field(RecordRefToProcess, ShortFieldNumber, '');
    end;

    local procedure Validate_Fld(var RecordRefToProcess: RecordRef; FieldToValidate: Integer; ValueToValidate: Text)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecordRefToProcess.Field(FieldToValidate);
        FldRef.Validate(ValueToValidate);
    end;

    local procedure SetValue_Fld(var RecordRefToProcess: RecordRef; FieldToSet: Integer; ValueToSet: Text)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecordRefToProcess.Field(FieldToSet);
        FldRef.Value(ValueToSet);
    end;

    local procedure Assert_Field(var RecordRefToProcess: RecordRef; FieldToCheck: Integer; ValueToCheck: Text)
    var
        Assert: Codeunit Assert;
        FldRef: FieldRef;
    begin
        FldRef := RecordRefToProcess.Field(FieldToCheck);
        if Format(FldRef.Value()) <> ValueToCheck then
            Assert.Fail(StrSubstNo('Unexpected value in field %1 of record %2. Values truncated to 20: Expected: ''%3'', Actual: ''%4''', FldRef.Name(), RecordRefToProcess.Name(),
                CopyStr(ValueToCheck, 1, 20), CopyStr(Format(FldRef.Value()), 1, 20)));
    end;

    local procedure CreateRecordForTable(var RecordRefToCreate: RecordRef; doInsert: Boolean)
    var
        FldRef: FieldRef;
        KRef: KeyRef;
        FldType: FieldType;
        i: Integer;
    begin
        KRef := RecordRefToCreate.KeyIndex(1);

        // For PowerBI, in the keys we only have guids and text at the moment
        for i := 1 to KRef.FieldCount() do begin
            FldRef := KRef.FieldIndex(1);
            case FldRef.Type() of
                FldType::Guid:
                    FldRef.Value(CreateGuid());
                FldType::Text:
                    FldRef.Value(LibraryRandom.RandText(FldRef.Length()));
                else
                    Error('FieldType not supported for setup: %1', FldRef.Type());
            end;
        end;

        if doInsert then
            RecordRefToCreate.Insert(true);
    end;
}
