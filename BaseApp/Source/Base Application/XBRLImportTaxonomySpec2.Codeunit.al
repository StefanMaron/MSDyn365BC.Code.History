codeunit 422 "XBRL Import Taxonomy Spec. 2"
{
    TableNo = "XBRL Schema";

    trigger OnRun()
    var
        InStr: InStream;
        TaxonomyNode: DotNet XmlNode;
        LinkbaseRefNodes: DotNet XmlNodeList;
        LinkbaseRefNode: DotNet XmlNode;
        LinkbaseFileName: Text[250];
        LinkbaseRole: Text[250];
        LinkBaseType: Option Label,Presentation,Calculation,Reference;
        i: Integer;
    begin
        CalcFields(XSD);
        if not XSD.HasValue then
            Error(Text002, TableCaption, "Line No.");

        XBRLSchema := Rec;

        ProgressBox.Open(Text000);
        ProgressBox.Update(1, StrSubstNo(Text001, "XBRL Taxonomy Name"));

        XSD.CreateInStream(InStr);

        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, TaxonomyDocument);

        TaxonomyNode := TaxonomyDocument.DocumentElement;
        if not TaxonomyNode.HasChildNodes then
            Error(Text005, TableCaption, "Line No.");

        DocumentPrefix := GetDocumentPreFix(TaxonomyNode);
        targetNamespace := GetAttribute('targetNamespace', TaxonomyNode);
        "xmlns:xbrli" := GetAttribute('xmlns:xbrli', TaxonomyNode);
        if "xmlns:xbrli" = '' then
            "xmlns:xbrli" := GetAttribute('xmlns:xbrl', TaxonomyNode);
        if "xmlns:xbrli" = '' then
            "xmlns:xbrli" := GetAttribute('xmlns:xbrli01', TaxonomyNode);

        targetNamespacePrefix := GetXmlnsPrefix(targetNamespace, TaxonomyNode);
        if targetNamespacePrefix <> '' then begin
            Description := CopyStr(targetNamespacePrefix, 1, MaxStrLen(Description));
            if Description[StrLen(Description)] = ':' then
                Description := CopyStr(Description, 1, StrLen(Description) - 1);
        end;

        Modify;
        XBRLSchema := Rec;

        GetCommonXmnsPrefixes(TaxonomyNode);
        CreateNameSpaceManager(TaxonomyDocument);
        PopulateNamespaceManager(TaxonomyDocument.DocumentElement);

        case "xmlns:xbrli" of
            'http://www.xbrl.org/2001/instance': // spec. 2.0
                begin
                    SelectNodes(
                      TaxonomyNode, '%1annotation/%1appinfo/' + StrSubstNo('%1linkbaseRef', LinkPrefix), xsdPrefix, LinkbaseRefNodes);
                    HandleDocument;
                    if not IsNull(LinkbaseRefNodes) and IsWindowsClientSession then
                        for i := 1 to LinkbaseRefNodes.Count do begin
                            LinkbaseRefNode := LinkbaseRefNodes.Item(i - 1);
                            LinkbaseRole := GetAttribute(XLinkPrefix + 'role', LinkbaseRefNode);
                            LinkbaseFileName := GetAttribute(XLinkPrefix + 'href', LinkbaseRefNode);
                            case LinkbaseRole of
                                'http://www.xbrl.org/linkprops/linkRef/presentation':
                                    LinkBaseType := LinkBaseType::Presentation;
                                'http://www.xbrl.org/linkprops/linkRef/calculation':
                                    LinkBaseType := LinkBaseType::Calculation;
                                'http://www.xbrl.org/linkprops/linkRef/label':
                                    LinkBaseType := LinkBaseType::Label;
                                'http://www.xbrl.org/linkprops/linkRef/reference':
                                    LinkBaseType := LinkBaseType::Reference;
                                else
                                    LinkbaseFileName := '';
                            end;
                            if LinkbaseFileName <> '' then
                                ImportLinkbase(Rec, LinkBaseType, LinkbaseFileName);
                        end;
                end;
            'http://www.xbrl.org/2003/instance': // spec. 2.1
                begin
                    SelectNodes(
                      TaxonomyNode, '%1annotation/%1appinfo/' + StrSubstNo('%1linkbaseRef', LinkPrefix), xsdPrefix, LinkbaseRefNodes);
                    HandleDocument;
                    if not IsNull(LinkbaseRefNodes) and IsWindowsClientSession then
                        for i := 1 to LinkbaseRefNodes.Count do begin
                            LinkbaseRefNode := LinkbaseRefNodes.Item(i - 1);
                            LinkbaseRole := GetAttribute(XLinkPrefix + 'role', LinkbaseRefNode);
                            LinkbaseFileName := GetAttribute(XLinkPrefix + 'href', LinkbaseRefNode);
                            case LinkbaseRole of
                                'http://www.xbrl.org/2003/role/presentationLinkbaseRef':
                                    LinkBaseType := LinkBaseType::Presentation;
                                'http://www.xbrl.org/2003/role/calculationLinkbaseRef':
                                    LinkBaseType := LinkBaseType::Calculation;
                                'http://www.xbrl.org/2003/role/labelLinkbaseRef':
                                    LinkBaseType := LinkBaseType::Label;
                                'http://www.xbrl.org/2003/role/referenceLinkbaseRef':
                                    LinkBaseType := LinkBaseType::Reference;
                                else
                                    LinkbaseFileName := '';
                            end;
                            if LinkbaseFileName <> '' then
                                ImportLinkbase(Rec, LinkBaseType, LinkbaseFileName);
                        end;
                end;
            else
                Error(Text018, "xmlns:xbrli");
        end;
    end;

    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLSchema: Record "XBRL Schema";
        XBRLLine: Record "XBRL Taxonomy Line";
        TempXBRLLine: Record "XBRL Taxonomy Line" temporary;
        XBRLGLMapLine: Record "XBRL G/L Map Line";
        TempXBRLGLMapLine: Record "XBRL G/L Map Line" temporary;
        XBRLCommentLine: Record "XBRL Comment Line";
        TempXBRLCommentLine: Record "XBRL Comment Line" temporary;
        XMLDOMManagement: Codeunit "XML DOM Management";
        TaxonomyDocument: DotNet XmlDocument;
        NamespaceMgr: DotNet XmlNamespaceManager;
        ProgressBox: Dialog;
        Text000: Label '#1###################################### \Progress            @2@@@@@@@@@@@@@@@@@@';
        Text001: Label 'Importing taxonomy %1';
        Text002: Label 'You must first import a taxonomy into %1 %2.';
        NextLineNo: Integer;
        Text005: Label '%1 %2 has no Elements.';
        Text007: Label 'Unexpected type: "%1".';
        UpdatingTaxonomyfromTaxonomyMsg: Label 'Updating new taxonomy from existing taxonomy %1.', Comment = '%1: Field(XBRL Taxonomy Name)';
        Text009: Label 'Updating database';
        Text012: Label 'You must first import a linkbase into %1 %2.';
        Text013: Label '%1 %2\%3 #4######## #5##################\@6@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        Text015: Label 'There is no Schemalocation defined in the document.';
        Text017: Label '%1 %2 has a different version than %3 %4. Do you want to continue anyway?';
        Text018: Label 'This document has an unknown version (%1).';
        targetNamespacePrefix: Text;
        xsdPrefix: Text;
        xbrliPrefix: Text;
        XLinkPrefix: Text;
        LinkPrefix: Text;
        FilesOnServer: Boolean;
        DocumentPrefix: Text[30];

    local procedure ImportLinkbase(XBRLSchema: Record "XBRL Schema"; LinkBaseType: Option Label,Presentation,Calculation,Reference; LinkBaseName: Text[250])
    var
        XBRLLinkbase: Record "XBRL Linkbase";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        XBRLLinkbase.SetRange("XBRL Taxonomy Name", XBRLSchema."XBRL Taxonomy Name");
        XBRLLinkbase.SetRange("XBRL Schema Line No.", XBRLSchema."Line No.");
        XBRLLinkbase.SetRange(Type, LinkBaseType);
        if XBRLSchema."Folder Name" <> '' then
            if XBRLSchema."Folder Name"[StrLen(XBRLSchema."Folder Name")] <> '\' then
                XBRLSchema."Folder Name" := XBRLSchema."Folder Name" + '\';

        // FilesOnServer is used when scripting this codeunit.
        if FilesOnServer then
            if not Exists(XBRLSchema."Folder Name" + LinkBaseName) then
                exit;

        XBRLLinkbase.SetRange(Type);
        if XBRLLinkbase.FindLast then
            XBRLLinkbase."Line No." := XBRLLinkbase."Line No." + 10000
        else
            XBRLLinkbase."Line No." := 10000;

        XBRLLinkbase."XBRL Taxonomy Name" := XBRLSchema."XBRL Taxonomy Name";
        XBRLLinkbase."XBRL Schema Line No." := XBRLSchema."Line No.";
        XBRLLinkbase.Type := LinkBaseType;
        XBRLLinkbase.Description := Format(XBRLLinkbase.Type);
        if FilesOnServer then
            XBRLLinkbase.XML.Import(XBRLSchema."Folder Name" + LinkBaseName)
        else begin
            if FileMgt.BLOBImport(TempBlob, XBRLSchema."Folder Name" + LinkBaseName) = '' then
                exit;
            RecordRef.GetTable(XBRLLinkbase);
            TempBlob.ToRecordRef(RecordRef, XBRLLinkbase.FieldNo(XML));
            RecordRef.SetTable(XBRLLinkbase);
        end;

        XBRLLinkbase."File Name" := LinkBaseName;
        XBRLLinkbase.Insert();

        case LinkBaseType of
            LinkBaseType::Label:
                ImportLabels(XBRLLinkbase);
            LinkBaseType::Presentation:
                ImportPresentation(XBRLLinkbase);
            LinkBaseType::Reference:
                ImportReference(XBRLLinkbase);
            LinkBaseType::Calculation:
                ImportCalculation(XBRLLinkbase);
        end;
    end;

    local procedure HandleDocument()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TaxonomyNode: DotNet XmlNode;
        TaxonomyNodeList: DotNet XmlNodeList;
        NoOfNodes: Integer;
        Progress: Integer;
        NewProgress: Integer;
        i: Integer;
        NodeIndex: Integer;
    begin
        XBRLTaxonomy.Get(XBRLSchema."XBRL Taxonomy Name");
        if XBRLTaxonomy.schemaLocation = '' then begin
            XBRLTaxonomy.schemaLocation := XBRLSchema.schemaLocation;
            XBRLTaxonomy.Modify();
        end;
        if XBRLTaxonomy."xmlns:xbrli" = '' then begin
            XBRLTaxonomy."xmlns:xbrli" := XBRLSchema."xmlns:xbrli";
            XBRLTaxonomy.Modify();
        end else
            if XBRLTaxonomy."xmlns:xbrli" <> XBRLSchema."xmlns:xbrli" then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       Text017, XBRLSchema.TableCaption, XBRLSchema.Description,
                       XBRLTaxonomy.TableCaption, XBRLSchema."XBRL Taxonomy Name"), false)
                then
                    exit;
        XBRLLine.LockTable();
        XBRLLine.SetRange("XBRL Taxonomy Name", XBRLSchema."XBRL Taxonomy Name");
        if XBRLLine.Find('+') then;
        NextLineNo := XBRLLine."Line No." + 10000;

        TaxonomyNode := TaxonomyDocument.DocumentElement;
        TaxonomyNodeList := TaxonomyNode.ChildNodes;
        NodeIndex := 0;
        TaxonomyNode := TaxonomyNodeList.Item(NodeIndex);
        NoOfNodes := TaxonomyNodeList.Count();
        Progress := 0;
        NewProgress := 0;
        i := 0;
        while not IsNull(TaxonomyNode) do begin
            if (TaxonomyNode.Name = StrSubstNo('%1element', xsdPrefix)) or
               (TaxonomyNode.Name = StrSubstNo('%1element', DocumentPrefix)) or
               (TaxonomyNode.Name = 'element')
            then
                HandleElement(TaxonomyNode, 0, -1);
            i := i + 1;
            NewProgress := Round(i / NoOfNodes * 10000, 1);
            if (Progress = 0) or (NewProgress >= Progress + 100) then begin
                ProgressBox.Update(2, NewProgress);
                Progress := NewProgress;
            end;
            NodeIndex := NodeIndex + 1;
            TaxonomyNode := TaxonomyNodeList.Item(NodeIndex);
        end;
        SortPresentationOrder(0, 0, '');

        if TempXBRLLine.Count = 0 then
            exit;

        // Update from existing data, if any
        ProgressBox.Update(1, StrSubstNo(UpdatingTaxonomyfromTaxonomyMsg, XBRLSchema."XBRL Taxonomy Name"));
        ProgressBox.Update(2, 0);
        Progress := 0;
        NewProgress := 0;
        i := 0;
        XBRLLine.SetRange("XBRL Taxonomy Name", XBRLSchema."XBRL Taxonomy Name");
        XBRLLine.SetRange("XBRL Schema Line No.", XBRLSchema."Line No.");
        if XBRLLine.Find('-') then
            repeat
                i := i + 1;
                NewProgress := Round(i / NoOfNodes * 10000, 1);
                if (Progress = 0) or (NewProgress >= Progress + 100) then begin
                    ProgressBox.Update(2, NewProgress);
                    Progress := NewProgress;
                end;
                XBRLLine.CalcFields("G/L Map Lines", Notes);
                if (XBRLLine."Constant Amount" <> 0) or (XBRLLine.Description <> '') or
                   XBRLLine."G/L Map Lines" or XBRLLine.Notes
                then begin
                    TempXBRLLine.SetCurrentKey(Name);
                    TempXBRLLine.SetRange("XBRL Taxonomy Name", XBRLLine."XBRL Taxonomy Name");
                    TempXBRLLine.SetRange(Name, XBRLLine.Name);
                    if TempXBRLLine.Find('-') then begin
                        TempXBRLLine."Constant Amount" := XBRLLine."Constant Amount";
                        if TempXBRLLine.Description = '' then
                            TempXBRLLine.Description := XBRLLine.Description;
                        TempXBRLLine.Modify();

                        XBRLGLMapLine.SetRange("XBRL Taxonomy Name", TempXBRLLine."XBRL Taxonomy Name");
                        XBRLGLMapLine.SetRange("XBRL Taxonomy Line No.", TempXBRLLine."Line No.");
                        if XBRLGLMapLine.Find('-') then
                            repeat
                                TempXBRLGLMapLine := XBRLGLMapLine;
                                TempXBRLGLMapLine."XBRL Taxonomy Line No." := TempXBRLLine."Line No.";
                                TempXBRLGLMapLine.Insert();
                            until XBRLGLMapLine.Next = 0;

                        XBRLCommentLine.SetRange("XBRL Taxonomy Name", TempXBRLLine."XBRL Taxonomy Name");
                        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", TempXBRLLine."Line No.");
                        XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Notes);
                        if XBRLCommentLine.Find('-') then
                            repeat
                                TempXBRLCommentLine := XBRLCommentLine;
                                TempXBRLCommentLine."XBRL Taxonomy Line No." := TempXBRLLine."Line No.";
                                TempXBRLCommentLine.Insert();
                            until XBRLCommentLine.Next = 0;
                    end;
                end;
                XBRLLine.Delete(true);
            until XBRLLine.Next = 0;
        TempXBRLLine.Reset();

        // Write back to database
        ProgressBox.Update(1, Text009);
        ProgressBox.Update(2, 0);
        if TempXBRLLine.Find('-') then
            repeat
                XBRLLine := TempXBRLLine;
                XBRLLine.Insert();
            until TempXBRLLine.Next = 0;
        if TempXBRLCommentLine.Find('-') then
            repeat
                XBRLCommentLine := TempXBRLCommentLine;
                XBRLCommentLine.Insert();
            until TempXBRLCommentLine.Next = 0;
        if TempXBRLGLMapLine.Find('-') then
            repeat
                XBRLGLMapLine := TempXBRLGLMapLine;
                XBRLGLMapLine.Insert();
            until TempXBRLGLMapLine.Next = 0;
    end;

    local procedure HandleElement(ElementNode: DotNet XmlNode; ParentLineNo: Integer; ParentLevel: Integer)
    var
        ThisXBRLLine: Record "XBRL Taxonomy Line";
        XMLNode: DotNet XmlNode;
        NamespacePrefix: Text[250];
        ReferenceElementName: Text[250];
        NumericContextPeriodType: Text[250];
        IsTypeDescription: Boolean;
    begin
        IsTypeDescription := IsElementTypeDescription(ElementNode);

        ReferenceElementName := GetAttribute('ref', ElementNode);
        if ReferenceElementName <> '' then begin
            if StrPos(ReferenceElementName, ':') > 0 then
                ReferenceElementName := CopyStr(ReferenceElementName, StrPos(ReferenceElementName, ':') + 1);
            ElementNode := TaxonomyDocument.DocumentElement;
            ElementNode := ElementNode.SelectSingleNode(StrSubstNo('%1element[@name="%2"]', xsdPrefix, ReferenceElementName), NamespaceMgr);
            if IsNull(ElementNode) then
                exit;
        end;
        TempXBRLLine.Init();
        TempXBRLLine."XBRL Taxonomy Name" := XBRLSchema."XBRL Taxonomy Name";
        TempXBRLLine."XBRL Schema Line No." := XBRLSchema."Line No.";
        TempXBRLLine."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        TempXBRLLine."Parent Line No." := ParentLineNo;
        TempXBRLLine.Level := ParentLevel + 1;
        TempXBRLLine.Name := GetAttribute('name', ElementNode);
        TempXBRLLine."Element ID" := CopyStr(GetAttribute('id', ElementNode), 1, MaxStrLen(TempXBRLLine."Element ID"));
        if TempXBRLLine."Element ID" = '' then
            TempXBRLLine."Element ID" := TempXBRLLine.Name;
        if TempXBRLLine.Name = '' then
            TempXBRLLine.Name := TempXBRLLine."Element ID";
        TempXBRLLine.TestField(Name);
        NumericContextPeriodType := CopyStr(GetAttribute('xbrli:periodType', ElementNode), 1, MaxStrLen(NumericContextPeriodType));
        case NumericContextPeriodType of
            'instant':
                TempXBRLLine."Numeric Context Period Type" := TempXBRLLine."Numeric Context Period Type"::Instant;
            'duration':
                TempXBRLLine."Numeric Context Period Type" := TempXBRLLine."Numeric Context Period Type"::Duration;
        end;

        TempXBRLLine."Type Description Element" := IsTypeDescription;
        TempXBRLLine."XBRL Item Type" := GetAttribute('type', ElementNode);
        if StrPos(TempXBRLLine."XBRL Item Type", ':') > 0 then begin
            NamespacePrefix := CopyStr(TempXBRLLine."XBRL Item Type", 1, StrPos(TempXBRLLine."XBRL Item Type", ':'));
            TempXBRLLine."XBRL Item Type" :=
              CopyStr(TempXBRLLine."XBRL Item Type", StrPos(TempXBRLLine."XBRL Item Type", ':') + 1);
        end;
        if (TempXBRLLine."XBRL Item Type" = '') or (NamespacePrefix = targetNamespacePrefix) then begin
            if GetAttribute('substitutionGroup', ElementNode) = StrSubstNo('%1tuple', xbrliPrefix) then
                TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Tuple
            else
                TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Description;
            TempXBRLLine.Insert();
            ThisXBRLLine := TempXBRLLine;
            HandleCustomType(TempXBRLLine, TempXBRLLine."XBRL Item Type", ElementNode);
        end else begin
            case LowerCase(TempXBRLLine."XBRL Item Type") of
                'stringitemtype', 'string':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Description;
                'monetaryitemtype':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::"General Ledger";
                'decimalitemtype':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Constant;
                'sharesitemtype':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Constant;
                'uriitemtype':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Description;
                'tupletype':
                    TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Tuple;
                'datetimeitemtype', 'dateitemtype':
                    begin
                        TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::Description;
                        TempXBRLLine.Description := '%6%3%2';
                    end;
                else begin
                        TempXBRLLine."Source Type" := TempXBRLLine."Source Type"::"Not Applicable";
                        if TempXBRLLine."XBRL Item Type" <> '' then
                            TempXBRLLine.Description := StrSubstNo(Text007, TempXBRLLine."XBRL Item Type");
                    end;
            end;
            TempXBRLLine.Insert();
            ThisXBRLLine := TempXBRLLine;
        end;

        XMLNode := ElementNode.SelectSingleNode(StrSubstNo('%1annotation//%1documentation', xsdPrefix), NamespaceMgr);
        if not IsNull(XMLNode) then begin
            XBRLCommentLine.SetRange("XBRL Taxonomy Name", ThisXBRLLine."XBRL Taxonomy Name");
            XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", ThisXBRLLine."Line No.");
            XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Information);
            XBRLCommentLine.DeleteAll();
            XBRLCommentLine.Init();
            XBRLCommentLine."XBRL Taxonomy Name" := ThisXBRLLine."XBRL Taxonomy Name";
            XBRLCommentLine."XBRL Taxonomy Line No." := ThisXBRLLine."Line No.";
            XBRLCommentLine."Comment Type" := XBRLCommentLine."Comment Type"::Information;
            XBRLCommentLine."Line No." := 0;
            InsertReference(XMLNode, XBRLCommentLine);
        end;
    end;

    local procedure HandleCustomType(ParentXBRLLine: Record "XBRL Taxonomy Line"; ElementType: Text[250]; SourceNode: DotNet XmlNode)
    var
        XMLElementList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        XMLElement: DotNet XmlNode;
        ReferenceElementName: Text;
        i: Integer;
    begin
        if ElementType = '' then
            SelectSingleNode(SourceNode, '%1complexType', xsdPrefix, XMLNode)
        else
            SelectSingleNode(
              TaxonomyDocument.DocumentElement, '%1' + StrSubstNo('complexType[@name="%1"]', ElementType),
              xsdPrefix, XMLNode);
        if IsNull(XMLNode) then
            exit;
        SelectNodes(XMLNode, '%1complexContent/%1extension/%1sequence/%1element', xsdPrefix, XMLElementList);
        if XMLElementList.Count = 0 then
            SelectNodes(XMLNode, '%1sequence/%1element', xsdPrefix, XMLElementList);
        // Choice Type
        if XMLElementList.Count = 0 then begin
            SelectSingleNode(XMLNode, '%1choice/%1element', xsdPrefix, XMLElement);
            if IsNull(XMLElement) then
                exit;
            ReferenceElementName := GetAttribute('ref', XMLElement);
            SelectNodes(
              XMLNode.OwnerDocument.DocumentElement, '%1' + StrSubstNo(
                'element[@substitutionGroup=''%1'']', ReferenceElementName), xsdPrefix, XMLElementList);
        end;

        if XMLElementList.Count = 0 then
            exit;
        for i := 1 to XMLElementList.Count do begin
            XMLElement := XMLElementList.Item(i - 1);
            HandleElement(XMLElement, ParentXBRLLine."Line No.", ParentXBRLLine.Level);
        end;
    end;

    local procedure GetAttribute(AttributeName: Text; XMLNode: DotNet XmlNode): Text[1024]
    var
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributeNode := XMLNode.Attributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');

        exit(Format(XMLAttributeNode.InnerText));
    end;

    local procedure GetAttributeNameByValue(AttributeValue: Text; XMLNode: DotNet XmlNode; IncludeTargetNamespace: Boolean): Text
    var
        XMLAttributeNode: DotNet XmlNode;
        XMLAttributes: DotNet XmlAttributeCollection;
        Index: Integer;
    begin
        XMLAttributes := XMLNode.Attributes;
        for Index := 1 to XMLAttributes.Count do begin
            XMLAttributeNode := XMLAttributes.Item(Index - 1);
            if (Format(XMLAttributeNode.InnerText) = AttributeValue) and
               (IncludeTargetNamespace or
                not IncludeTargetNamespace and (XMLAttributeNode.Name <> 'targetNamespace'))
            then
                exit(XMLAttributeNode.Name);
        end;
        exit('');
    end;

    [Scope('OnPrem')]
    procedure ImportLabels(var XBRLLinkbase: Record "XBRL Linkbase")
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        InStr: InStream;
        LinkbaseDocument: DotNet XmlDocument;
        LinkbaseDocNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        ArcNodeList: DotNet XmlNodeList;
        LabelNodeList: DotNet XmlNodeList;
        LabelNode: DotNet XmlNode;
        Window: Dialog;
        i: Integer;
        j: Integer;
        Progress: Integer;
        NoOfRecords: Integer;
        Schemalocation: Text[1024];
    begin
        XBRLSchema.Get(XBRLLinkbase."XBRL Taxonomy Name", XBRLLinkbase."XBRL Schema Line No.");
        Window.Open(
          StrSubstNo(
            Text013, XBRLSchema.TableCaption, XBRLSchema.Description, XBRLLinkbase.TableCaption));
        Window.Update(4, XBRLLinkbase.Type);
        Window.Update(5, XBRLLinkbase.Description);

        with XBRLLinkbase do begin
            TestField(Type, Type::Label);
            CalcFields(XML);
            if not XML.HasValue then
                Error(Text012, TableCaption, "Line No.");
            XML.CreateInStream(InStr);
        end;
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, LinkbaseDocument);
        LinkbaseDocNode := LinkbaseDocument.FirstChild;
        while LowerCase(LinkbaseDocNode.NodeType.ToString) in ['xmldeclaration', 'processinginstruction', 'comment'] do
            LinkbaseDocNode := LinkbaseDocNode.NextSibling;
        Schemalocation := GetAttribute('xsi:schemaLocation', LinkbaseDocNode);
        if Schemalocation = '' then
            Error(Text015);
        i := StrPos(Schemalocation, XBRLSchema.targetNamespace + ' ');
        if i <> 0 then begin
            i := i + StrLen(XBRLSchema.targetNamespace);
            while Schemalocation[i] = ' ' do
                i := i + 1;
            j := i;
            while (Schemalocation[j] <> ' ') and (j <= StrLen(Schemalocation)) do
                j := j + 1;
            Schemalocation := CopyStr(Schemalocation, i, j - i);
        end else
            Schemalocation := XBRLSchema.schemaLocation;

        GetCommonXmnsPrefixes(LinkbaseDocNode);
        CreateNameSpaceManager(LinkbaseDocument);
        PopulateNamespaceManager(LinkbaseDocument.DocumentElement);
        PopulateNamespaceManager(LinkbaseDocNode.FirstChild);

        XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
        XBRLTaxonomyLine.SetRange("XBRL Schema Line No.", XBRLLinkbase."XBRL Schema Line No.");
        NoOfRecords := XBRLTaxonomyLine.Count();

        if XBRLTaxonomyLine.Find('-') then
            repeat
                Progress := Progress + 1;
                Window.Update(6, Round(Progress / NoOfRecords * 10000, 1));
                XMLNode :=
                  LinkbaseDocNode.SelectSingleNode(
                    StrSubstNo(
                      '%3labelLink/%3loc[@%4href="%1#%2"]',
                      Schemalocation, XBRLTaxonomyLine."Element ID", LinkPrefix, XLinkPrefix), NamespaceMgr);
                if not IsNull(XMLNode) then begin
                    ArcNodeList :=
                      LinkbaseDocNode.SelectNodes(
                        StrSubstNo(
                          '%2labelLink/%2labelArc[@%3from="%1"]',
                          GetAttribute(XLinkPrefix + 'label', XMLNode), LinkPrefix, XLinkPrefix), NamespaceMgr);
                    for i := 1 to ArcNodeList.Count do begin
                        XMLNode := ArcNodeList.Item(i - 1);
                        LabelNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%2labelLink/%2label[@%3label="%1"]',
                              GetAttribute(XLinkPrefix + 'to', XMLNode), LinkPrefix, XLinkPrefix), NamespaceMgr);
                        for j := 1 to LabelNodeList.Count do begin
                            LabelNode := LabelNodeList.Item(j - 1);
                            InsertLabel(LabelNode, XBRLTaxonomyLine);
                        end
                    end;
                end;
            until XBRLTaxonomyLine.Next = 0;
        Window.Close;
    end;

    local procedure InsertLabel(XMLNode: DotNet XmlNode; var XBRLLine: Record "XBRL Taxonomy Line")
    var
        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
        langAttribute: Text[30];
        roleAttribute: Text[1024];
        Label: Text[250];
    begin
        langAttribute := GetAttribute('xml:lang', XMLNode);
        roleAttribute := LowerCase(GetAttribute(XLinkPrefix + 'role', XMLNode));
        if (roleAttribute <> 'http://www.xbrl.org/2003/role/label') and // spec. 2.1
           (roleAttribute <> 'http://www.xbrl.org/linkprops/label/standard') // spec. 2.0
        then
            exit;
        Label := CopyStr(XMLNode.InnerText, 1, MaxStrLen(XBRLTaxonomyLabel.Label));
        if not XBRLTaxonomyLabel.Get(XBRLLine."XBRL Taxonomy Name", XBRLLine."Line No.", langAttribute) then begin
            XBRLTaxonomyLabel.Init();
            XBRLTaxonomyLabel."XBRL Taxonomy Name" := XBRLLine."XBRL Taxonomy Name";
            XBRLTaxonomyLabel."XBRL Taxonomy Line No." := XBRLLine."Line No.";
            XBRLTaxonomyLabel."XML Language Identifier" := langAttribute;
            XBRLTaxonomyLabel.Label := Label;
            XBRLTaxonomyLabel.Insert();
        end else
            if XBRLTaxonomyLabel.Label <> Label then begin
                XBRLTaxonomyLabel.Label := Label;
                XBRLTaxonomyLabel.Modify();
            end;
    end;

    [Scope('OnPrem')]
    procedure ImportPresentation(var XBRLLinkbase: Record "XBRL Linkbase")
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLine2: Record "XBRL Taxonomy Line";
        XBRLSchema: Record "XBRL Schema";
        TempXBRLSchema: Record "XBRL Schema" temporary;
        LinkbaseDocument: DotNet XmlDocument;
        LinkbaseDocNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        Window: Dialog;
        CurrNodeIndex: Integer;
        i: Integer;
        Progress: Integer;
        NoOfRecords: Integer;
        Schemalocation: Text;
        FromSchemalocation: Text;
        ToSchemalocation: Text;
        fromLabel: Text[250];
        toLabel: Text[250];
        ToName: Text[250];
        t: Text[30];
        "Order": Decimal;
        UpdateParentPresentationLineNo: Boolean;
        LastXBRLLineNo: Integer;
    begin
        XBRLSchema.Get(XBRLLinkbase."XBRL Taxonomy Name", XBRLLinkbase."XBRL Schema Line No.");
        Window.Open(
          StrSubstNo(
            Text013, XBRLSchema.TableCaption, XBRLSchema.Description, XBRLLinkbase.TableCaption));
        Window.Update(4, XBRLLinkbase.Type);
        Window.Update(5, XBRLLinkbase.Description);

        LoadLinkbaseDocument(XBRLLinkbase, LinkbaseDocument);
        FindLinkbaseDocNode(LinkbaseDocument, LinkbaseDocNode);
        Schemalocation := GetAttribute('xsi:schemaLocation', LinkbaseDocNode);

        if Schemalocation = '' then
            Error(Text015);

        UpdateSchemaLocation(TempXBRLSchema, XBRLSchema, XBRLLinkbase, Schemalocation, FromSchemalocation);
        GetCommonXmnsPrefixes(LinkbaseDocNode);
        CreateNameSpaceManager(LinkbaseDocument);
        PopulateNamespaceManager(LinkbaseDocument.DocumentElement);
        PopulateNamespaceManager(LinkbaseDocNode.FirstChild);

        XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
        XBRLTaxonomyLine.SetRange("Presentation Linkbase Line No.", XBRLLinkbase."Line No.");
        XBRLTaxonomyLine.ModifyAll("Presentation Linkbase Line No.", 0);
        XBRLTaxonomyLine.SetRange("Presentation Linkbase Line No.");
        NoOfRecords := XBRLTaxonomyLine.Count();

        if XBRLTaxonomyLine.FindLast then
            LastXBRLLineNo := XBRLTaxonomyLine."Line No.";

        InitTaxonomyLinesBuf(XBRLTaxonomyLine, TempXBRLLine);
        if TempXBRLLine.FindSet then
            repeat
                Progress := Progress + 1;
                Window.Update(6, Round(Progress / NoOfRecords * 10000, 1));
                if TempXBRLSchema."Line No." <> TempXBRLLine."XBRL Schema Line No." then
                    TempXBRLSchema.Get(TempXBRLLine."XBRL Taxonomy Name", TempXBRLLine."XBRL Schema Line No.");
                FromSchemalocation := TempXBRLSchema.schemaLocation;
                XMLNode :=
                  LinkbaseDocNode.SelectSingleNode(
                    StrSubstNo(
                      '%3presentationLink/%3loc[@%4href="%1#%2"]',
                      FromSchemalocation, TempXBRLLine."Element ID", LinkPrefix, XLinkPrefix), NamespaceMgr);
                if not IsNull(XMLNode) then begin
                    fromLabel := GetAttribute(XLinkPrefix + 'label', XMLNode);
                    if XBRLSchema."xmlns:xbrli" = 'http://www.xbrl.org/2001/instance' then // spec. 2.0
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3presentationLink/%3presentationArc[@%4from="%1" and @%4arcrole="%2"]',
                              fromLabel, 'http://www.xbrl.org/linkprops/arc/parent-child', LinkPrefix, XLinkPrefix), NamespaceMgr)
                    else // 'http://www.xbrl.org/2003/instance' // spec. 2.1
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3presentationLink/%3presentationArc[@%4from="%1" and @%4arcrole="%2"]',
                              fromLabel, 'http://www.xbrl.org/2003/arcrole/parent-child', LinkPrefix, XLinkPrefix), NamespaceMgr);

                    for CurrNodeIndex := 0 to XMLNodeList.Count - 1 do begin
                        XMLNode := XMLNodeList.Item(CurrNodeIndex);
                        t := GetAttribute('order', XMLNode);
                        if t = '' then
                            Order := 1
                        else
                            Evaluate(Order, t);
                        toLabel := GetAttribute(XLinkPrefix + 'to', XMLNode);
                        XMLNode :=
                          LinkbaseDocNode.SelectSingleNode(
                            StrSubstNo(
                              '%2presentationLink/%2loc[@%3label="%1"]', toLabel, LinkPrefix, XLinkPrefix), NamespaceMgr);
                        if not IsNull(XMLNode) then begin
                            ToName := GetAttribute(XLinkPrefix + 'href', XMLNode);
                            if ToName <> '' then begin
                                i := StrPos(ToName, '#');
                                if i > 0 then begin
                                    ToSchemalocation := CopyStr(ToName, 1, i - 1);
                                    ToName := CopyStr(ToName, i + 1);
                                end else
                                    ToSchemalocation := '';
                                CopyXBRLElementsForPresentation(
                                  LinkbaseDocNode, XBRLSchema."xmlns:xbrli", XBRLLinkbase."XBRL Taxonomy Name", ToName, LastXBRLLineNo);
                                XBRLTaxonomyLine2.Copy(TempXBRLLine);
                                TempXBRLLine.SetCurrentKey("XBRL Taxonomy Name", "Element ID");
                                TempXBRLLine.SetRange("Element ID", ToName);
                                TempXBRLLine.SetRange(
                                  "XBRL Taxonomy Name", TempXBRLLine."XBRL Taxonomy Name");
                                if TempXBRLSchema.schemaLocation = ToSchemalocation then
                                    TempXBRLLine.SetRange("XBRL Schema Line No.", TempXBRLSchema."Line No.")
                                else begin
                                    TempXBRLSchema.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
                                    TempXBRLSchema.SetRange(schemaLocation, ToSchemalocation);
                                    if TempXBRLSchema.FindFirst then
                                        TempXBRLLine.SetRange("XBRL Schema Line No.", TempXBRLSchema."Line No.")
                                    else
                                        TempXBRLLine.SetRange("XBRL Schema Line No.");
                                end;
                                UpdateParentPresentationLineNo := false;
                                TempXBRLLine.SetRange("Presentation Linkbase Line No.", 0);
                                if TempXBRLLine.IsEmpty then
                                    TempXBRLLine.SetRange("Presentation Linkbase Line No.");
                                if TempXBRLLine.Find('-') then begin
                                    TempXBRLLine."Parent Line No." := XBRLTaxonomyLine2."Line No.";
                                    TempXBRLLine."Presentation Order No." := Round(Order, 1);
                                    TempXBRLLine."Presentation Linkbase Line No." := XBRLLinkbase."Line No.";
                                    TempXBRLLine.Modify();
                                    UpdateParentPresentationLineNo := true;
                                end;
                                TempXBRLLine.Copy(XBRLTaxonomyLine2);
                                if UpdateParentPresentationLineNo and (TempXBRLLine."Presentation Linkbase Line No." = 0) then begin
                                    TempXBRLLine."Presentation Linkbase Line No." := XBRLLinkbase."Line No.";
                                    TempXBRLLine.Modify();
                                end;
                                TempXBRLLine.SetCurrentKey("XBRL Taxonomy Name", "Line No.");
                            end;
                        end;
                    end;
                end;
            until TempXBRLLine.Next = 0;

        SortPresentationOrder(0, 0, '');
        SaveTaxonomyLines(TempXBRLLine);

        Window.Close;
    end;

    [Scope('OnPrem')]
    procedure ImportCalculation(var XBRLLinkbase: Record "XBRL Linkbase")
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLine2: Record "XBRL Taxonomy Line";
        XBRLRollupLine: Record "XBRL Rollup Line";
        TempXBRLSchema: Record "XBRL Schema" temporary;
        InStr: InStream;
        LinkbaseDocument: DotNet XmlDocument;
        LinkbaseDocNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        Window: Dialog;
        CurrNodeIndex: Integer;
        i: Integer;
        Progress: Integer;
        NoOfRecords: Integer;
        Schemalocation: Text;
        fromLabel: Text[250];
        toLabel: Text[250];
        ToName: Text[250];
        WeightTxt: Text[30];
        Weight: Decimal;
        FromSchemalocation: Text;
        ToSchemalocation: Text;
    begin
        XBRLSchema.Get(XBRLLinkbase."XBRL Taxonomy Name", XBRLLinkbase."XBRL Schema Line No.");
        Window.Open(
          StrSubstNo(
            Text013, XBRLSchema.TableCaption, XBRLSchema.Description, XBRLLinkbase.TableCaption));
        Window.Update(4, XBRLLinkbase.Type);
        Window.Update(5, XBRLLinkbase.Description);

        with XBRLLinkbase do begin
            TestField(Type, Type::Calculation);
            CalcFields(XML);
            if not XML.HasValue then
                Error(Text012, TableCaption, "Line No.");
            XML.CreateInStream(InStr);
        end;
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, LinkbaseDocument);
        LinkbaseDocNode := LinkbaseDocument.FirstChild;
        while LowerCase(LinkbaseDocNode.NodeType.ToString) in ['xmldeclaration', 'processinginstruction', 'comment'] do
            LinkbaseDocNode := LinkbaseDocNode.NextSibling;
        Schemalocation := GetAttribute('xsi:schemaLocation', LinkbaseDocNode);
        if Schemalocation = '' then
            Error(Text015);
        i := StrPos(Schemalocation, XBRLSchema.targetNamespace + ' ');
        if i = 0 then
            Schemalocation := XBRLSchema.schemaLocation;

        UpdateSchemaLocation(TempXBRLSchema, XBRLSchema, XBRLLinkbase, Schemalocation, FromSchemalocation);
        GetCommonXmnsPrefixes(LinkbaseDocNode);
        CreateNameSpaceManager(LinkbaseDocument);
        PopulateNamespaceManager(LinkbaseDocument.DocumentElement);
        PopulateNamespaceManager(LinkbaseDocNode.FirstChild);

        XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
        NoOfRecords := XBRLTaxonomyLine.Count();

        if XBRLTaxonomyLine.Find('-') then
            repeat
                Progress := Progress + 1;
                Window.Update(6, Round(Progress / NoOfRecords * 10000, 1));
                if TempXBRLSchema."Line No." <> XBRLTaxonomyLine."XBRL Schema Line No." then
                    TempXBRLSchema.Get(XBRLTaxonomyLine."XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Schema Line No.");
                FromSchemalocation := TempXBRLSchema.schemaLocation;
                XMLNode :=
                  LinkbaseDocNode.SelectSingleNode(
                    StrSubstNo(
                      '%3calculationLink/%3loc[@%4href="%1#%2"]',
                      FromSchemalocation, XBRLTaxonomyLine."Element ID", LinkPrefix, XLinkPrefix), NamespaceMgr);
                if not IsNull(XMLNode) then begin
                    fromLabel := GetAttribute(XLinkPrefix + 'label', XMLNode);
                    if XBRLSchema."xmlns:xbrli" = 'http://www.xbrl.org/2001/instance' then // spec. 2.0
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3calculationLink/%3calculationArc[@%4from="%1" and @%4arcrole="%2"]',
                              fromLabel, 'http://www.xbrl.org/linkprops/arc/parent-child', LinkPrefix, XLinkPrefix), NamespaceMgr)
                    else // 'http://www.xbrl.org/2003/instance' // spec. 2.1
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3calculationLink/%3calculationArc[@%4from="%1" and @%4arcrole="%2"]',
                              fromLabel, 'http://www.xbrl.org/2003/arcrole/summation-item', LinkPrefix, XLinkPrefix), NamespaceMgr);

                    for CurrNodeIndex := 0 to XMLNodeList.Count - 1 do begin
                        XMLNode := XMLNodeList.Item(CurrNodeIndex);
                        toLabel := GetAttribute(StrSubstNo('%1to', XLinkPrefix), XMLNode);
                        WeightTxt := GetAttribute('weight', XMLNode);
                        if WeightTxt <> '' then
                            Evaluate(Weight, WeightTxt)
                        else
                            Weight := 0;
                        XMLNode :=
                          LinkbaseDocNode.SelectSingleNode(
                            StrSubstNo('%2calculationLink/%2loc[@%3label="%1"]', toLabel, LinkPrefix, XLinkPrefix), NamespaceMgr);
                        if not IsNull(XMLNode) then begin
                            ToName := GetAttribute(StrSubstNo('%1href', XLinkPrefix), XMLNode);
                            if ToName <> '' then begin
                                i := StrPos(ToName, '#');
                                if i > 0 then begin
                                    ToSchemalocation := CopyStr(ToName, 1, i - 1);
                                    ToName := CopyStr(ToName, i + 1);
                                end else
                                    ToSchemalocation := '';
                                XBRLTaxonomyLine2.SetCurrentKey("XBRL Taxonomy Name", "Element ID");
                                XBRLTaxonomyLine2.SetRange("Element ID", ToName);
                                XBRLTaxonomyLine2.SetRange(
                                  "XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
                                if TempXBRLSchema.schemaLocation = ToSchemalocation then
                                    XBRLTaxonomyLine2.SetRange("XBRL Schema Line No.", TempXBRLSchema."Line No.")
                                else begin
                                    TempXBRLSchema.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
                                    TempXBRLSchema.SetRange(schemaLocation, ToSchemalocation);
                                    if TempXBRLSchema.FindFirst then
                                        XBRLTaxonomyLine2.SetRange("XBRL Schema Line No.", TempXBRLSchema."Line No.")
                                    else
                                        XBRLTaxonomyLine2.SetRange("XBRL Schema Line No.");
                                end;
                                if XBRLTaxonomyLine2.FindFirst then begin
                                    if not XBRLRollupLine.Get(
                                         XBRLTaxonomyLine."XBRL Taxonomy Name", XBRLTaxonomyLine."Line No.",
                                         XBRLTaxonomyLine2."Line No.")
                                    then begin
                                        XBRLRollupLine.Init();
                                        XBRLRollupLine."XBRL Taxonomy Name" := XBRLTaxonomyLine2."XBRL Taxonomy Name";
                                        XBRLRollupLine."XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
                                        XBRLRollupLine."From XBRL Taxonomy Line No." := XBRLTaxonomyLine2."Line No.";
                                        XBRLRollupLine.Weight := Weight;
                                        XBRLRollupLine.Insert();
                                    end else
                                        if XBRLRollupLine.Weight <> Weight then begin
                                            XBRLRollupLine.Weight := Weight;
                                            XBRLRollupLine.Modify();
                                        end;
                                    if XBRLTaxonomyLine."Source Type" <> XBRLTaxonomyLine."Source Type"::Rollup then begin
                                        XBRLTaxonomyLine."Source Type" := XBRLTaxonomyLine."Source Type"::Rollup;
                                        XBRLTaxonomyLine.Modify();
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            until XBRLTaxonomyLine.Next = 0;
        Window.Close;
    end;

    [Scope('OnPrem')]
    procedure ImportReference(var XBRLLinkbase: Record "XBRL Linkbase")
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLCommentLine: Record "XBRL Comment Line";
        InStr: InStream;
        LinkbaseDocument: DotNet XmlDocument;
        LinkbaseDocNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        ReferenceNode: DotNet XmlNode;
        Window: Dialog;
        CurrNodeIndex: Integer;
        i: Integer;
        j: Integer;
        Progress: Integer;
        NoOfRecords: Integer;
        Schemalocation: Text[1024];
        FromLabel: Text[250];
    begin
        XBRLSchema.Get(XBRLLinkbase."XBRL Taxonomy Name", XBRLLinkbase."XBRL Schema Line No.");
        Window.Open(
          StrSubstNo(
            Text013, XBRLSchema.TableCaption, XBRLSchema.Description, XBRLLinkbase.TableCaption));
        Window.Update(4, XBRLLinkbase.Type);
        Window.Update(5, XBRLLinkbase.Description);

        with XBRLLinkbase do begin
            TestField(Type, Type::Reference);
            CalcFields(XML);
            if not XML.HasValue then
                Error(Text012, TableCaption, "Line No.");
            XML.CreateInStream(InStr);
        end;
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, LinkbaseDocument);
        LinkbaseDocNode := LinkbaseDocument.FirstChild;
        while LowerCase(LinkbaseDocNode.NodeType.ToString) in ['xmldeclaration', 'processinginstruction', 'comment'] do
            LinkbaseDocNode := LinkbaseDocNode.NextSibling;
        Schemalocation := GetAttribute('xsi:schemaLocation', LinkbaseDocNode);
        if Schemalocation = '' then
            Error(Text015);
        i := StrPos(Schemalocation, XBRLSchema.targetNamespace + ' ');
        if i <> 0 then begin
            i := i + StrLen(XBRLSchema.targetNamespace);
            while Schemalocation[i] = ' ' do
                i := i + 1;
            j := i;
            while (Schemalocation[j] <> ' ') and (j <= StrLen(Schemalocation)) do
                j := j + 1;
            Schemalocation := CopyStr(Schemalocation, i, j - i);
        end else
            Schemalocation := XBRLSchema.schemaLocation;

        GetCommonXmnsPrefixes(LinkbaseDocNode);
        CreateNameSpaceManager(LinkbaseDocument);
        PopulateNamespaceManager(LinkbaseDocument.DocumentElement);
        PopulateNamespaceManager(LinkbaseDocNode.FirstChild);

        XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
        XBRLTaxonomyLine.SetRange("XBRL Schema Line No.", XBRLLinkbase."XBRL Schema Line No.");
        NoOfRecords := XBRLTaxonomyLine.Count();

        if XBRLTaxonomyLine.Find('-') then
            repeat
                Progress := Progress + 1;
                Window.Update(6, Round(Progress / NoOfRecords * 10000, 1));
                XMLNode :=
                  LinkbaseDocNode.SelectSingleNode(
                    StrSubstNo(
                      '%3referenceLink/%3loc[@%4href="%1#%2"]',
                      Schemalocation, XBRLTaxonomyLine."Element ID", LinkPrefix, XLinkPrefix), NamespaceMgr);
                if not IsNull(XMLNode) then begin
                    FromLabel := GetAttribute(StrSubstNo('%1label', XLinkPrefix), XMLNode);
                    if XBRLSchema."xmlns:xbrli" = 'http://www.xbrl.org/2001/instance' then // spec. 2.0
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3referenceLink/%3referenceArc[@%4from="%1" and @%4arcrole="%2"]',
                              FromLabel, 'http://www.xbrl.org/linkprops/arc/element-reference', LinkPrefix, XLinkPrefix), NamespaceMgr)
                    else // 'http://www.xbrl.org/2003/instance' // spec. 2.1
                        XMLNodeList :=
                          LinkbaseDocNode.SelectNodes(
                            StrSubstNo(
                              '%3referenceLink/%3referenceArc[@%4from="%1" and @%4arcrole="%2"]',
                              FromLabel, 'http://www.xbrl.org/2003/arcrole/concept-reference', LinkPrefix, XLinkPrefix), NamespaceMgr);

                    if XMLNodeList.Count > 0 then begin
                        XBRLCommentLine.SetRange("XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
                        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");
                        XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Reference);
                        XBRLCommentLine.DeleteAll();
                        XBRLCommentLine.Init();
                        XBRLCommentLine."XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
                        XBRLCommentLine."XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
                        XBRLCommentLine."Comment Type" := XBRLCommentLine."Comment Type"::Reference;
                        XBRLCommentLine."Line No." := 0;
                        for CurrNodeIndex := 0 to XMLNodeList.Count - 1 do begin
                            XMLNode := XMLNodeList.Item(CurrNodeIndex);
                            ReferenceNode :=
                              LinkbaseDocNode.SelectSingleNode(
                                StrSubstNo(
                                  '%2referenceLink/%2reference[@%3label="%1"]',
                                  GetAttribute(XLinkPrefix + 'to', XMLNode), LinkPrefix, XLinkPrefix), NamespaceMgr);
                            if not IsNull(ReferenceNode) then begin
                                ReferenceNode := ReferenceNode.FirstChild;
                                while not IsNull(ReferenceNode) do begin
                                    InsertReference(ReferenceNode, XBRLCommentLine);
                                    ReferenceNode := ReferenceNode.NextSibling;
                                end;
                            end;
                        end;
                    end;
                end;
            until XBRLTaxonomyLine.Next = 0;
        Window.Close;
    end;

    local procedure InsertReference(DocumentationNode2: DotNet XmlNode; var XBRLCommentLine: Record "XBRL Comment Line")
    var
        i: Integer;
        CommentTextCutIndex: Integer;
        s: Text[1024];
        CommentText: Text[1024];
    begin
        if XBRLCommentLine."Comment Type" = XBRLCommentLine."Comment Type"::Reference then begin
            s := CopyStr(DocumentationNode2.LocalName, 1, 70);
            i := StrPos(s, ':');
            if i > 0 then
                s := CopyStr(s, i + 1);
            s := s + ': ';
            i := StrLen(s);
        end;

        CommentText := CopyStr(DocumentationNode2.InnerText, 1, 1024);
        CommentTextCutIndex := StrPos(CommentText, ' ');
        if s <> '' then begin
            CommentText := CopyStr(s, 1, i) + CopyStr(CommentText, 1, 1024 - i);
            CommentTextCutIndex := CommentTextCutIndex + i;
        end;

        if (CommentTextCutIndex < 66) or (CommentTextCutIndex > MaxStrLen(XBRLCommentLine.Comment)) then
            CommentTextCutIndex := MaxStrLen(XBRLCommentLine.Comment);

        XBRLCommentLine."Line No." := XBRLCommentLine."Line No." + 10000;
        XBRLCommentLine.Comment := CopyStr(CommentText, 1, CommentTextCutIndex);
        XBRLCommentLine.Insert();
    end;

    local procedure SortPresentationOrder(ParentLineNo: Integer; ParentLevel: Integer; ParentPresentationOrder: Text[100])
    var
        TempXBRLLine0: Record "XBRL Taxonomy Line" temporary;
        PresentationOrderNo: Integer;
    begin
        TempXBRLLine0.DeleteAll();
        TempXBRLLine.SetCurrentKey("Parent Line No.");
        TempXBRLLine.SetRange("Parent Line No.", ParentLineNo);
        if not TempXBRLLine.Find('-') then begin
            TempXBRLLine.SetRange("Parent Line No.");
            exit;
        end;
        repeat
            if ParentLineNo = 0 then begin
                TempXBRLLine.Level := ParentLevel;
                TempXBRLLine."Presentation Order" := CopyStr(Format(100000000 + TempXBRLLine."Line No."), 2)
            end else begin
                TempXBRLLine.Level := ParentLevel + 1;
                PresentationOrderNo := PresentationOrderNo + 1;
                if TempXBRLLine."Presentation Order No." = 0 then
                    TempXBRLLine."Presentation Order No." := PresentationOrderNo;
                TempXBRLLine."Presentation Order" :=
                  ParentPresentationOrder + '.' + CopyStr(Format(1000 + TempXBRLLine."Presentation Order No."), 2);
                // Presentation order must be unique
                TempXBRLLine0.Reset();
                TempXBRLLine0.SetCurrentKey("XBRL Taxonomy Name", "Presentation Order");
                TempXBRLLine0.SetRange("XBRL Taxonomy Name", TempXBRLLine."XBRL Taxonomy Name");
                TempXBRLLine0.SetRange("Presentation Order", TempXBRLLine."Presentation Order");
                if not TempXBRLLine0.IsEmpty then begin
                    TempXBRLLine0.SetRange("Presentation Order");
                    TempXBRLLine0.SetRange("Parent Line No.", ParentLineNo);
                    TempXBRLLine0.FindLast;
                    TempXBRLLine."Presentation Order" := IncStr(TempXBRLLine0."Presentation Order");
                end;
            end;
            TempXBRLLine.Modify();
            TempXBRLLine0 := TempXBRLLine;
            TempXBRLLine0.Insert();
        until TempXBRLLine.Next = 0;
        TempXBRLLine.SetRange("Parent Line No.");

        TempXBRLLine0.Reset();
        if TempXBRLLine0.Find('-') then
            repeat
                SortPresentationOrder(TempXBRLLine0."Line No.", TempXBRLLine0.Level, TempXBRLLine0."Presentation Order");
            until TempXBRLLine0.Next = 0;
        TempXBRLLine.Reset();
    end;

    local procedure GetCommonXmnsPrefixes(DocNode: DotNet XmlNode)
    begin
        xsdPrefix := GetXmlnsPrefix('http://www.w3.org/2001/XMLSchema', DocNode);

        XLinkPrefix := GetXmlnsPrefix('http://www.w3.org/1999/xlink', DocNode);

        LinkPrefix := GetXmlnsPrefix('http://www.xbrl.org/2001/XLink/xbrllinkbase', DocNode);
        if LinkPrefix = '' then
            LinkPrefix := GetXmlnsPrefix('http://www.xbrl.org/2003/linkbase', DocNode);

        xbrliPrefix := GetXmlnsPrefix('http://www.xbrl.org/2001/instance', DocNode);
        if xbrliPrefix = '' then
            xbrliPrefix := GetXmlnsPrefix('http://www.xbrl.org/2003/instance', DocNode);
    end;

    local procedure GetXmlnsPrefix(NameSpace: Text[260]; DocNode: DotNet XmlNode): Text
    var
        DocNode2: DotNet XmlNode;
        Prefix: Text;
        i: Integer;
    begin
        Prefix := GetAttributeNameByValue(NameSpace, DocNode, false);
        if (Prefix = '') and DocNode.HasChildNodes then begin
            DocNode2 := DocNode.FirstChild;
            Prefix := GetAttributeNameByValue(NameSpace, DocNode2, false);
        end;

        i := StrPos(Prefix, 'xmlns:');
        if i > 0 then begin
            Prefix := CopyStr(Prefix, i + 6);
            if StrLen(Prefix) > 0 then
                Prefix := Prefix + ':';
        end else
            Prefix := '';
        exit(Prefix);
    end;

    [Scope('OnPrem')]
    procedure ReadNamespaceFromSchema(var SchemaLocation: Text): Text[1024]
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        TaxonomyNode: DotNet XmlNode;
        BlobInStream: InStream;
        i: Integer;
        FileName: Text;
    begin
        if StrPos(SchemaLocation, '/') <= 0 then begin
            i := StrLen(SchemaLocation);
            if i > 1 then
                while (i > 1) and (SchemaLocation[i] <> '\') do
                    i := i - 1;
            if i > 1 then
                FileName := CopyStr(SchemaLocation, 1, i);
        end;
        FileName := FileMgt.BLOBImport(TempBlob, FileName + '*.xsd');
        if FileName = '' then
            exit('');

        TempBlob.CreateInStream(BlobInStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(BlobInStream, TaxonomyDocument);
        TaxonomyNode := TaxonomyDocument.DocumentElement;
        SchemaLocation := FileName;
        exit(GetAttribute('targetNamespace', TaxonomyNode));
    end;

    procedure SetFilesOnServer(NewFilesOnServer: Boolean)
    begin
        // FilesOnServer is used when scripting this codeunit.
        FilesOnServer := NewFilesOnServer;
    end;

    local procedure PopulateNamespaceManager(XmlNode: DotNet XmlNode)
    var
        Attribute: DotNet XmlAttribute;
        Attributes: DotNet XmlAttributeCollection;
        i: Integer;
        Prefix: Text;
    begin
        if not IsNull(XmlNode) then begin
            Attributes := XmlNode.Attributes;
            for i := 0 to Attributes.Count - 1 do begin
                Attribute := Attributes.Item(i);
                if StrPos(Attribute.Name, 'xmlns') = 1 then
                    if StrPos(Attribute.Name, ':') > 0 then begin
                        Prefix := CopyStr(Attribute.Name, StrPos(Attribute.Name, ':') + 1);
                        if XmlNode.Prefix = Prefix then
                            xsdPrefix := Prefix + ':';
                        NamespaceMgr.AddNamespace(Prefix, Attribute.Value)
                    end else begin
                        NamespaceMgr.AddNamespace('defns', Attribute.Value);
                        xsdPrefix := 'defns:'
                    end;
            end;

            if XLinkPrefix = '' then
                XLinkPrefix := xsdPrefix;
            if LinkPrefix = '' then
                LinkPrefix := xsdPrefix;
            if xbrliPrefix = '' then
                xbrliPrefix := xsdPrefix;
        end;
    end;

    local procedure IsWindowsClientSession(): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId, SessionId);
        exit(ActiveSession."Client Type" = ActiveSession."Client Type"::"Windows Client");
    end;

    local procedure CreateNameSpaceManager(XmlDocument: DotNet XmlDocument)
    begin
        if not IsNull(NamespaceMgr) then
            Clear(NamespaceMgr);

        NamespaceMgr := NamespaceMgr.XmlNamespaceManager(XmlDocument.NameTable);
    end;

    local procedure GetDocumentPreFix(TaxonomyNode: DotNet XmlNode): Text[30]
    begin
        if StrPos(TaxonomyNode.Name, ':') > 1 then
            exit(CopyStr(TaxonomyNode.Name, 1, StrPos(TaxonomyNode.Name, ':')));
    end;

    local procedure IsElementTypeDescription(ElementNode: DotNet XmlNode): Boolean
    var
        XMLElement: DotNet XmlNode;
    begin
        // "Sequence" type
        XMLElement :=
          ElementNode.OwnerDocument.DocumentElement.SelectSingleNode(
            StrSubstNo('%1element/%1complexType/%1sequence/%1element[@ref="%2%3"]',
              xsdPrefix, targetNamespacePrefix, GetAttribute('name', ElementNode)),
            NamespaceMgr);

        // "Choice" type
        if IsNull(XMLElement) then
            XMLElement :=
              ElementNode.OwnerDocument.DocumentElement.SelectSingleNode(
                StrSubstNo('%1element/%1complexType/%1choice/%1element[@ref="%2%3"]',
                  xsdPrefix, targetNamespacePrefix, GetAttribute('name', ElementNode)),
                NamespaceMgr);

        if IsNull(XMLElement) then
            XMLElement :=
              ElementNode.OwnerDocument.DocumentElement.SelectSingleNode(
                StrSubstNo('%1element/%1complexType/%1choice/%1element[@ref="%2%3"]',
                  xsdPrefix, targetNamespacePrefix, GetAttribute('substitutionGroup', ElementNode)),
                NamespaceMgr);

        exit(not IsNull(XMLElement));
    end;

    local procedure SelectSingleNode(SourceNode: DotNet XmlNode; XPathExpr: Text; Prefix: Text; var ResultNode: DotNet XmlNode)
    begin
        ResultNode := SourceNode.SelectSingleNode(StrSubstNo(XPathExpr, Prefix), NamespaceMgr);
        if IsNull(ResultNode) then
            ResultNode := SourceNode.SelectSingleNode(StrSubstNo(XPathExpr, ''), NamespaceMgr);
    end;

    local procedure SelectNodes(SourceNode: DotNet XmlNode; XPathExpr: Text; Prefix: Text; var ResultElementList: DotNet XmlNodeList)
    begin
        ResultElementList := SourceNode.SelectNodes(StrSubstNo(XPathExpr, Prefix), NamespaceMgr);
        if ResultElementList.Count = 0 then
            ResultElementList := SourceNode.SelectNodes(StrSubstNo(XPathExpr, ''), NamespaceMgr);
    end;

    local procedure CopyXBRLElementsForPresentation(var LinkbaseDocNode: DotNet XmlNode; xbrli: Text; XBRLTaxonomyName: Code[20]; XBRLElementName: Text; var LastXBRLLineNo: Integer)
    var
        XBRLTaxonomyLine2: Record "XBRL Taxonomy Line";
        XMLNodeList: DotNet XmlNodeList;
        i: Integer;
    begin
        if xbrli = 'http://www.xbrl.org/2001/instance' then // spec. 2.0
            XMLNodeList :=
              LinkbaseDocNode.SelectNodes(
                StrSubstNo(
                  '%3presentationLink/%3presentationArc[@%4to="%1" and @%4arcrole="%2"]',
                  XBRLElementName, 'http://www.xbrl.org/linkprops/arc/parent-child', LinkPrefix, XLinkPrefix), NamespaceMgr)
        else // 'http://www.xbrl.org/2003/instance' // spec. 2.1
            XMLNodeList :=
              LinkbaseDocNode.SelectNodes(
                StrSubstNo(
                  '%3presentationLink/%3presentationArc[@%4to="%1" and @%4arcrole="%2"]',
                  XBRLElementName, 'http://www.xbrl.org/2003/arcrole/parent-child', LinkPrefix, XLinkPrefix), NamespaceMgr);

        // TempXBRLLine is a global variable, so we must save its current state before any manupulations to restore it later
        XBRLTaxonomyLine2.Copy(TempXBRLLine);
        TempXBRLLine.Reset();
        TempXBRLLine.SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
        TempXBRLLine.SetRange("Element ID", XBRLElementName);
        TempXBRLLine.SetRange("Type Description Element", false);

        for i := 1 to XMLNodeList.Count - TempXBRLLine.Count do begin
            LastXBRLLineNo += 10000;
            CopyElementLine(XBRLTaxonomyName, XBRLElementName, LastXBRLLineNo);
        end;

        TempXBRLLine.Copy(XBRLTaxonomyLine2);
    end;

    local procedure CopyElementLine(TaxonomyName: Code[20]; ElementName: Text; XBRLLineNo: Integer)
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
    begin
        with TempXBRLLine do begin
            XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", TaxonomyName);
            XBRLTaxonomyLine.SetRange("Element ID", ElementName);
            if XBRLTaxonomyLine.FindFirst then begin
                TransferFields(XBRLTaxonomyLine);
                "Presentation Linkbase Line No." := 0;
                "Line No." := XBRLLineNo;
                Insert;

                CopyRelatedXBRLSetup(TaxonomyName, XBRLTaxonomyLine."Line No.", XBRLLineNo, DATABASE::"XBRL Taxonomy Label");
                CopyRelatedXBRLSetup(TaxonomyName, XBRLTaxonomyLine."Line No.", XBRLLineNo, DATABASE::"XBRL Comment Line");
                CopyRelatedXBRLSetup(TaxonomyName, XBRLTaxonomyLine."Line No.", XBRLLineNo, DATABASE::"XBRL G/L Map Line");
                CopyRelatedXBRLSetup(TaxonomyName, XBRLTaxonomyLine."Line No.", XBRLLineNo, DATABASE::"XBRL Rollup Line");
            end;
        end;
    end;

    local procedure CopyRelatedXBRLSetup(TaxonomyName: Code[20]; FromTaxonomyLineNo: Integer; ToTaxonomyLineNo: Integer; TableNo: Integer)
    var
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
        FilterFieldRef: FieldRef;
        NewLineNoFieldRef: FieldRef;
    begin
        FromRecRef.Open(TableNo);
        FilterFieldRef := FromRecRef.Field(1);  // Field "XBRL Taxonomy Name"
        FilterFieldRef.SetRange(TaxonomyName);
        FilterFieldRef := FromRecRef.Field(2);  // Field "XBRL Taxonomy Line No."
        FilterFieldRef.SetRange(FromTaxonomyLineNo);
        if FromRecRef.FindSet then
            repeat
                ToRecRef := FromRecRef.Duplicate;
                NewLineNoFieldRef := ToRecRef.Field(2);
                NewLineNoFieldRef.Value := ToTaxonomyLineNo;
                ToRecRef.Insert();
            until FromRecRef.Next = 0;
    end;

    local procedure LoadLinkbaseDocument(var XBRLLinkbase: Record "XBRL Linkbase"; var LinkbaseDocument: DotNet XmlDocument)
    var
        InStr: InStream;
    begin
        with XBRLLinkbase do begin
            TestField(Type, Type::Presentation);
            CalcFields(XML);
            if not XML.HasValue then
                Error(Text012, TableCaption, "Line No.");
            XML.CreateInStream(InStr);
        end;
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, LinkbaseDocument);
    end;

    local procedure FindLinkbaseDocNode(var LinkbaseDocument: DotNet XmlDocument; var LinkbaseDocNode: DotNet XmlNode)
    begin
        LinkbaseDocNode := LinkbaseDocument.FirstChild;
        while LowerCase(LinkbaseDocNode.NodeType.ToString) in ['xmldeclaration', 'processinginstruction', 'comment'] do
            LinkbaseDocNode := LinkbaseDocNode.NextSibling;
    end;

    local procedure SaveTaxonomyLines(var TempXBRLTaxonomyLine: Record "XBRL Taxonomy Line" temporary)
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
    begin
        if TempXBRLTaxonomyLine.FindSet then
            repeat
                with XBRLTaxonomyLine do begin
                    XBRLTaxonomyLine := TempXBRLTaxonomyLine;
                    SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
                    SetRange("Line No.", "Line No.");
                    if IsEmpty then
                        Insert
                    else
                        Modify;
                end;
            until TempXBRLTaxonomyLine.Next = 0;
    end;

    local procedure InitTaxonomyLinesBuf(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; var TempXBRLTaxonomyLine: Record "XBRL Taxonomy Line" temporary)
    begin
        TempXBRLTaxonomyLine.DeleteAll();
        XBRLTaxonomyLine.SetRange("Type Description Element", false);
        if XBRLTaxonomyLine.FindSet then
            repeat
                TempXBRLTaxonomyLine := XBRLTaxonomyLine;
                TempXBRLTaxonomyLine.Insert();
            until XBRLTaxonomyLine.Next = 0;
    end;

    local procedure UpdateSchemaLocation(var TempXBRLSchema: Record "XBRL Schema" temporary; var XBRLSchema: Record "XBRL Schema"; XBRLLinkbase: Record "XBRL Linkbase"; SchemaLocation: Text; var FromSchemalocation: Text)
    var
        i: Integer;
        j: Integer;
    begin
        TempXBRLSchema.DeleteAll();
        XBRLSchema.SetRange("XBRL Taxonomy Name", XBRLLinkbase."XBRL Taxonomy Name");
        if XBRLSchema.Find('-') then
            repeat
                if XBRLSchema."Line No." = XBRLLinkbase."XBRL Schema Line No." then begin
                    i := StrPos(SchemaLocation, XBRLSchema.targetNamespace + ' ');
                    if i > 0 then begin
                        i := i + StrLen(XBRLSchema.targetNamespace);
                        while (i < StrLen(SchemaLocation)) and (SchemaLocation[i] <> ' ') do
                            i := i + 1;
                        while (i < StrLen(SchemaLocation)) and (SchemaLocation[i] = ' ') do
                            i := i + 1;
                        j := i;
                        while (i < StrLen(SchemaLocation)) and (SchemaLocation[i] <> ' ') do
                            i := i + 1;
                        if i = StrLen(SchemaLocation) then
                            i := i + 1;
                        XBRLSchema.schemaLocation := CopyStr(SchemaLocation, j, i - j);
                        XBRLSchema.Modify();
                        FromSchemalocation := XBRLSchema.schemaLocation;
                    end;
                end;
                TempXBRLSchema := XBRLSchema;
                TempXBRLSchema.Insert();
            until XBRLSchema.Next = 0;
    end;
}

