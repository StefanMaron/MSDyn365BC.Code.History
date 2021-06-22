codeunit 1530 "Request Page Parameters Helper"
{

    trigger OnRun()
    begin
    end;

    var
        DataItemPathTxt: Label '/ReportParameters/DataItems/DataItem', Locked = true;
        OptionPathTxt: Label '/ReportParameters/Options/Field', Locked = true;
        XmlNodesNotFoundErr: Label 'The XML Nodes at %1 cannot be found in the XML Document %2.';
        RepParamsWrongNumberFoundErr: Label 'XML contains incorrect number of <ReportParameters> nodes.';

    [Scope('OnPrem')]
    procedure ShowRequestPageAndGetFilters(var NewFilters: Text; ExistingFilters: Text; EntityName: Code[20]; TableNum: Integer; PageCaption: Text) FiltersSet: Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
    begin
        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, TableNum) then
            exit(false);

        if ExistingFilters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(
                 FilterPageBuilder, ExistingFilters, EntityName, TableNum)
            then
                exit(false);

        FilterPageBuilder.PageCaption := PageCaption;
        if not FilterPageBuilder.RunModal then
            exit(false);

        NewFilters :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, TableNum);

        FiltersSet := true;
    end;

    procedure ConvertParametersToFilters(RecRef: RecordRef; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        TableMetadata: Record "Table Metadata";
        FoundXmlNodeList: DotNet XmlNodeList;
    begin
        if not TableMetadata.Get(RecRef.Number) then
            exit(false);

        if not FindNodes(FoundXmlNodeList, ReadParameters(TempBlob), DataItemPathTxt) then
            exit(false);

        exit(GetFiltersForTable(RecRef, FoundXmlNodeList));
    end;

    local procedure ReadParameters(TempBlob: Codeunit "Temp Blob") Parameters: Text
    var
        ParametersInStream: InStream;
    begin
        if TempBlob.HasValue then begin
            TempBlob.CreateInStream(ParametersInStream);
            ParametersInStream.ReadText(Parameters);
        end;
    end;

    local procedure FindNodes(var FoundXmlNodeList: DotNet XmlNodeList; Parameters: Text; NodePath: Text): Boolean
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ParametersXmlDoc: DotNet XmlDocument;
    begin
        if not XMLDOMMgt.LoadXMLDocumentFromText(Parameters, ParametersXmlDoc) then
            exit(false);

        if IsNull(ParametersXmlDoc.DocumentElement) then
            exit(false);

        if not XMLDOMMgt.FindNodes(ParametersXmlDoc.DocumentElement, NodePath, FoundXmlNodeList) then
            Error(XmlNodesNotFoundErr, NodePath, ParametersXmlDoc.DocumentElement.InnerXml);

        exit(true);
    end;

    local procedure GetFiltersForTable(RecRef: RecordRef; FoundXmlNodeList: DotNet XmlNodeList): Boolean
    var
        FoundXmlNode: DotNet XmlNode;
        XmlTableName: Text;
        TableName: Text;
        TableCaption: Text;
        TableNumber: Text;
    begin
        foreach FoundXmlNode in FoundXmlNodeList do begin
            XmlTableName := UpperCase(FoundXmlNode.Attributes.ItemOf('name').Value);
            TableCaption := UpperCase(GetTableCaption(RecRef.Number()));
            TableName := UpperCase(GetTableName(RecRef.Number()));
            TableNumber := StrSubstNo('TABLE%1', RecRef.Number());
            if (StrPos(TableCaption, XmlTableName) <> 0) or
               (StrPos(TableName, XmlTableName) <> 0) or
               (StrPos(TableNumber, XmlTableName) <> 0)
            then begin
                RecRef.SetView(FoundXmlNode.InnerText);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.Caption);
    end;

    local procedure GetTableName(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.Name);
    end;

    procedure BuildDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; EntityName: Code[20]; TableID: Integer): Boolean
    var
        TableList: DotNet ArrayList;
        Name: Text;
        "Table": Integer;
    begin
        if not GetDataItems(TableList, EntityName, TableID) then
            exit(false);

        foreach Table in TableList do begin
            Name := FilterPageBuilder.AddTable(GetTableCaption(Table), Table);
            AddFields(FilterPageBuilder, Name, Table);
        end;

        exit(true);
    end;

    local procedure GetDataItems(var TableList: DotNet ArrayList; EntityName: Code[20]; TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        if not TableMetadata.Get(TableID) then
            exit(false);

        TableList := TableList.ArrayList;
        TableList.Add(TableID);

        DynamicRequestPageEntity.SetRange(Name, EntityName);
        DynamicRequestPageEntity.SetRange("Table ID", TableID);
        if DynamicRequestPageEntity.FindSet then
            repeat
                if not TableList.Contains(DynamicRequestPageEntity."Related Table ID") then
                    TableList.Add(DynamicRequestPageEntity."Related Table ID");
            until DynamicRequestPageEntity.Next = 0;

        exit(true);
    end;

    local procedure AddFields(var FilterPageBuilder: FilterPageBuilder; Name: Text; TableID: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        DynamicRequestPageField.SetRange("Table ID", TableID);
        if DynamicRequestPageField.FindSet then
            repeat
                FilterPageBuilder.AddFieldNo(Name, DynamicRequestPageField."Field ID");
            until DynamicRequestPageField.Next = 0;
    end;

    procedure SetViewOnDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; Filters: Text; EntityName: Code[20]; TableID: Integer): Boolean
    var
        RecRef: RecordRef;
        FoundXmlNodeList: DotNet XmlNodeList;
        TableList: DotNet ArrayList;
        "Table": Integer;
    begin
        if not FindNodes(FoundXmlNodeList, Filters, DataItemPathTxt) then
            exit(false);

        if not GetDataItems(TableList, EntityName, TableID) then
            exit(false);

        foreach Table in TableList do begin
            RecRef.Open(Table);
            GetFiltersForTable(RecRef, FoundXmlNodeList);
            FilterPageBuilder.SetView(GetTableCaption(Table), RecRef.GetView(false));
            RecRef.Close;
            Clear(RecRef);
        end;

        exit(true);
    end;

    procedure GetViewFromDynamicRequestPage(var FilterPageBuilder: FilterPageBuilder; EntityName: Code[20]; TableID: Integer): Text
    var
        TableList: DotNet ArrayList;
        TableFilterDictionary: DotNet GenericDictionary2;
        "Table": Integer;
    begin
        if not GetDataItems(TableList, EntityName, TableID) then
            exit('');

        TableFilterDictionary := TableFilterDictionary.Dictionary(TableList.Count);

        foreach Table in TableList do begin
            if not TableFilterDictionary.ContainsKey(Table) then
                TableFilterDictionary.Add(Table, FilterPageBuilder.GetView(GetTableCaption(Table), false));
        end;

        exit(ConvertFiltersToParameters(TableFilterDictionary));
    end;

    local procedure ConvertFiltersToParameters(TableFilterDictionary: DotNet GenericDictionary2): Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        DataItemXmlNode: DotNet XmlNode;
        DataItemsXmlNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
        ReportParametersXmlNode: DotNet XmlNode;
        TableFilter: DotNet GenericKeyValuePair2;
    begin
        XmlDoc := XmlDoc.XmlDocument;

        XMLDOMMgt.AddRootElement(XmlDoc, 'ReportParameters', ReportParametersXmlNode);
        XMLDOMMgt.AddDeclaration(XmlDoc, '1.0', 'utf-8', 'yes');

        XMLDOMMgt.AddElement(ReportParametersXmlNode, 'DataItems', '', '', DataItemsXmlNode);
        foreach TableFilter in TableFilterDictionary do begin
            XMLDOMMgt.AddElement(DataItemsXmlNode, 'DataItem', TableFilter.Value, '', DataItemXmlNode);
            XMLDOMMgt.AddAttribute(DataItemXmlNode, 'name', StrSubstNo('Table%1', TableFilter.Key));
        end;

        exit(XmlDoc.InnerXml);
    end;

    procedure GetRequestPageOptionValue(OptionName: Text; Parameters: Text): Text
    var
        FoundXmlNodeList: DotNet XmlNodeList;
        FoundXmlNode: DotNet XmlNode;
        TempValue: Text;
    begin
        if not FindNodes(FoundXmlNodeList, Parameters, OptionPathTxt) then
            exit('');

        foreach FoundXmlNode in FoundXmlNodeList do begin
            TempValue := FoundXmlNode.Attributes.ItemOf('name').Value;
            if Format(TempValue) = Format(OptionName) then
                exit(FoundXmlNode.InnerText);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetReportID(RequestPageParameters: Text): Text
    var
        FoundXmlNodeList: DotNet XmlNodeList;
    begin
        if not FindNodes(FoundXmlNodeList, RequestPageParameters, '/ReportParameters') then
            Error(RepParamsWrongNumberFoundErr);

        if FoundXmlNodeList.Count <> 1 then
            Error(RepParamsWrongNumberFoundErr);

        exit(FoundXmlNodeList.Item(0).Attributes.ItemOf('id').Value)
    end;
}

