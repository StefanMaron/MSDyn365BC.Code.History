namespace Microsoft.Bank.Statement;

using System;
using System.IO;
using System.Xml;

codeunit 1200 "Import Bank Statement"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNode: DotNet XmlNode;
        XMLStream: InStream;
        LineNo: Integer;
    begin
        Rec."File Content".CreateInStream(XMLStream);
        XMLDOMManagement.LoadXMLNodeFromInStream(XMLStream, XmlNode);

        DataExchLineDef.Get(Rec."Data Exch. Def Code", Rec."Data Exch. Line Def Code");

        ProgressWindow.Open(ProgressMsg);
        Parse(DataExchLineDef, Rec."Entry No.", XmlNode, '', '', LineNo, LineNo);
        ProgressWindow.Close();
        OnRunOnAfterRun(Rec);
    end;

    var
        ProgressMsg: Label 'Preparing line number #1#######';
        ProgressWindow: Dialog;

    local procedure Parse(DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; XMLNode: DotNet XmlNode; ParentPath: Text; NodeId: Text[250]; var LastGivenLineNo: Integer; CurrentLineNo: Integer)
    var
        CurrentDataExchLineDef: Record "Data Exch. Line Def";
        XMLAttributeCollection: DotNet XmlAttributeCollection;
        XMLNodeList: DotNet XmlNodeList;
        XMLNodeType: DotNet XmlNodeType;
        i: Integer;
    begin
        CurrentDataExchLineDef.SetRange("Data Line Tag", ParentPath + '/' + XMLNode.LocalName);
        CurrentDataExchLineDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        if CurrentDataExchLineDef.FindFirst() then begin
            DataExchLineDef := CurrentDataExchLineDef;
            LastGivenLineNo += 1;
            CurrentLineNo := LastGivenLineNo;
            DataExchLineDef.ValidateNamespace(XMLNode);
        end;

        if XMLNode.NodeType.Equals(XMLNodeType.Text) or XMLNode.NodeType.Equals(XMLNodeType.CDATA) then
            InsertColumn(ParentPath,
              CurrentLineNo, NodeId, XMLNode.Value, XMLNode.ParentNode.Name,
              DataExchLineDef, EntryNo);

        if not IsNull(XMLNode.Attributes) then begin
            XMLAttributeCollection := XMLNode.Attributes;
            for i := 1 to XMLAttributeCollection.Count do
                InsertColumn(ParentPath + '/' + XMLNode.LocalName + '[@' + XMLAttributeCollection.Item(i - 1).Name + ']',
                  CurrentLineNo, NodeId, XMLAttributeCollection.Item(i - 1).Value, XMLAttributeCollection.Item(i - 1).Name,
                  DataExchLineDef, EntryNo);
        end;

        if XMLNode.HasChildNodes then begin
            XMLNodeList := XMLNode.ChildNodes;
            for i := 1 to XMLNodeList.Count do
                Parse(DataExchLineDef, EntryNo, XMLNodeList.Item(i - 1), ParentPath + '/' + XMLNode.LocalName,
                  NodeId + Format(i, 0, '<Integer,4><Filler Char,0>'), LastGivenLineNo, CurrentLineNo);
        end;
    end;

    local procedure InsertColumn(Path: Text; LineNo: Integer; NodeId: Text[250]; Value: Text; Name: Text; var DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertColumn(DataExchLineDef, EntryNo, LineNo, NodeId, Name, ProgressWindow, IsHandled, Path, Value);
        if IsHandled then
            exit;

        // Note: The Data Exch. variable is passed by reference only to improve performance.
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Path, Path);

        if DataExchColumnDef.FindFirst() then begin
            ProgressWindow.Update(1, LineNo);
            if DataExchColumnDef."Use Node Name as Value" then
                DataExchField.InsertRecXMLField(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, Name,
                  DataExchLineDef.Code)
            else
                DataExchField.InsertRecXMLField(EntryNo, LineNo, DataExchColumnDef."Column No.", NodeId, Value,
                  DataExchLineDef.Code);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterRun(var DataExch: Record "Data Exch.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertColumn(var DataExchLineDef: Record "Data Exch. Line Def"; EntryNo: Integer; LineNo: Integer; NodeId: Text[250]; Name: Text; var ProgressWindow: Dialog; var IsHandled: Boolean; Path: Text; Value: Text)
    begin
    end;
}

