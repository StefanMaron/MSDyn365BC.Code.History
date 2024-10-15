codeunit 132543 "Data Exch. Def UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        Assert: Codeunit Assert;
        LibraryXMLRead: Codeunit "Library - XML Read";
        DefaultTxt: Label 'DEFAULT', Comment = 'Please translate';
        ServerFileName: Text;
        AssertIsNotTrueOnInsertFailedErr: Label 'The record should be inserted.';

    [Test]
    [Scope('OnPrem')]
    procedure InsertDataExchDef()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        DataExchDefCard.OpenNew;
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK.Invoke;

        // Verify
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Name, DataExchDef.Code);
        DataExchLineDef.Get(DataExchDef.Code, DefaultTxt);
        DataExchLineDef.TestField(Code, DefaultTxt);
        DataExchLineDef.TestField(Name, DefaultTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDataExchDef()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        DataExchDefCard.OpenNew;
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK.Invoke;
        DataExchDef.Get(DataExchCode);

        // Pre-Verify
        Assert.IsTrue(DataExchLineDef.Get(DataExchDef.Code, DefaultTxt), '');

        // Exercise
        DataExchDef.Delete(true);

        // Verify
        Assert.IsFalse(DataExchLineDef.Get(DataExchDef.Code, DefaultTxt), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsNonXMLFileType()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        // Verify
        Assert.IsTrue(DataExchDef.CheckEnableDisableIsNonXMLFileType, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsImportTypePaymentExport()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Init
        DataExchDef."File Type" := DataExchDef."File Type"::"Variable Text";

        // Setup
        DataExchDef.Validate(Type, DataExchDef.Type::"Payment Export");

        // Verify
        Assert.IsFalse(DataExchDef.CheckEnableDisableIsImportType, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsImportTypePayrollImport()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate(Type, DataExchDef.Type::"Payroll Import");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::Xml);

        // Verify
        Assert.IsFalse(DataExchDef.CheckEnableDisableIsImportType, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableDelimitedFileType()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");

        // Verify
        Assert.IsTrue(DataExchDef.CheckEnableDisableDelimitedFileType, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineDefititionsForImportAreAllowed()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef1: Record "Data Exch. Line Def";
        DataExchLineDef2: Record "Data Exch. Line Def";
    begin
        // Pre-Setup
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID;
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Insert(true);

        // Setup
        DataExchLineDef1.Init();
        DataExchLineDef1."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef1.Code := LibraryUtility.GenerateGUID;
        DataExchLineDef1.Insert(true);

        // Exercise
        DataExchLineDef2.Init();
        DataExchLineDef2."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef2.Code := LibraryUtility.GenerateGUID;
        DataExchLineDef2.Insert(true);

        // Verify: no error was raised.
    end;

    [Test]
    [HandlerFunctions('MappingPageHandler')]
    [Scope('OnPrem')]
    procedure SetCustomType()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDefCard.OpenNew;
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK.Invoke;

        DataExchDef.Get(DataExchCode);
        DataExchDef.Type := 1000;
        DataExchDef.Modify();

        // Verify - Check is done in handler
        DataExchDefCard.OpenView;
        DataExchDefCard.GotoRecord(DataExchDef);

        DataExchDefCard."Line Definitions"."Field Mapping".Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MappingPageHandler(var MappingPage: TestPage "Data Exch Mapping Card")
    begin
        Assert.AreEqual(0, MappingPage."Table ID".AsInteger, 'There must be no default mapping for custom Types');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesAreCreatedInTable()
    var
        DataExchLineType: Option Detail,Header,Footer;
    begin
        // Scenario 1: New Data Exch. Line Type can be set on the page and is saved correctly.
        ValidateUISavesLineType(DataExchLineType::Header);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesExport()
    var
        DataExchLineType: Option Detail,Header,Footer;
    begin
        // Scenario 2: Export of Data Exchange Definition correctly captures the new Line Type field value
        ValidateExportOfLineType(DataExchLineType::Header);
        ValidateExportOfLineType(DataExchLineType::Detail);
        ValidateExportOfLineType(DataExchLineType::Footer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesImport()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef1: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        InputFile: File;
        OutStream: OutStream;
        InStream: InStream;
        DataExchCode: Code[20];
        DataExchLineType: Option Detail,Header,Footer;
        LineTypeCount: Integer;
    begin
        // Secnario 3: Import of Data Exchange Definition correctly recreates new Line Type field values
        // Pre-Setup
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID;
        DataExchCode := DataExchDef.Code;
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Insert(true);

        InsertLineTypeRecords(DataExchCode, DataExchLineType::Header, '');
        InsertLineTypeRecords(DataExchCode, DataExchLineType::Detail, '');
        InsertLineTypeRecords(DataExchCode, DataExchLineType::Footer, '');

        // Export Data Exch Def with 3 line records via XML1225 to file BLAH
        DataExchDef.SetRange(Code, DataExchCode);
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close;

        // Remove Header and Line Records just saved.
        RemoveDataExch(DataExchCode);

        // Import file via XML1225
        InputFile.Open(ServerFileName);
        InputFile.CreateInStream(InStream);
        XMLPORT.Import(XMLPORT::"Imp / Exp Data Exch Def & Map", InStream);

        // Verify that there are 3 records in 1227 table with different Line Types.
        LineTypeCount := 1;
        DataExchLineDef1.SetRange("Data Exch. Def Code", DataExchCode);
        if DataExchLineDef1.FindSet then begin
            repeat
                case LineTypeCount of
                    1:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Header);
                    2:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Detail);
                    3:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Footer);
                end;

                LineTypeCount := LineTypeCount + 1;
            until DataExchLineDef1.Next = 0;
        end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLinesImportWhenDescendantGoesFirstAlphabetically()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        InputFile: File;
        InStream: InStream;
        DataExchLineType: Option Detail,Header,Footer;
        ParentCode: Code[20];
    begin
        // [SCENARIO 381089] When descendant Data Exch. Def. Line goes before parent alphabetically, then export and import of such Data Exch. Def. should not cause an error

        // [GIVEN] Data Exch. Def.
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID);
        DataExchDef.Validate(Type, DataExchDef.Type::"Bank Statement Import");
        DataExchDef.Insert(true);

        // [GIVEN] Data Exch. Def. Line ZZZ, which surely be last alphabetically
        InsertLineTypeRecords(DataExchDef.Code, DataExchLineType::Detail, 'Z');
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindLast;
        ParentCode := DataExchLineDef.Code;

        // [GIVEN] Data Exch. Def. Line AAA, which surely be 1st alphabetically and has ZZZ as "Parent Code"
        InsertLineTypeRecords(DataExchDef.Code, DataExchLineType::Detail, 'A');
        DataExchLineDef.FindFirst;
        DataExchLineDef.Validate("Parent Code", ParentCode);
        DataExchLineDef.Modify(true);

        // [GIVEN] Export Data Exch Def with 2 lines via XMLPort "Imp / Exp Data Exch Def & Map" to file
        DataExchDef.SetRecFilter;
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportViaXMLPort(DataExchDef);

        // [GIVEN] Data Exch. Def. header and lines are deleted
        RemoveDataExch(DataExchDef.Code);

        // [WHEN] Import file via XMLPort "Imp / Exp Data Exch Def & Map"
        InputFile.Open(ServerFileName);
        InputFile.CreateInStream(InStream);
        XMLPORT.Import(XMLPORT::"Imp / Exp Data Exch Def & Map", InStream);

        // [THEN] There are 2 records in "Data Exch. Line Def" table and no errors appeared
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        Assert.RecordCount(DataExchLineDef, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnModifyDefinitionCheckPositivePayExportFileTypeFixedText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] When the Data Exch. Def. "Type" has value of "Positive Pay Export", then the "File Type" can be changed to "Fixed Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition inserted
        // [GIVEN] Validating "Type" as "Positive Pay Export" and "File Type" as "Fixed Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID);
        DataExchDef.Insert(true);
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");

        // [WHEN] Modify the record
        DataExchDef.Modify(true);

        // [THEN] The record is modified and "File Type" as "Fixed Text" is saved
        DataExchDef.Find;
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Fixed Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnModifyDefinitionCheckPositivePayExportFileTypeVariableText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] When the Data Exch. Def. "Type" has value of "Positive Pay Export", then the "File Type" can be changed to "Variable Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition inserted
        // [GIVEN] Validating "Type" as "Positive Pay Export" and "File Type" as "Variable Text" and modify the record
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID);
        DataExchDef.Insert(true);
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");

        // [WHEN] Modify the record
        DataExchDef.Modify(true);

        // [THEN] The record is modified and "File Type" as "Variable Text" is saved
        DataExchDef.Find;
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Variable Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnInsertDefinitionCheckPositivePayExportFileTypeFixedText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] A newly created Data Exch. Def. with "Type" of "Positive Pay Export" can have "File Type" as "Fixed Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition
        // [GIVEN] Validate "Type" as "Positive Pay Export" and "File Type" as "Fixed Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID);
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");

        // [WHEN] Insert a record
        DataExchDef.Insert(true);

        // [THEN] The record is inserted with "File Type" as "Fixed Text"
        Assert.IsTrue(DataExchDef.Find, AssertIsNotTrueOnInsertFailedErr);
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Fixed Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnInsertDefinitionCheckPositivePayExportFileTypeVariableText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] A newly created Data Exch. Def. with "Type" of "Positive Pay Export" can have "File Type" as "Variable Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition
        // [GIVEN] Validate "Type" as "Positive Pay Export" and "File Type" as "Variable Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID);
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");

        // [WHEN] Insert a record
        DataExchDef.Insert(true);

        // [THEN] The record is inserted with "File Type" as "Variable Text"
        Assert.IsTrue(DataExchDef.Find, AssertIsNotTrueOnInsertFailedErr);
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Variable Text");
    end;

    local procedure ExportViaXMLPort(var DataExchDef: Record "Data Exch. Def")
    var
        ExportFile: File;
        OutStream: OutStream;
    begin
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close;
    end;

    local procedure RemoveDataExch(DataExchDefCode: Code[20])
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchDef.SetRange(Code, DataExchDefCode);
        DataExchDef.DeleteAll(true);

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.DeleteAll(true);
    end;

    local procedure ValidateExportOfLineType(LineType: Option Detail,Header,Footer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
        DataExchCode: Code[20];
        OptionNumber: Integer;
    begin
        // Setup for Line Type validation
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID;
        DataExchCode := DataExchDef.Code;
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Insert(true);
        OptionNumber := LineType;

        DataExchLineDef.Init();
        DataExchLineDef.Code := LibraryUtility.GenerateGUID;
        DataExchLineDef."Data Exch. Def Code" := DataExchCode;
        DataExchLineDef."Line Type" := OptionNumber;
        DataExchLineDef.Insert(true);

        // Export Data Exch Def with Header Type line record via XML1225 to XML file
        DataExchDef.SetRange(Code, DataExchCode);
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close;

        // Verify that element in XML file with <LineType> tag of Header.
        if FileManagement.ClientFileExists(ServerFileName) then
            LibraryXMLRead.Initialize(ServerFileName)
        else
            LibraryXMLRead.Initialize(FileManagement.DownloadTempFile(ServerFileName));
        LibraryXMLRead.VerifyAttributeValueInSubtree('DataExchDef', 'DataExchLineDef', 'LineType', Format(OptionNumber));
    end;

    local procedure ValidateUISavesLineType(DataExchLineType: Option Detail,Header,Footer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup for Detail Line Type
        DataExchDefCard.OpenNew;
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard."Line Definitions"."Line Type".SetValue(DataExchLineType);
        DataExchDefCard.OK.Invoke;

        // Verify record saved, Line Type should equal Line Type passed in.
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Name, DataExchDef.Code);
        DataExchLineDef.Get(DataExchDef.Code, DefaultTxt);
        DataExchLineDef.TestField(Code, DefaultTxt);
        DataExchLineDef.TestField(Name, DefaultTxt);
        DataExchLineDef.TestField("Line Type", DataExchLineType);
    end;

    local procedure InsertLineTypeRecords(DataExchCode: Code[20]; DataExchLineType: Option Detail,Header,Footer; LineCodePrefix: Code[1])
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        DataExchLineDef.Init();
        DataExchLineDef.Code := LineCodePrefix + LibraryUtility.GenerateGUID;
        DataExchLineDef."Data Exch. Def Code" := DataExchCode;
        DataExchLineDef."Line Type" := DataExchLineType;
        DataExchLineDef."Column Count" := 1;
        DataExchLineDef.Insert(true);

        DataExchColDef.Init();
        DataExchColDef."Data Exch. Def Code" := DataExchCode;
        DataExchColDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColDef."Column No." := 1;
        DataExchColDef.Name := 'Column1';
        DataExchColDef.Insert(true);

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchCode;
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := 271;
        DataExchMapping.Insert(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchFieldMapping."Table ID" := 271;
        DataExchFieldMapping."Column No." := 1;
        DataExchFieldMapping."Field ID" := 1;
        DataExchFieldMapping.Insert(true);
    end;
}

