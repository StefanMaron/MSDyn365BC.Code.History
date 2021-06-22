page 6710 "OData Column Choose SubForm"
{
    Caption = 'OData Column Choose SubForm';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Tenant Web Service Columns";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Include; Include)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field name that is selected in the data set.';

                    trigger OnValidate()
                    begin
                        if CalledForExcelExport then
                            CheckFieldFilter;
                        IsDirty := true;
                    end;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the field names in a data set.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    Editable = false;
                    ToolTip = 'Specifies the Field Captions in a data set.';
                }
                field("Data Item Caption"; "Data Item Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Table';
                    Editable = false;
                    ToolTip = 'Specifies the Source Table for the Field Name.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    var
        LoadingXMLErr: Label 'There was an error loading the object.';
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        ColumnList: DotNet GenericList1;
        SourceObjectType: Option ,,,,,,,,"Page","Query";
        ActionType: Option "Create a new data set","Create a copy of an existing data set","Edit an existing data set";
        SourceServiceName: Text;
        SourceObjectID: Integer;
        IsDirty: Boolean;
        CheckFieldErr: Label 'You cannot exclude field from selection because of applied filter for it.';
        CalledForExcelExport: Boolean;

    [Scope('OnPrem')]
    procedure InitColumns(ObjectType: Option ,,,,,,,,"Page","Query"; ObjectID: Integer; InActionType: Option "Create a new data set","Create a copy of an existing data set","Edit an existing data set"; InSourceServiceName: Text; DestinationServiceName: Text)
    var
        AllObj: Record AllObj;
        NAVAppObjectMetadata: Record "NAV App Object Metadata";
        inStream: InStream;
    begin
        if FindFirst then
            exit;

        ActionType := InActionType;
        SourceObjectType := ObjectType;
        SourceServiceName := InSourceServiceName;
        SourceObjectID := ObjectID;
        DestinationServiceName := DestinationServiceName;

        AllObj.Get(SourceObjectType, SourceObjectID);
        NAVAppObjectMetadata.Get(AllObj."App Package ID", SourceObjectType, SourceObjectID);
        if not NAVAppObjectMetadata.Metadata.HasValue then
            exit;

        NAVAppObjectMetadata.CalcFields(Metadata);
        NAVAppObjectMetadata.Metadata.CreateInStream(inStream, TEXTENCODING::Windows);

        if SourceObjectType = SourceObjectType::Query then
            InitColumnsForQuery(inStream)
        else
            if SourceObjectType = SourceObjectType::Page then
                InitColumnsForPage(inStream);

        Clear(Rec);
        CurrPage.Update;
    end;

    procedure GetColumns(var TempTenantWebServiceColumns: Record "Tenant Web Service Columns" temporary)
    begin
        SetRange(Include, true);
        if FindFirst then
            repeat
                TempTenantWebServiceColumns.TransferFields(Rec);
                TempTenantWebServiceColumns.Insert;

            until Next = 0;
        Reset;
    end;

    local procedure InitColumnsForQuery(queryStream: InStream)
    var
        queryField: DotNet QueryFields;
        metaData: DotNet QueryMetadataReader;
        i: Integer;
        OldTableNo: Integer;
    begin
        // Load into Query Metadata Reader and retrieve values
        metaData := metaData.FromStream(queryStream);
        if metaData.Fields.Count = 0 then
            exit;
        for i := 0 to metaData.Fields.Count - 1 do begin
            queryField := metaData.Fields.Item(i);
            if OldTableNo <> queryField.TableNo then
                ColumnList := ColumnList.List;
            OldTableNo := queryField.TableNo;
            Clear(Rec);
            if not queryField.IsFilterOnly then
                InsertRecord(queryField.TableNo, queryField.FieldNo, queryField.FieldName, false);
        end;
    end;

    local procedure InitColumnsForPage(pageStream: InStream)
    var
        FieldsTable: Record "Field";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ODataUtility: Codeunit ODataUtility;
        XmlDocument: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
        XmlNode: DotNet XmlNode;
        XmlAttribute: DotNet XmlAttribute;
        AttributesCollection: DotNet XmlAttributeCollection;
        NodeListEnum: DotNet IEnumerator;
        CollectionAttributeEnum: DotNet IEnumerator;
        PageStreamText: Text;
        XmlText: Text;
        SourceTableText: Text;
        FieldIDText: Text;
        FieldNameText: Text;
        ValidTag: Boolean;
        ColumnVisible: Boolean;
    begin
        while not pageStream.EOS do begin
            Clear(PageStreamText);
            pageStream.ReadText(PageStreamText);
            XmlText := XmlText + PageStreamText;
        end;

        XmlDocument := XmlDocument.XmlDocument;
        if not XMLDOMManagement.LoadXMLDocumentFromText(XmlText, XmlDocument) then
            Error(LoadingXMLErr);

        XmlNodeList := XmlDocument.GetElementsByTagName('SourceObject');
        if XmlNodeList.Count <> 1 then
            Error(LoadingXMLErr);

        NodeListEnum := XmlNodeList.GetEnumerator;
        NodeListEnum.MoveNext;
        XmlNode := NodeListEnum.Current;
        AttributesCollection := XmlNode.Attributes;
        CollectionAttributeEnum := AttributesCollection.GetEnumerator;
        while CollectionAttributeEnum.MoveNext do begin
            XmlAttribute := CollectionAttributeEnum.Current;
            if XmlAttribute.Name = 'SourceTable' then
                SourceTableText := XmlAttribute.Value;
        end;

        XmlNodeList := XmlDocument.GetElementsByTagName('Controls');
        NodeListEnum := XmlNodeList.GetEnumerator;
        ColumnList := ColumnList.List;
        while NodeListEnum.MoveNext do begin
            ValidTag := false;
            FieldIDText := '';
            FieldNameText := '';
            ColumnVisible := true;

            XmlNode := NodeListEnum.Current;
            AttributesCollection := XmlNode.Attributes;
            CollectionAttributeEnum := AttributesCollection.GetEnumerator;
            while CollectionAttributeEnum.MoveNext do begin
                XmlAttribute := CollectionAttributeEnum.Current;

                if (XmlAttribute.Name = 'xsi:type') and (XmlAttribute.Value = 'ControlDefinition') then
                    ValidTag := true;

                if XmlAttribute.Name = 'Name' then
                    FieldNameText := XmlAttribute.Value;

                if XmlAttribute.Name = 'DataColumnName' then
                    FieldIDText := XmlAttribute.Value;

                if ActionType = ActionType::"Create a new data set" then
                    if (XmlAttribute.Name = 'Visible') and (XmlAttribute.Value = 'false') then
                        ColumnVisible := false;

                if StrPos(FieldIDText, 'Control') > 0 then
                    ValidTag := false;
            end;

            if ValidTag then begin
                Evaluate(FieldsTable.TableNo, SourceTableText);
                Evaluate(FieldsTable."No.", FieldIDText);
                if TypeHelper.GetField(FieldsTable.TableNo, FieldsTable."No.", FieldsTable) then begin
                    if FieldNameText = '' then
                        FieldNameText := FieldsTable.FieldName;

                    // Convert to OData compatible name.
                    FieldNameText := ODataUtility.ConvertNavFieldNameToOdataName(FieldNameText);
                    InsertRecord(FieldsTable.TableNo, FieldsTable."No.", FieldNameText, ColumnVisible);
                end;
            end;
        end;
    end;

    local procedure InsertRecord(TableNo: Integer; FieldNo: Integer; FieldName: Text; IncludeParam: Boolean)
    begin
        if ColumnList.Contains(FieldNo) then
            exit;

        Init;
        Validate("Data Item", TableNo);
        Validate("Field Number", FieldNo);
        Validate("Field Name", CopyStr(FieldName, 1));
        if (ActionType = ActionType::"Create a copy of an existing data set") or
           (ActionType = ActionType::"Edit an existing data set")
        then begin
            if SourceColumnExists(TableNo, FieldNo) then
                Include := true;
        end else
            Include := IncludeParam;
        repeat
            "Entry ID" := "Entry ID" + 1;
        until Insert(true);

        ColumnList.Add(FieldNo);
    end;

    procedure DeleteColumns()
    begin
        Clear(Rec);
        DeleteAll;
    end;

    local procedure SourceColumnExists(TableNo: Integer; FieldNumber: Integer): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
    begin
        TenantWebService.Init;
        if TenantWebService.Get(SourceObjectType, SourceServiceName) then begin
            TenantWebServiceColumns.Init;
            TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            TenantWebServiceColumns.SetRange("Field Number", FieldNumber);
            TenantWebServiceColumns.SetRange("Data Item", TableNo);
            if TenantWebServiceColumns.FindFirst then
                exit(true);
        end;
    end;

    procedure IncludeIsChanged(): Boolean
    var
        LocalDirty: Boolean;
    begin
        LocalDirty := IsDirty;
        Clear(IsDirty);
        exit(LocalDirty);
    end;

    procedure SetCalledForExcelExport(var SourceRecRef: RecordRef)
    begin
        CalledForExcelExport := true;
        RecRef := SourceRecRef;
    end;

    local procedure CheckFieldFilter()
    var
        FieldRef: FieldRef;
    begin
        if not Include then begin
            FieldRef := RecRef.Field("Field Number");
            if FieldRef.GetFilter <> '' then
                Error(CheckFieldErr);
        end;
    end;
}

