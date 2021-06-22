codeunit 5306 "Outlook Synch. Export Schema"
{

    trigger OnRun()
    begin
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchField: Record "Outlook Synch. Field";
        SortedEntitiesBuffer: Record "Outlook Synch. Lookup Name" temporary;
        OSynchSetupDetail: Record "Outlook Synch. Setup Detail";
        Base64Convert: Codeunit "Base64 Convert";
        OSynchTypeConversion: Codeunit "Outlook Synch. Type Conv";
        OsynchOutlookMgt: Codeunit "Outlook Synch. Outlook Mgt.";
        XMLWriter: DotNet "OLSync.Common.XmlTextWriter";
        Text001: Label 'The synchronization failed because the synchronization data could not be sent from %1. Try again later and if the problem persists contact your system administrator.', Comment = '%1 - product name';
        Text002: Label 'The synchronization failed because the %1 user has no entities to synchronize. Try again later and if the problem persists contact your system administrator.';
        Text003: Label 'The synchronization failed because the synchronization data from Microsoft Outlook cannot be processed. Try again later and if the problem persists contact your system administrator.';

    [Scope('OnPrem')]
    procedure Export(UserID: Text[50]; var XMLMessage: Text)
    var
        OsynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        OsynchNAVMgt.GetSortedEntities(UserID, SortedEntitiesBuffer, true);
        SendMappingScheme(UserID, XMLMessage);
    end;

    [Scope('OnPrem')]
    procedure SendMappingScheme(UserID: Code[50]; var XMLMessage: Text)
    var
        XMLTextReader: DotNet "OLSync.Common.XmlTextReader";
        TempDateTime: DateTime;
        OutlookCheckSum: Text[250];
        CurrentCheckSum: Text[250];
    begin
        if not SortedEntitiesBuffer.Find('-') then
            Error(Text002, UserID);

        Clear(XMLTextReader);
        XMLTextReader := XMLTextReader.XmlTextReader;
        TempDateTime := OSynchTypeConversion.LocalDT2UTC(CurrentDateTime);

        if not XMLTextReader.LoadXml(XMLMessage) then
            Error(Text003);

        if IsNull(XMLWriter) then
            XMLWriter := XMLWriter.XmlTextWriter;

        XMLWriter.WriteStartDocument;
        XMLWriter.WriteStartElement('Schema');
        XMLWriter.WriteAttribute('StartSynchTime', Format(OSynchTypeConversion.SetDateTimeFormat(TempDateTime)));

        repeat
            OSynchEntity.Get(SortedEntitiesBuffer.Name);
            if OSynchEntity."Outlook Item" <> '' then
                ComposeSynchEntityNode(OSynchEntity, UserID);
        until SortedEntitiesBuffer.Next = 0;

        XMLWriter.WriteEndElement;
        XMLWriter.WriteEndDocument;

        OutlookCheckSum := GetOutlookSchemaCheckSum(XMLTextReader);
        if OutlookCheckSum <> '' then
            CurrentCheckSum := GetCurrentSchemaCheckSum(XMLWriter);

        if (OutlookCheckSum <> '') and (OutlookCheckSum = CurrentCheckSum) then
            PutCurrentSchemaCheckSum(XMLWriter, CurrentCheckSum, TempDateTime);

        XMLMessage := XMLWriter.ToString;

        if StrLen(XMLMessage) = 0 then begin
            Clear(XMLWriter);
            Error(Text001, PRODUCTNAME.Full);
        end;

        Clear(XMLWriter);
    end;

    local procedure ComposeSynchEntityNode(OSynchEntity1: Record "Outlook Synch. Entity"; UserID: Code[50])
    var
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        TempOSynchField: Record "Outlook Synch. Field" temporary;
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        IntVar: Integer;
    begin
        if IsNull(XMLWriter) then
            exit;

        OSynchEntity1.TestField(Code);
        OSynchUserSetup.Get(UserID, OSynchEntity1.Code);
        IntVar := OSynchUserSetup."Synch. Direction";

        XMLWriter.WriteStartElement('SynchEntity');
        XMLWriter.WriteAttribute('Code', OSynchEntity1.Code);
        XMLWriter.WriteAttribute('Description', OSynchEntity1.Description);
        XMLWriter.WriteAttribute('OutlookItemType', OSynchEntity1."Outlook Item");
        XMLWriter.WriteAttribute('SynchDirection', Format(IntVar));

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntity1.Code);
        OSynchField.SetRange("Element No.", 0);
        OSynchField.SetFilter("Outlook Object", '<>%1', '');
        OSynchField.SetFilter("Outlook Property", '<>%1', '');
        if OSynchField.Find('-') then
            repeat
                TempOSynchField.Reset();
                TempOSynchField.SetRange("Synch. Entity Code", OSynchField."Synch. Entity Code");
                TempOSynchField.SetRange("Element No.", OSynchField."Element No.");
                TempOSynchField.SetRange("Outlook Property", OSynchField."Outlook Property");
                if not TempOSynchField.Find('-') then begin
                    TempOSynchField.Init();
                    TempOSynchField := OSynchField;
                    TempOSynchField.Insert();
                end;
            until OSynchField.Next = 0;

        TempOSynchField.Reset();
        if TempOSynchField.Find('-') then
            repeat
                ComposeFieldNode(TempOSynchField);
            until TempOSynchField.Next = 0;

        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetCurrentKey("Table No.");
        OSynchSetupDetail.SetRange("Synch. Entity Code", OSynchEntity1.Code);
        OSynchSetupDetail.SetRange("User ID", UserID);
        if OSynchSetupDetail.Find('-') then
            repeat
                OSynchEntityElement.Get(OSynchSetupDetail."Synch. Entity Code", OSynchSetupDetail."Element No.");
                if OSynchEntityElement."Outlook Collection" <> '' then
                    ComposeCollectionNode(OSynchEntityElement);
            until OSynchSetupDetail.Next = 0;

        XMLWriter.WriteEndElement;
    end;

    local procedure ComposeFieldNode(OSynchFieldIn: Record "Outlook Synch. Field")
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if IsNull(XMLWriter) then
            exit;

        OSynchFieldIn.TestField("Synch. Entity Code");
        OSynchFieldIn.TestField("Line No.");

        XMLWriter.WriteStartElement('Field');
        if OSynchFieldIn."Outlook Property" <> '' then
            XMLWriter.WriteAttribute('Name', OSynchFieldIn."Outlook Property");

        if OSynchFieldIn."Read-Only Status" <> OSynchFieldIn."Read-Only Status"::" " then begin
            RecRef.GetTable(OSynchFieldIn);
            FldRef := RecRef.Field(OSynchFieldIn.FieldNo("Read-Only Status"));

            XMLWriter.WriteAttribute('Read-OnlyStatus', SelectStr(OSynchFieldIn."Read-Only Status" + 1, FldRef.OptionMembers));
            RecRef.Close
        end;

        if OSynchFieldIn."User-Defined" then
            XMLWriter.WriteAttribute('User-Defined', OSynchTypeConversion.SetBoolFormat(OSynchFieldIn."User-Defined"));

        if OSynchFieldIn."Search Field" then
            XMLWriter.WriteAttribute('SearchKey', OSynchTypeConversion.SetBoolFormat(OSynchFieldIn."Search Field"));

        if OSynchFieldIn."Table No." = 0 then
            Field.Get(OSynchFieldIn."Master Table No.", OSynchFieldIn."Field No.")
        else
            Field.Get(OSynchFieldIn."Table No.", OSynchFieldIn."Field No.");

        if Field.Type = Field.Type::BLOB then
            XMLWriter.WriteAttribute('Base64', OSynchTypeConversion.SetBoolFormat(true));

        XMLWriter.WriteEndElement;
    end;

    local procedure ComposeCollectionNode(OSynchEntityElementIn: Record "Outlook Synch. Entity Element")
    var
        TempOSynchField: Record "Outlook Synch. Field" temporary;
        OSynchDependency: Record "Outlook Synch. Dependency";
    begin
        if IsNull(XMLWriter) then
            exit;

        OSynchEntityElementIn.TestField("Synch. Entity Code");
        OSynchEntityElementIn.TestField("Element No.");

        XMLWriter.WriteStartElement('Collection');
        XMLWriter.WriteAttribute('Name', OSynchEntityElementIn."Outlook Collection");

        OSynchField.Reset();
        OSynchField.SetRange("Synch. Entity Code", OSynchEntityElementIn."Synch. Entity Code");
        OSynchField.SetRange("Element No.", OSynchEntityElementIn."Element No.");
        OSynchField.SetFilter("Outlook Object", '<>%1', '');
        OSynchField.SetFilter("Outlook Property", '<>%1', '');
        if OSynchField.Find('-') then
            repeat
                TempOSynchField.Reset();
                TempOSynchField.SetRange("Synch. Entity Code", OSynchField."Synch. Entity Code");
                TempOSynchField.SetRange("Element No.", OSynchField."Element No.");
                TempOSynchField.SetRange("Outlook Property", OSynchField."Outlook Property");
                if not TempOSynchField.Find('-') then begin
                    TempOSynchField.Init();
                    TempOSynchField := OSynchField;
                    TempOSynchField.Insert();
                end;
            until OSynchField.Next = 0;

        TempOSynchField.Reset();
        if TempOSynchField.Find('-') then
            repeat
                ComposeFieldNode(TempOSynchField);
            until TempOSynchField.Next = 0;

        OSynchDependency.Reset();
        OSynchDependency.SetRange("Synch. Entity Code", TempOSynchField."Synch. Entity Code");
        OSynchDependency.SetRange("Element No.", TempOSynchField."Element No.");
        if OSynchDependency.FindFirst then begin
            TempOSynchField.SetRange("Search Field", true);
            if TempOSynchField.Find('-') then
                repeat
                    ComposeSearchFieldNode(TempOSynchField, OSynchDependency);
                until TempOSynchField.Next = 0;
        end;

        XMLWriter.WriteEndElement;
    end;

    local procedure ComposeSearchFieldNode(OSynchFieldIn: Record "Outlook Synch. Field"; OSynchDependency: Record "Outlook Synch. Dependency")
    var
        OSynchField1: Record "Outlook Synch. Field";
        SearchKeyBuffer: Record "Outlook Synch. Lookup Name" temporary;
    begin
        if IsNull(XMLWriter) then
            exit;

        XMLWriter.WriteStartElement('SearchKey');
        XMLWriter.WriteAttribute('Field', OSynchFieldIn."Outlook Property");

        if OSynchDependency.Find('-') then
            repeat
                OSynchField.Reset();
                OSynchField.SetRange("Synch. Entity Code", OSynchFieldIn."Synch. Entity Code");
                OSynchField.SetRange("Element No.", OSynchFieldIn."Element No.");
                OSynchField.SetRange("Outlook Property", OSynchFieldIn."Outlook Property");
                if OSynchField.Find('-') then
                    repeat
                        OSynchEntity.Get(OSynchDependency."Depend. Synch. Entity Code");
                        OSynchField1.Reset();
                        OSynchField1.SetRange("Synch. Entity Code", OSynchEntity.Code);
                        OSynchField1.SetRange("Element No.", 0);
                        if OSynchField."Table No." = 0 then
                            if OSynchField."Master Table No." = OSynchEntity."Table No." then
                                OSynchField1.SetRange("Table No.", 0)
                            else
                                OSynchField1.SetRange("Table No.", OSynchField."Master Table No.")
                        else
                            if OSynchField."Table No." = OSynchEntity."Table No." then
                                OSynchField1.SetRange("Table No.", 0)
                            else
                                OSynchField1.SetRange("Table No.", OSynchField."Table No.");

                        OSynchField1.SetRange("Field No.", OSynchField."Field No.");
                        if OSynchField1.FindFirst then begin
                            SearchKeyBuffer.Reset();
                            SearchKeyBuffer.SetRange(Name, OSynchEntity.Code);
                            if not SearchKeyBuffer.FindFirst then begin
                                XMLWriter.WriteStartElement('Entity');
                                XMLWriter.WriteAttribute('Name', OSynchEntity.Code);
                                XMLWriter.WriteAttribute('Field', OSynchField1."Outlook Property");
                                XMLWriter.WriteEndElement;

                                SearchKeyBuffer.Init();
                                SearchKeyBuffer."Entry No." := SearchKeyBuffer."Entry No." + 1;
                                SearchKeyBuffer.Name := OSynchEntity.Code;
                                SearchKeyBuffer.Insert();
                            end;
                        end;
                    until OSynchField.Next = 0;
            until OSynchDependency.Next = 0;

        XMLWriter.WriteEndElement;
    end;

    local procedure GetOutlookSchemaCheckSum(XmlTextReader: DotNet "OLSync.Common.XmlTextReader") CheckSum: Text[250]
    var
        Container: Text;
        RootIterator: Text[38];
    begin
        if IsNull(XmlTextReader) then
            Error(Text003);

        if XmlTextReader.RootLocalName <> 'Schema' then
            Error(Text003);

        if XmlTextReader.SelectElements(RootIterator, 'child::CheckSum') > 0 then begin
            Container := Base64Convert.FromBase64(XmlTextReader.GetValue(RootIterator));
            CheckSum := CopyStr(Container, 1, 250);
        end;
    end;

    local procedure GetCurrentSchemaCheckSum(var XMLTextWriter: DotNet "OLSync.Common.XmlTextWriter") CheckSum: Text[250]
    var
        XmlTextReader: DotNet "OLSync.Common.XmlTextReader";
        Container: DotNet String;
        CarriageChar: Char;
        ReturnChar: Char;
    begin
        XmlTextReader := XmlTextReader.XmlTextReader;
        XmlTextReader.Initialize(XMLTextWriter);
        XmlTextReader.XPathNavigator.MoveToRoot;
        Container := XmlTextReader.XPathNavigator.InnerXml;
        // Remove the first line of the container (contains timestamp)
        Container := Container.Substring(Container.IndexOf('<SynchEntity'));
        // Remove all \r from \r\n as the recipent over the wire will only recieve \n.
        CarriageChar := 13;
        ReturnChar := 10;
        Container := Container.Replace(Format(CarriageChar) + Format(ReturnChar), Format(ReturnChar));
        CheckSum := OsynchOutlookMgt.ComputeHash(Container);
        Clear(XmlTextReader);
    end;

    local procedure PutCurrentSchemaCheckSum(var XMLTextWriter: DotNet "OLSync.Common.XmlTextWriter"; CheckSumText: Text[250]; StartDateTime: DateTime)
    var
        TempOSynchLink: Record "Outlook Synch. Link" temporary;
        OutStrm: OutStream;
        EntryIDContainer: Text;
    begin
        Clear(XMLTextWriter);
        Clear(EntryIDContainer);

        XMLTextWriter := XMLTextWriter.XmlTextWriter;

        XMLTextWriter.WriteStartDocument;
        XMLTextWriter.WriteStartElement('Schema');
        XMLWriter.WriteAttribute('StartSynchTime', Format(OSynchTypeConversion.SetDateTimeFormat(StartDateTime)));

        XMLTextWriter.WriteStartElement('CheckSum');
        if CheckSumText <> '' then begin
            Clear(TempOSynchLink);
            Clear(OutStrm);
            TempOSynchLink.Reset();
            TempOSynchLink.Init();
            TempOSynchLink."Outlook Entry ID".CreateOutStream(OutStrm);
            TempOSynchLink.Insert();
            if OutStrm.WriteText(CheckSumText, StrLen(CheckSumText)) > 0 then begin
                TempOSynchLink.CalcFields("Outlook Entry ID");
                if TempOSynchLink.GetEntryID(EntryIDContainer) then
                    XMLTextWriter.WriteElementTextContent(Base64Convert.ToBase64(EntryIDContainer));
            end;
        end;
        XMLTextWriter.WriteEndElement;
        XMLTextWriter.WriteEndElement;
    end;
}

