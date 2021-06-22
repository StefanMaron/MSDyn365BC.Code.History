codeunit 131007 "Library - Report Dataset"
{
    // This library is used to verify the data output of a report
    // There are 2 possible layouts:
    // Old layout - Created by TestRequestPage.SaveAsXML - this one is serializing the output of report previewer (will be deprecated in the future)
    // New layout - Created by REPORT.SaveAs or REPORT.SaveAsXML - this one should be used for new tests
    // For new layout the functions with Tag in the name cannot be used, since the schema does not use tags


    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        InvalidRowErr: Label 'Row does not exist.';
        InvalidFieldErr: Label 'Field ''%1'' does not exist.';
        RowNotFoundErr: Label 'No row found where Field ''%1'' = <%2>.', Locked = true;
        RowFoundErr: Label 'Row is found where Field ''%1'' = <%2>.', Locked = true;
        CurrentRowErr: Label 'Current row does not have Field ''%1'' = <%2>.', Locked = true;
        ElementNotFoundInScemaErr: Label 'Field ''%1'' was not found in the embedded xml schema.';
        RowIndexErr: Label 'Invalid row index: %1';
        ElementNameErr: Label 'Element with name ''%1'' was not found';
        RowIndexNotFoundErr: Label 'Could not find row with index %1 in report dataset';
        NameTagTxt: Label 'Name', Locked = true;
        StringTagTxt: Label 'string', Locked = true;
        XmlDoc: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
        SchemaNodeList: DotNet XmlNodeList;
        XMLSchemaType: Option ReportPreview,XML;
        FunctionNotSupportedForXMLErr: Label 'The function is not supported for XML Dataset. Functions with Tag cannot be used, use the functions named Element.';
        DataSetFileName: Text;
        ParametersFileName: Text;
        CurrentRowIndex: Integer;

    procedure AssertElementTagExists(ElementTag: Text)
    begin
        VerifyTagIsSupported;
        SetXmlNodeList(ElementTag);
        Assert.IsTrue(
          FindRowWithTagNoValue(ElementTag) <> -1,
          StrSubstNo(RowNotFoundErr, ElementTag, ''))
    end;

    procedure AssertElementTagWithValueExists(ElementTag: Text; ExpectedValue: Variant)
    begin
        VerifyTagIsSupported;
        SetXmlNodeList(ElementTag);
        Assert.IsTrue(
          SearchForElementTagByValue(ElementTag, ExpectedValue),
          StrSubstNo(RowNotFoundErr, ElementTag, ExpectedValue))
    end;

    procedure AssertElementTagWithValueNotExist(ElementTag: Text; ExpectedValue: Variant)
    begin
        VerifyTagIsSupported;
        SetXmlNodeList(ElementTag);
        Assert.IsFalse(
          SearchForElementTagByValue(ElementTag, ExpectedValue),
          StrSubstNo(RowNotFoundErr, ElementTag, ExpectedValue))
    end;

    procedure AssertElementWithValueExists(ElementName: Text; ExpectedValue: Variant)
    begin
        Assert.IsTrue(
          SearchForElementByValue(ElementName, ExpectedValue),
          StrSubstNo(RowNotFoundErr, ElementName, ExpectedValue))
    end;

    procedure AssertElementWithValueNotExist(ElementName: Text; ExpectedValue: Variant)
    begin
        Assert.IsFalse(
          SearchForElementByValue(ElementName, ExpectedValue),
          StrSubstNo(RowFoundErr, ElementName, ExpectedValue))
    end;

    procedure AssertCurrentRowValueEquals(ElementName: Text; ExpectedValue: Variant)
    var
        Value: Variant;
    begin
        FindCurrentRowValue(ElementName, Value);
        ConvertValue(ExpectedValue, Value);
        Assert.AreEqual(ExpectedValue, Value,
          StrSubstNo(CurrentRowErr, ElementName, ExpectedValue));
    end;

    procedure AssertCurrentRowValueNotEquals(ElementName: Text; ExpectedValue: Variant)
    var
        Value: Variant;
    begin
        FindCurrentRowValue(ElementName, Value);
        ConvertValue(ExpectedValue, Value);
        Assert.AreNotEqual(ExpectedValue, Value,
          StrSubstNo(CurrentRowErr, ElementName, ExpectedValue));
    end;

    procedure AssertParameterValueExists(ParameterName: Text; ExpectedValue: Text)
    var
        ParameterNameRow: Integer;
        ValueNameRow: Integer;
    begin
        SetXmlNodeList(NameTagTxt);
        ParameterNameRow := FindRowWithTag(NameTagTxt, ParameterName);
        Assert.IsTrue(
          ParameterNameRow <> -1,
          StrSubstNo(RowNotFoundErr, NameTagTxt, ParameterName));

        SetXmlNodeList(StringTagTxt);
        ValueNameRow := FindRowWithTag(StringTagTxt, ExpectedValue);
        Assert.IsTrue(
          ValueNameRow <> -1,
          StrSubstNo(RowNotFoundErr, StringTagTxt, ExpectedValue));

        while (ValueNameRow <> -1) and (ValueNameRow < ParameterNameRow) do begin
            MoveToRow(ValueNameRow + 1);
            ValueNameRow := FindRowWithTag(StringTagTxt, ExpectedValue);
        end;

        Assert.IsTrue(
          ParameterNameRow = ValueNameRow,
          StrSubstNo(RowNotFoundErr, ParameterName, ExpectedValue))
    end;

    procedure CurrentRowHasElementTag(ElementName: Text): Boolean
    var
        XmlNode: DotNet XmlNode;
    begin
        XmlNode := XmlNodeList.Item(CurrentRowIndex);
        exit(XmlNode.Name = ElementName);
    end;

    procedure CurrentRowHasElement(ElementName: Text): Boolean
    var
        XmlNode: DotNet XmlNode;
    begin
        XmlNode := XmlNodeList.Item(CurrentRowIndex);

        case XMLSchemaType of
            XMLSchemaType::ReportPreview:
                exit(not IsNull(XmlNode.Item(ElementName)));
            XMLSchemaType::XML:
                exit(NameAttributeMatchesValue(XmlNode, ElementName));
        end;
    end;

    procedure FindCurrentRowTagValue(ElementTag: Text; var Value: Variant)
    var
        XmlNode: DotNet XmlNode;
        ElementText: Text;
    begin
        VerifyTagIsSupported;

        if CurrentRowIndex = -1 then
            Error(InvalidRowErr);

        XmlNode := XmlNodeList.Item(CurrentRowIndex);

        if not CurrentRowHasElementTag(ElementTag) then
            Error(InvalidFieldErr, ElementTag);

        ElementText := XmlNode.InnerText;
        Value := ElementText;
    end;

    procedure FindCurrentRowValue(ElementName: Text; var Value: Variant)
    var
        XmlNode: DotNet XmlNode;
        ElementText: Text;
        Decimal: Decimal;
        "Integer": Integer;
        Boolean: Boolean;
    begin
        if CurrentRowIndex = -1 then
            Error(InvalidRowErr);

        XmlNode := XmlNodeList.Item(CurrentRowIndex);
        if not CurrentRowHasElement(ElementName) then
            Error(InvalidFieldErr, ElementName);

        if XMLSchemaType = XMLSchemaType::XML then begin
            Value := XmlNode.InnerText;
            exit;
        end;

        ElementText := XmlNode.Item(ElementName).InnerText;

        case GetElementSchemaType(ElementName) of
            'xs:boolean':
                begin
                    Evaluate(Boolean, ElementText, 9);
                    Value := Boolean;
                end;
            'xs:int':
                begin
                    Evaluate(Integer, ElementText, 9);
                    Value := Integer;
                end;
            'xs:decimal':
                begin
                    Evaluate(Decimal, ElementText, 9);
                    Value := Decimal;
                end;
            else
                Value := ElementText;
        end;
    end;

    local procedure GetElementSchemaType(ElementName: Text): Text
    var
        i: Integer;
    begin
        for i := 0 to SchemaNodeList.Count - 1 do begin
            if SchemaNodeList.Item(i).Attributes.GetNamedItem('name').Value = ElementName then
                exit(SchemaNodeList.Item(i).Attributes.GetNamedItem('type').Value);
        end;
        Error(ElementNotFoundInScemaErr, ElementName);
    end;

    procedure "Sum"(ElementName: Text) TotalValue: Decimal
    var
        ValueVar: Variant;
        Value: Decimal;
    begin
        while GetNextRow do
            if CurrentRowHasElement(ElementName) then begin
                FindCurrentRowValue(ElementName, ValueVar);
                Value := ValueVar;
                TotalValue += Value;
            end;

        CurrentRowIndex := -1
    end;

    procedure GetNextRow(): Boolean
    begin
        if CurrentRowIndex < RowCount - 1 then begin
            CurrentRowIndex += 1;
            exit(true);
        end;
        exit(false)
    end;

    procedure MoveToRow(RowIndex: Integer)
    begin
        // Assume incoming index is in range  1..Count (like arrays in C/AL)
        // Dataset indices start from 0.. thus we need compare CurrentRowIndex with passed decremented (by 1) RowIndex
        CurrentRowIndex := -1;
        while GetNextRow and (CurrentRowIndex <> (RowIndex - 1)) do;
        if not ((CurrentRowIndex = (RowIndex - 1)) and (CurrentRowIndex > -1)) then
            Error(StrSubstNo(RowIndexNotFoundErr, RowIndex));
    end;

    procedure GetFileName(): Text[1024]
    begin
        DataSetFileName := FileManagement.ServerTempFileName('.xml');
        exit(DataSetFileName)
    end;

    procedure SetFileName(FileName: Text)
    begin
        DataSetFileName := FileName;
    end;

    procedure GetParametersFileName(): Text
    begin
        ParametersFileName := FileManagement.ServerTempFileName('.xml');
        exit(ParametersFileName)
    end;

    procedure RunReportAndLoad(ReportID: Integer; RecordVariant: Variant; RequestPageParametersXML: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        DataTypeManagement: Codeunit "Data Type Management";
        ReportOutStream: OutStream;
        ReportInStream: InStream;
        ReportRecordRef: RecordRef;
    begin
        TempBlob.CreateOutStream(ReportOutStream);

        if DataTypeManagement.GetRecordRef(RecordVariant, ReportRecordRef) then
            REPORT.SaveAs(ReportID, RequestPageParametersXML, REPORTFORMAT::Xml, ReportOutStream, ReportRecordRef)
        else
            REPORT.SaveAs(ReportID, RequestPageParametersXML, REPORTFORMAT::Xml, ReportOutStream);

        TempBlob.CreateInStream(ReportInStream);

        LoadFromInStream(ReportInStream);
    end;

    procedure LoadFromInStream(DataSetInStream: InStream)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        DatasetXMLText: Text;
        XMLStartIndex: Integer;
    begin
        DataSetInStream.Read(DatasetXMLText);
        // Remove junk characters
        XMLStartIndex := StrPos(DatasetXMLText, '<?xml');
        if XMLStartIndex > 0 then
            DatasetXMLText := CopyStr(DatasetXMLText, XMLStartIndex);

        XMLSchemaType := XMLSchemaType::XML;
        XMLDOMManagement.LoadXMLDocumentFromText(DatasetXMLText, XmlDoc);
        InitializeGlobals(false);
    end;

    procedure LoadDataSetFileWithNoSchema()
    begin
        LoadXMLFile(DataSetFileName, false);
    end;

    procedure LoadDataSetFile()
    begin
        LoadXMLFile(DataSetFileName, true);
    end;

    procedure LoadParametersFile()
    begin
        LoadXMLFile(ParametersFileName, false);
    end;

    local procedure LoadXMLFile(FileName: Text; "Schema": Boolean)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FileName, XmlDoc);
        InitializeGlobals(Schema);
    end;

    local procedure InitializeGlobals("Schema": Boolean)
    begin
        CurrentRowIndex := -1;

        if Schema then
            SchemaNodeList := XmlDoc.GetElementsByTagName('xs:sequence').Item(0).ChildNodes
        else
            Clear(SchemaNodeList);

        Clear(XmlNodeList);

        // Clear filename to avoid consecutive tests to validate pre-existing data
        DataSetFileName := '';
        ParametersFileName := '';
    end;

    procedure SetRange(ElementName: Text; Value: Variant)
    begin
        SetRangeWithTrimmedValues(ElementName, Value, false)
    end;

    procedure Reset()
    begin
        Clear(XmlNodeList);
        CurrentRowIndex := -1
    end;

    procedure RowCount(): Integer
    begin
        if IsNull(XmlNodeList) then
            case XMLSchemaType of
                XMLSchemaType::ReportPreview:
                    XmlNodeList := XmlDoc.GetElementsByTagName('Result');
                XMLSchemaType::XML:
                    XmlNodeList := XmlDoc.GetElementsByTagName('Column');
            end;

        exit(XmlNodeList.Count);
    end;

    local procedure SearchForElementTagByValue(ElementTag: Text; ElementValue: Variant): Boolean
    begin
        exit(FindRowWithTag(ElementTag, ElementValue) <> -1);
    end;

    procedure SearchForElementByValue(ElementName: Text; ElementValue: Variant): Boolean
    begin
        exit(FindRow(ElementName, ElementValue) <> -1);
    end;

    procedure FindRowWithTagNoValue(ElementTag: Text) Result: Integer
    begin
        while GetNextRow do
            if CurrentRowHasElementTag(ElementTag) then begin
                Result := CurrentRowIndex;
                CurrentRowIndex := -1;
                exit(Result);
            end;

        CurrentRowIndex := -1;
        Result := -1;
        exit(Result);
    end;

    procedure FindRowWithTag(ElementTag: Text; ElementValue: Variant) Result: Integer
    var
        CurrentValue: Variant;
    begin
        while GetNextRow do
            if CurrentRowHasElementTag(ElementTag) then begin
                FindCurrentRowTagValue(ElementTag, CurrentValue);
                if Assert.Compare(CurrentValue, ElementValue) then begin
                    Result := CurrentRowIndex;
                    CurrentRowIndex := -1;
                    exit(Result);
                end;
            end;

        CurrentRowIndex := -1;
        Result := -1;
        exit(Result);
    end;

    procedure FindRow(ElementName: Text; ElementValue: Variant) Result: Integer
    var
        CurrentValue: Variant;
    begin
        while GetNextRow do
            if CurrentRowHasElement(ElementName) then begin
                FindCurrentRowValue(ElementName, CurrentValue);
                ConvertValue(ElementValue, CurrentValue);
                if Assert.Compare(CurrentValue, ElementValue) then begin
                    Result := CurrentRowIndex;
                    CurrentRowIndex := -1;
                    exit(Result);
                end;
            end;

        CurrentRowIndex := -1;
        Result := -1;
        exit(Result);
    end;

    procedure GetElementValueInCurrentRow(ElementName: Text; var Result: Variant)
    begin
        Assert.IsTrue(CurrentRowIndex > -1, StrSubstNo(RowIndexErr, CurrentRowIndex));
        Assert.IsTrue(CurrentRowHasElement(ElementName), StrSubstNo(ElementNameErr, ElementName));
        FindCurrentRowValue(ElementName, Result);
    end;

    procedure SetRangeWithTrimmedValues(ElementName: Text; Value: Variant; TrimSpacesInValue: Boolean)
    var
        XmlNode: DotNet XmlNode;
    begin
        // Validate that the element exists in the dataset
        GetElementSchemaType(ElementName);
        XmlNode := XmlDoc.GetElementsByTagName('DataSet').Item(0);
        if TrimSpacesInValue = false then
            XmlNodeList := XmlNode.SelectNodes(StrSubstNo('//*/*[%1="%2"]', ElementName, Format(Value, 0, 9)))
        else
            XmlNodeList := XmlNode.SelectNodes(StrSubstNo('//*/*[normalize-space(%1)="%2"]', ElementName, Format(Value, 0, 9)));
        CurrentRowIndex := -1
    end;

    procedure SetXmlNodeList(value: Text)
    begin
        XmlNodeList := XmlDoc.GetElementsByTagName(value);
    end;

    procedure GetLastRow()
    begin
        CurrentRowIndex := RowCount - 1;
    end;

    local procedure NameAttributeMatchesValue(var XmlNode: DotNet XmlNode; AttributeName: Text): Boolean
    var
        Attribute: DotNet XmlNode;
    begin
        foreach Attribute in XmlNode.Attributes do
            if Attribute.Name = 'name' then
                exit(Attribute.Value = AttributeName);

        exit(false);
    end;

    local procedure ConvertValue(var ExpectedValue: Variant; var ActualValue: Variant)
    var
        ConvertedDecimal: Decimal;
        ConvertedInteger: Integer;
        ConvertedBoolean: Boolean;
    begin
        if XMLSchemaType <> XMLSchemaType::XML then
            exit;

        if ExpectedValue.IsDecimal then begin
            Evaluate(ConvertedDecimal, ActualValue);
            ActualValue := ConvertedDecimal;
            exit;
        end;

        if ExpectedValue.IsInteger then begin
            Evaluate(ConvertedInteger, ActualValue);
            ActualValue := ConvertedInteger;
            exit;
        end;

        if ExpectedValue.IsBoolean then begin
            Evaluate(ConvertedBoolean, ActualValue);
            ActualValue := ConvertedBoolean;
            exit;
        end;
    end;

    local procedure VerifyTagIsSupported()
    begin
        if XMLSchemaType = XMLSchemaType::XML then
            Error(FunctionNotSupportedForXMLErr);
    end;
}

