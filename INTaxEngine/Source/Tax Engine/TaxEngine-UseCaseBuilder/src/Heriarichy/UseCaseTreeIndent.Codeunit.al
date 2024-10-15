codeunit 20299 "Use Case Tree-Indent"
{
    TableNo = "Use Case Tree Node";

    trigger OnRun()
    begin
        Indent();
    end;

    var
        UseCaseTreeNode: Record "Use Case Tree Node";
        NodeValueIndentedMsg: Label 'All Node values between a Begin and the matching End are indented by one level. ';
        IndentingNodeValueMsg: Label 'Indenting Node Values @1@@@@@@@@@@@@@@@@@@';
        MissingBeginTotalErr: Label 'End %1 is missing a matching Begin.', Comment = '%1 = Node value';
        ArrayExceededErr: Label 'You can only indent %1 levels for node values of the type Begin.', Comment = '%1 = A number bigger than 1';
        Window: Dialog;
        NodeCode: array[10] of Code[20];
        i: Integer;

    procedure Indent()
    var
        NoOfNodes: Integer;
        Progress: Integer;
    begin
        Window.Open(IndentingNodeValueMsg);

        NoOfNodes := UseCaseTreeNode.Count();
        if NoOfNodes = 0 then
            NoOfNodes := 1;
        if UseCaseTreeNode.FindSet() then
            repeat
                Progress := Progress + 1;
                Window.Update(1, 10000 * Progress div NoOfNodes);

                if UseCaseTreeNode."Node Type" = UseCaseTreeNode."Node Type"::"End" then begin
                    if i < 1 then
                        Error(
                          MissingBeginTotalErr,
                          UseCaseTreeNode.Code);
                    i := i - 1;
                end;

                UseCaseTreeNode.Indentation := i;
                ValidateAndUpdateTableName(UseCaseTreeNode);
                UseCaseTreeNode.Modify();

                if UseCaseTreeNode."Node Type" = UseCaseTreeNode."Node Type"::"Begin" then begin
                    i := i + 1;
                    if i > ArrayLen(NodeCode) then
                        Error(ArrayExceededErr, ArrayLen(NodeCode));
                    NodeCode[i] := UseCaseTreeNode.Code;
                end;
            until UseCaseTreeNode.Next() = 0;

        Window.Close();
    end;

    procedure ValidateAndUpdateTableName(var UseCaseTreeNode: Record "Use Case Tree Node")
    var
        UseCaseTreeNode2: Record "Use Case Tree Node";
    begin
        if UseCaseTreeNode.Indentation <= 1 then
            exit;

        UseCaseTreeNode2.SetFilter(Code, '<%1', UseCaseTreeNode.Code);
        UseCaseTreeNode2.SetFilter(Indentation, '%1..%2', 2, UseCaseTreeNode.Indentation - 1);
        if not UseCaseTreeNode2.FindLast() then
            exit;

        if UseCaseTreeNode2."Table ID" <> 0 then
            if UseCaseTreeNode."Table ID" <> 0 then
                UseCaseTreeNode.TestField("Table ID", UseCaseTreeNode2."Table ID")
            else
                UseCaseTreeNode."Table ID" := UseCaseTreeNode2."Table ID";
    end;

    procedure ExportNodes(var UseCaseTreeNode: Record "Use Case Tree Node")
    var
        TempBlob: Codeunit "Temp Blob";
        OStream: OutStream;
        IStream: InStream;
        JArray: JsonArray;
        JsonText: Text;
        FileText: Text;
    begin
        UseCaseTreeNode.FindSet();
        repeat
            ExportSingleTreeNode(UseCaseTreeNode, JArray);
        until UseCaseTreeNode.Next() = 0;

        JArray.WriteTo(JsonText);
        TempBlob.CreateOutStream(OStream);
        OStream.WriteText(JsonText);
        FileText := 'UseCaseTree.json';
        TempBlob.CreateInStream(IStream);
        DownloadFromStream(IStream, '', '', '', FileText);
    end;

    procedure ImportNodes()
    var
        TypeHelper: Codeunit "Type Helper";
        FileText: Text;
        JsonText: Text;
        IStream: InStream;
    begin
        UploadIntoStream('', '', '', FileText, IStream);
        if FileText = '' then
            exit;

        JsonText := TypeHelper.ReadAsTextWithSeparator(IStream, '');
        ReadUseCaseTree(JsonText);
    end;

    procedure ReadUseCaseTree(JsonText: Text)
    var
        JToken: JsonToken;
        JArray: JsonArray;
    begin
        JArray.ReadFrom(JsonText);
        foreach JToken in JArray do
            ReadUseCaseTree(JToken.AsObject());
        Indent();
    end;

    local procedure ExportSingleTreeNode(UseCaseTreeNode: Record "Use Case Tree Node"; var JArray: JsonArray)
    var
        UseCase: Record "Tax Use Case";
        IStream: InStream;
        JObject: JsonObject;
        Txt: Text;
        ConditionTxt: Text;
    begin
        JObject.Add('Code', UseCaseTreeNode.Code);
        JObject.Add('Name', UseCaseTreeNode.Name);
        JObject.Add('NodeType', format(UseCaseTreeNode."Node Type"));
        JObject.Add('TableID', UseCaseTreeNode."Table ID");
        if UseCase.Get(UseCaseTreeNode."Use Case ID") then
            JObject.Add('UseCaseName', UseCase.Description);

        UseCaseTreeNode.CalcFields(Condition);
        if UseCaseTreeNode.Condition.HasValue then begin
            UseCaseTreeNode.Condition.CreateInStream(IStream);
            while not IStream.EOS do begin
                IStream.ReadText(Txt);
                ConditionTxt += Txt;
            end;
            JObject.Add('Condition', ConditionTxt);
        end;
        JObject.Add('TaxType', UseCaseTreeNode."Tax Type");
        JObject.Add('IsTaxTypeRoot', UseCaseTreeNode."Is Tax Type Root");
        JArray.Add(JObject);
    end;

    local procedure ReadUseCaseTree(JObject: JsonObject)
    var
        UseCaseTree: Record "Use Case Tree Node";
        UseCase: Record "Tax Use Case";
        ScriptDataTypeMgmt: Codeunit "Script Data Type Mgmt.";
        OStream: OutStream;
        JToken: JsonToken;
        property: Text;
    begin
        UseCaseTree.Init();
        foreach property in JObject.Keys() do begin
            JObject.Get(property, JToken);
            case property of
                'Code':
                    UseCaseTree.Code := JToken.AsValue().AsCode();
                'Name':
                    UseCaseTree.Name := JToken.AsValue().AsText();
                'NodeType':
                    UseCaseTree."Node Type" := ScriptDataTypeMgmt.GetFieldOptionIndex(Database::"Use Case Tree Node", UseCaseTree.FieldNo("Node Type"), JToken.AsValue().AsText());
                'TableID':
                    UseCaseTree."Table ID" := JToken.AsValue().AsInteger();
                'UseCaseName':
                    begin
                        UseCase.SetRange(Description, JToken.AsValue().AsText());
                        UseCase.FindFirst();
                        UseCaseTree."Use Case ID" := UseCase.ID;
                        UseCaseTree.Name := CopyStr(UseCase.Description, 1, 250);
                    end;
                'Condition':
                    begin
                        UseCaseTree.Condition.CreateOutStream(OStream);
                        OStream.WriteText(JToken.AsValue().AsText());
                    end;
                'TaxType':
                    UseCaseTree."Tax Type" := JToken.AsValue().AsCode();
                'IsTaxTypeRoot':
                    UseCaseTree."Is Tax Type Root" := JToken.AsValue().AsBoolean();
            end;
        end;
        UseCaseTree.Insert();
    end;
}