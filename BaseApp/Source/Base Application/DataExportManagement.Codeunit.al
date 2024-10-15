codeunit 11000 "Data Export Management"
{

    trigger OnRun()
    begin
    end;

    var
        IndentQst: Label 'There are table relations defined for the table %1. If you indent the table, the relation will be deleted. Do you want to continue?';
        UnindentQst: Label 'There are table relations defined for the table %1. If you unindent the table, the relation will be deleted. Do you want to continue?';
        RelationsExistErr: Label 'Table relations only exist for indented tables.';
        GLSetup: Record "General Ledger Setup";
        IndexNotCreatedErr: Label 'The index.xml file was not created.';

    [Scope('OnPrem')]
    procedure UpdateTableRelation(DataExportRecordSource: Record "Data Export Record Source")
    var
        DataExportTableRelationPage: Page "Data Export Table Relation";
    begin
        with DataExportRecordSource do begin
            if "Relation To Table No." = 0 then
                Error(RelationsExistErr);

            FilterGroup(2);
            SetRange("Data Export Code", "Data Export Code");
            SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
            SetRange("Line No.", "Line No.");
            FilterGroup(0);
            Clear(DataExportTableRelationPage);
            DataExportTableRelationPage.SetTableView(DataExportRecordSource);
            DataExportTableRelationPage.RunModal;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateSourceIndentation(var DataExportRecordSource: Record "Data Export Record Source"; OldIndentation: Integer)
    var
        RelDataExportRecordSource: Record "Data Export Record Source";
        FoundRelation: Boolean;
        Indented: Boolean;
    begin
        with DataExportRecordSource do begin
            CalcFields("Table Relation Defined", "Table Name");
            if "Table Relation Defined" then
                case true of
                    OldIndentation < Indentation:
                        if not Confirm(IndentQst, false, "Table Name") then begin
                            Indentation := OldIndentation;
                            exit;
                        end;
                    else
                        if not Confirm(UnindentQst, false, "Table Name") then begin
                            Indentation := OldIndentation;
                            exit;
                        end;
                end;

            FoundRelation := false;
            case true of
                Indentation < 0:
                    Indentation := 0;
                Indentation = 0:
                    begin
                        FoundRelation := true;
                        "Relation To Table No." := 0;
                        "Relation To Line No." := 0;
                    end;
                else begin
                        RelDataExportRecordSource.Copy(DataExportRecordSource);
                        if RelDataExportRecordSource.Find('<') then begin
                            if RelDataExportRecordSource.Indentation >= Indentation - 1 then begin
                                repeat
                                    if RelDataExportRecordSource.Indentation = Indentation - 1 then begin
                                        FoundRelation := true;
                                        "Relation To Table No." := RelDataExportRecordSource."Table No.";
                                        "Relation To Line No." := RelDataExportRecordSource."Line No.";
                                    end;
                                until (RelDataExportRecordSource.Next(-1) = 0) or FoundRelation;
                            end else
                                Indentation := OldIndentation;
                        end else
                            Indentation := OldIndentation
                    end;
            end;

            if FoundRelation then begin
                RelDataExportRecordSource.Copy(DataExportRecordSource);
                if RelDataExportRecordSource.Find('>') then begin
                    if OldIndentation < Indentation then begin
                        // indent:
                        repeat
                            Indented := false;
                            if RelDataExportRecordSource.Indentation > OldIndentation then begin
                                RelDataExportRecordSource.Indentation := RelDataExportRecordSource.Indentation + Indentation - OldIndentation;
                                Indented := true;
                                RelDataExportRecordSource.Modify();
                            end;
                        until (not Indented) or (RelDataExportRecordSource.Next = 0);
                    end else
                        // unindent:
                        repeat
                            Indented := false;
                            if RelDataExportRecordSource.Indentation >= OldIndentation then begin
                                RelDataExportRecordSource.Indentation := RelDataExportRecordSource.Indentation + Indentation - OldIndentation;
                                if RelDataExportRecordSource.Indentation = Indentation then begin
                                    RelDataExportRecordSource."Relation To Table No." := "Relation To Table No.";
                                    RelDataExportRecordSource."Relation To Line No." := "Relation To Line No.";
                                end;
                                RelDataExportRecordSource.Modify();
                                Indented := true;
                            end;
                        until (not Indented) or (RelDataExportRecordSource.Next = 0);
                end;
            end;

            if FoundRelation then begin
                Modify;
                DeleteTableRelation("Data Export Code", "Data Exp. Rec. Type Code", "Table No.");
            end;
        end;
    end;

    local procedure DeleteTableRelation(DataExportCode: Code[10]; RecordCode: Code[10]; TableNo: Integer)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
    begin
        DataExportTableRelation.Reset();
        DataExportTableRelation.SetRange("Data Export Code", DataExportCode);
        DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportTableRelation.SetRange("To Table No.", TableNo);
        DataExportTableRelation.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateIndexXML(var TempDataExportRecordSource: Record "Data Export Record Source" temporary; ExportPath: Text; Description: Text; StartDate: Date; EndDate: Date; DTDFileName: Text)
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        OutStr: OutStream;
        IndexFile: File;
    begin
        if DataExportRecordDefinition.Get(
             TempDataExportRecordSource."Data Export Code", TempDataExportRecordSource."Data Exp. Rec. Type Code")
        then
            ;

        IndexFile.Create(ExportPath + '\' + IndexFileName);
        IndexFile.CreateOutStream(OutStr);
        CreateIndexXmlStream(
          TempDataExportRecordSource, OutStr, Description, StartDate, EndDate,
          DTDFileName, Format(DataExportRecordDefinition."File Encoding"));
        IndexFile.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateIndexXmlStream(var TempDataExportRecordSource: Record "Data Export Record Source" temporary; OutStr: OutStream; Description: Text; StartDate: Date; EndDate: Date; DTDFileName: Text; FileEncoding: Text)
    var
        DataExportRecField: Record "Data Export Record Field";
        CompanyInfo: Record "Company Information";
        TempPKDataExportRecordField: Record "Data Export Record Field" temporary;
        TempNonPKDataExportRecordField: Record "Data Export Record Field" temporary;
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlElement;
        XMLMediaNode: DotNet XmlElement;
        Symbol: array[2] of Text[1];
    begin
        GLSetup.Get();

        if IsNull(XMLDocOut) then
            XMLDocOut := XMLDocOut.XmlDocument;

        LoadEmptyIndexXMLWithDTD(XMLDocOut, DTDFileName);

        if XMLDocOut.OuterXml = '' then
            Error(IndexNotCreatedErr);

        CompanyInfo.Get();
        XMLCurrNode := XMLDocOut.DocumentElement;
        XMLDOMManagement.AddNode(XMLCurrNode, 'Version', '');
        XMLDOMManagement.AddGroupNode(XMLCurrNode, 'DataSupplier');
        XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(CompanyName));
        XMLDOMManagement.AddNode(XMLCurrNode, 'Location',
          ConvertString(CompanyInfo.Address) + ' ' + ConvertString(CompanyInfo."Address 2") + ' ' +
          ConvertString(CompanyInfo."Post Code") + ' ' + ConvertString(CompanyInfo.City));
        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Comment', ConvertString(Description));
        if TempDataExportRecordSource.FindSet then begin
            XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Media');
            XMLMediaNode := XMLCurrNode;
            XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(TempDataExportRecordSource."Data Exp. Rec. Type Code"));
            repeat
                XMLCurrNode := XMLMediaNode;
                XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Table');
                XMLDOMManagement.AddNode(XMLCurrNode, 'URL', ConvertString(TempDataExportRecordSource."Export File Name"));
                XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(TempDataExportRecordSource."Export Table Name"));
                TempDataExportRecordSource.CalcFields("Table Name");
                XMLDOMManagement.AddNode(XMLCurrNode, 'Description', ConvertString(TempDataExportRecordSource."Table Name"));
                if TempDataExportRecordSource."Period Field No." > 0 then begin
                    XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Validity');
                    XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Range');
                    XMLDOMManagement.AddNode(XMLCurrNode, 'From', Format(StartDate, 0, '<Day,2>.<Month,2>.<Year4>'));
                    XMLDOMManagement.AddLastNode(XMLCurrNode, 'To', Format(EndDate, 0, '<Day,2>.<Month,2>.<Year4>'));
                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;
                XMLDOMManagement.AddNode(XMLCurrNode, FileEncoding, '');

                GetDelimiterSymbols(Symbol);
                XMLDOMManagement.AddNode(XMLCurrNode, 'DecimalSymbol', Symbol[1]);
                XMLDOMManagement.AddNode(XMLCurrNode, 'DigitGroupingSymbol', Symbol[2]);
                XMLDOMManagement.AddGroupNode(XMLCurrNode, 'VariableLength');
                FilterFields(DataExportRecField, TempDataExportRecordSource);
                CollectFieldNumbers(DataExportRecField, TempPKDataExportRecordField, TempNonPKDataExportRecordField);
                AddFieldsData(DataExportRecField, TempPKDataExportRecordField, 'VariablePrimaryKey', XMLCurrNode);
                AddFieldsData(DataExportRecField, TempNonPKDataExportRecordField, 'VariableColumn', XMLCurrNode);

            until TempDataExportRecordSource.Next = 0;
        end;

        XMLDocOut.Save(OutStr);
        Clear(XMLDocOut);
    end;

    local procedure GetDelimiterSymbols(var Symbol: array[2] of Text[1])
    var
        DecimalSymbol: Decimal;
    begin
        DecimalSymbol := 1 / 10;
        if StrPos(Format(DecimalSymbol, 0, 1), ',') > 0 then begin
            Symbol[1] := ',';
            Symbol[2] := '.';
        end else begin
            Symbol[1] := '.';
            Symbol[2] := ',';
        end;
    end;

    local procedure FilterFields(var DataExportRecField: Record "Data Export Record Field"; DataExportRecordSource: Record "Data Export Record Source")
    begin
        with DataExportRecField do begin
            SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
            SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
            SetRange("Table No.", DataExportRecordSource."Table No.");
            SetRange("Source Line No.", DataExportRecordSource."Line No.");
        end;
    end;

    local procedure CollectFieldNumbers(var DataExportRecField: Record "Data Export Record Field"; var TempPKDataExportRecordField: Record "Data Export Record Field" temporary; var TempNonPKDataExportRecordField: Record "Data Export Record Field" temporary)
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
    begin
        TempPKDataExportRecordField.DeleteAll();
        TempNonPKDataExportRecordField.DeleteAll();
        with DataExportRecField do
            if FindSet then begin
                RecRef.Open("Table No.");
                KeyRef := RecRef.KeyIndex(1);
                repeat
                    if FieldIsInPrimaryKey("Field No.", KeyRef) then
                        AddFieldNoToBuffer(TempPKDataExportRecordField, DataExportRecField)
                    else
                        AddFieldNoToBuffer(TempNonPKDataExportRecordField, DataExportRecField);
                until Next = 0;
                RecRef.Close;
            end;
    end;

    local procedure FieldIsInPrimaryKey(FieldNumber: Integer; var KeyRef: KeyRef): Boolean
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(i);
            if FieldRef.Number = FieldNumber then
                exit(true);
        end;
        exit(false);
    end;

    local procedure AddFieldNoToBuffer(var TempDataExportRecordField: Record "Data Export Record Field" temporary; DataExportRecField: Record "Data Export Record Field")
    begin
        with TempDataExportRecordField do begin
            Init;
            "Data Export Code" := DataExportRecField."Data Export Code";
            "Data Exp. Rec. Type Code" := DataExportRecField."Data Exp. Rec. Type Code";
            "Source Line No." := DataExportRecField."Source Line No.";
            "Table No." := DataExportRecField."Table No.";
            "Line No." := DataExportRecField."Line No.";
            "Field No." := DataExportRecField."Field No.";
            Insert;
        end;
    end;

    local procedure AddFieldsData(var DataExportRecordField: Record "Data Export Record Field"; var TempDataExportRecordField: Record "Data Export Record Field" temporary; FieldTagName: Text; XMLRootNode: DotNet XmlElement)
    var
        DataExportRecordField2: Record "Data Export Record Field";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLCurrNode: DotNet XmlElement;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        DataExportRecordField2.CopyFilters(DataExportRecordField);
        if DataExportRecordField2.FindFirst then;
        RecRef.Open(DataExportRecordField2."Table No.");
        if TempDataExportRecordField.FindSet then
            repeat
                FieldRef := RecRef.Field(TempDataExportRecordField."Field No.");

                XMLCurrNode := XMLRootNode;
                XMLDOMManagement.AddGroupNode(XMLCurrNode, FieldTagName);

                DataExportRecordField2.SetRange("Field No.", TempDataExportRecordField."Field No.");
                DataExportRecordField2.SetRange("Line No.", TempDataExportRecordField."Line No.");
                DataExportRecordField2.FindFirst;
                XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(DataExportRecordField2."Export Field Name"));
                DataExportRecordField2.CalcFields("Field Name");
                XMLDOMManagement.AddNode(XMLCurrNode, 'Description', ConvertString(DataExportRecordField2."Field Name"));

                case FieldRef.Type of
                    FieldType::Integer, FieldType::BigInteger:
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Numeric', '');
                    FieldType::Decimal:
                        begin
                            XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Numeric');
                            XMLDOMManagement.AddLastNode(XMLCurrNode, 'Accuracy',
                              CopyStr(GLSetup."Amount Decimal Places", StrLen(GLSetup."Amount Decimal Places")));
                            XMLCurrNode := XMLCurrNode.ParentNode;
                        end;
                    FieldType::Date:
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Date', '');
                    else
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'AlphaNumeric', '');
                end;
            until TempDataExportRecordField.Next = 0;
        RecRef.Close;
    end;

    [Scope('OnPrem')]
    procedure FormatForIndexXML(InputText: Text[1024]): Text[50]
    begin
        InputText := DelChr(InputText, '=', '~!$^&*(){}[]\|;:''"?/,<>@#`.-+=');
        InputText := DelChr(InputText, '=');
        exit(CopyStr(ConvertString(InputText), 1, 50));
    end;

    local procedure LoadEmptyIndexXMLWithDTD(var XMLDocOut: DotNet XmlDocument; DTDFileName: Text)
    var
        FileMgt: Codeunit "File Management";
        File: File;
        EmptyIndexXMLName: Text;
        EmptyDTDFileName: Text;
    begin
        EmptyIndexXMLName := FileMgt.ServerTempFileName('xml');
        EmptyDTDFileName := FileMgt.GetDirectoryName(EmptyIndexXMLName) + '\' + DTDFileName;
        with File do begin
            TextMode(true);

            Create(EmptyDTDFileName);
            Close;

            Create(EmptyIndexXMLName);
            Write('<?xml version="1.0" encoding="UTF-8" ?>');
            Write('<!DOCTYPE DataSet SYSTEM "' + DTDFileName + '"><DataSet />');
            Close;

            // TFS 379960 - We keep XMLDocument.Load(FileName), because the validation against DTD file doesn't work for XmlDocument.Load(XmlTextReader)
            XMLDocOut.Load(EmptyIndexXMLName);
            Erase(EmptyIndexXMLName);
            Erase(EmptyDTDFileName);
        end;
    end;

    local procedure IndexFileName(): Text[30]
    begin
        exit('index.xml');
    end;

    local procedure ConvertString(String: Text) NewString: Text
    var
        StrLength: Integer;
        i: Integer;
    begin
        StrLength := StrLen(String);
        for i := 1 to StrLength do
            if String[i] in ['Ä', 'ä', 'Ö', 'ö', 'Ü', 'ü', 'ß'] then
                NewString := NewString + ConvertSpecialChars(String[i])
            else
                NewString := NewString + Format(String[i]);
    end;

    local procedure ConvertSpecialChars(Char: Char) Text: Text[2]
    begin
        case Char of
            'Ä':
                Text := 'Ae';
            'ä':
                Text := 'ae';
            'Ö':
                Text := 'Oe';
            'ö':
                Text := 'oe';
            'Ü':
                Text := 'Ue';
            'ü':
                Text := 'ue';
            'ß':
                Text := 'ss';
        end;
        exit(Text);
    end;
}

