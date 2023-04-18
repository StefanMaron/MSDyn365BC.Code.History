codeunit 1283 "Export Generic XML"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchTableFilter: Record "Data Exch. Table Filter";
        xmlDoc: XmlDocument;
        OutStr: OutStream;
        IsHandled: Boolean;
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchLineDef.SetFilter(Code, '<>%1', Rec."Data Exch. Line Def Code");
        if DataExchLineDef.FindSet() then
            if DataExchLineDef."Data Line Tag" <> '' then
                Error(RootHeaderElementNotFoundErr)
            else
                repeat
                    DataExchMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
                    DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
                    DataExchMapping.FindFirst();

                    DataExch.Init();
                    DataExch."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
                    DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
                    if DataExchTableFilter.Get(Rec."Entry No.", DataExchMapping."Table ID") then begin
                        DataExchTableFilter.CalcFields("Table Filters");
                        DataExch."Table Filters" := DataExchTableFilter."Table Filters";
                    end else
                        DataExch."Table Filters" := Rec."Table Filters";
                    DataExch.Insert(true);

                    OnBeforeProcessDataExc(DataExch, IsHandled);
                    If not IsHandled then begin
                        if DataExchMapping."Pre-Mapping Codeunit" > 0 then
                            Codeunit.Run(DataExchMapping."Pre-Mapping Codeunit", DataExch);

                        Codeunit.Run(DataExchMapping."Mapping Codeunit", DataExch);

                        if DataExchMapping."Post-Mapping Codeunit" > 0 then
                            Codeunit.Run(DataExchMapping."Post-Mapping Codeunit", DataExch);

                        if DataExchLineDef."Line Type" = DataExchLineDef."Line Type"::Detail then
                            ProcessDetails(DataExch, xmlDoc)
                        else
                            ProcessHeader(DataExch, xmlDoc);
                    end;
                    DataExch.Delete(true);
                until DataExchLineDef.Next() = 0;

        ProcessDetails(Rec, xmlDoc);

        Rec."File Content".CreateOutStream(OutStr);
        xmlDoc.WriteTo(OutStr);
    end;

    local procedure ProcessDetails(var DataExch: Record "Data Exch."; var xmlDoc: XmlDocument);
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        xmlDocPerLine: XmlDocument;
        xmlElem, xmlElemRoot, xmlElemSubRoot : XmlElement;
        xmlNode: XmlNode;
        i, LineCount : Integer;
        isSubRoot, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeExportDetails(DataExch, xmlDoc, IsHandled);
        if IsHandled then
            exit;

        DataExchDef.Get(DataExch."Data Exch. Def Code");
        DataExchLineDef.Get(DataExch."Data Exch. Def Code", DataExch."Data Exch. Line Def Code");
        if DataExchLineDef."Data Line Tag" <> '' then begin
            xmlDoc.SelectSingleNode(DataExchLineDef."Data Line Tag".Replace('/', '/' + DefNameSpacePrefixLbl + ':').Replace('[', '[' + DefNameSpacePrefixLbl + ':'), xmlNamespaceManager, xmlNode);
            // currently xPath with only one [node = value] criteria is supported
            xmlElemRoot := xmlNode.AsXmlElement();
        end else begin
            xmlDoc := xmlDocument.Create();
            xmlElemRoot := xmlElement.Create('root');
            xmlDoc.Add(xmlElemRoot);
        end;

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindLast() then
            LineCount := DataExchField."Line No."
        else
            LineCount := 1;

        for i := 1 to LineCount do begin
            DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
            DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
            if DataExchColumnDef.FindSet() then begin
                xmlDocPerLine := xmlDocument.Create();
                xmlElem := xmlElement.Create('root');
                xmlDocPerLine.Add(xmlElem);
                isSubRoot := true;
                repeat
                    ProcessDataExchColumnDef(DataExchColumnDef, GetDataExchFieldValue(DataExch."Entry No.", i, DataExchColumnDef."Column No."), xmlElem, xmlElemSubRoot, isSubRoot);
                until DataExchColumnDef.Next() = 0;
                xmlElemRoot.Add(xmlElemSubRoot);
                Clear(xmlDocPerLine);
            end;
        end;
    end;

    local procedure ProcessHeader(var DataExch: Record "Data Exch."; var xmlDoc: XmlDocument)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        xmlElem, xmlElemRoot, xmlElemSubRoot : XmlElement;
        xmlSubDoc: XmlDocument;
        xmlNode: XmlNode;
        xmlDec: XmlDeclaration;
        xmlPath, nName, nVal : Text;
        isSubRoot, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeExportHeader(DataExch, xmlDoc, IsHandled);
        if IsHandled then
            exit;

        DataExchDef.Get(DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        if DataExchColumnDef.FindSet() then
            if DataExchLineDef.Get(DataExch."Data Exch. Def Code", DataExch."Data Exch. Line Def Code") and (DataExchLineDef."Data Line Tag" <> '') then begin
                xmlDoc.SelectSingleNode(DataExchLineDef."Data Line Tag".Replace('/', '/' + DefNameSpacePrefixLbl + ':'), xmlNamespaceManager, xmlNode);
                xmlElemRoot := xmlNode.AsXmlElement();

                xmlSubDoc := xmlDocument.Create();
                xmlElem := xmlElement.Create('root');
                xmlSubDoc.Add(xmlElem);
                isSubRoot := true;
                repeat
                    ProcessDataExchColumnDef(DataExchColumnDef, GetDataExchFieldValue(DataExch."Entry No.", 1, DataExchColumnDef."Column No."), xmlElem, xmlElemSubRoot, isSubRoot);
                until DataExchColumnDef.Next() = 0;
                xmlElemRoot.Add(xmlElemSubRoot);
            end else begin
                xmlDoc := xmlDocument.Create();
                IsHandled := false;
                OnBeforeCreateXMLDeclaration(xmlDec, IsHandled);
                if not IsHandled then
                    xmlDec := xmlDeclaration.Create('1.0', 'utf-8', 'yes');
                xmlDoc.SetDeclaration(xmlDec);

                xmlPath := DataExchColumnDef.Path;
                if not xmlPath.Split('/').Get(2, nName) then
                    nName := 'root';

                nVal := GetDataExchFieldValue(DataExch."Entry No.", 1, DataExchColumnDef."Column No.");

                DefaultNameSpace := DataExchLineDef.Namespace;
                xmlNamespaceManager.AddNamespace(DefNameSpacePrefixLbl, DefaultNameSpace);

                IsHandled := false;
                OnBeforeCreateRootElement(xmlElem, nName, nVal, DefaultNameSpace, xmlNamespaceManager, IsHandled);
                if not IsHandled then
                    xmlElem := xmlElement.Create(nName, DefaultNameSpace, nVal);

                xmlDoc.Add(xmlElem);
                if DataExchColumnDef.Next() = 0 then
                    exit;

                repeat
                    ProcessDataExchColumnDef(DataExchColumnDef, GetDataExchFieldValue(DataExch."Entry No.", 1, DataExchColumnDef."Column No."), xmlElem, xmlElemSubRoot, isSubRoot);
                    xmlDoc.GetRoot(xmlElem);
                until DataExchColumnDef.Next() = 0;
            end;
    end;

    local procedure GetDataExchFieldValue(DataExchEntryNo: Integer; LineNo: Integer; ColumnNo: Integer) nVal: Text
    var
        DataExchField: Record "Data Exch. Field";
    begin
        if DataExchField.Get(DataExchEntryNo, LineNo, ColumnNo) then
            nVal := DataExchField.GetValue()
        else
            nVal := '';
    end;

    local procedure ProcessDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; eValue: Text; var xmlElem: XmlElement; var xmlElemSubRoot: XmlElement; var isSubRoot: Boolean)
    var
        xmlElemNew: XmlElement;
        xmlNode: XmlNode;
        xmlNodeList: XmlNodeList;
        xmlAttributesText: List of [Text];
        xmlAttributeText: Text;
        xPathPart, attrName, attrValue, eName : Text;
        xmlNodesText: List of [Text];
        i: Integer;
        IsHandled: Boolean;
    begin
        Clear(xmlNodesText);
        xPathPart := DataExchColumnDef.Path;
        xmlNodesText := xPathPart.Split('/');
        for i := 1 to xmlNodesText.Count() do begin
            xPathPart := xmlNodesText.Get(i);
            if xPathPart <> '' then begin
                xmlElem.SelectNodes(StrSubstNo(xPathLbl, DefNameSpacePrefixLbl, xPathPart), xmlNamespaceManager, xmlNodeList);
                if xmlNodeList.Count = 0 then
                    case true of
                        StrPos(xPathPart, '@') = 0:
                            begin
                                eName := xPathPart;
                                IsHandled := false;
                                OnBeforeCreateXMLNodeWithoutAttributes(eName, eValue, DataExchColumnDef, DefaultNameSpace, IsHandled);
                                if not IsHandled then begin
                                    if DataExchColumnDef."Export If Not Blank" and (eValue = '') then
                                        exit;
                                    if i = xmlNodesText.Count() then
                                        xmlElemNew := xmlElement.Create(eName, DefaultNameSpace, eValue)
                                    else
                                        xmlElemNew := xmlElement.Create(eName, DefaultNameSpace, '');
                                    xmlElem.Add(xmlElemNew);
                                    xmlElem := xmlElemNew;
                                    if isSubRoot then begin
                                        xmlElemSubRoot := xmlElem;
                                        isSubRoot := false;
                                    end;
                                end;
                            end;
                        (StrPos(xPathPart, '@') <> 0) and (StrPos(xPathPart, '=') = 0):
                            begin
                                eName := xPathPart.Split('[').Get(1);
                                xmlElem.SelectSingleNode(StrSubstNo(xPathLbl, DefNameSpacePrefixLbl, eName), xmlNamespaceManager, xmlNode);
                                xmlElem := xmlNode.AsXmlElement();
                                attrName := xPathPart.Split('[@').Get(2).TrimEnd(']');

                                IsHandled := false;
                                OnBeforeCreateXMLAttribute(attrName, eValue, DataExchColumnDef, DefaultNameSpace, IsHandled);
                                if not IsHandled then
                                    xmlElem.SetAttribute(attrName, eValue);
                            end;
                        (StrPos(xPathPart, '@') <> 0) and (StrPos(xPathPart, '=') <> 0):
                            begin
                                eName := xPathPart.Split('[').Get(1);
                                IsHandled := false;
                                OnBeforeCreateXMLNodeWithAttributes(eName, eValue, DataExchColumnDef, DefaultNameSpace, IsHandled);
                                if not IsHandled then begin
                                    if DataExchColumnDef."Export If Not Blank" and (eValue = '') then
                                        exit;
                                    if i = xmlNodesText.Count() then
                                        xmlElemNew := xmlElement.Create(eName, DefaultNameSpace, eValue)
                                    else
                                        xmlElemNew := xmlElement.Create(eName, DefaultNameSpace, '');
                                    xmlElem.Add(xmlElemNew);
                                    xmlElem := xmlElemNew;

                                    attrValue := xPathPart.Split('[').Get(2).TrimEnd(']');
                                    xmlAttributesText := attrValue.Split(' and ');
                                    foreach xmlAttributeText in xmlAttributesText do begin
                                        attrName := xmlAttributeText.Split('=').Get(1).TrimStart('@');
                                        attrValue := xmlAttributeText.Split('=').Get(2).TrimStart('"').TrimEnd('"');
                                        xmlElem.SetAttribute(attrName, attrValue)
                                    end;
                                    if isSubRoot then begin
                                        xmlElemSubRoot := xmlElem;
                                        isSubRoot := false;
                                    end;
                                end;
                            end;
                        else
                            Error(XPathNotSupportedErr);
                    end
                else begin
                    xmlNodeList.Get(xmlNodeList.Count, xmlNode);
                    xmlElem := xmlNode.AsXmlElement();
                end;
            end;
        end;
    end;

    var
        DefaultNameSpace: Text;
        xmlNamespaceManager: XmlNamespaceManager;
        RootHeaderElementNotFoundErr: Label 'Root header element is not found.';
        XPathNotSupportedErr: Label 'xPath is not supported.';
        DefNameSpacePrefixLbl: Label 'def', Locked = true;
        xPathLbl: Label '//%1:%2', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateXMLNodeWithoutAttributes(var xmlNodeName: Text; var xmlNodeValue: Text; var DataExchColumnDef: Record "Data Exch. Column Def"; var DefaultNameSpace: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateXMLAttribute(var xmlAttributeName: Text; var xmlAttributeValue: Text; var DataExchColumnDef: Record "Data Exch. Column Def"; var DefaultNameSpace: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateXMLNodeWithAttributes(var xmlNodeName: Text; var xmlNodeValue: Text; var DataExchColumnDef: Record "Data Exch. Column Def"; var DefaultNameSpace: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportHeader(var DataExch: Record "Data Exch."; var xmlDoc: XmlDocument; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportDetails(var DataExch: Record "Data Exch."; var xmlDoc: XmlDocument; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDataExc(var DataExch: Record "Data Exch."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateXMLDeclaration(var xmlDec: XmlDeclaration; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRootElement(var xmlElem: XmlElement; var nName: Text; var nVal: Text; DefaultNameSpace: Text; var xmlNamespaceManager: XmlNamespaceManager; var IsHandled: Boolean)
    begin
    end;
}