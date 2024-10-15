report 11406 "Process Response Messages"
{
    Caption = 'Process Response Messages';
    Permissions = TableData "Elec. Tax Decl. Error Log" = i,
                  TableData "Elec. Tax Decl. Response Msg." = m;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Elec. Tax Decl. Response Msg."; "Elec. Tax Decl. Response Msg.")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending) WHERE(Status = CONST(Received));

            trigger OnAfterGetRecord()
            var
                ErrorLog: Record "Elec. Tax Decl. Error Log";
                XMLDOMManagement: Codeunit "XML DOM Management";
                XMLDoc: DotNet XmlDocument;
                InStream: InStream;
                NodeList: DotNet XmlNodeList;
                XmlNode: DotNet XmlNode;
                Index: Integer;
                NextErrorNo: Integer;
            begin
                if not ElecTaxDeclHeader.Get("Declaration Type", "Declaration No.") then
                    Error(HeaderNotFoundErr, "Declaration Type", "Declaration No.");

                ErrorLog.Reset();
                ErrorLog.SetRange("Declaration Type", "Declaration Type");
                ErrorLog.SetRange("Declaration No.", "Declaration No.");
                if not ErrorLog.FindLast then
                    ErrorLog."No." := 0;
                NextErrorNo := ErrorLog."No." + 1;

                CalcFields(Message);
                if Message.HasValue and ("Status Code" in ['311']) then begin
                    Message.CreateInStream(InStream);
                    XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, XMLDoc);

                    NodeList := XMLDoc.GetElementsByTagName('msg');
                    for Index := 0 to NodeList.Count - 1 do begin
                        XmlNode := NodeList.ItemOf(Index);

                        ErrorLog.Init();
                        ErrorLog."No." := NextErrorNo;
                        ErrorLog."Declaration Type" := "Declaration Type";
                        ErrorLog."Declaration No." := "Declaration No.";
                        ErrorLog."Error Class" := CopyStr(GetAttributeValue(XmlNode, 'level'), 1, MaxStrLen(ErrorLog."Error Class"));
                        ErrorLog."Error Description" := CopyStr(XmlNode.InnerXml, 1, MaxStrLen(ErrorLog."Error Description"));

                        ErrorLog.Insert(true);
                        NextErrorNo += 1;
                    end;
                end;

                case "Status Code" of
                    '210', '220', '311', '410', '510', '710':
                        ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Error;
                    '230', '321', '420', '720':
                        if ElecTaxDeclHeader.Status <> ElecTaxDeclHeader.Status::Error then
                            ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Warning;
                    '100':
                        if not (ElecTaxDeclHeader.Status in [ElecTaxDeclHeader.Status::Error, ElecTaxDeclHeader.Status::Warning]) then
                            ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Acknowledged;
                end;

                ElecTaxDeclHeader."Date Received" := Today;
                ElecTaxDeclHeader."Time Received" := Time;

                Status := Status::Processed;
                Modify(true);

                ElecTaxDeclHeader.Modify(true);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        HeaderNotFoundErr: Label 'Elec. Tax Declaration header %1,%2 could not be found.';

    local procedure GetAttributeValue(var XMLNode: DotNet XmlNode; "Key": Text): Text
    var
        XmlAttNode: DotNet XmlNode;
        XmlAttributes: DotNet XmlAttributeCollection;
    begin
        XmlAttributes := XMLNode.Attributes;
        XmlAttNode := XmlAttributes.GetNamedItem(Key);
        exit(XmlAttNode.Value);
    end;
}

