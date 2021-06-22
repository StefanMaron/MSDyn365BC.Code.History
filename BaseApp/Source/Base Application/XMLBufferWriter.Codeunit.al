codeunit 1235 "XML Buffer Writer"
{

    trigger OnRun()
    begin
    end;

    var
        GetJsonStructure: Codeunit "Get Json Structure";
        XmlReader: DotNet XmlReader;
        XmlReaderSettings: DotNet XmlReaderSettings;
        XmlUrlResolver: DotNet XmlUrlResolver;
        XmlDtdProcessing: DotNet DtdProcessing;
        XmlNodeType: DotNet XmlNodeType;
        NetCredentialCache: DotNet CredentialCache;
        StringReader: DotNet StringReader;
        OnlyGenerateStructure: Boolean;
        UnsupportedInputTypeErr: Label 'The supplied variable type is not supported.';
        ValueStringToLongErr: Label '%1 must not be longer than %2.', Comment = '%1 field Value; %2 the length of the string';
        rdfaboutTok: Label 'rdf:about', Locked = true;

    [Scope('OnPrem')]
    procedure InitializeXMLBufferFrom(var XMLBuffer: Record "XML Buffer"; StreamOrServerFile: Variant)
    begin
        OnlyGenerateStructure := false;
        InitializeXMLReaderSettings;
        CreateXMLReaderFrom(StreamOrServerFile);
        ReadXmlReader;
        ParseXML(XMLBuffer);
    end;

    procedure InitializeXMLBufferFromStream(var XMLBuffer: Record "XML Buffer"; XmlStream: InStream)
    begin
        OnlyGenerateStructure := false;
        InitializeXMLReaderSettings;
        CreateXMLReaderFromInStream(XmlStream);
        ReadXmlReader;
        ParseXML(XMLBuffer);
    end;

    procedure InitializeXMLBufferFromText(var XMLBuffer: Record "XML Buffer"; XmlText: Text)
    begin
        InitializeXMLReaderSettings;
        CreateXmlReaderFromXmlText(XmlText);
        ReadXmlReader;
        ParseXML(XMLBuffer);
    end;

    [Scope('OnPrem')]
    procedure GenerateStructureFromPath(var XMLBuffer: Record "XML Buffer"; Path: Text)
    begin
        OnlyGenerateStructure := true;
        InitializeXMLReaderSettings;
        CreateXMLReaderFromPath(Path);
        if ReadXmlReader then
            ParseXML(XMLBuffer)
        else
            GetJsonStructure.GenerateStructure(Path, XMLBuffer);
    end;

    procedure GenerateStructure(var XMLBuffer: Record "XML Buffer"; OutStream: OutStream)
    begin
        InitializeXMLReaderSettings;
        CreateXMLReaderFromOutStream(OutStream);
        ReadXmlReader;
        ParseXML(XMLBuffer);
    end;

    local procedure CreateXMLReaderFrom(StreamOrServerFile: Variant)
    begin
        case true of
            StreamOrServerFile.IsText:
                CreateXMLReaderFromPath(StreamOrServerFile);
            StreamOrServerFile.IsInStream:
                CreateXMLReaderFromInStream(StreamOrServerFile);
            StreamOrServerFile.IsOutStream:
                CreateXMLReaderFromOutStream(StreamOrServerFile);
            else
                Error(UnsupportedInputTypeErr);
        end;
    end;

    local procedure CreateXMLReaderFromPath(Path: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.IsAllowedPath(Path, false);
        XmlReader := XmlReader.Create(Path, XmlReaderSettings);
    end;

    local procedure CreateXMLReaderFromInStream(InStream: InStream)
    begin
        XmlReader := XmlReader.Create(InStream, XmlReaderSettings);
    end;

    local procedure CreateXMLReaderFromOutStream(OutStream: OutStream)
    begin
        XmlReader := XmlReader.Create(OutStream, XmlReaderSettings);
    end;

    local procedure CreateXmlReaderFromXmlText(XmlText: Text)
    begin
        StringReader := StringReader.StringReader(XmlText);
        XmlReader := XmlReader.Create(StringReader, XmlReaderSettings);
    end;

    local procedure InitializeXMLReaderSettings()
    begin
        XmlUrlResolver := XmlUrlResolver.XmlUrlResolver;
        XmlUrlResolver.Credentials := NetCredentialCache.DefaultNetworkCredentials;

        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings;
        XmlReaderSettings.DtdProcessing := XmlDtdProcessing.Ignore;
        XmlReaderSettings.XmlResolver := XmlUrlResolver;
    end;

    local procedure ParseXML(var XMLBuffer: Record "XML Buffer")
    var
        ParentXMLBuffer: Record "XML Buffer";
    begin
        if XMLBuffer.FindLast then;

        ParentXMLBuffer.Init();
        ParseXMLIteratively(XMLBuffer, ParentXMLBuffer);

        XmlReader.Close;
        XMLBuffer.Reset();
        XMLBuffer.SetRange("Import ID", XMLBuffer."Import ID");
        XMLBuffer.FindFirst;
    end;

    local procedure ParseXMLIteratively(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer")
    var
        LastInsertedXMLBufferElement: Record "XML Buffer";
        ElementNumber: Integer;
        Depth: Integer;
        ProcessingInstructionNumber: Integer;
    begin
        Depth := XmlReader.Depth;
        repeat
            if IsParentElement(Depth) then
                exit;
            ParseCurrentXmlNode(XMLBuffer, ParentXMLBuffer, LastInsertedXMLBufferElement, ElementNumber, Depth, ProcessingInstructionNumber);
        until not XmlReader.Read;
    end;

    local procedure ParseCurrentXmlNode(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; var LastInsertedXMLBufferElement: Record "XML Buffer"; var ElementNumber: Integer; Depth: Integer; var ProcessingInstructionNumber: Integer)
    begin
        if IsParentElement(Depth) then
            exit;
        if IsChildElement(Depth) then begin
            ParseXMLIteratively(XMLBuffer, LastInsertedXMLBufferElement);
            ParseCurrentXmlNode(XMLBuffer, ParentXMLBuffer, LastInsertedXMLBufferElement, ElementNumber, Depth, ProcessingInstructionNumber);
        end else
            ReadAndInsertXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber, LastInsertedXMLBufferElement, ProcessingInstructionNumber);
    end;

    local procedure IsChildElement(CurrentDepth: Integer): Boolean
    begin
        exit(XmlReader.Depth > CurrentDepth)
    end;

    local procedure IsParentElement(CurrentDepth: Integer): Boolean
    begin
        exit(XmlReader.Depth < CurrentDepth)
    end;

    local procedure ReadAndInsertXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; var ElementNumber: Integer; var InsertedXMLBufferElement: Record "XML Buffer"; var ProcessingInstructionNumber: Integer)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        XmlNodeType := XmlReader.NodeType;
        if XmlNodeType.Equals(XmlNodeType.Element) then begin
            ElementNumber += 1;
            ProcessXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber, InsertedXMLBufferElement)
        end else
            if XmlNodeType.Equals(XmlNodeType.Text) then begin
                if XMLBuffer.IsTemporary then begin
                    TempXMLBuffer.Copy(XMLBuffer, true);
                    TempXMLBuffer := ParentXMLBuffer;
                    AddXmlTextNodeIntoParentXMLBuffer(TempXMLBuffer);
                end else
                    AddXmlTextNodeIntoParentXMLBuffer(ParentXMLBuffer);
            end else
                if XmlNodeType.Equals(XmlNodeType.ProcessingInstruction) then begin
                    ProcessingInstructionNumber += 1;
                    InsertXmlProcessingInstruction(XMLBuffer, ParentXMLBuffer, ProcessingInstructionNumber)
                end else
                    if XmlNodeType.Equals(XmlNodeType.XmlDeclaration) or
                       XmlNodeType.Equals(XmlNodeType.Comment)
                    then
                        ;
    end;

    local procedure ProcessXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; var InsertedXMLBufferElement: Record "XML Buffer")
    var
        AttributeNumber: Integer;
    begin
        InsertXmlElement(XMLBuffer, ParentXMLBuffer, ElementNumber);
        InsertedXMLBufferElement := XMLBuffer;

        if XmlReader.MoveToFirstAttribute then
            repeat
                AttributeNumber += 1;
                InsertXmlAttribute(XMLBuffer, InsertedXMLBufferElement, AttributeNumber);
            until not XmlReader.MoveToNextAttribute;
    end;

    local procedure InsertXmlElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer)
    begin
        with XMLBuffer do begin
            if OnlyGenerateStructure then begin
                Reset;
                SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
                SetRange(Type, Type::Element);
                SetRange(Name, XmlReader.Name);
                if FindFirst then
                    exit;
            end;

            InsertElement(XMLBuffer, ParentXMLBuffer, ElementNumber, XmlReader.Depth + 1, XmlReader.Name, '');
        end;
    end;

    local procedure InsertXmlAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; AttributeNumber: Integer)
    begin
        with XMLBuffer do begin
            if OnlyGenerateStructure then begin
                Reset;
                SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
                SetRange(Type, Type::Attribute);
                SetRange(Name, XmlReader.Name);
                if FindFirst then
                    exit;
            end;

            if CanPassValue(XmlReader.Name, XmlReader.Value) then
                InsertAttribute(XMLBuffer, ParentXMLBuffer, AttributeNumber, XmlReader.Depth + 1, XmlReader.Name, XmlReader.Value);
        end;
    end;

    local procedure InsertXmlProcessingInstruction(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ProcessingInstructionNumber: Integer)
    begin
        with XMLBuffer do begin
            if OnlyGenerateStructure then begin
                Reset;
                SetRange("Parent Entry No.", ParentXMLBuffer."Entry No.");
                SetRange(Type, Type::"Processing Instruction");
                SetRange(Name, XmlReader.Name);
                if FindFirst then
                    exit;
            end;

            InsertProcessingInstruction(XMLBuffer, ParentXMLBuffer, ProcessingInstructionNumber, XmlReader.Depth + 1
              , XmlReader.Name, XmlReader.Value);
        end;
    end;

    local procedure GetType(Value: Text): Integer
    var
        DummyXMLBuffer: Record "XML Buffer";
        Decimal: Decimal;
    begin
        if Value = '' then
            exit(DummyXMLBuffer."Data Type"::Text);

        if Evaluate(Decimal, Value) then
            exit(DummyXMLBuffer."Data Type"::Decimal);

        exit(DummyXMLBuffer."Data Type"::Text)
    end;

    local procedure AddXmlTextNodeIntoParentXMLBuffer(var XMLBuffer: Record "XML Buffer")
    begin
        if XMLBuffer.Value <> '' then
            exit;

        XMLBuffer.SetValueWithoutModifying(XmlReader.Value);
        XMLBuffer.Validate("Data Type", GetType(XMLBuffer.Value));
        XMLBuffer.Modify();
    end;

    procedure InsertAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; AttributeName: Text; AttributeValue: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAttribute(XMLBuffer, ParentXMLBuffer, NodeNumber, NodeDepth, AttributeName, AttributeValue, IsHandled);
        IF IsHandled then
            exit;

        with XMLBuffer do begin
            Reset;
            if FindLast then;
            Init;
            "Entry No." += 1;
            "Parent Entry No." := ParentXMLBuffer."Entry No.";
            Path := CopyStr(ParentXMLBuffer.Path + '/@' + AttributeName, 1, MaxStrLen(Path));
            "Node Number" := NodeNumber;
            Name := AttributeName;
            Value := CopyStr(AttributeValue, 1, MaxStrLen(Value));
            Depth := NodeDepth;
            "Data Type" := GetType(Value);
            Type := Type::Attribute;
            "Import ID" := ParentXMLBuffer."Import ID";

            Insert;
        end;
    end;

    procedure InsertElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; ElementDepth: Integer; ElementNameAndNamespace: Text; ElementValue: Text)
    var
        ElementName: Text;
        ElementNamespace: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertElement(XMLBuffer, ParentXMLBuffer, ElementNumber, ElementDepth, ElementNameAndNamespace, ElementValue, IsHandled);
        IF IsHandled then
            exit;

        SplitXmlElementName(ElementNameAndNamespace, ElementName, ElementNamespace);

        if IsNullGuid(ParentXMLBuffer."Import ID") then
            ParentXMLBuffer."Import ID" := CreateGuid;

        with XMLBuffer do begin
            Reset;
            if FindLast then;
            Init;
            "Entry No." += 1;
            "Parent Entry No." := ParentXMLBuffer."Entry No.";
            Path := CopyStr(StrSubstNo('%1/%2', ParentXMLBuffer.Path, ElementNameAndNamespace), 1, MaxStrLen(Path));
            "Node Number" := ElementNumber;
            Depth := ElementDepth;
            Name := CopyStr(ElementName, 1, MaxStrLen(Name));
            SetValueWithoutModifying(ElementValue);
            Type := Type::Element;
            Namespace := CopyStr(ElementNamespace, 1, MaxStrLen(Namespace));
            "Import ID" := ParentXMLBuffer."Import ID";

            Insert;
        end;
    end;

    procedure InsertProcessingInstruction(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; InstructionName: Text; InstructionValue: Text)
    begin
        with XMLBuffer do begin
            Reset;
            if FindLast then;
            Init;
            "Entry No." += 1;
            "Parent Entry No." := ParentXMLBuffer."Entry No.";
            Path := CopyStr(ParentXMLBuffer.Path + '/processing-instruction(''' + InstructionName + ''')', 1, MaxStrLen(Path));
            "Node Number" := NodeNumber;
            Depth := NodeDepth;
            Name := CopyStr(InstructionName, 1, MaxStrLen(Name));
            SetValueWithoutModifying(InstructionValue);
            Type := Type::"Processing Instruction";
            "Import ID" := ParentXMLBuffer."Import ID";

            Insert;
        end;
    end;

    local procedure SplitXmlElementName(RawXmlElementName: Text; var ElementName: Text; var ElementNamespace: Text)
    var
        ColonPosition: Integer;
    begin
        ColonPosition := StrPos(RawXmlElementName, ':');
        if ColonPosition <> 0 then begin
            ElementNamespace := CopyStr(RawXmlElementName, 1, ColonPosition - 1);
            ElementName := CopyStr(RawXmlElementName, ColonPosition + 1);
        end else begin
            ElementName := RawXmlElementName;
            ElementNamespace := '';
        end;
    end;

    [TryFunction]
    local procedure ReadXmlReader()
    begin
        XmlReader.Read
    end;

    local procedure CanPassValue(Name: Text; Value: Text): Boolean
    var
        XMLBuffer: Record "XML Buffer";
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanPassValue(Name, Value, ReturnValue, IsHandled);
        IF IsHandled then
            exit(ReturnValue);

        if StrLen(Value) <= MaxStrLen(XMLBuffer.Value) then
            exit(true);
        if Name = rdfaboutTok then
            exit(false);
        Error(ValueStringToLongErr, XMLBuffer.FieldCaption(Value), MaxStrLen(XMLBuffer.Value))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanPassValue(Name: Text; var Value: Text; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttribute(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; NodeNumber: Integer; NodeDepth: Integer; var AttributeName: Text; var AttributeValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertElement(var XMLBuffer: Record "XML Buffer"; ParentXMLBuffer: Record "XML Buffer"; ElementNumber: Integer; ElementDepth: Integer; ElementNameAndNamespace: Text; ElementValue: Text; var IsHandled: Boolean);
    begin
    end;
}

